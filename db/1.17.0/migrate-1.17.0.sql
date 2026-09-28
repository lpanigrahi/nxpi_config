-- migrate-1.17.0.sql — schema delta 1.16.0 → 1.17.0 (source migration 0095).
--
-- ADDITIVE-ONLY: one new table (org_permission_usage) with its FKs, partial
-- unique indexes and RLS policy — every step existence-guarded, so the
-- rolling `./update.sh` path applies it with no maintenance window and
-- re-running is a no-op. No optional-* companion this version.
--
-- W-S7 (G5): per-permission usage telemetry. One row per
-- (org, user, permission[, team]) tracking first/last exercise + use count,
-- upserted (debounced in-process) from decide()'s success arms;
-- manager-bypass admissions land under the `__manager__` pseudo-slug. The
-- SoD report and W-S8's recertification evidence read it. RLS ships via the
-- app-tree runner (rls 0019), not this bundle — see the note at the end.

CREATE TABLE IF NOT EXISTS "org_permission_usage" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "permission" varchar(100) NOT NULL,
  "team_id" uuid,
  "first_used_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "last_used_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "use_count" integer DEFAULT 1 NOT NULL
);

DO $$ BEGIN
  ALTER TABLE "org_permission_usage" ADD CONSTRAINT "org_permission_usage_organization_id_organization_id_fk"
    FOREIGN KEY ("organization_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "org_permission_usage" ADD CONSTRAINT "org_permission_usage_user_id_user_id_fk"
    FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "org_permission_usage" ADD CONSTRAINT "org_permission_usage_team_id_team_id_fk"
    FOREIGN KEY ("team_id") REFERENCES "public"."team"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "org_permission_usage_orgwide_unique"
  ON "org_permission_usage" ("organization_id","user_id","permission") WHERE "team_id" IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "org_permission_usage_team_unique"
  ON "org_permission_usage" ("organization_id","user_id","permission","team_id") WHERE "team_id" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "org_permission_usage_org_idx" ON "org_permission_usage" ("organization_id");
CREATE INDEX IF NOT EXISTS "org_permission_usage_user_idx" ON "org_permission_usage" ("user_id");
CREATE INDEX IF NOT EXISTS "org_permission_usage_last_used_idx" ON "org_permission_usage" ("last_used_at");

-- NO RLS in this bundle, deliberately: the sourceless package ships without
-- row-level security across ALL tables (a disclosed limit in the compliance
-- register; the app's session-GUC scoping is the active control there). The
-- table's policy lives in the application tree's runner channel
-- (src/lib/db/rls/0019_org_permission_usage.sql) with the scratch-DB
-- isolation proof — S11 is the wave that revisits packaged-RLS posture.
