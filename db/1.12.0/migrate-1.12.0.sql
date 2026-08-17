-- migrate-1.12.0.sql — schema delta 1.11.0 → 1.12.0 (source migration 0080).
--
-- ADDITIVE-ONLY: three new columns on "user", one of them with a constant
-- default and the other two nullable. Nothing is dropped, narrowed or written,
-- so `./update.sh`'s rolling (additive-only) path applies it with no
-- maintenance window and no downtime.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX
-- lines of this file. `apply_migrations` detects it with a bare
-- `head -n 6 | grep -q` (lib.sh:612, :669) — a naive substring match that
-- cannot tell a flag from prose about a flag. Even the sentence you are
-- reading would re-arm the maintenance-window gate if it sat six lines higher.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE: db/1.11.0 composes source migrations
-- through 0079 only. Any image carrying 0080 therefore rolls AHEAD of the
-- packaged delta, and once an admin enables account lockout the sign-in path
-- reads "user".locked_until on EVERY attempt — so the VM 42703s there and
-- NOBODY CAN SIGN IN, the same blast radius as 1.10.0's session column. That
-- is the SIXTH occurrence of this incident class (1.6.0 `qa_baseline_hash`,
-- 1.8.0 `skill.deployed`, 1.10.0 `session.mfa_verified_at`, 1.11.0
-- `organization_entitlement`, and the 2026-07-28 `skill.scope` outage before
-- them). `src/lib/db/schema-sentinels.ts` carries a matching probe on
-- user.locked_until so a mismatched VM says so at boot rather than at the
-- first sign-in, and `schema-sentinels.packaging.guard.test.ts` fails the
-- build when a sentinel has no packaged delta behind it.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- delta — every step is existence-guarded, so re-running is a no-op:
--   0080_account_lockout.sql   (three columns on "user")
-- with no additions of any kind: unlike 1.11.0 this delta creates no unique
-- index, so no live-data pre-flight check is possible or needed — an ADD
-- COLUMN with a constant default cannot conflict with existing rows.
--
-- METADATA-ONLY, NO TABLE REWRITE: `DEFAULT 0` is a non-volatile constant, so
-- PostgreSQL 11+ records it in the catalog and leaves the heap untouched. The
-- statement takes an ACCESS EXCLUSIVE lock on "user" for the duration of the
-- catalog update only — milliseconds regardless of user count.
--
-- INERT ON ARRIVAL: the lockout policy ships disabled (its stored default has
-- enabled=false, and ACCOUNT_LOCKOUT_ENABLED=false in .env.app is a hard kill
-- switch on top of that), so until an operator turns it on nothing reads or
-- writes these columns and every sign-in behaves exactly as before. No
-- backfill is possible or wanted: zero failures is the correct history for
-- every existing row.
--
-- The columns are deliberately NOT part of the Better Auth user model (they
-- are not registered in `user.additionalFields`), so its drizzle adapter never
-- names them in the sign-up INSERT — an older image running against this newer
-- schema is therefore unaffected, and the delta may be applied ahead of the
-- image roll with `./migrate.sh`.
--
-- rollback:
--   ALTER TABLE "user"
--     DROP COLUMN IF EXISTS failed_login_attempts,
--     DROP COLUMN IF EXISTS last_failed_login_at,
--     DROP COLUMN IF EXISTS locked_until;
BEGIN;

-- ── 0080 — account-lockout counters on "user" ────────────────────────────────
-- The three values backing the credential-stuffing brake: a rolling failure
-- count, the timestamp of the most recent failure (which decides whether that
-- count is still inside the policy window or has aged out), and the lock
-- expiry — the one value the sign-in route reads to answer HTTP 423 with a
-- Retry-After. All three are existence-guarded, so this file is re-runnable.
ALTER TABLE "user"
  ADD COLUMN IF NOT EXISTS failed_login_attempts integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_failed_login_at timestamp,
  ADD COLUMN IF NOT EXISTS locked_until timestamp;

COMMIT;
