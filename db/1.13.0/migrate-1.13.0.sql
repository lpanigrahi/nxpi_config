-- migrate-1.13.0.sql — schema delta 1.12.0 → 1.13.0 (source migration 0081).
--
-- ADDITIVE-ONLY: one boolean column with a constant default, plus a partial
-- index. Nothing is dropped, narrowed or rewritten, so `./update.sh`'s rolling
-- (additive-only) path applies it with no maintenance window and no downtime.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX lines
-- of this file (see 1.12.0's note): `apply_migrations` greps `head -n 6`.
--
-- WHAT IT IS FOR. Org RBAC was a pure union — a role's effective permissions
-- were its own rows plus its ancestors' and its attached groups', with no way
-- to subtract. The Permission Matrix therefore had to render inherited and
-- group-granted cells locked, because the state unticking one would ask for was
-- unrepresentable. This column represents it: the row's presence still means
-- the role states something about the slug, and `denied` says which —
--
--   no row         -> no statement; inherit whatever an ancestor/group says
--   denied = false -> granted by this role (every row before this delta)
--   denied = true  -> refused, outranking any inheritance
--
-- INERT ON ARRIVAL. The default is false, so every existing row keeps its exact
-- meaning and permission resolution returns byte-identical results until an
-- admin unticks an inherited cell for the first time. No backfill, no data
-- migration, no behaviour change at deploy time.
--
-- ORDERING MATTERS. The application queries this column on every read of the
-- Permission Matrix, so the app image that carries ADR-0083 must NOT be
-- promoted before this delta has been applied — otherwise Organizations →
-- Roles & Permissions fails to load with `column "denied" does not exist`.
-- `./update.sh` applies migrations before switching the app image, which is the
-- correct order; a manual image swap is the way to get this wrong.
ALTER TABLE org_role_permission
  ADD COLUMN IF NOT EXISTS denied boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS org_role_permission_denied_idx
  ON org_role_permission (role_id) WHERE denied;
