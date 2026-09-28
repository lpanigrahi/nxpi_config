-- migrate-1.41.0.sql — schema delta 1.40.1 → 1.41.0 (R14 QA campaign, plane P2 week 4, finding F1 round 1 item 3): `agent` learns WHICH AUTHORITY DISABLED IT. Source migration 0042 (journaled migration 0042_agent_governance_disabled_by.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- `agent.governance_status` is ONE column with TWO authorities on it: the
-- PLATFORM's cross-org kill switch (the admin control plane's force-disable,
-- which blocks the agent at invocation for every tenant on the installation)
-- and the OWNING ORGANIZATION's own lifecycle and review verbs. The column
-- cannot say which authority ruled — so the SUBJECT of a platform enforcement
-- lifted it. Measured at the wire on an earlier bundle: a platform trust &
-- safety admin force-disabled an abusive agent; the tenant's own AI admin
-- clicked Enable on the same agent in its workspace; the agent returned to
-- `approved`, its A2A capability card was re-advertised and `/execute` answered
-- 200 again, with the tenant's own governor recorded as the reviewer.
--
-- The app fix shipped first as a RULE with no schema change: the org tier
-- derived the platform's standing ruling from the platform's own append-only
-- audit pair (`AGENT_PLATFORM_DISABLED` / `AGENT_PLATFORM_ENABLED`, newest row
-- wins). That closed the door, and left one: the ruling lived in a SECOND write
-- in a SECOND transaction, ordered by a millisecond clock. An audit write that
-- is lost leaves the agent disabled with no ruling on record, and the org lift
-- returns — an authorization control failing OPEN on an INSERT. Writing the
-- audit row first and blocking (where the previous bundle left it) trades that
-- for the mirror state: a recorded ruling whose status write then failed, which
-- refuses org lifts on an agent nobody disabled until a platform admin retries.
--
-- This delta makes the PLATFORM's decision and the state it authorizes ONE
-- write. `governance_disabled_by` is `'platform'` when the platform disables,
-- NULL when the platform re-enables, `'org'` when the organization disables or
-- archives, and NULL when the organization enables or approves — and an ORG
-- write can never move it OFF `'platform'` (the app's org-tier writer is
-- platform-sticky in SQL, not by convention). The audit rows are still written,
-- and still blocking: they remain the evidence trail, they are no longer the
-- authorization fact.
--
-- WHAT THAT SENTENCE DOES *NOT* CLAIM (review round 0, SF-1 — recorded here
-- because the journaled 0042_agent_governance_disabled_by.sql is FROZEN by its
-- own sha and a landed migration is never edited; a packaged header is not
-- frozen, which is where this series puts corrections).
--
-- Atomicity holds for the PLATFORM's write. The ORGANIZATION's refusal is a
-- different shape: the app reads the row, decides, and then issues a separate
-- UPDATE. Nothing in this FILE binds those two, so on the app image that shipped
-- with this delta's first cut, a platform disable committing in that interval let
-- an org `enable` land `governance_status = 'approved'` while the `CASE` above
-- preserved `governance_disabled_by = 'platform'` — and the invocation check
-- reads only the status, so the result was an invocable agent under a standing
-- kill switch. That is closed in the APP, not in the schema: the org-tier writer
-- now carries `governance_disabled_by IS DISTINCT FROM 'platform'` in the WHERE
-- of any write that could lift, so the refusal is decided by the row the UPDATE
-- locks. An operator reading only this file should know the column is the
-- substrate for that guard and not the guard itself — a database at 1.41.0 with
-- an app image older than the guard still has the window.
--
-- ONE PROPERTY OF THE BACKFILL'S ORDER, so a later reader does not mistake it for
-- a causal rule (review round 0, NIT-3): `admin_audit_log.id` is a `uuid`, so
-- `ORDER BY created_at DESC, id DESC` breaks an exact-timestamp tie by
-- LEXICOGRAPHIC uuid — deterministic (which is what makes this statement
-- re-runnable) but arbitrary, NOT "the later decision wins". That is deliberate:
-- the predicate is byte-for-byte the reader this release retires, so the backfill
-- reproduces exactly the answers the previous release gave, and no FUTURE write
-- depends on it — the tier is written directly from here on.
--
-- WHAT AN OPERATOR SHOULD KNOW ABOUT THE BACKFILL.
--
-- The platform's past decisions ARE on record, in the audit pair the previous
-- release read, so for every agent under a STANDING platform disable the tier
-- is derivable rather than guessed. The UPDATE below claims exactly those:
-- current status `disabled`, `governance_disabled_by` still NULL (so a row the
-- new app image has already stamped is never clobbered — deploy the image and
-- run this in either order), and the newest of the two platform audit literals
-- for that agent being the DISABLE, `created_at DESC, id DESC`, which is the
-- retired reader's own predicate including its tie-break.
--
-- The remaining `disabled` agents are DELIBERATELY left NULL rather than painted
-- `'org'`. A disable written before this column existed was written by a tier
-- nobody recorded, and `'org'` would assert one; NULL says what is true, and the
-- app treats NULL exactly as it treats `'org'` — the organization may lift it,
-- as it could before this column existed. Nothing is lost by telling the truth.
--
-- NOT DESTRUCTIVE. Nothing is dropped, nothing is renamed, and the single
-- statement that writes data writes a column this file creates — so this delta
-- deliberately carries no review marker in its header and ./update.sh takes it
-- on the ordinary rolling path. Re-runnable in full: ADD COLUMN IF NOT EXISTS,
-- the CHECK guarded on (conname, conrelid), and a backfill that is a no-op on
-- its second run because it claims only rows whose value is still NULL.
--
-- SIZING AND LOCKS. `SET lock_timeout` bounds lock ACQUISITION, not the hold:
-- the ADD COLUMN and the ADD CONSTRAINT take ACCESS EXCLUSIVE on `agent` and
-- this file carries no COMMIT between its statements, so those locks are held
-- through the backfill. `agent` holds one row per authored agent — not one per
-- event — and the UPDATE touches only rows that are both `disabled` and
-- platform-ruled, so on any real installation this is a short statement. Both
-- triage queries below are read-only; run them before and after:
--
--     SELECT count(*) FILTER (WHERE governance_disabled_by IS NOT NULL) AS attributed,
--            count(*) FILTER (WHERE governance_status = 'disabled') AS disabled,
--            count(*) AS total
--       FROM agent WHERE deleted_at IS NULL;
--     SELECT count(*) AS derivable FROM agent a
--      WHERE a.governance_status = 'disabled' AND a.governance_disabled_by IS NULL
--        AND (SELECT l.action FROM admin_audit_log l
--              WHERE l.action IN ('AGENT_PLATFORM_DISABLED','AGENT_PLATFORM_ENABLED')
--                AND l.metadata->>'agentId' = a.id::text
--              ORDER BY l.created_at DESC, l.id DESC LIMIT 1) = 'AGENT_PLATFORM_DISABLED';
--
-- The app image is safe at every point during the run: nothing reads a column
-- that does not exist yet, and an image that predates this delta simply never
-- names the column.
--
-- THE ONE PATH THIS DELTA DOES *NOT* HEAL, and how to see it. `install.sh`'s
-- FRESH path applies `schema.sql`, STAMPS the migration journal instead of
-- running it, and applies `seed.sql`. So an installation created fresh from this
-- bundle has the column (schema.sql carries it) and has NEVER run the backfill.
-- That is correct for a fresh install — there are no agents — but it is NOT
-- correct for a database that acquired rows another way, e.g. a restored dump
-- into a freshly installed schema. On such a database a standing platform kill
-- switch sits with no tier on record and is therefore liftable by its own
-- tenant. `pnpm db:preflight`'s `0042-platform-disable-unattributed` gate counts
-- exactly those rows and names this file's backfill as the repair; taking the
-- deployment through ./update.sh to 1.41.0 or later runs it.
--
-- ROLLBACK. Drop the CHECK, then the column:
--     DO $$ BEGIN
--       IF EXISTS (SELECT 1 FROM pg_constraint
--                   WHERE conname = 'agent_governance_disabled_by_check'
--                     AND conrelid = to_regclass('agent')) THEN
--         ALTER TABLE agent DROP CONSTRAINT agent_governance_disabled_by_check;
--       END IF;
--     END $$;
--     ALTER TABLE agent DROP COLUMN IF EXISTS governance_disabled_by;
-- It restores the pre-1.41.0 shape exactly and loses nothing that was here
-- first. What it COSTS is the finding: roll the APP image back with it. An app
-- image of 1.41.0 or later names this column in every governance lifecycle
-- write at both tiers, so the column's absence 42703s the platform's
-- force-disable and the organization's approve alike.

SET lock_timeout = '5s';

ALTER TABLE agent ADD COLUMN IF NOT EXISTS governance_disabled_by varchar(16);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'agent_governance_disabled_by_check'
      AND conrelid = to_regclass('agent')
  ) THEN
    ALTER TABLE agent
      ADD CONSTRAINT agent_governance_disabled_by_check
      CHECK (governance_disabled_by IN ('org', 'platform'));
  END IF;
END $$;

UPDATE agent a
   SET governance_disabled_by = 'platform'
 WHERE a.governance_status = 'disabled'
   AND a.governance_disabled_by IS NULL
   AND (
     SELECT l.action
       FROM admin_audit_log l
      WHERE l.action IN ('AGENT_PLATFORM_DISABLED', 'AGENT_PLATFORM_ENABLED')
        AND l.metadata->>'agentId' = a.id::text
      ORDER BY l.created_at DESC, l.id DESC
      LIMIT 1
   ) = 'AGENT_PLATFORM_DISABLED';
