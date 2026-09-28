-- migrate-1.21.0.sql — schema delta 1.20.0 → 1.21.0 (source migration 0099).
--
-- ADDITIVE-ONLY, every step existence-guarded; re-running is a no-op. W-S10
-- (G8): the mid-session step-up stamp on the Better Auth session table.
-- better-auth's drizzle adapter emits an EXPLICIT column list on every
-- session read, so an image ahead of this delta 42703s on
-- `auth.api.getSession` — a TOTAL LOGIN OUTAGE (the 1.10.0
-- mfa_verified_at incident class). This file must ship WITH the image
-- that declares the column (source migration
-- 0099_session_step_up_at.sql).
--
-- No RLS in this bundle by design: policies are applied post-restore by the
-- src/lib/db/rls/ runner; row security is not applied by the packaged
-- deployment (compliance register).

ALTER TABLE "session"
  ADD COLUMN IF NOT EXISTS step_up_at timestamp;
