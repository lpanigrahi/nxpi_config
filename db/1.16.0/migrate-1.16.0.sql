-- migrate-1.16.0.sql — schema delta 1.15.0 → 1.16.0 (source migration 0093).
--
-- ADDITIVE-ONLY: two nullable timestamp columns and two partial indexes,
-- every step existence-guarded, so `./update.sh`'s rolling (additive-only)
-- path applies it with no maintenance window and re-running is a no-op.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX
-- lines of this file (see 1.11.0's note): `apply_migrations` greps `head -n 6`.
--
-- 0094 (DROP TABLE agent_memory — an orphan with zero readers/writers,
-- backlog #126) is deliberately NOT in this file: the rolling path is
-- additive-only by contract, and a DROP, however safe, is not additive. It
-- ships beside this file as `optional-0094-drop-agent-memory.sql` (not
-- matched by the `migrate-*.sql` glob, so never applied automatically) with
-- the operator step in the README. Fresh installs from this directory's
-- schema.sql never have that table.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- delta:
--   0093_rbac_privilege_expiry.sql   (org_role_assignment.expires_at,
--                                     org_resource_grant.expires_at,
--                                     two partial indexes)
--
-- W-S2 (G3): time-boxed privilege. NULL keeps standing-grant behaviour
-- unchanged; a non-null expiry is enforced at READ time by the repository
-- liveness filter, and the daily rbac-privilege-expiry sweep (03:55 UTC)
-- garbage-collects lapsed rows and writes ORG_PRIVILEGE_EXPIRED audits.

-- ── 0093: RBAC privilege expiry ─────────────────────────────────────────────
ALTER TABLE org_role_assignment
  ADD COLUMN IF NOT EXISTS expires_at timestamp;
ALTER TABLE org_resource_grant
  ADD COLUMN IF NOT EXISTS expires_at timestamp;

CREATE INDEX IF NOT EXISTS org_role_assignment_expires_at_idx
  ON org_role_assignment (expires_at)
  WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS org_resource_grant_expires_at_idx
  ON org_resource_grant (expires_at)
  WHERE expires_at IS NOT NULL;
