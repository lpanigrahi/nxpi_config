-- migrate-1.7.0.sql — schema delta 1.6.0 → 1.7.0 (source migration 0069).
--
-- ADDITIVE-ONLY: one NULL-able column on `skill_qa_run` and one new table
-- (skill_qa_recording). No renames, no drops, no type changes — a 1.6.x app
-- image keeps running against this schema, so the rolling update path
-- (./update.sh) may apply it directly.
--
-- LOWER RISK THAN 1.6.0, and it is worth saying why rather than assuming it.
-- 1.6.0's danger was `skill.qa_baseline_hash`: drizzle emits an EXPLICIT
-- select column list, so `selectSkillById` — the funnel every skill load goes
-- through — named it whether or not the QA flag was on, and a VM ahead of the
-- delta 42703'd every skill load with no QA code involved. `skill_qa_run` is
-- read only by QA code, which is flag-gated, so the blast radius here is the
-- Quality panel rather than chat. `src/lib/db/schema-sentinels.ts` still
-- carries two matching probes so a mismatched VM says so at boot instead of
-- failing at a user's first click.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- delta — every step is existence-guarded, so re-running is a no-op:
--   0069_skill_qa_replay.sql  (skill_qa_run.fingerprint + skill_qa_recording +
--                              neo_gen GRANT)
--
-- Verified by applying it three times consecutively against a database built
-- from db/1.6.0/schema.sql, then dumping the result into this directory's
-- schema.sql.

-- SQAF follow-up (ADR-0014): make L1 regression real, and make re-analysis
-- possible without a provider call. Idempotent delta (project convention:
-- never blanket db:push). Apply with the PRIVILEGED role; the trailing GRANT
-- gives the runtime `neo_gen` role DML (the "neo_gen grant gotcha").
--
-- WHY: `runLiveSuite` computed an L1 structural fingerprint and then had
-- nowhere to put it, so regression compared CHECK OUTCOMES instead — the only
-- signal the schema could carry. A fingerprint comparison would have reported
-- `no_baseline` on every run, and a feature that always answers "cannot say"
-- is worse than one that is honestly absent. One nullable column fixes that.
--
-- The recording table is the other half of doc 05: `CachedGenerateEnvelope[]`
-- captured through `wrapLanguageModel`, so a six-month-old run can be
-- re-scored against a brand-new rubric with ZERO provider calls. That is the
-- determinism that is actually achievable — replaying the MODEL, not
-- reconstructing a conversation.
--
-- ADDITIVE-ONLY: one NULL-able column and one new table. A 1.6.x app image
-- keeps running against this schema.

BEGIN;

-- ── L1 fingerprint (nullable: every existing run predates it) ───────────────
ALTER TABLE "skill_qa_run"
  ADD COLUMN IF NOT EXISTS "fingerprint" json;

-- ── Replay envelopes ───────────────────────────────────────────────────────
-- Deliberately NOT `chat_export`: that table is a user-facing share artifact
-- with its own retention and expiry, and overloading it would couple a QA
-- lifetime to a sharing lifetime.
CREATE TABLE IF NOT EXISTS "skill_qa_recording" (
  "id"           uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "run_id"       uuid NOT NULL,
  "skill_id"     uuid NOT NULL,
  "content_hash" text NOT NULL,
  -- Which authored case this recording replays, so a suite of N cases yields
  -- N independently replayable rows rather than one opaque blob.
  "case_id"      varchar NOT NULL,
  "model_id"     text NOT NULL,
  -- CachedGenerateEnvelope[] — the verbatim provider parts, one entry per
  -- generation in the run.
  "envelopes"    json NOT NULL,
  "created_at"   timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

DO $$ BEGIN
  ALTER TABLE "skill_qa_recording" ADD CONSTRAINT "skill_qa_recording_run_id_fk"
    FOREIGN KEY ("run_id") REFERENCES "skill_qa_run"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_recording" ADD CONSTRAINT "skill_qa_recording_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- A run replays one recording per case. UNIQUE also creates an INDEX, so this
-- raises `duplicate_table` on a re-run, not `duplicate_object` — both are
-- caught (the 0068 lesson).
DO $$ BEGIN
  ALTER TABLE "skill_qa_recording"
    ADD CONSTRAINT "skill_qa_recording_run_case_uq" UNIQUE ("run_id", "case_id");
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_qa_recording_skill_hash_idx"
  ON "skill_qa_recording" ("skill_id", "content_hash", "created_at" DESC NULLS LAST);

GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_recording" TO neo_gen;

COMMIT;
