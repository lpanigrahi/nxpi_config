-- migrate-1.10.0.sql — schema delta 1.9.0 → 1.10.0 (source migration 0077).
--
-- ADDITIVE-ONLY and a BEHAVIOURAL NO-OP: one nullable column, no default, no
-- backfill, so `./update.sh`'s rolling (additive-only) path applies it with no
-- maintenance window.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX
-- lines of this file. `apply_migrations` detects it with a bare
-- `head -n 6 | grep -q` (lib.sh:612, :669) — a naive substring match that
-- cannot tell a flag from prose about a flag. Even the sentence you are
-- reading would re-arm the maintenance-window gate if it sat six lines higher.
--
-- Being its own version, rather than an append to 1.9.0, is deliberate on two
-- counts. 1.9.0 is flagged REQUIRES-REVIEW (0073's document_chunk FK cascade),
-- so folding an outage-preventing column into it would force every operator to
-- accept the destructive cascade in a maintenance window purely to avoid a
-- login outage. And the applied-marker is keyed on FILENAME (lib.sh:599-609),
-- so an in-place 1.9.0 edit is a silent no-op on any database that already ran
-- it — the column would never arrive, while every check reported clean.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE: `session.mfa_verified_at` is named
-- in Better Auth's EXPLICIT select column list — the drizzle adapter emits one
-- for every model — so `auth.api.getSession()` requests it on EVERY
-- authenticated request the moment the image carries 0077. A VM that rolls the
-- image ahead of this delta 42703s on session resolution itself: not a
-- degraded surface, a TOTAL LOGIN OUTAGE, with no new feature involved at all.
-- That is the same incident class as 1.8.0's `skill.deployed`, 1.6.0's
-- `qa_baseline_hash` and 1.5.0's `lifecycle_status` — the fourth occurrence,
-- and the first to take authentication down rather than one page.
-- `src/lib/db/schema-sentinels.ts` carries a matching probe so a mismatched VM
-- says so at boot rather than at the first sign-in.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- delta — every step is existence-guarded, so re-running is a no-op:
--   0077_session_mfa_verified_at.sql  (session.mfa_verified_at)
--
-- Verified by applying it twice consecutively against a database built from
-- db/1.9.0/schema.sql, then diffing the resulting catalog against a database
-- built fresh from this directory's schema.sql — the two lineages are
-- identical.

-- rollback: ALTER TABLE "session" DROP COLUMN IF EXISTS mfa_verified_at;
--
-- 0077 — record the IdP's MFA assertion on the session. Idempotent; re-runnable.
-- Set by databaseHooks.session.create.before when Microsoft Entra returns an
-- `amr` claim containing mfa/ngcmfa/mngcmfa (or a configured `acr`), and read
-- at request time as one half of `mfaSatisfied` — the other half being local
-- TOTP enrolment. Null means "no upstream assertion", which is the pre-existing
-- behaviour, so this delta is inert until the `amr` optional claim is added to
-- the Entra app registration. Additive and nullable: no backfill is possible
-- (the claim is per-sign-in) and none is wanted — existing sessions keep
-- falling back to TOTP.
BEGIN;

ALTER TABLE "session"
  ADD COLUMN IF NOT EXISTS mfa_verified_at timestamp;

COMMIT;
