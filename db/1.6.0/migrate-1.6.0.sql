-- migrate-1.6.0.sql — schema delta 1.5.0 → 1.6.0 (source migration 0068).
--
-- ADDITIVE-ONLY: three new tables (skill_qa_run, skill_qa_check_result,
-- skill_qa_certification) and one NULL-able column on `skill`. No renames, no
-- drops, no type changes — a 1.5.x app image keeps running against this
-- schema, so the rolling update path (./update.sh) may apply it directly.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE: `skill.qa_baseline_hash` is named in
-- drizzle's EXPLICIT select column list, so `selectSkillById` — the single
-- funnel every skill load goes through — requests it whether or not
-- `skill_qa_v1` is on. A VM that rolls the image ahead of this delta therefore
-- 42703s on every skill load with no QA code involved at all. That is the
-- 2026-07-27 "column skill.scope does not exist" incident class verbatim, and
-- it is exactly the shape 1.5.0's header warns about for lifecycle_status.
-- `src/lib/db/schema-sentinels.ts` carries four matching probes (one per table
-- this delta touches) so a mismatched VM says so out loud at boot.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- delta — every step is existence-guarded, so re-running is a no-op:
--   0068_skill_qa.sql   (skill.qa_baseline_hash + skill_qa_run +
--                        skill_qa_check_result + skill_qa_certification +
--                        neo_gen GRANTs)
--
-- Verified by applying it three times consecutively against a database built
-- from db/1.5.0/schema.sql, then dumping the result into this directory's
-- schema.sql.

-- Skill Quality Assurance Framework v1 (SQAF, ADR-0014, flag `skill_qa_v1`):
-- durable per-(skill, served-surface, registry-version) quality runs, their
-- per-check results, and certification records. Idempotent delta (project
-- convention: never blanket db:push). Apply with the PRIVILEGED role; the
-- trailing GRANTs give the runtime `neo_gen` role DML (the "neo_gen grant
-- gotcha").
--
-- WHY NOT EXTEND `skill_scan`: it is already per-(skill, content_hash,
-- version_number) and carries deductions + a score, so reuse is tempting. Four
-- reasons against:
--   1. Different lifecycles. Drizzle emits ALL columns on insert, so a shared
--      table would force every writer to know both domains — exactly the
--      coupling "independently replaceable" forbids.
--   2. Different cardinality. One run has N check results. As a JSON blob
--      "show me every skill failing md-round-trip" is a full-table scan; as a
--      child table it is an index seek. That query IS the point at fleet scale.
--   3. Different retention. Scans are security evidence and are kept; QA runs
--      are noisy (re-run on every registry bump) and want FIFO trimming.
--   4. Certification needs its own issuer/revoker row with its own lifetime.
--
-- RLS posture: NONE — same as 0064/0065/0066. Skill access derives from the
-- repository's viewer/audience checks; QA surfaces gate on
-- resolveOrgPermission at the route layer.
--
-- BACKFILL: none, deliberately. `skill.qa_baseline_hash` is NULLABLE with no
-- default, so the ALTER is a catalog-only change (no table rewrite) and every
-- existing row is atomically "never QA-measured" at COMMIT. That NULL is the
-- grandfather marker: an already-published skill gets exactly one free,
-- VISIBLE, audited pass (the run is recorded in full and the author sees the
-- failing report) before enforcement bites. Absence of a
-- skill_qa_certification row is likewise the correct state for every
-- pre-existing skill — unlike 0066's lifecycle_status there is nothing to
-- grandfather INTO, because certification is never a precondition for running
-- or publishing.

BEGIN;

-- ── Grandfather marker (the SGTF fast-default analogue) ─────────────────────
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "qa_baseline_hash" text;

-- ── One QA run per (skill, served surface, registry version, tier) ──────────
CREATE TABLE IF NOT EXISTS "skill_qa_run" (
  "id"                 uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "skill_id"           uuid NOT NULL,
  "version_number"     integer,
  "content_hash"       text NOT NULL,
  "inputs_fingerprint" text NOT NULL,
  "registry_version"   integer NOT NULL,
  "tier"               varchar NOT NULL DEFAULT 'static',
  "trigger"            varchar NOT NULL DEFAULT 'manual',
  "status"             varchar NOT NULL,
  "quality_score"      integer NOT NULL,
  "quality_grade"      varchar NOT NULL,
  "category_scores"    json NOT NULL,
  "deductions"         json NOT NULL,
  "blocking"           json NOT NULL DEFAULT '[]'::json,
  "coverage"           json,
  "enforcement_mode"   varchar NOT NULL DEFAULT 'advisory',
  "grandfathered"      boolean NOT NULL DEFAULT false,
  "degraded"           boolean NOT NULL DEFAULT false,
  "duration_ms"        integer NOT NULL DEFAULT 0,
  "requested_by"       uuid,
  "created_at"         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_requested_by_fk"
    FOREIGN KEY ("requested_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_tier_check"
    CHECK ("tier" IN ('static','live'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_status_check"
    CHECK ("status" IN ('passed','failed','degraded','skipped'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Only values a v1 producer actually emits. `skill_scan.scan_source` already
-- carries an orphan 'scheduled' that nothing writes; declaring an enum value
-- with no producer implies a capability that does not exist.
DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_trigger_check"
    CHECK ("trigger" IN ('publish','save','approval','manual','import'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_enforcement_check"
    CHECK ("enforcement_mode" IN ('advisory','enforcing'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_run" ADD CONSTRAINT "skill_qa_run_score_check"
    CHECK ("quality_score" BETWEEN 0 AND 100);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_qa_run_skill_created_idx"
  ON "skill_qa_run" ("skill_id", "created_at" DESC NULLS LAST);
-- THE certifying lookup: the newest run for these exact bytes under this bar.
CREATE INDEX IF NOT EXISTS "skill_qa_run_certifying_idx"
  ON "skill_qa_run" ("skill_id", "content_hash", "registry_version", "tier",
                     "created_at" DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS "skill_qa_run_fingerprint_idx"
  ON "skill_qa_run" ("inputs_fingerprint");
CREATE INDEX IF NOT EXISTS "skill_qa_run_status_idx"
  ON "skill_qa_run" ("status", "created_at" DESC NULLS LAST);

-- ── Per-check result: the fleet-query surface ───────────────────────────────
CREATE TABLE IF NOT EXISTS "skill_qa_check_result" (
  "id"          uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "run_id"      uuid NOT NULL,
  -- Denormalized so fleet queries ("every skill failing md-round-trip") never
  -- join back through skill_qa_run.
  "skill_id"    uuid NOT NULL,
  "check_id"    varchar NOT NULL,
  "category"    varchar NOT NULL,
  "tier"        varchar NOT NULL,
  "enforcement" varchar NOT NULL,
  "status"      varchar NOT NULL,
  "points"      integer NOT NULL DEFAULT 0,
  "deductions"  json NOT NULL DEFAULT '[]'::json,
  "findings"    json NOT NULL DEFAULT '[]'::json,
  "evidence"    json,
  "duration_ms" integer NOT NULL DEFAULT 0,
  "error"       text,
  "skip_reason" varchar,
  "created_at"  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

DO $$ BEGIN
  ALTER TABLE "skill_qa_check_result"
    ADD CONSTRAINT "skill_qa_check_result_run_id_fk"
    FOREIGN KEY ("run_id") REFERENCES "skill_qa_run"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_check_result"
    ADD CONSTRAINT "skill_qa_check_result_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_check_result"
    ADD CONSTRAINT "skill_qa_check_result_status_check"
    CHECK ("status" IN ('pass','warn','fail','skipped','error'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- The orchestrator already rejects a duplicate check id at wiring time; this
-- is the same invariant enforced where it cannot be argued with.
--
-- `duplicate_table` is caught alongside `duplicate_object` and it is NOT
-- belt-and-braces: a UNIQUE constraint also creates an INDEX of the same name,
-- and re-adding it raises `duplicate_table` ("relation already exists") rather
-- than `duplicate_object`. A `duplicate_object`-only handler passes on the
-- first run and aborts the whole transaction on the second — found by actually
-- running this delta twice, which is why the house rule says to.
DO $$ BEGIN
  ALTER TABLE "skill_qa_check_result"
    ADD CONSTRAINT "skill_qa_check_result_run_check_uq"
    UNIQUE ("run_id", "check_id");
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_qa_check_result_run_idx"
  ON "skill_qa_check_result" ("run_id");
CREATE INDEX IF NOT EXISTS "skill_qa_check_result_skill_check_idx"
  ON "skill_qa_check_result" ("skill_id", "check_id", "status");

-- ── Certification: its own row, its own issuer, its own lifetime ────────────
CREATE TABLE IF NOT EXISTS "skill_qa_certification" (
  "id"                 uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "skill_id"           uuid NOT NULL,
  "run_id"             uuid,
  "tier"               varchar NOT NULL,
  "quality_score"      integer NOT NULL,
  "trust_score"        integer,
  -- Compared against a hash RECOMPUTED from the served surface at read time.
  -- A mismatch orphans the record: no UPDATE, no background job, no race.
  "content_hash"       text NOT NULL,
  "version_number"     integer,
  "registry_version"   integer NOT NULL,
  "inputs_fingerprint" text NOT NULL,
  -- The satisfied/unsatisfied ledger — the deduction-list doctrine applied to
  -- certification: it explains why you are Silver and not Gold.
  "requirements"       json NOT NULL DEFAULT '[]'::json,
  "issued_by"          uuid,
  "created_at"         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "revoked_at"         timestamp,
  "revoked_by"         uuid,
  "revoked_reason"     text
);

DO $$ BEGIN
  ALTER TABLE "skill_qa_certification"
    ADD CONSTRAINT "skill_qa_certification_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_certification"
    ADD CONSTRAINT "skill_qa_certification_run_id_fk"
    FOREIGN KEY ("run_id") REFERENCES "skill_qa_run"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_certification"
    ADD CONSTRAINT "skill_qa_certification_issued_by_fk"
    FOREIGN KEY ("issued_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_certification"
    ADD CONSTRAINT "skill_qa_certification_revoked_by_fk"
    FOREIGN KEY ("revoked_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_qa_certification"
    ADD CONSTRAINT "skill_qa_certification_tier_check"
    CHECK ("tier" IN ('none','bronze','silver','gold','enterprise'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_qa_certification_skill_created_idx"
  ON "skill_qa_certification" ("skill_id", "created_at" DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS "skill_qa_certification_skill_hash_idx"
  ON "skill_qa_certification" ("skill_id", "content_hash");

GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_run" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_check_result" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_certification" TO neo_gen;

COMMIT;
