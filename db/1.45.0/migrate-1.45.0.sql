-- migrate-1.45.0.sql — schema delta 1.44.0 → 1.45.0: a new table records who has attached which knowledge base, so a shared knowledge base is used only by the people who attach it (ADR-0120). Source migration 0046 (journaled migration 0046_knowledge_base_attachment.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- Being able to read a knowledge base (as its owner, its team, its
-- organization or through a share) no longer means it is searched in every
-- chat: a shared knowledge base is used only by the people who attach it.
-- Attachment is a per-user fact, so it gets its own table,
-- `knowledge_base_attachment` — one row per (knowledge base, user), both
-- foreign keys ON DELETE CASCADE. It carries no organization_id: the knowledge
-- base row carries the tenant, and the table is control-plane (no RLS policy),
-- read with an explicit user filter.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE TABLE. The app reads
-- it on retrieval and for the Attach / Unattach controls, so an image ahead
-- of this delta fails those requests with 42P01; the boot sentinel names the
-- missing table instead.
--
-- NOT DESTRUCTIVE. One table and one index are created; nothing is dropped,
-- renamed or rewritten. The backfill attaches every existing knowledge base's
-- OWNER to it, nobody else — so owners keep searching their own knowledge
-- bases exactly as before. Re-runnable: CREATE TABLE / INDEX IF NOT EXISTS,
-- and the backfill is ON CONFLICT DO NOTHING. `SET lock_timeout` bounds the
-- brief lock the foreign keys take on `knowledge_base` and `user`.
--
-- No RLS in this bundle by design: the table is control-plane and takes no
-- policy (the src/lib/db/rls/ runner has no row for it).
--
-- ROLLBACK.
--
--     DROP TABLE IF EXISTS knowledge_base_attachment;
--
-- (Every attachment made after this delta is lost; an image that reads the
-- table then fails retrieval with 42P01.)

SET lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS knowledge_base_attachment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  knowledge_base_id uuid NOT NULL CONSTRAINT knowledge_base_attachment_knowledge_base_id_fk REFERENCES knowledge_base(id) ON DELETE CASCADE,
  user_id uuid NOT NULL CONSTRAINT knowledge_base_attachment_user_id_fk REFERENCES "user"(id) ON DELETE CASCADE,
  attached_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT knowledge_base_attachment_unique UNIQUE (knowledge_base_id, user_id)
);

CREATE INDEX IF NOT EXISTS knowledge_base_attachment_user_idx ON knowledge_base_attachment (user_id);

INSERT INTO knowledge_base_attachment (knowledge_base_id, user_id)
SELECT kb.id, kb.user_id FROM knowledge_base kb WHERE kb.user_id IS NOT NULL
ON CONFLICT (knowledge_base_id, user_id) DO NOTHING;
