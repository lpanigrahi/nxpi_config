-- migrate-1.15.0.sql — schema delta 1.14.0 → 1.15.0 (source migrations 0083,
-- 0084, 0085, 0086, 0087, 0088, 0089).
--
-- ADDITIVE-ONLY: six nullable-or-defaulted columns, five CHECK constraints
-- (each keyed on pg_constraint by name, so a database that already has one
-- takes a no-op). Nothing is dropped, narrowed or rewritten, so `./update.sh`'s
-- rolling (additive-only) path applies it with no maintenance window.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX
-- lines of this file (see 1.11.0's note): `apply_migrations` greps `head -n 6`.
--
-- WHY THIS FILE EXISTS (the SEVENTH occurrence of the incident class the
-- 1.14.0 header enumerates): source migrations 0082–0089 landed between the
-- cut of db/1.13.0 (0081) and the cut of db/1.14.0 (0090–0092) and were
-- packaged by NEITHER — 1.14.0's schema.sql was derived from the 1.13.0
-- lineage plus 0090–0092, so it lacks everything in between. The app image
-- built from the same tree reads `plugin_bundle.deleted_at` (0089) on EVERY
-- Plugins list/detail query (the soft-delete filter), so a VM at db 1.14.0
-- rolling that image 42703s on the Plugins tab. `plugin_bundle_install.enabled`
-- (0087) and `skill_install.enabled` (0085) are read on every chat-toolkit
-- resolution once an installer has toggled anything. The packaging guard
-- (`schema-sentinels.packaging.guard.test.ts`) stayed green because it is
-- sentinel-bound and no sentinel existed for 0081–0089; both the sentinels and
-- a migration-bound guard (`migrations-packaged.guard.test.ts`) now exist so
-- the next gap reds CI instead of a VM.
--
-- 0082 (DROP INDEX knowledge_embeddings_embedding_ivfflat_idx — a redundant
-- IVFFlat twin of the HNSW index, never read, metadata-only to drop) is
-- deliberately NOT in this file: the rolling path is additive-only by contract,
-- and a DROP, however safe, is not additive. It ships beside this file as
-- `optional-0082-drop-ivfflat-index.sql` (not matched by the `migrate-*.sql`
-- glob, so never applied automatically) with the operator step in the README.
-- Fresh installs from this directory's schema.sql never have that index.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas — every step is existence-guarded, so re-running is a no-op:
--   0083_model_pricing_cache_rates.sql        (model_pricing.cached_input_cost_per_1m / .cache_write_cost_per_1m)
--   0084_nav_visibility_scope_org.sql          (nav_visibility_override_scope_org_check, with a reconciling UPDATE)
--   0085_skill_install_chat_toggle.sql         (skill_install.enabled)
--   0086_plugin_bundle_reconciled_items.sql    (plugin_bundle_install.reconciled_items)
--   0087_plugin_bundle_install_chat_toggle.sql (plugin_bundle_install.enabled)
--   0088_plugin_bundle_enum_checks.sql         (plugin_bundle_{scope,status,publisher_kind}_check, plugin_bundle_item_resource_type_check)
--   0089_plugin_bundle_soft_delete.sql         (plugin_bundle.deleted_at)
-- No pre-flight duplicate check is needed: every new object is a column with
-- a constant default or no default, or a constraint whose 0084 delta first
-- reconciles the only rows that could violate it.
--
-- Verified by applying it TWICE consecutively against a database built from
-- db/1.14.0/schema.sql (a no-op the second time), then comparing the resulting
-- catalog — tables, columns with types/nullability/defaults, constraint names,
-- index names — against a database built fresh from this directory's
-- schema.sql: identical, except for `knowledge_embeddings_embedding_ivfflat_idx`,
-- which the upgraded lineage keeps until the optional 0082 step is run.
-- (CHECK-constraint BODIES do not byte-diff between the lineages — postgres
-- re-prints an `x IN (...)` predicate as `x = ANY (ARRAY[...])` — which is why
-- names, not bodies, are what the verification compares.)

-- ── 0083: operator-supplied cache rates for model_pricing ───────────────────
-- NULLABLE WITH NO DEFAULT, deliberately: absent means "no rate on file, bill
-- at the input rate"; 0 would mean "genuinely free". Inert on arrival.
ALTER TABLE model_pricing
  ADD COLUMN IF NOT EXISTS cached_input_cost_per_1m real,
  ADD COLUMN IF NOT EXISTS cache_write_cost_per_1m real;

-- ── 0084: nav_visibility_override — scope and organization_id must agree ────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'nav_visibility_override_scope_org_check'
      AND conrelid = 'nav_visibility_override'::regclass
  ) THEN
    -- Reconcile any pre-existing mismatch before constraining, so the delta
    -- cannot fail on legacy data.
    UPDATE nav_visibility_override
       SET scope = CASE WHEN organization_id IS NULL THEN 'global' ELSE 'org' END
     WHERE (scope = 'global') <> (organization_id IS NULL);

    ALTER TABLE nav_visibility_override
      ADD CONSTRAINT nav_visibility_override_scope_org_check
      CHECK ((scope = 'global') = (organization_id IS NULL));
  END IF;
END $$;

-- ── 0085: per-install chat enablement — the INSTALLER's switch ──────────────
-- DEFAULT TRUE NOT NULL: every existing install stays live; behavioural no-op.
ALTER TABLE "skill_install"
  ADD COLUMN IF NOT EXISTS "enabled" boolean NOT NULL DEFAULT true;

-- ── 0086: plugin_bundle_install.reconciled_items — last clean member set ────
-- NULLABLE with no default: NULL means "unknown", healed on the next pass.
ALTER TABLE "plugin_bundle_install"
  ADD COLUMN IF NOT EXISTS "reconciled_items" jsonb;

-- ── 0087: plugin_bundle_install.enabled — the INSTALLER's bundle switch ──────
-- DEFAULT TRUE NOT NULL: every existing bundle install stays live.
ALTER TABLE "plugin_bundle_install"
  ADD COLUMN IF NOT EXISTS "enabled" boolean NOT NULL DEFAULT true;

-- ── 0088: the plugin enums, at the DATABASE ─────────────────────────────────
-- A database whose plugin tables pre-date 0063's CHECKs (created by an earlier
-- db:push) took the IF-NOT-EXISTS no-op and has none of them; this adds them,
-- keyed on pg_constraint by name, and is a no-op where 0063 created the table.
DO $$
DECLARE
  ck RECORD;
BEGIN
  FOR ck IN
    SELECT * FROM (VALUES
      ('plugin_bundle_scope_check',              'plugin_bundle',      'scope',          $q$scope in ('personal','team','organization','enterprise','public')$q$),
      ('plugin_bundle_status_check',             'plugin_bundle',      'status',         $q$status in ('draft','pending_review','approved','published','rejected','suspended')$q$),
      ('plugin_bundle_publisher_kind_check',     'plugin_bundle',      'publisher_kind', $q$publisher_kind in ('platform','partner','community')$q$),
      ('plugin_bundle_item_resource_type_check', 'plugin_bundle_item', 'resource_type',  $q$resource_type in ('agent','skill','workflow','assistant','prompt','knowledge_pack','mcp')$q$)
    ) AS t(conname, tbl, col, expr)
  LOOP
    -- Skip cleanly when the table itself is absent (a database that has not
    -- reached 0063 yet): this delta constrains, it does not create.
    CONTINUE WHEN to_regclass(ck.tbl) IS NULL;
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE contype = 'c'
        AND conname = ck.conname
        AND conrelid = ck.tbl::regclass
    ) THEN
      EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I CHECK (%s)', ck.tbl, ck.conname, ck.expr);
    END IF;
  END LOOP;
END $$;

-- ── 0089: plugin_bundle.deleted_at — withdrawal without destruction ─────────
-- Nullable with no default: every existing row reads as live; no backfill.
-- READ ON EVERY PLUGINS QUERY by the app image — the column this delta most
-- urgently exists for.
ALTER TABLE "plugin_bundle" ADD COLUMN IF NOT EXISTS "deleted_at" timestamp;
