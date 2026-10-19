-- migrate-1.54.0.sql — schema delta 1.53.0 → 1.54.0: org labels removed (ADR-0124 amendment). Source migration 0055 (journaled migration 0055_drop_org_label.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see FORWARD-ONLY below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- Org-owned labels are gone from the product: no screen, route, resolver or
-- repository reads or writes them, and a member's tool access is decided by
-- the platform rules and the member's own allow/deny lists alone. This delta
-- drops `org_user_label` (the assignments) and then `org_label` (the labels);
-- their RLS policy, FKs, indexes, constraints and grants go with them.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT STOPS READING THE TABLES (or after
-- it). An image older than 1.54.0 reads both tables on the tool-access path
-- and the label routes, and fails with 42P01 once they are gone.
--
-- FORWARD-ONLY and re-runnable (DROP TABLE IF EXISTS). The data loss is
-- deliberate. Rolling the IMAGE back past this delta is NOT safe: a pre-1.54.0
-- image reads the dropped tables. `SET lock_timeout` bounds every lock wait.
--
-- RLS in this bundle: `org_label`'s `tenant_isolation` policy and its
-- ENABLE + FORCE leave with the table; `org_user_label` carried none.
-- schema.sql is 1.53.0's minus exactly these objects; grants.sql is 1.53.0's,
-- unchanged (it grants by schema, not by table); seed.sql drops the empty
-- `org_user_label` data section and re-renders the journal stamp through 0055.
--
-- ROLLBACK.
--
--     Forward-only. The tables and their rows are not recoverable from this
--     bundle; restore from a pre-1.54.0 backup and run a pre-1.54.0 image.

SET lock_timeout = '5s';
DROP TABLE IF EXISTS "org_user_label";
DROP TABLE IF EXISTS "org_label";
