-- migrate-1.47.0.sql — schema delta 1.46.0 → 1.47.0: a large folder is uploaded to a knowledge base and ingested as one resumable batch, so two new org-scoped tables record each batch and each file in it; documents gain the folder path they were uploaded under; and four per-organization upload limits are added (ADR-0121). Source migration 0048 (journaled migration 0048_knowledge_upload_batch.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- A knowledge-base manager can upload a folder tree of up to ~100 GB straight
-- from the browser, in resumable parts, and the server ingests it in fair,
-- windowed slices. That needs durable state the browser cannot hold:
-- `knowledge_upload_batch` (one row per folder upload: its knowledge base, its
-- uploader, its status and byte-weighted counters) and `knowledge_upload_item`
-- (one row per file: its path, size, status, multipart upload id and stored
-- parts). Both carry `organization_id` and take the canonical strict
-- `tenant_isolation` row-level-security policy, ENABLE + FORCE.
-- `knowledge_base_document` gains three nullable columns (relative_path,
-- source_last_modified, content_sha256) and an index on (knowledge_base_id,
-- relative_path); `org_storage_governance` gains four nullable limits
-- (kb_max_batch_size_gb, kb_max_file_size_mb, kb_max_files_per_batch,
-- kb_max_storage_gb — NULL means the platform default).
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE TABLES (or before
-- it). Every read of `knowledge_base_document` and `org_storage_governance`
-- names the new columns, so an image ahead of this delta fails the document
-- list and the storage settings with 42703, and the batch routes with 42P01;
-- the boot sentinel names the missing object instead.
--
-- NOT DESTRUCTIVE. Two tables and four indexes are created and seven nullable
-- columns added without a default (catalog-only, no table rewrite); nothing
-- is dropped, renamed or rewritten, and existing rows keep NULL in every new
-- column. Re-runnable: CREATE TABLE / INDEX IF NOT EXISTS, ADD COLUMN IF NOT
-- EXISTS, and the RLS block drops its policy before re-creating it. `SET
-- lock_timeout` bounds the brief locks the foreign keys and ADD COLUMNs take.
--
-- RLS in this bundle: the two new tables, ENABLE + FORCE + tenant_isolation,
-- in the DO-block shape 1.35.0 shipped for assistant and
-- organization_entitlement. schema.sql carries the same posture; grants.sql
-- is 1.46.0's, unchanged (the default privileges already cover new tables).
--
-- ROLLBACK.
--
--     DROP TABLE IF EXISTS knowledge_upload_item;
--     DROP TABLE IF EXISTS knowledge_upload_batch;
--     DROP INDEX IF EXISTS knowledge_base_document_path_idx;
--     ALTER TABLE knowledge_base_document DROP COLUMN IF EXISTS relative_path,
--       DROP COLUMN IF EXISTS source_last_modified, DROP COLUMN IF EXISTS content_sha256;
--     ALTER TABLE org_storage_governance DROP COLUMN IF EXISTS kb_max_batch_size_gb,
--       DROP COLUMN IF EXISTS kb_max_file_size_mb, DROP COLUMN IF EXISTS kb_max_files_per_batch,
--       DROP COLUMN IF EXISTS kb_max_storage_gb;
--
-- (Every batch in flight loses its state — its stored objects stay,
-- uncatalogued; documents lose their folder path; saved upload limits fall
-- back to the platform defaults. An image that reads the tables then fails
-- with 42P01.)

SET lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS "knowledge_upload_batch" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL REFERENCES "organization"("id") ON DELETE CASCADE,
  "knowledge_base_id" uuid NOT NULL REFERENCES "knowledge_base"("id") ON DELETE CASCADE,
  "user_id" uuid NOT NULL REFERENCES "user"("id") ON DELETE CASCADE,
  "root_name" text NOT NULL,
  "status" text DEFAULT 'registering' NOT NULL,
  "stop_code" text,
  "declared_files" integer NOT NULL,
  "declared_bytes" bigint NOT NULL,
  "accepted_files" integer DEFAULT 0 NOT NULL,
  "accepted_bytes" bigint DEFAULT 0 NOT NULL,
  "uploaded_bytes" bigint DEFAULT 0 NOT NULL,
  "processed_bytes" bigint DEFAULT 0 NOT NULL,
  "finished_files" integer DEFAULT 0 NOT NULL,
  "done_files" integer DEFAULT 0 NOT NULL,
  "replaced_files" integer DEFAULT 0 NOT NULL,
  "skipped_files" integer DEFAULT 0 NOT NULL,
  "failed_files" integer DEFAULT 0 NOT NULL,
  "reserved_bytes" bigint DEFAULT 0 NOT NULL,
  "last_client_seen_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "finished_at" timestamp,
  CONSTRAINT "knowledge_upload_batch_status_check" CHECK ("status" IN
    ('registering','uploading','processing','completed','completed_with_errors','stopped','cancelled'))
);
CREATE INDEX IF NOT EXISTS "knowledge_upload_batch_kb_idx" ON "knowledge_upload_batch" ("knowledge_base_id", "created_at");
CREATE INDEX IF NOT EXISTS "knowledge_upload_batch_user_idx" ON "knowledge_upload_batch" ("user_id", "status");
CREATE TABLE IF NOT EXISTS "knowledge_upload_item" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL REFERENCES "organization"("id") ON DELETE CASCADE,
  "batch_id" uuid NOT NULL REFERENCES "knowledge_upload_batch"("id") ON DELETE CASCADE,
  "relative_path" text NOT NULL,
  "size" bigint NOT NULL,
  "last_modified" timestamp NOT NULL,
  "mime_type" text NOT NULL,
  "status" text DEFAULT 'pending' NOT NULL,
  "error_code" text,
  "storage_key" text,
  "multipart_upload_id" text,
  "parts" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "uploaded_bytes" bigint DEFAULT 0 NOT NULL,
  "source_key" text,
  "replaces_source_key" text,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT "knowledge_upload_item_path_unique" UNIQUE ("batch_id", "relative_path"),
  CONSTRAINT "knowledge_upload_item_status_check" CHECK ("status" IN
    ('pending','uploading','uploaded','queued','ingesting','done','skipped','failed','cancelled'))
);
CREATE INDEX IF NOT EXISTS "knowledge_upload_item_batch_status_idx" ON "knowledge_upload_item" ("batch_id", "status");
ALTER TABLE "knowledge_base_document" ADD COLUMN IF NOT EXISTS "relative_path" text;
ALTER TABLE "knowledge_base_document" ADD COLUMN IF NOT EXISTS "source_last_modified" timestamp;
ALTER TABLE "knowledge_base_document" ADD COLUMN IF NOT EXISTS "content_sha256" text;
CREATE INDEX IF NOT EXISTS "knowledge_base_document_path_idx" ON "knowledge_base_document" ("knowledge_base_id", "relative_path");
ALTER TABLE "org_storage_governance" ADD COLUMN IF NOT EXISTS "kb_max_batch_size_gb" integer;
ALTER TABLE "org_storage_governance" ADD COLUMN IF NOT EXISTS "kb_max_file_size_mb" integer;
ALTER TABLE "org_storage_governance" ADD COLUMN IF NOT EXISTS "kb_max_files_per_batch" integer;
ALTER TABLE "org_storage_governance" ADD COLUMN IF NOT EXISTS "kb_max_storage_gb" integer;
DO $$
DECLARE
  t text;
  strict_org text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid';
BEGIN
  FOREACH t IN ARRAY ARRAY['knowledge_upload_batch', 'knowledge_upload_item'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t, strict_org, strict_org);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO neo_gen', t);
  END LOOP;
END $$;
