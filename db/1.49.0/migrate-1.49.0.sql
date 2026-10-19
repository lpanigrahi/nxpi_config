-- migrate-1.49.0.sql — schema delta 1.48.0 → 1.49.0: prompt_template_comment (ADR-0123 slice 2). Source migration 0050 (journaled migration 0050_prompt_template_comment.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- A prompt template's reviewers reject with a comment and its readers discuss
-- it. One table, `prompt_template_comment`, holds that thread: keyed by
-- template id (ON DELETE CASCADE), threaded through parent_id (ON DELETE
-- CASCADE), author SET NULL on user deletion so a thread outlives its
-- participants, TipTap JSON content, kind user|decision. It carries NO
-- `organization_id` (ruling R-16.a, the 0046/0049 precedent): the parent
-- template carries the tenant and every door reads the template through its
-- access scope first.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE TABLE (or before it).
-- An image ahead of this delta fails the template comment routes and the
-- review decision note with 42P01; the boot sentinel names it first.
--
-- NOT DESTRUCTIVE. One table and two indexes are created; nothing is
-- dropped, renamed or rewritten. Re-runnable: CREATE TABLE / INDEX IF NOT
-- EXISTS. CREATE TABLE takes a brief SHARE ROW EXCLUSIVE on prompt_template
-- and "user" for its foreign keys; the indexes build on an empty table.
-- `SET lock_timeout` bounds the wait for the lock itself.
--
-- RLS in this bundle: none — the table carries no organization_id
-- (0046/0049 precedent). schema.sql is 1.48.0's plus exactly these objects;
-- grants.sql is 1.48.0's, unchanged.
--
-- ROLLBACK.
--
--     DROP TABLE IF EXISTS prompt_template_comment;
--
-- (Drops every comment and decision note; the templates themselves are
-- untouched. An image that reads the table then fails the comment routes
-- with 42P01.)

SET lock_timeout = '5s';
CREATE TABLE IF NOT EXISTS "prompt_template_comment" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "template_id" uuid NOT NULL,
  "author_id" uuid,
  "parent_id" uuid,
  "content" json NOT NULL,
  "kind" varchar NOT NULL DEFAULT 'user',
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "prompt_template_comment_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "prompt_template_comment_template_id_fk" FOREIGN KEY ("template_id") REFERENCES "prompt_template"("id") ON DELETE CASCADE,
  CONSTRAINT "prompt_template_comment_author_id_fk" FOREIGN KEY ("author_id") REFERENCES "user"("id") ON DELETE SET NULL,
  CONSTRAINT "prompt_template_comment_parent_id_fk" FOREIGN KEY ("parent_id") REFERENCES "prompt_template_comment"("id") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS "prompt_template_comment_template_id_idx" ON "prompt_template_comment" ("template_id");
CREATE INDEX IF NOT EXISTS "prompt_template_comment_parent_id_idx" ON "prompt_template_comment" ("parent_id");
