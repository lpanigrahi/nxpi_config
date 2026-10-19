-- migrate-1.52.0.sql — schema delta 1.51.0 → 1.52.0: org presentation templates (ADR-0126). Source migration 0053 (journaled migration 0053_org_presentation_template.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see FORWARD-ONLY below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- An organization can now keep its own PowerPoint masters for the
-- presentation engine: `org_presentation_template` holds one row per
-- template (name unique per org ignoring case, the file-storage key of the
-- .pptx/.potx bytes, and the layouts the engine found in it at upload). A
-- new table and nothing else: no existing row is read or rewritten.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE TABLE (or before it).
-- An image ahead of this delta fails the presentation template routes and
-- createPresentation's templateId with 42P01; the boot sentinel names it
-- first.
--
-- FORWARD-ONLY and re-runnable (CREATE TABLE / INDEX IF NOT EXISTS, guarded
-- ADD CONSTRAINT, the policy dropped before it is re-created). Rolling back
-- the IMAGE is safe: pre-1.52.0 code never reads the table. `SET
-- lock_timeout` bounds every lock wait.
--
-- RLS in this bundle: `org_presentation_template`, ENABLE + FORCE +
-- tenant_isolation, in the DO-block shape 1.35.0 shipped. schema.sql is
-- 1.51.0's plus exactly these objects; grants.sql is 1.51.0's, unchanged (the
-- default privileges already cover new tables); seed.sql re-renders the
-- journal stamp through 0053.
--
-- ROLLBACK.
--
--     Forward-only. To remove the schema objects:
--     DROP TABLE IF EXISTS org_presentation_template;

SET lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS "org_presentation_template" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"storage_key" text NOT NULL,
	"filename" text NOT NULL,
	"size_bytes" integer NOT NULL,
	"layout_names" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"layout_map" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_by" uuid,
	"created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "org_presentation_template_org_lower_name_uidx" ON "org_presentation_template" USING btree ("organization_id", lower("name"));
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_presentation_template_organization_id_organization_id_fk') THEN
    ALTER TABLE "org_presentation_template" ADD CONSTRAINT "org_presentation_template_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE cascade;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_presentation_template_created_by_user_id_fk') THEN
    ALTER TABLE "org_presentation_template" ADD CONSTRAINT "org_presentation_template_created_by_user_id_fk" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE set null;
  END IF;
END $$;
DO $$
DECLARE
  t text;
  strict_org text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid';
BEGIN
  FOREACH t IN ARRAY ARRAY['org_presentation_template'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t, strict_org, strict_org);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO neo_gen', t);
  END LOOP;
END $$;
