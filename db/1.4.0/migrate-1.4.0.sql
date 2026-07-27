-- migrate-1.4.0.sql — schema delta 1.3.0 → 1.4.0 (source migrations 0063–0065).
--
-- additive-only: new tables (plugin_bundle*, skill_version) and new columns
-- with defaults or NULL (skill.scope/team_id/active_version_number/
-- last_auto_rollback_at, tool_usage.skill_id/…tokens). No renames, no drops,
-- no type changes — the 1.3.x app image keeps running against this schema,
-- so the rolling-update path (./update.sh) may apply it directly.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas, in order — every step is existence-guarded, so re-running is a no-op:
--   0063_plugin_bundle.sql   (plugin_bundle / _item / _install control-plane tables + neo_gen GRANTs)
--   0064_skills_core.sql     (skill_version table; skill.scope + skill.team_id + FK/check/indexes + GRANT)
--   0065_skill_runtime.sql   (tool_usage skill telemetry columns; skill.active_version_number + last_auto_rollback_at)
--
-- This delta is what the deployed image built from current main REQUIRES:
-- skill-repository projections name skill.scope et al unconditionally, so a
-- DB at the 1.3.0 snapshot fails every skill read with 42703
-- ("column skill.scope does not exist" — the Skill Install 500).


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0063_plugin_bundle.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Plugin Bundles (Directory ▸ Plugins): curated capability packs that install
-- several resources at once. Platform control-plane tables — NO RLS (same
-- posture as marketplace_listing); repositories carry explicit user/audience
-- filters. Idempotent delta (project convention: never blanket db:push).
-- Apply with the PRIVILEGED role; the trailing GRANTs give the runtime
-- `neo_gen` role DML (the "neo_gen grant gotcha" — without them the feature
-- 42501s in production while passing on dev's looser default privileges).

CREATE TABLE IF NOT EXISTS "plugin_bundle" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "publisher" text NOT NULL,
  "publisher_kind" varchar NOT NULL DEFAULT 'platform',
  "icon" json,
  "tags" text[],
  "scope" varchar NOT NULL DEFAULT 'enterprise',
  "team_id" uuid,
  "organization_id" uuid,
  "status" varchar NOT NULL DEFAULT 'pending_review',
  "featured" boolean NOT NULL DEFAULT false,
  "install_count" integer NOT NULL DEFAULT 0,
  "version" integer NOT NULL DEFAULT 1,
  "submitted_by" uuid,
  "submitted_at" timestamp,
  "reviewed_by" uuid,
  "reviewed_at" timestamp,
  "rejection_reason" text,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "plugin_bundle_slug_unique" UNIQUE ("slug"),
  CONSTRAINT "plugin_bundle_publisher_kind_check"
    CHECK ("publisher_kind" IN ('platform', 'partner', 'community')),
  CONSTRAINT "plugin_bundle_scope_check"
    CHECK ("scope" IN ('personal', 'team', 'organization', 'enterprise', 'public')),
  CONSTRAINT "plugin_bundle_status_check"
    CHECK ("status" IN ('draft', 'pending_review', 'approved', 'published', 'rejected', 'suspended'))
);

DO $$ BEGIN
  ALTER TABLE "plugin_bundle" ADD CONSTRAINT "plugin_bundle_team_id_team_id_fk"
    FOREIGN KEY ("team_id") REFERENCES "team"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "plugin_bundle" ADD CONSTRAINT "plugin_bundle_organization_id_organization_id_fk"
    FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "plugin_bundle" ADD CONSTRAINT "plugin_bundle_submitted_by_user_id_fk"
    FOREIGN KEY ("submitted_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "plugin_bundle" ADD CONSTRAINT "plugin_bundle_reviewed_by_user_id_fk"
    FOREIGN KEY ("reviewed_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "plugin_bundle_status_idx" ON "plugin_bundle" ("status");
CREATE INDEX IF NOT EXISTS "plugin_bundle_publisher_kind_idx" ON "plugin_bundle" ("publisher_kind");
CREATE INDEX IF NOT EXISTS "plugin_bundle_org_idx" ON "plugin_bundle" ("organization_id");

CREATE TABLE IF NOT EXISTS "plugin_bundle_item" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "bundle_id" uuid NOT NULL,
  "resource_type" varchar NOT NULL,
  "resource_id" uuid NOT NULL,
  "payload" jsonb,
  "position" integer NOT NULL DEFAULT 0,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "plugin_bundle_item_unique" UNIQUE ("bundle_id", "resource_type", "resource_id"),
  CONSTRAINT "plugin_bundle_item_resource_type_check"
    CHECK ("resource_type" IN ('agent', 'skill', 'workflow', 'assistant', 'prompt', 'knowledge_pack', 'mcp'))
);

DO $$ BEGIN
  ALTER TABLE "plugin_bundle_item" ADD CONSTRAINT "plugin_bundle_item_bundle_id_plugin_bundle_id_fk"
    FOREIGN KEY ("bundle_id") REFERENCES "plugin_bundle"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "plugin_bundle_item_bundle_idx" ON "plugin_bundle_item" ("bundle_id");

CREATE TABLE IF NOT EXISTS "plugin_bundle_install" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "bundle_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "organization_id" uuid,
  "installed_version" integer,
  "installed_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "plugin_bundle_install_unique" UNIQUE ("bundle_id", "user_id")
);

DO $$ BEGIN
  ALTER TABLE "plugin_bundle_install" ADD CONSTRAINT "plugin_bundle_install_bundle_id_plugin_bundle_id_fk"
    FOREIGN KEY ("bundle_id") REFERENCES "plugin_bundle"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "plugin_bundle_install" ADD CONSTRAINT "plugin_bundle_install_user_id_user_id_fk"
    FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "plugin_bundle_install" ADD CONSTRAINT "plugin_bundle_install_organization_id_organization_id_fk"
    FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "plugin_bundle_install_user_idx" ON "plugin_bundle_install" ("user_id");

GRANT SELECT, INSERT, UPDATE, DELETE ON "plugin_bundle" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "plugin_bundle_item" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "plugin_bundle_install" TO neo_gen;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0064_skills_core.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Skills Core v2 (AI-capabilities program Phase 2, flag `skills_core_v2`):
-- immutable skill version snapshots + team/organization scoping columns.
-- Idempotent delta (project convention: never blanket db:push). Apply with
-- the PRIVILEGED role; the trailing GRANTs give the runtime `neo_gen` role
-- DML (the "neo_gen grant gotcha").
--
-- RLS posture: NONE on skill_version, and none added to skill. The parent
-- `skill` table has no RLS (user-owned rows; organization_id is nullable and
-- plays no part in today's access checks) — skill_version access derives
-- entirely from the parent skill's repository checkAccess with explicit
-- filters, the same posture as plugin_bundle (0063). An org-keyed
-- tenant_isolation policy here would break user-owned skills with NULL org
-- while adding no boundary the unprotected parent doesn't already lack.
--
-- Backfill: NONE. Every existing skill row keeps scope='personal' (column
-- default). Mapping organization_id → scope='organization' would silently
-- widen access to org members — a regression-gate violation; org scope is
-- opt-in per skill from here on.

BEGIN;

-- Skill version snapshots (mirrors agent_version; FIFO retention of the
-- last 50 is enforced in the repository, not here).
CREATE TABLE IF NOT EXISTS "skill_version" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "skill_id" uuid NOT NULL,
  "version_number" integer NOT NULL,
  "label" text,
  "snapshot" json NOT NULL,
  "created_by" uuid,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "skill_version_number_unique" UNIQUE ("skill_id", "version_number")
);

DO $$ BEGIN
  ALTER TABLE "skill_version" ADD CONSTRAINT "skill_version_skill_id_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_version" ADD CONSTRAINT "skill_version_created_by_user_id_fk"
    FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_version_skill_id_idx" ON "skill_version" ("skill_id");

-- Team/organization scoping (additive; inert while the flag is off).
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "team_id" uuid;
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "scope" varchar NOT NULL DEFAULT 'personal';

DO $$ BEGIN
  ALTER TABLE "skill" ADD CONSTRAINT "skill_team_id_team_id_fk"
    FOREIGN KEY ("team_id") REFERENCES "team"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill" ADD CONSTRAINT "skill_scope_check"
    CHECK ("scope" IN ('personal', 'team', 'organization'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_team_id_idx" ON "skill" ("team_id");
CREATE INDEX IF NOT EXISTS "skill_scope_idx" ON "skill" ("scope");

GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_version" TO neo_gen;

COMMIT;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0065_skill_runtime.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Skill Runtime v2 (AI-capabilities program Phase 3, flag `skills_runtime_v2`):
-- per-skill execution telemetry (extends tool_usage) + a runtime version pin
-- for rollback (skill.active_version_number). Idempotent delta (project
-- convention: never blanket db:push). Apply with the PRIVILEGED role.
--
-- No new tables, so no new GRANTs: every column rides an already-granted
-- table (tool_usage, skill) and inherits its existing neo_gen DML grants —
-- exactly as 0064 altered `skill` (team_id/scope) without re-granting.
--
-- Backfill: NONE. All new columns are nullable and inert:
--   * tool_usage.skill_id/skill_version_number/*_tokens stay NULL for the
--     existing generic-tool rows — no query shape changes, no regression.
--   * skill.active_version_number NULL means "run the live skill row" (today's
--     behavior); a non-NULL pin is only ever written when the runtime flag is
--     on. last_auto_rollback_at is the auto-revert flap-cooldown stamp.

BEGIN;

-- Per-skill execution telemetry: which skill (and pinned version) a runtime
-- invocation resolved, plus token accounting for agent-mode sub-generations.
-- skill_id SET NULL so deleting a skill keeps its historical usage rows.
ALTER TABLE "tool_usage" ADD COLUMN IF NOT EXISTS "skill_id" uuid;
ALTER TABLE "tool_usage" ADD COLUMN IF NOT EXISTS "skill_version_number" integer;
ALTER TABLE "tool_usage" ADD COLUMN IF NOT EXISTS "input_tokens" integer;
ALTER TABLE "tool_usage" ADD COLUMN IF NOT EXISTS "output_tokens" integer;
ALTER TABLE "tool_usage" ADD COLUMN IF NOT EXISTS "total_tokens" integer;

DO $$ BEGIN
  ALTER TABLE "tool_usage" ADD CONSTRAINT "tool_usage_skill_id_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "tool_usage_skill_id_idx" ON "tool_usage" ("skill_id");

-- Runtime version pin (rollback). NULL = use the live skill row (default,
-- byte-identical to pre-v3). A non-NULL value references
-- skill_version.version_number for THIS skill; the runtime loads that snapshot
-- instead of the live row. last_auto_rollback_at gates auto-revert flapping.
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "active_version_number" integer;
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "last_auto_rollback_at" timestamp;

COMMIT;
