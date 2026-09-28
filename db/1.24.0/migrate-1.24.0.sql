-- migrate-1.24.0.sql — schema delta 1.23.0 → 1.24.0 (source migrations 0007
-- and 0008 of the journaled series:
-- src/lib/db/migrations/pg/0007_authz_generation_and_key_platform_scopes.sql,
-- src/lib/db/migrations/pg/0008_authz_generation_settings_trigger.sql).
-- Additive-safe (ADR-0108; Phase 2).
--
-- Additive-safe, deliberately unflagged (lib.sh scans the first six lines
-- for its destructive-review marker — that token must not appear up here):
-- adds two columns (one with a default, no existing row's shape changes)
-- plus two SECURITY DEFINER trigger functions and ten AFTER triggers — no
-- table/column/row is dropped and no cascade is introduced. Idempotent
-- (ADD COLUMN IF NOT EXISTS; CREATE OR REPLACE FUNCTION; DROP TRIGGER IF
-- EXISTS before each CREATE TRIGGER) — re-running is a no-op.
--
-- WHY: Phase 2 caches the per-request AuthzContext snapshot; this counter
-- is the DB-side truth a cross-request cache invalidates against, bumped by
-- an AFTER trigger on every table whose row can change an authorization
-- decision for the org. apikey.platform_scopes is the column the platform
-- axis reads (in shadow) for machine subjects. Without these objects an
-- image ahead of the delta 42703s on organization.authz_generation on the
-- authorization hot path (every AuthzContext snapshot load) — the same
-- incident class as 0077/0099's session columns. 0008 (P2-T4 follow-up)
-- closes the gap 0007 left: organization_settings carries
-- managersPolicyBound, read into the snapshot's `settings`, but had no
-- trigger — without Redis a settings flip left a warm snapshot stale until
-- the 60s TTL instead of the DB column being the truth.
-- db/1.24.0/schema.sql carries the same columns, functions and triggers for
-- fresh installs.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0007_authz_generation_and_key_platform_scopes.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0007 — authz generation counter (DB truth for the snapshot cache) + api-key
-- platform scopes (ADR-0108 / Phase 2). SECURITY DEFINER + SET search_path on
-- both trigger functions (owned by the migrating/privileged role, which
-- BYPASSes RLS): every direct-trigger source table carries FORCE ROW LEVEL
-- SECURITY except organization_member (identity tier), and all three junction
-- tables carry it too (rls/0022, Shape E) — an invoker-rights trigger would
-- run with the WRITER's own privileges/RLS visibility instead, so a write
-- whose GUC is unset or narrower than the row could silently miss the bump.
-- See the source migration for the full rationale.

ALTER TABLE "organization" ADD COLUMN IF NOT EXISTS "authz_generation" bigint NOT NULL DEFAULT 0;
ALTER TABLE "apikey" ADD COLUMN IF NOT EXISTS "platform_scopes" text[] NOT NULL DEFAULT '{}';

-- ── Direct trigger: tables that carry their own organization_id ────────────
CREATE OR REPLACE FUNCTION authz_bump_generation() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE org uuid;
BEGIN
  org := COALESCE(NEW.organization_id, OLD.organization_id);
  UPDATE "organization" SET authz_generation = authz_generation + 1 WHERE id = org;
  RETURN NULL;
END
$$;

DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['org_role','org_role_assignment','org_resource_grant','org_permission_group','organization_member','org_policy'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS authz_gen_bump ON %I', t);
    EXECUTE format('CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION authz_bump_generation()', t);
  END LOOP;
END $$;

-- ── Via-parent trigger: the three org-less junctions ────────────────────────
-- org_role_permission and org_role_permission_group resolve through org_role
-- (role_id); org_permission_group_item carries no role_id at all, only
-- group_id, so it resolves through org_permission_group instead. Branches on
-- TG_TABLE_NAME rather than a generic column-name lookup, since the two
-- parent tables differ.
CREATE OR REPLACE FUNCTION authz_bump_generation_via_role() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE org uuid;
BEGIN
  IF TG_TABLE_NAME = 'org_permission_group_item' THEN
    SELECT organization_id INTO org FROM org_permission_group
      WHERE id = COALESCE(NEW.group_id, OLD.group_id);
  ELSE
    SELECT organization_id INTO org FROM org_role
      WHERE id = COALESCE(NEW.role_id, OLD.role_id);
  END IF;
  UPDATE "organization" SET authz_generation = authz_generation + 1 WHERE id = org;
  RETURN NULL;
END
$$;

DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['org_role_permission','org_permission_group_item','org_role_permission_group'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS authz_gen_bump ON %I', t);
    EXECUTE format('CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION authz_bump_generation_via_role()', t);
  END LOOP;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0008_authz_generation_settings_trigger.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0008 (P2-T4b) — organization_settings joins the authz_generation bump.
-- organization_settings.organization_id IS its primary key (no separate
-- surrogate id + FK column), but it is still a real "organization_id"
-- column every NEW/OLD row carries, so 0007's own authz_bump_generation()
-- applies unchanged — no new trigger function. See the source migration for
-- the full rationale.

DROP TRIGGER IF EXISTS authz_gen_bump ON organization_settings;
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON organization_settings FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();
