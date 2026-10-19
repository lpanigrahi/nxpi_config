-- migrate-1.50.0.sql — data delta 1.49.0 → 1.50.0: every prompt template becomes a user prompt (ADR-0123 slice 3: only user prompts). Source migration 0051 (journaled migration 0051_prompt_template_category_user.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE TO SCHEMA below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- A prompt template's `category` used to be one of system / user / tool /
-- context (or NULL), and every category but `user` steered a chat instead of
-- inserting text. The platform owner retired that taxonomy on 2026-10-10:
-- prompt templates are insert-text only. From this release the create and
-- edit doors accept only `user`; this delta normalises the rows written
-- before that rule so no surface can steer with a legacy category again.
--
-- This delta writes rows: every prompt_template.category becomes 'user'
-- (NULL included — the application treated NULL as a steer category).
--
-- SHIP IT WITH THE IMAGE THAT ACCEPTS ONLY `user` (or after it). An image
-- that still accepts the other categories could write them again after this
-- delta ran; re-running the delta normalises them.
--
-- NOT DESTRUCTIVE TO SCHEMA. No DDL: rows of prompt_template only, and only
-- the `category` column. Re-runnable: the predicate excludes rows already
-- 'user', so a second apply changes nothing. `SET lock_timeout` bounds every
-- row-lock wait.
--
-- No RLS and no schema change in this bundle: schema.sql and grants.sql are
-- 1.49.0's, unchanged; seed.sql re-renders the journal stamp through 0051.
--
-- ROLLBACK.
--
--     Forward-only. The prior category of each row is not recorded, so
--     there is nothing to restore it from; the steer taxonomy is retired
--     (ADR-0123) and the column is dropped by a later cleanup migration.

SET lock_timeout = '5s';

UPDATE "prompt_template" SET "category" = 'user' WHERE "category" IS DISTINCT FROM 'user';
