-- migrate-1.14.0.sql — schema delta 1.13.0 → 1.14.0 (source migrations 0090,
-- 0091, 0092).
--
-- ADDITIVE-ONLY: two new tables (plugin_source, plugin_source_entry), two new
-- nullable columns on plugin_bundle (source_id, origin), one new nullable
-- column on plugin_source (last_sync_notes), their indexes and FKs. Nothing is
-- dropped, narrowed or rewritten, so `./update.sh`'s rolling (additive-only)
-- path applies it with no maintenance window and no downtime.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX
-- lines of this file (see 1.11.0's note): `apply_migrations` greps `head -n 6`.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE (ADR-0105, Plugin Acquisition W1.1):
-- db/1.13.0 composes source migrations through 0081 only. Any image carrying
-- 0090-0092 (the plugin-source registry: a registered GitHub/git-URL/hosted-
-- marketplace source, its synced entries, and the acquisition provenance a
-- plugin_bundle records) therefore rolls AHEAD of the packaged delta, and
-- every read that selects plugin_bundle.origin — which the shipped Plugins
-- tab does on every list/detail render — 42703s. That is the SIXTH occurrence
-- of this incident class (1.6.0 qa_baseline_hash, 1.8.0 skill.deployed, 1.10.0
-- session.mfa_verified_at, 1.11.0 organization_entitlement, and the
-- 2026-07-28 skill.scope outage before them). `src/lib/db/schema-sentinels.ts`
-- now carries matching probes (plugin_source, plugin_bundle.origin,
-- plugin_source.last_sync_notes) so a mismatched VM says so at boot rather
-- than at the first request, and `schema-sentinels.packaging.guard.test.ts`
-- fails the build when a sentinel's migration has no packaged delta behind
-- it — this file is what keeps that guard green.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas — every step is existence-guarded, so re-running is a no-op:
--   0090_plugin_source.sql               (plugin_source, plugin_source_entry)
--   0091_plugin_bundle_origin.sql        (plugin_bundle.source_id / .origin)
--   0092_plugin_source_sync_notes.sql    (plugin_source.last_sync_notes)
-- No pre-flight duplicate check is needed here (unlike 1.11.0's org_invite/
-- invoice indexes): every new object is either a brand-new table or a
-- nullable column with no default, so there is no existing data an ADD
-- COLUMN or CREATE TABLE could conflict with.
--
-- Verified by applying it twice consecutively against a database built from
-- db/1.13.0/schema.sql (a no-op the second time), then diffing the resulting
-- catalog against a database built fresh from this directory's schema.sql —
-- the two lineages carry the same tables, columns, constraint NAMES, indexes
-- and FKs. (CHECK-constraint BODIES are the one thing that does not
-- byte-diff: postgres re-prints an `x = ANY (ARRAY[...]::type[])` expression
-- differently depending on whether it was parsed from an `IN (...)` clause or
-- from that already-printed form, which is what a raw reload of schema.sql
-- does to every pre-existing enum CHECK in the file, not only these three —
-- a cosmetic, pre-existing property of this dump/reload pair, not a
-- structural divergence.)
--
-- rollback:
--   ALTER TABLE plugin_source DROP COLUMN IF EXISTS last_sync_notes;
--   ALTER TABLE plugin_bundle DROP COLUMN IF EXISTS source_id, DROP COLUMN IF EXISTS origin;
--   DROP TABLE IF EXISTS plugin_source_entry;
--   DROP TABLE IF EXISTS plugin_source;
BEGIN;

-- ── (a) 0090 — plugin_source / plugin_source_entry ──────────────────────────
-- The source registry an operator points at a GitHub repo, a git URL, or a
-- hosted marketplace.json URL to pull installable plugin entries from, and
-- the entries last seen there on each sync.
--
-- Platform control-plane tables — NO RLS (same posture as plugin_bundle /
-- marketplace_listing): a source is a deployment-wide registration, not a
-- per-org resource, so there is no organization_id column to key row-level
-- security on; every repository method carries explicit filters instead.
CREATE TABLE IF NOT EXISTS "plugin_source" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "source_type" varchar NOT NULL,
  "source_ref" text NOT NULL,
  "ref" text,
  "added_by" uuid,
  "status" varchar NOT NULL DEFAULT 'active',
  "last_sync_at" timestamp,
  "last_sync_status" varchar,
  "last_sync_error" text,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  "deleted_at" timestamp,
  CONSTRAINT "plugin_source_slug_unique" UNIQUE ("slug"),
  CONSTRAINT "plugin_source_source_type_check"
    CHECK ("source_type" IN ('github', 'git_url', 'url')),
  CONSTRAINT "plugin_source_status_check"
    CHECK ("status" IN ('active', 'disabled')),
  CONSTRAINT "plugin_source_last_sync_status_check"
    CHECK ("last_sync_status" IS NULL OR "last_sync_status" IN ('ok', 'error'))
);

DO $$ BEGIN
  ALTER TABLE "plugin_source" ADD CONSTRAINT "plugin_source_added_by_user_id_fk"
    FOREIGN KEY ("added_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "plugin_source_status_idx" ON "plugin_source" ("status");

CREATE TABLE IF NOT EXISTS "plugin_source_entry" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "source_id" uuid NOT NULL,
  "name" text NOT NULL,
  "display_name" text,
  "description" text,
  "version" text,
  "category" text,
  "tags" text[],
  "source_spec" jsonb NOT NULL,
  "manifest" jsonb,
  "first_seen_at" timestamp NOT NULL DEFAULT now(),
  "last_seen_at" timestamp NOT NULL DEFAULT now(),
  "removed_at" timestamp,
  CONSTRAINT "plugin_source_entry_unique" UNIQUE ("source_id", "name")
);

DO $$ BEGIN
  ALTER TABLE "plugin_source_entry"
    ADD CONSTRAINT "plugin_source_entry_source_id_plugin_source_id_fk"
    FOREIGN KEY ("source_id") REFERENCES "plugin_source"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "plugin_source_entry_source_idx" ON "plugin_source_entry" ("source_id");

GRANT SELECT, INSERT, UPDATE, DELETE ON "plugin_source" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "plugin_source_entry" TO neo_gen;

-- ── (b) 0091 — plugin_bundle.source_id / origin ─────────────────────────────
-- Provenance for a bundle created FROM a plugin_source_entry via acquisition,
-- as distinct from a bundle authored directly in the Directory. NULLABLE with
-- no default, deliberately: every existing bundle predates this feature, and
-- absence must read as "not acquired / unknown", never as a claim about
-- origin.
ALTER TABLE "plugin_bundle" ADD COLUMN IF NOT EXISTS "source_id" uuid;
ALTER TABLE "plugin_bundle" ADD COLUMN IF NOT EXISTS "origin" jsonb;

DO $$ BEGIN
  ALTER TABLE "plugin_bundle"
    ADD CONSTRAINT "plugin_bundle_source_id_plugin_source_id_fk"
    FOREIGN KEY ("source_id") REFERENCES "plugin_source"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "plugin_bundle_source_idx" ON "plugin_bundle" ("source_id");

-- ── (c) 0092 — plugin_source.last_sync_notes ────────────────────────────────
-- Persists parseMarketplaceManifest's lossNotes from the most recent
-- SUCCESSFUL sync, so an operator can see what was silently narrowed instead
-- of the catalog just being quietly incomplete. NULLABLE with no default:
-- most syncs produce zero loss notes, and absence must read as "nothing was
-- dropped", never as an empty-but-meaningful [].
ALTER TABLE "plugin_source" ADD COLUMN IF NOT EXISTS "last_sync_notes" jsonb;

COMMIT;
