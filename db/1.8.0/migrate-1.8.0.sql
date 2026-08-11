-- migrate-1.8.0.sql — schema delta 1.7.0 → 1.8.0 (source migration 0070).
--
-- ADDITIVE-ONLY and a BEHAVIOURAL NO-OP: one NOT NULL column with
-- `DEFAULT true`, plus a partial index. Every existing skill stays exactly as
-- available as it was, which is the whole point — any other default would
-- silently remove the entire fleet from chat the moment this landed.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE: `skill.deployed` is named in
-- drizzle's EXPLICIT select column list, so `selectSkillById` — the funnel
-- every skill load goes through — requests it whether or not any deployment UI
-- is reachable. A VM that rolls the image ahead of this delta 42703s on every
-- skill load, with no new feature involved at all. That is the same incident
-- class as 1.6.0's `qa_baseline_hash` and 1.5.0's `lifecycle_status`; this is
-- the third time, and `src/lib/db/schema-sentinels.ts` carries a matching
-- probe so a mismatched VM says so at boot rather than at a user's first click.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- delta — every step is existence-guarded, so re-running is a no-op:
--   0070_skill_deployed.sql  (skill.deployed + skill_undeployed_idx)
--
-- Verified by applying it three times consecutively against a database built
-- from db/1.7.0/schema.sql, then dumping the result into this directory's
-- schema.sql.

-- Skill deployment: an author-facing switch over CHAT AVAILABILITY.
-- Idempotent delta (project convention: never blanket db:push). Apply with the
-- PRIVILEGED role.
--
-- WHY: a skill you own has been unconditionally active in every chat turn from
-- the moment you saved it. There was no "not ready yet" short of deleting it —
-- the governance lifecycle is an org-level concept and personal skills are born
-- `approved`. Worse, `resolveActiveToolIds` caps the active set at 50 and
-- truncates by ownership order, so a prolific author's skills silently stopped
-- reaching the model with nothing anywhere saying so. `deployed` is the switch
-- that makes that cap governable instead of arbitrary: an undeployed skill
-- leaves the active set and stops consuming a slot.
--
-- DEFAULT TRUE, and NOT NULL, deliberately. Every existing skill is active
-- today; any other default would silently remove the entire fleet from chat at
-- the moment this delta lands. This migration is a behavioural no-op — which
-- is the point, and is what makes it safe to ship ahead of the UI.
--
-- ADDITIVE-ONLY: one column with a default. A pre-0070 app image keeps running
-- against this schema.

BEGIN;

ALTER TABLE "skill"
  ADD COLUMN IF NOT EXISTS "deployed" boolean DEFAULT true NOT NULL;

-- Partial index on the FALSE side only. The overwhelming majority of rows are
-- `true`, so an index over all of them would be a second copy of the table
-- that no query narrows on; the interesting question is always "which are NOT
-- deployed?" (the management list and the cap-pressure count).
CREATE INDEX IF NOT EXISTS "skill_undeployed_idx"
  ON "skill" ("user_id") WHERE "deployed" = false;

COMMIT;
