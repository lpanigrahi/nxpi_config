-- migrate-1.36.0.sql — schema delta 1.35.0 → 1.36.0 (R14 plane P6, findings F2/F3/F6): thread_attachment becomes the catalog for EVERY stored object. Source migration 0037 (journaled migration 0037_thread_attachment_storage_catalog.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- `thread_attachment` is the ONLY record this platform keeps of a stored
-- object, and both storage quota caps — max storage per user, max storage per
-- organization — are `SUM(thread_attachment.size)` over it. The upload route's
-- catalog INSERT sat inside an `if (threadId)` branch, so an upload that simply
-- omitted one optional multipart field stored bytes that NO row described:
-- 2.1 MB landed under a 1 MB per-org cap AND a 1 MB per-user cap, measured at
-- the wire, deterministically, for any member of any organization. Those bytes
-- were also invisible to the org's own storage console and were never reclaimed
-- by the retention sweep, which walks the catalog. The same shape made the
-- stored object OWNERLESS, which `/api/storage/files/[...path]` read as "an
-- unowned shared asset" and served to any authenticated session on the
-- platform — including one belonging to an unrelated tenant.
--
-- The delta makes `thread_id` NULLABLE, so a row can exist for an object with
-- no chat thread, and ADDS `organization_id` (FK to `organization`, ON DELETE
-- SET NULL, plus its index) so such a row still names its tenant. No data rows
-- are written: `organization_id` is deliberately NOT backfilled, because the
-- application's two quota sums COALESCE the `chat_thread`-joined organization
-- with the new column — every pre-existing row keeps counting exactly as it did
-- through the join, and every new row counts on its own. Nothing is dropped and
-- nothing is rewritten, so this delta is not REQUIRES-REVIEW and takes the
-- ordinary rolling path.
--
-- IDEMPOTENT throughout: `DROP NOT NULL` on an already-nullable column is a
-- Postgres no-op, the column is `ADD COLUMN IF NOT EXISTS`, the foreign key is
-- guarded on (conname, conrelid) inside a DO block, and the index is
-- `CREATE INDEX IF NOT EXISTS`. Applying it twice changes nothing.
--
-- Apply with psql -1 (ON_ERROR_STOP) so the batch lands or does not.

SET lock_timeout = '5s';

ALTER TABLE "thread_attachment" ALTER COLUMN "thread_id" DROP NOT NULL;

ALTER TABLE "thread_attachment" ADD COLUMN IF NOT EXISTS "organization_id" uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'thread_attachment_organization_id_organization_id_fk'
      AND conrelid = to_regclass('thread_attachment')
  ) THEN
    ALTER TABLE "thread_attachment"
      ADD CONSTRAINT "thread_attachment_organization_id_organization_id_fk"
      FOREIGN KEY ("organization_id") REFERENCES "organization"("id")
      ON DELETE SET NULL ON UPDATE NO ACTION;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "thread_attachment_organization_id_idx" ON "thread_attachment" USING btree ("organization_id");
