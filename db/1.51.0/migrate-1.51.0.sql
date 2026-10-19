-- migrate-1.51.0.sql — schema + data delta 1.50.0 → 1.51.0: org-owned labels (ADR-0124). Source migration 0052 (journaled migration 0052_org_label.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see FORWARD-ONLY below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- An organization's admin now owns the labels assigned to its members:
-- `org_label` holds them (name unique per org, a colour, and a `tool_policy`
-- of tool → allow|deny that the tool-access resolver reads at request time).
-- Until this release `org_user_label.label_id` pointed at PLATFORM labels
-- (`user_access_label`). This delta copies every platform label an
-- `org_user_label` row referenced into an org-owned label in that org
-- (carrying its `label_access_policy.tool_permissions` as the tool policy),
-- repoints each assignment at its org's copy, deletes assignments whose
-- platform label no longer exists, and adds the FK
-- `org_user_label_label_id_org_label_id_fk` (ON DELETE CASCADE).
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE TABLE (or before it).
-- An image ahead of this delta fails the org label routes and the
-- tool-access resolver with 42P01; the boot sentinel names it first.
--
-- FORWARD-ONLY. The table, its FKs and the RLS block are re-runnable
-- (CREATE TABLE IF NOT EXISTS, guarded ADD CONSTRAINT, the policy dropped
-- before it is re-created), and so is the data step: a second apply copies
-- nothing (ON CONFLICT DO NOTHING), repoints nothing and deletes nothing.
-- But the repoint REWRITES `org_user_label.label_id` from platform label ids
-- to org label ids and the pre-1.51.0 ids are not kept. Rolling back the
-- IMAGE is safe: pre-1.51.0 code only displays org label assignments and
-- never enforces them. `SET lock_timeout` bounds every lock wait.
--
-- RLS in this bundle: `org_label`, ENABLE + FORCE + tenant_isolation, in the
-- DO-block shape 1.35.0 shipped. `org_user_label` stays as it was (no RLS,
-- tenant-debt — ruling R-S2-7). schema.sql is 1.50.0's plus exactly these
-- objects; grants.sql is 1.50.0's, unchanged (the default privileges already
-- cover new tables); seed.sql re-renders the journal stamp through 0052.
--
-- ROLLBACK.
--
--     Forward-only. The platform label ids the assignments carried before
--     the repoint are not recorded. To remove the schema objects:
--     ALTER TABLE org_user_label DROP CONSTRAINT IF EXISTS
--       org_user_label_label_id_org_label_id_fk;
--     DROP TABLE IF EXISTS org_label;
--     (the assignments then point at ids nothing resolves.)

SET lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS "org_label" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"color" varchar(20) DEFAULT 'gray' NOT NULL,
	"tool_policy" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_by" uuid,
	"created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT "org_label_org_name_unique" UNIQUE("organization_id","name")
);
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_label_organization_id_organization_id_fk') THEN
    ALTER TABLE "org_label" ADD CONSTRAINT "org_label_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE cascade;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_label_created_by_user_id_fk') THEN
    ALTER TABLE "org_label" ADD CONSTRAINT "org_label_created_by_user_id_fk" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE set null;
  END IF;
END $$;
INSERT INTO "org_label" ("organization_id", "name", "description", "color", "tool_policy")
SELECT DISTINCT oul.organization_id, ual.name, ual.description,
       COALESCE(ual.color, 'gray'), COALESCE(lap.tool_permissions, '{}'::jsonb)
  FROM "org_user_label" oul
  JOIN "user_access_label" ual ON ual.id = oul.label_id
  LEFT JOIN "label_access_policy" lap ON lap.label_id = ual.id
ON CONFLICT ("organization_id", "name") DO NOTHING;
UPDATE "org_user_label" oul
   SET label_id = ol.id
  FROM "user_access_label" ual, "org_label" ol
 WHERE ual.id = oul.label_id
   AND ol.organization_id = oul.organization_id
   AND ol.name = ual.name;
DELETE FROM "org_user_label" oul
 WHERE NOT EXISTS (SELECT 1 FROM "org_label" ol WHERE ol.id = oul.label_id);
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_user_label_label_id_org_label_id_fk') THEN
    ALTER TABLE "org_user_label" ADD CONSTRAINT "org_user_label_label_id_org_label_id_fk" FOREIGN KEY ("label_id") REFERENCES "org_label"("id") ON DELETE cascade;
  END IF;
END $$;
DO $$
DECLARE
  t text;
  strict_org text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid';
BEGIN
  FOREACH t IN ARRAY ARRAY['org_label'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t, strict_org, strict_org);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO neo_gen', t);
  END LOOP;
END $$;
