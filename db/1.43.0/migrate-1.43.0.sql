-- migrate-1.43.0.sql — schema delta 1.42.0 → 1.43.0: a knowledge base owns its ingestion settings, and a marketplace install records the copy it created (ADR-0119). Source migration 0044 (journaled migration 0044_knowledge_base_ingestion_settings.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- How an uploaded document is read, cut into chunks and embedded was decided
-- by the uploader's personal settings or by the organization, never by the
-- knowledge base. This delta gives `knowledge_base` eight nullable columns —
-- extraction_method (auto, text, ocr, vision), extraction_model, chunk_size,
-- chunk_overlap, chunking_strategy, embedding_provider, embedding_model,
-- embedding_dims (768, 1024, 1536, 3072) — and gives `marketplace_install`
-- one, installed_resource_id, the id of the copy an install created, so a
-- knowledge pack can be updated in place and removed on uninstall.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE COLUMNS. The app names
-- the eight knowledge-base columns in every knowledge-base read and
-- `installed_resource_id` in every install-ledger read, so an image ahead of
-- this delta fails those requests with 42703; the boot sentinel names the
-- missing column instead.
--
-- NOT DESTRUCTIVE. Nine nullable columns are added; nothing is dropped,
-- renamed or backfilled, so every existing row reads NULL — "inherit" — and
-- behaves exactly as before. An install recorded before this delta has no
-- copy id; uninstalling it removes the ledger row only, as today.
-- Re-runnable: ADD COLUMN IF NOT EXISTS, and each CHECK is guarded on
-- (conname, conrelid). A nullable column with no default is a catalog-only
-- change; each CHECK scans `knowledge_base` (one row per knowledge base) under
-- ACCESS EXCLUSIVE, and `SET lock_timeout` bounds the wait to acquire it.
--
-- No RLS in this bundle by design: policies are applied post-restore by the
-- src/lib/db/rls/ runner; a column inherits its table's policies.
--
-- ROLLBACK.
--
--     ALTER TABLE marketplace_install DROP COLUMN IF EXISTS installed_resource_id;
--     ALTER TABLE knowledge_base
--       DROP COLUMN IF EXISTS extraction_method,
--       DROP COLUMN IF EXISTS extraction_model,
--       DROP COLUMN IF EXISTS chunk_size,
--       DROP COLUMN IF EXISTS chunk_overlap,
--       DROP COLUMN IF EXISTS chunking_strategy,
--       DROP COLUMN IF EXISTS embedding_provider,
--       DROP COLUMN IF EXISTS embedding_model,
--       DROP COLUMN IF EXISTS embedding_dims;
--
-- (A dropped column takes its CHECK with it.)

SET lock_timeout = '5s';

ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS extraction_method text;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS extraction_model text;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS chunk_size integer;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS chunk_overlap integer;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS chunking_strategy text;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS embedding_provider text;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS embedding_model text;
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS embedding_dims integer;

ALTER TABLE marketplace_install ADD COLUMN IF NOT EXISTS installed_resource_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'knowledge_base_extraction_method_check'
      AND conrelid = to_regclass('knowledge_base')
  ) THEN
    ALTER TABLE knowledge_base
      ADD CONSTRAINT knowledge_base_extraction_method_check
      CHECK (extraction_method IN ('auto', 'text', 'ocr', 'vision'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'knowledge_base_embedding_dims_check'
      AND conrelid = to_regclass('knowledge_base')
  ) THEN
    ALTER TABLE knowledge_base
      ADD CONSTRAINT knowledge_base_embedding_dims_check
      CHECK (embedding_dims IN (768, 1024, 1536, 3072));
  END IF;
END $$;
