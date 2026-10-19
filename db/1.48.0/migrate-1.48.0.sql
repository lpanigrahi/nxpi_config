-- migrate-1.48.0.sql — schema delta 1.47.0 → 1.48.0: paging indexes for a knowledge base's documents, and the folder list a folder upload maintains (ADR-0121). Source migration 0049 (journaled migration 0049_knowledge_page_indexes.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- The paged documents endpoint targets knowledge bases of 10^5–10^6
-- documents; without these objects every page read and sorted the whole
-- knowledge base. Three indexes serve the page's keyset
-- (knowledge_base_document: knowledge_base_id, added_at DESC, source_key
-- DESC), the folder filter's range scan under the C collation
-- (knowledge_base_id, relative_path COLLATE "C") and the page's newest-job
-- probe (ingestion_jobs: source_ref, created_at DESC). One table,
-- `knowledge_base_folder` (knowledge_base_id, path), holds every ancestor
-- folder of every document a folder upload wrote, so the folder picker reads
-- folders instead of exploding every path; it is backfilled from existing
-- `relative_path` values. It carries NO `organization_id` and no RLS (ruling
-- R-16.a, like knowledge_base_attachment): the knowledge base row carries the
-- tenant and its read check runs first.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE TABLE (or before it).
-- An image ahead of this delta fails the folders endpoint and every folder
-- upload's document insert with 42P01; the boot sentinel names it first.
--
-- NOT DESTRUCTIVE. One table and three indexes are created; nothing is
-- dropped, renamed or rewritten. Re-runnable: CREATE TABLE / INDEX IF NOT
-- EXISTS and the backfill is ON CONFLICT DO NOTHING. A plain CREATE INDEX
-- takes a SHARE lock for its build: writes to knowledge_base_document and
-- ingestion_jobs wait, reads do not (ingestion_jobs is the larger build).
-- `SET lock_timeout` bounds the wait for the lock itself.
--
-- RLS in this bundle: none added. schema.sql is 1.47.0's plus exactly these
-- objects; grants.sql is 1.47.0's, unchanged.
--
-- ROLLBACK.
--
--     DROP TABLE IF EXISTS knowledge_base_folder;
--     DROP INDEX IF EXISTS knowledge_base_document_page_idx;
--     DROP INDEX IF EXISTS knowledge_base_document_path_c_idx;
--     DROP INDEX IF EXISTS ingestion_jobs_source_ref_idx;
--
-- (The paged read goes back to sorting the whole knowledge base per page; an
-- image that reads the table then fails the folders endpoint with 42P01.)

SET lock_timeout = '5s';
CREATE INDEX IF NOT EXISTS "knowledge_base_document_page_idx" ON "knowledge_base_document" ("knowledge_base_id", "added_at" DESC, "source_key" DESC);
CREATE INDEX IF NOT EXISTS "knowledge_base_document_path_c_idx" ON "knowledge_base_document" ("knowledge_base_id", "relative_path" COLLATE "C");
CREATE INDEX IF NOT EXISTS "ingestion_jobs_source_ref_idx" ON "ingestion_jobs" ("source_ref", "created_at" DESC);
CREATE TABLE IF NOT EXISTS "knowledge_base_folder" (
  "knowledge_base_id" uuid NOT NULL CONSTRAINT "knowledge_base_folder_knowledge_base_id_fk" REFERENCES "knowledge_base"("id") ON DELETE CASCADE,
  "path" text NOT NULL,
  CONSTRAINT "knowledge_base_folder_pkey" PRIMARY KEY ("knowledge_base_id", "path")
);
INSERT INTO "knowledge_base_folder" ("knowledge_base_id", "path")
SELECT DISTINCT d."knowledge_base_id",
       array_to_string((string_to_array(d."relative_path", '/'))[1:n], '/')
FROM "knowledge_base_document" d,
     LATERAL generate_series(1, cardinality(string_to_array(d."relative_path", '/')) - 1) AS n
WHERE d."relative_path" IS NOT NULL
ON CONFLICT ("knowledge_base_id", "path") DO NOTHING;
