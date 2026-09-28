-- migrate-1.19.0.sql — schema delta 1.18.0 → 1.19.0 (source migration 0097).
--
-- ADDITIVE-ONLY: one new table (org_privilege_request) with FKs + indexes,
-- every step existence-guarded — the rolling ./update.sh path applies it with
-- no maintenance window and re-running is a no-op. No optional companion.
-- W-S9 (G4/G9): dual-control privilege requests — with `rbac.dual_control_tier`
-- armed, a role whose effective risk reaches the tier cannot be assigned by
-- one person; a request row is filed and a DIFFERENT manager approves
-- (self-approval refused). Pending requests lapse on expires_at. Break-glass
-- deliberately writes NO new table: it is a system-role assignment with a
-- mandatory short expiry (1.16.0's expires_at column) plus a
-- BREAK_GLASS_ACTIVATED audit row. As with every table in this package, RLS
-- is NOT part of the bundle (the compliance register discloses that limit);
-- the policies live in the app tree's runner (rls/0021).


-- org_privilege_request (overhaul W-S9, gap G4): dual-control (maker/checker)
-- for high-tier role assignments. With `rbac.dual_control_tier` set, a role
-- whose effective risk reaches the tier cannot be assigned directly — a
-- request row is filed and a DIFFERENT manager approves (requester===approver
-- refused). Pending requests lapse on expires_at. Break-glass writes NO new
-- table: it is a system-role assignment with a mandatory short expiry
-- (0093's column) plus a BREAK_GLASS_ACTIVATED audit row.
CREATE TABLE IF NOT EXISTS "org_privilege_request" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "role_id" uuid NOT NULL,
  "team_id" uuid,
  "requested_by" uuid NOT NULL,
  "reason" text NOT NULL,
  "status" varchar DEFAULT 'pending' NOT NULL,
  "decided_by" uuid,
  "decided_at" timestamp,
  "decision_note" text,
  "expires_at" timestamp NOT NULL,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);
DO $$ BEGIN
ALTER TABLE "org_privilege_request" ADD CONSTRAINT "org_privilege_request_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
ALTER TABLE "org_privilege_request" ADD CONSTRAINT "org_privilege_request_membership_id_organization_member_id_fk" FOREIGN KEY ("membership_id") REFERENCES "public"."organization_member"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
ALTER TABLE "org_privilege_request" ADD CONSTRAINT "org_privilege_request_role_id_org_role_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."org_role"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
ALTER TABLE "org_privilege_request" ADD CONSTRAINT "org_privilege_request_team_id_team_id_fk" FOREIGN KEY ("team_id") REFERENCES "public"."team"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
ALTER TABLE "org_privilege_request" ADD CONSTRAINT "org_privilege_request_requested_by_user_id_fk" FOREIGN KEY ("requested_by") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
ALTER TABLE "org_privilege_request" ADD CONSTRAINT "org_privilege_request_decided_by_user_id_fk" FOREIGN KEY ("decided_by") REFERENCES "public"."user"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS "org_privilege_request_org_idx" ON "org_privilege_request" ("organization_id");
CREATE INDEX IF NOT EXISTS "org_privilege_request_status_idx" ON "org_privilege_request" ("status");
