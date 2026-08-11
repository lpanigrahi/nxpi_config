-- migrate-1.5.0.sql — schema delta 1.4.0 → 1.5.0 (source migrations 0066–0067).
--
-- ADDITIVE-ONLY: two new tables (skill_scan, skill_attestation) and four new
-- columns on `skill`, all NULL-able or defaulted. No renames, no drops, no type
-- changes — a 1.4.x app image keeps running against this schema, so the rolling
-- update path (./update.sh) may apply it directly.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE: `skill.lifecycle_status` is read with
-- NO feature-flag gate by `selectSkillById` — the single funnel every skill load
-- goes through — and by both advertise queries. A VM that rolls the image ahead
-- of the delta therefore 42703s on every skill load, and those call sites
-- swallow the error, so skills silently VANISH from chat even with
-- `skill_governance_v1` off. That is the 2026-07-27 "column skill.scope does not
-- exist" incident class verbatim; `src/lib/db/schema-sentinels.ts` carries the
-- matching probes so a mismatched VM says so out loud at boot.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas, in order — every step is existence-guarded, so re-running is a no-op:
--   0066_skill_governance_trust.sql          (lifecycle columns + skill_scan +
--                                             skill_attestation + neo_gen GRANTs)
--   0067_skill_lifecycle_previous_status.sql (skill.lifecycle_previous_status)
--
-- Applied twice against the dev database as the idempotency proof.

-- Skill Governance & Trust Framework v1 (SGTF, ADR-0012, flag
-- `skill_governance_v1`): skill lifecycle columns + durable security-scan/
-- trust records + Ed25519 attestation records. Idempotent delta (project
-- convention: never blanket db:push). Apply with the PRIVILEGED role; the
-- trailing GRANTs give the runtime `neo_gen` role DML (the "neo_gen grant
-- gotcha").
--
-- NAMING NOTE: the legacy delta src/lib/db/migrations/pg/0017_skill_governance
-- .sql predates the copilot→assistant rename — the `skill` table it altered is
-- today's `assistant`, and its `governance_status` column has nothing to do
-- with this framework. All names here are fresh (`lifecycle_status`) so an
-- environment that ever ran 0017 against a table literally named `skill`
-- cannot collide with this delta.
--
-- RLS posture: NONE — same as 0064/0065. Skill access derives from the
-- repository's viewer/audience checks; governance access goes through
-- resolveOrgPermission at the route layer.
--
-- Backfill: the `lifecycle_status` NOT NULL DEFAULT 'approved' IS the
-- backfill (PG11+ fast default): every existing skill row is grandfathered as
-- approved atomically, so nothing that runs today stops running when the flag
-- turns on. No UPDATE statement needed; re-running is a no-op.

BEGIN;

-- ── Lifecycle columns on skill (inert while the flag is off) ────────────────

ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "lifecycle_status" varchar NOT NULL DEFAULT 'approved';
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "lifecycle_reviewed_by" uuid;
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "lifecycle_reviewed_at" timestamp;
ALTER TABLE "skill" ADD COLUMN IF NOT EXISTS "lifecycle_note" text;

DO $$ BEGIN
  ALTER TABLE "skill" ADD CONSTRAINT "skill_lifecycle_status_check"
    CHECK ("lifecycle_status" IN
      ('draft', 'pending', 'approved', 'rejected', 'disabled',
       'deprecated', 'retired', 'archived'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill" ADD CONSTRAINT "skill_lifecycle_reviewed_by_user_id_fk"
    FOREIGN KEY ("lifecycle_reviewed_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_org_lifecycle_idx"
  ON "skill" ("organization_id", "lifecycle_status");

-- ── Durable per-(skill, content) security-scan + trust record ───────────────
-- version_number NULL = the live skill row's content; content_hash is the
-- canonical payload sha256 that binds scan ↔ attestation ↔ execution gate.

CREATE TABLE IF NOT EXISTS "skill_scan" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "skill_id" uuid NOT NULL,
  "version_number" integer,
  "content_hash" text NOT NULL,
  "findings" json NOT NULL,
  "summary" json NOT NULL,
  "blocking" boolean NOT NULL DEFAULT false,
  "permission_profile" json NOT NULL,
  "risk_level" varchar NOT NULL,
  "trust_score" integer NOT NULL,
  "trust_grade" varchar NOT NULL,
  "deductions" json NOT NULL,
  "scan_source" varchar NOT NULL DEFAULT 'manual',
  "scanned_by" uuid,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DO $$ BEGIN
  ALTER TABLE "skill_scan" ADD CONSTRAINT "skill_scan_skill_id_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_scan" ADD CONSTRAINT "skill_scan_scanned_by_user_id_fk"
    FOREIGN KEY ("scanned_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_scan" ADD CONSTRAINT "skill_scan_risk_level_check"
    CHECK ("risk_level" IN ('low', 'medium', 'high', 'critical'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_scan" ADD CONSTRAINT "skill_scan_source_check"
    CHECK ("scan_source" IN ('import', 'save', 'approval', 'manual', 'scheduled'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_scan_skill_created_idx"
  ON "skill_scan" ("skill_id", "created_at" DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS "skill_scan_skill_hash_idx"
  ON "skill_scan" ("skill_id", "content_hash");

-- ── Immutable attestation (signing) records with revocation ─────────────────
-- signature = base64 Ed25519 over content_hash; rows are never updated except
-- to stamp revocation.

CREATE TABLE IF NOT EXISTS "skill_attestation" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "skill_id" uuid NOT NULL,
  "version_number" integer,
  "content_hash" text NOT NULL,
  "signature" text NOT NULL,
  "key_id" varchar NOT NULL,
  "algorithm" varchar NOT NULL DEFAULT 'ed25519',
  "signed_by" uuid,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "revoked_at" timestamp,
  "revoked_by" uuid,
  "revoked_reason" text
);

DO $$ BEGIN
  ALTER TABLE "skill_attestation" ADD CONSTRAINT "skill_attestation_skill_id_skill_id_fk"
    FOREIGN KEY ("skill_id") REFERENCES "skill"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_attestation" ADD CONSTRAINT "skill_attestation_signed_by_user_id_fk"
    FOREIGN KEY ("signed_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "skill_attestation" ADD CONSTRAINT "skill_attestation_revoked_by_user_id_fk"
    FOREIGN KEY ("revoked_by") REFERENCES "user"("id") ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "skill_attestation_skill_created_idx"
  ON "skill_attestation" ("skill_id", "created_at" DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS "skill_attestation_skill_hash_idx"
  ON "skill_attestation" ("skill_id", "content_hash");

GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_scan" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_attestation" TO neo_gen;

COMMIT;

-- SGTF follow-up (review round 6): remember what a submission came FROM.
--
-- Round 5 added `deprecated` and `disabled` to `submit.from`, because a status
-- whose content can still reach a model must be able to re-enter review. That
-- fix was necessary but lossy: a deprecated skill edited by its owner became
-- `pending`, and re-approval returned it as `approved` — silently ending a
-- sunset. Consumers mid-migration lost the deprecation warning, and the
-- retirement schedule had to be re-applied by hand.
--
-- One nullable column records the pre-submit status so `approve` can restore
-- `deprecated` instead of flattening it to `approved`. NULL means "nothing to
-- restore", which is every existing row and every ordinary submission.
--
-- Idempotent delta (house rule): IF NOT EXISTS, safe to run twice.

BEGIN;

ALTER TABLE "skill"
  ADD COLUMN IF NOT EXISTS "lifecycle_previous_status" varchar;

COMMIT;
