-- migrate-1.42.0.sql — schema delta 1.41.0 → 1.42.0: `thread_attachment` records WHY a file was not indexed. Source migration 0043 (journaled migration 0043_thread_attachment_rag_skip_reason.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- A chat attachment that was not indexed for search is stored with
-- `rag_status = 'skipped'` and, until this delta, no reason. The model was then
-- told every such file "could not be indexed — ask the user to re-upload". For
-- a user at the knowledge-base document limit, every new upload is skipped by
-- the quota check, and re-uploading can never help. `rag_skip_reason` holds one
-- of quota, no_text, unsupported_type, embedding_unavailable, policy,
-- cancelled, written only with `skipped`; a file skipped for "quota" is
-- presented as "not searchable because the document limit is full (not a
-- problem with the file)".
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE COLUMN. The app names
-- `rag_skip_reason` in every attachment status write, so an image ahead of this
-- delta fails those writes with 42703 and attachments stay `pending`; the boot
-- sentinel names the missing column instead.
--
-- NOT DESTRUCTIVE. One nullable column is added; nothing is dropped, renamed or
-- backfilled (a historical skip's reason was never recorded), so every existing
-- row reads NULL — "no reason on record" — and is presented exactly as before.
-- Re-runnable: ADD COLUMN IF NOT EXISTS. A nullable column with no default is a
-- catalog-only change; the ACCESS EXCLUSIVE lock on `thread_attachment` is held
-- for milliseconds, and `SET lock_timeout` bounds the wait to acquire it.
--
-- No RLS in this bundle by design: policies are applied post-restore by the
-- src/lib/db/rls/ runner; a column inherits its table's policies.
--
-- ROLLBACK.
--
--     ALTER TABLE thread_attachment DROP COLUMN IF EXISTS rag_skip_reason;

SET lock_timeout = '5s';

ALTER TABLE thread_attachment ADD COLUMN IF NOT EXISTS rag_skip_reason text;
