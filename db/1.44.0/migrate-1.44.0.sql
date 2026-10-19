-- migrate-1.44.0.sql — schema delta 1.43.0 → 1.44.0: a marketplace listing can carry listing-scoped facts, so a shared knowledge base remembers the visibility it had before it was shared (ADR-0119 D5′). Source migration 0045 (journaled migration 0045_marketplace_listing_metadata.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- A knowledge pack no longer copies the knowledge base: sharing it with a
-- team or with the organization sets the live knowledge base's visibility, and
-- "Stop sharing" restores the visibility it had before the first share. That
-- previous visibility is recorded on the listing, in a new nullable
-- `marketplace_listing.metadata jsonb` column:
--   { "previousVisibility": "private" | "team" | "org" | "public",
--     "previousTeamId": uuid | null }
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE COLUMN. The app names
-- `metadata` in every marketplace-listing read, so an image ahead of this
-- delta fails browse, publish and every listing request with 42703; the boot
-- sentinel names the missing column instead.
--
-- NOT DESTRUCTIVE. One nullable column is added; nothing is dropped, renamed
-- or backfilled, so every existing listing reads NULL — which the app treats
-- as "not a shared knowledge base": withdrawing such a listing restores no
-- visibility. Re-runnable: ADD COLUMN IF NOT EXISTS. A nullable
-- column with no default is a catalog-only change, and `SET lock_timeout`
-- bounds the wait to acquire its lock.
--
-- No RLS in this bundle by design: policies are applied post-restore by the
-- src/lib/db/rls/ runner; a column inherits its table's policies.
--
-- ROLLBACK.
--
--     ALTER TABLE marketplace_listing DROP COLUMN IF EXISTS metadata;
--
-- (A knowledge base shared after this delta then falls back to `private` when
-- sharing stops.)

SET lock_timeout = '5s';

ALTER TABLE marketplace_listing ADD COLUMN IF NOT EXISTS metadata jsonb;
