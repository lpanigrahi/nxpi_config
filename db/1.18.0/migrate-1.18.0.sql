-- migrate-1.18.0.sql — schema delta 1.17.0 → 1.18.0 (source migration 0096).
--
-- ADDITIVE-ONLY: two new tables (access_review_campaign / access_review_item)
-- with FKs + indexes, every step existence-guarded — the rolling ./update.sh
-- path applies it with no maintenance window and re-running is a no-op. No
-- optional companion. W-S8 (G2): access recertification — campaigns freeze
-- per-member holdings snapshots; decisions certify/revoke/modify; close
-- stamps an evidence hash beside the audit-chain head signature. As with
-- every table in this package, RLS is NOT part of the bundle (the compliance
-- register discloses that limit); the policies live in the app tree's runner
-- (rls/0020).


CREATE TABLE IF NOT EXISTS "access_review_campaign" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "name" varchar(200) NOT NULL,
  "status" varchar DEFAULT 'open' NOT NULL,
  "created_by" uuid,
  "opened_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "closed_at" timestamp,
  "closed_by" uuid,
  "evidence_sha" varchar(64),
  "audit_head_signature" varchar(128)
);

CREATE TABLE IF NOT EXISTS "access_review_item" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "campaign_id" uuid NOT NULL,
  "organization_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "subject_snapshot" jsonb NOT NULL,
  "decision" varchar DEFAULT 'pending' NOT NULL,
  "decided_by" uuid,
  "decided_at" timestamp,
  "note" text,
  "action_result" jsonb
);

DO $$ BEGIN
  ALTER TABLE "access_review_campaign" ADD CONSTRAINT "access_review_campaign_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_campaign" ADD CONSTRAINT "access_review_campaign_created_by_user_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."user"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_campaign" ADD CONSTRAINT "access_review_campaign_closed_by_user_id_fk" FOREIGN KEY ("closed_by") REFERENCES "public"."user"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_item" ADD CONSTRAINT "access_review_item_campaign_id_access_review_campaign_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."access_review_campaign"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_item" ADD CONSTRAINT "access_review_item_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_item" ADD CONSTRAINT "access_review_item_membership_id_organization_member_id_fk" FOREIGN KEY ("membership_id") REFERENCES "public"."organization_member"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_item" ADD CONSTRAINT "access_review_item_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "access_review_item" ADD CONSTRAINT "access_review_item_decided_by_user_id_fk" FOREIGN KEY ("decided_by") REFERENCES "public"."user"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "access_review_campaign_org_idx" ON "access_review_campaign" ("organization_id");

CREATE UNIQUE INDEX IF NOT EXISTS "access_review_item_campaign_member_unique" ON "access_review_item" ("campaign_id","membership_id");

CREATE INDEX IF NOT EXISTS "access_review_item_campaign_idx" ON "access_review_item" ("campaign_id");

CREATE INDEX IF NOT EXISTS "access_review_item_org_idx" ON "access_review_item" ("organization_id");
