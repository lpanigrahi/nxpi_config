-- migrate-1.25.0.sql — schema delta 1.24.0 → 1.25.0 (source migrations 0009 to 0017
-- of the journaled series, under src/lib/db/migrations/pg/; each one's own block
-- header is below, in journal order).
-- Constraint-tightening on ONE existing column (0009), additive provenance and
-- tenancy columns with composite foreign keys (0010, 0011), the permission_catalog
-- reference table (0012), the org_member_deny table (0013), the visibility CHECKs
-- (0014), org_resource_grant rebuilt as a partitioned table with cascading typed
-- FKs (0015), the virtual-system-roles cleanup that deletes the catalog defaults
-- every organization had materialised (0016), and the three RBAC junctions made
-- strict-org (0017) (plan §Phase 4 / P4-T2 … P4-T8, P4-T13; review DR-01).
-- 0017's other half — the mirror of src/lib/db/rls/*.sql that gives the authz
-- substrate its POLICIES — is deliberately NOT here: this lineage ships no
-- row-level security and the compliance register's CC6.1 control discloses
-- that. See 0017's own block header below.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0009_org_role_key_not_null.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0009 — custom roles get a stable slug key. FORWARD-ONLY: the NOT NULL is
-- the contract, and reinstating the NULLs would restore a state in which a
-- custom role has no identity (every later authz migration in this phase
-- assumes the key is total). The rollback of record is restore-from-backup.
-- See the source migration for the full rationale.

SET lock_timeout = '5s';

ALTER TABLE org_role DROP CONSTRAINT IF EXISTS org_role_key_check;

-- id::text is always lower-case hex in Postgres, which is why the TypeScript
-- twin (`customRoleKey`) lower-cases before slicing.
UPDATE org_role SET key = 'custom-' || left(replace(id::text,'-',''), 8) WHERE key IS NULL;

ALTER TABLE org_role ALTER COLUMN key SET NOT NULL;

ALTER TABLE org_role ADD CONSTRAINT org_role_key_check CHECK (key ~ '^[a-z0-9][a-z0-9-]{1,63}$');

-- The partial index (`WHERE key IS NOT NULL`) was the only thing that let two
-- custom roles coexist while both keys were NULL; with the column total it
-- becomes a FULL unique index.
DROP INDEX IF EXISTS org_role_org_key_unique;
CREATE UNIQUE INDEX IF NOT EXISTS org_role_org_key_unique ON org_role (organization_id, key);

ALTER TABLE org_role ADD COLUMN IF NOT EXISTS assignable_scope text NOT NULL DEFAULT 'org' CHECK (assignable_scope IN ('org','team'));
ALTER TABLE org_role ADD COLUMN IF NOT EXISTS catalog_version int;

-- ── 0010_composite_fks_and_assignment_source (the second source migration of this delta; its own operator header follows the statements it introduces in the journaled file) ──
SET lock_timeout = '5s';

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0010_composite_fks_and_assignment_source.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- ── The referenced unique indexes (an FK needs one on its target columns) ──
CREATE UNIQUE INDEX IF NOT EXISTS organization_member_org_id_unique ON organization_member (organization_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS org_role_org_id_unique ON org_role (organization_id, id);

-- ── Provenance columns + their DB-enforced vocabulary ─────────────────────
ALTER TABLE org_role_assignment
  ADD COLUMN IF NOT EXISTS source text NOT NULL DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS source_ref text;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_source_check'
      AND conrelid = 'org_role_assignment'::regclass
  ) THEN
    ALTER TABLE org_role_assignment ADD CONSTRAINT org_role_assignment_source_check
      CHECK (source IN ('manual','sso','scim','elevation','break_glass','review','import'));
  END IF;
END $$;

-- ── The composite foreign keys ────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_member_org_fk'
      AND conrelid = 'org_role_assignment'::regclass
  ) THEN
    ALTER TABLE org_role_assignment ADD CONSTRAINT org_role_assignment_member_org_fk
      FOREIGN KEY (organization_id, membership_id)
      REFERENCES organization_member (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_member_org_fk'
      AND conrelid = 'org_role_assignment'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_role_assignment VALIDATE CONSTRAINT org_role_assignment_member_org_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_role_org_fk'
      AND conrelid = 'org_role_assignment'::regclass
  ) THEN
    ALTER TABLE org_role_assignment ADD CONSTRAINT org_role_assignment_role_org_fk
      FOREIGN KEY (organization_id, role_id)
      REFERENCES org_role (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_role_org_fk'
      AND conrelid = 'org_role_assignment'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_role_assignment VALIDATE CONSTRAINT org_role_assignment_role_org_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_resource_grant_member_org_fk'
      AND conrelid = 'org_resource_grant'::regclass
  ) THEN
    ALTER TABLE org_resource_grant ADD CONSTRAINT org_resource_grant_member_org_fk
      FOREIGN KEY (organization_id, membership_id)
      REFERENCES organization_member (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_resource_grant_member_org_fk'
      AND conrelid = 'org_resource_grant'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_resource_grant VALIDATE CONSTRAINT org_resource_grant_member_org_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_privilege_request_member_org_fk'
      AND conrelid = 'org_privilege_request'::regclass
  ) THEN
    ALTER TABLE org_privilege_request ADD CONSTRAINT org_privilege_request_member_org_fk
      FOREIGN KEY (organization_id, membership_id)
      REFERENCES organization_member (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_privilege_request_member_org_fk'
      AND conrelid = 'org_privilege_request'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_privilege_request VALIDATE CONSTRAINT org_privilege_request_member_org_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_privilege_request_role_org_fk'
      AND conrelid = 'org_privilege_request'::regclass
  ) THEN
    ALTER TABLE org_privilege_request ADD CONSTRAINT org_privilege_request_role_org_fk
      FOREIGN KEY (organization_id, role_id)
      REFERENCES org_role (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_privilege_request_role_org_fk'
      AND conrelid = 'org_privilege_request'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_privilege_request VALIDATE CONSTRAINT org_privilege_request_role_org_fk;
  END IF;
END $$;

-- ── PRE-FLIGHT: duplicate pending requests a DEPLOYED database may hold ───
-- org_privilege_request carried no uniqueness at all before this delta and
-- the product does not dedupe filings, so two pending rows for the same
-- (membership, role, team) are a state your database can already be in.
-- Without this block the CREATE UNIQUE INDEX below fails 23505 naming the
-- INDEX and saying nothing about the DATA. So: it names the offending groups
-- and STOPS. Remediation is in the product — decide (approve or deny) or
-- expire the extra filings, then re-run ./migrate.sh. This delta never
-- DELETEs a tenant's rows to make itself pass.
DO $$
DECLARE
  dup_groups bigint;
  dup_rows bigint;
  sample text;
BEGIN
  SELECT count(*), coalesce(sum(n), 0) INTO dup_groups, dup_rows
  FROM (
    SELECT count(*) AS n
      FROM org_privilege_request
     WHERE status = 'pending'
     GROUP BY membership_id, role_id,
              coalesce(team_id, '00000000-0000-0000-0000-000000000000'::uuid)
    HAVING count(*) > 1
  ) g;
  IF dup_groups > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('(membership=%s, role=%s, team=%s) x%s',
                    membership_id, role_id,
                    coalesce(min(team_id::text), 'org-wide'), count(*)) AS k
        FROM org_privilege_request
       WHERE status = 'pending'
       GROUP BY membership_id, role_id,
                coalesce(team_id, '00000000-0000-0000-0000-000000000000'::uuid)
      HAVING count(*) > 1
       LIMIT 5
    ) s;
    RAISE EXCEPTION
      'migration 0010 STOPPED: % duplicate pending privilege-request group(s) (% rows) already exist, so org_privilege_request_pending_unique cannot be created',
      dup_groups, dup_rows
      USING
        DETAIL = 'first offending groups: ' || sample,
        HINT = 'Decide (approve or deny) or expire the extra pending filings in the product, then re-run this migration. It will not DELETE them for you.';
  END IF;
END $$;

-- ── One pending request per (membership, role, team) ──────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS org_privilege_request_pending_unique
  ON org_privilege_request (membership_id, role_id, coalesce(team_id, '00000000-0000-0000-0000-000000000000'::uuid))
  WHERE status = 'pending';

-- ── 0011_team_member_org_membership (the third source migration of this delta; its own operator header follows the statements it introduces in the journaled file) ──
SET lock_timeout = '5s';

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0011_team_member_org_membership.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- team_member gains its TENANT (organization_id) and its ORG MEMBERSHIP
-- (membership_id), both backfilled and then made NOT NULL, plus the composite
-- (organization_id, team_id) → team (organization_id, id) foreign key.
--
-- WHY: "a team member must already be an org member" is a platform-wide
-- invariant enforced by FOUR agreeing writers (the org teams route's 409
-- not_org_member, IdP group-sync, SCIM's group push, team-invite acceptance)
-- and by nothing in the database; and team_member carried no tenant at all, so
-- the single-column team_id reference — satisfied by ANY team in the cluster —
-- was all that stood between a lost org predicate and a cross-tenant team
-- membership. This makes both facts the database's.
--
-- ONE statement can REFUSE on a live database, and it is the pre-flight DO
-- block, on purpose: a team_member row whose user has no organization_member
-- row in the team's org is a DATA DEFECT (a membership removed by a path that
-- skipped removeUserFromOrgTeams, a historic import). It RAISEs with the
-- count, the first five offending rows and the remediation, and the whole file
-- rolls back — the alternative was `SET NOT NULL` failing 23502 naming only
-- the column. Triage:
--   select tm.id, tm.team_id, tm.user_id, t.organization_id
--     from team_member tm
--     join team t on t.id = tm.team_id
--    where not exists (select 1 from organization_member om
--                       where om.organization_id = t.organization_id
--                         and om.user_id = tm.user_id);
-- Enrol each user in the team's organization, or remove the team membership,
-- then re-run. This delta will not invent an organization_member row and will
-- not delete a team_member row.
--
-- Where such rows came from, so the count is not a mystery: a PLATFORM ADMIN
-- who belongs to no organization can create a team in it (the global-admin
-- membership bypass), and team creation makes the creator the team owner — a
-- team_member row for a user with no organization_member row. The image that
-- ships this delta stops that producer (the team is still created; the owner
-- row it cannot write is skipped), so the rows this block may name are
-- historical.
--
-- The VALIDATE of the composite FK can also refuse (23503) if a deployed
-- database already holds a team_member whose organization_id and team_id name
-- different tenants — impossible before this delta, since the column did not
-- exist, and therefore only reachable on a re-run after a hand-written UPDATE.
--
-- THE SAME PAIR LANDS ON TWO MORE TABLES, and there the violation is NOT
-- impossible. org_role_assignment and org_privilege_request gained their
-- (organization_id, membership_id) and (organization_id, role_id) references
-- in the 0010 block above and kept a team_id whose only reference was the
-- single-column team(id) — satisfied by ANY team in the cluster. A
-- team-scoped assignment tagged org A that names org B's team was therefore
-- accepted, and every later read filters by organization_id, so the row is
-- invisible until an authorization decision is made on it. Both now carry
-- (organization_id, team_id) → team (organization_id, id) ON DELETE CASCADE
-- (the same cascade their single-column team_id reference already had).
-- team_id stays NULLABLE: a composite FK is MATCH SIMPLE, so an ORG-WIDE
-- assignment or request (team_id NULL) satisfies it trivially and is not
-- touched. Because their team_id predates this delta, the two VALIDATEs CAN
-- refuse (23503, the DETAIL naming the offending key). Triage:
--   select 'org_role_assignment' as tbl, a.id, a.organization_id, a.team_id
--     from org_role_assignment a join team t on t.id = a.team_id
--    where t.organization_id <> a.organization_id
--   union all
--   select 'org_privilege_request', r.id, r.organization_id, r.team_id
--     from org_privilege_request r join team t on t.id = r.team_id
--    where t.organization_id <> r.organization_id;
-- Each offender is a privilege scoped to another tenant's team: REVOKE it
-- (delete the row), or re-point team_id at a team of its own organization,
-- then re-run. This delta will not delete a privilege row for you.
--
-- An image ahead of this delta cannot ADD a team member at all: the
-- application's addMember names both columns in its INSERT (and its
-- argument-less RETURNING expands to every column), so team creation, the
-- Members UI, SSO group sync, SCIM, team-invite acceptance and bulk import all
-- 42703 on the write path — which is why the boot sentinels probe both columns
-- as NOT NULL (presence proves the column, NOT NULL proves the backfill).
--
-- Applies on the rolling path, deliberately unflagged: no table, column or row
-- is dropped. The ON DELETE CASCADE on the new FK is not a NEW cascade — it
-- matches the single-column team_id FK beside it, which has cascaded since the
-- table was created (with NO ACTION a team deletion would start raising 23503
-- where it cascades today). Idempotent (IF NOT EXISTS / DO $$ guarded by
-- pg_constraint, both UPDATEs guarded by IS NULL); re-running is a no-op.
--
-- LOCK POSTURE: one transaction on BOTH paths (lib.sh applies this file with
-- psql -1; the journaled path carries no drizzle breakpoint marker), so every
-- ACCESS EXCLUSIVE lock is held to COMMIT — through both backfill UPDATEs,
-- both SET NOT NULLs, the two index builds and all THREE VALIDATEs. THREE
-- TABLES are locked, not one: this block's three ADD CONSTRAINTs take ACCESS
-- EXCLUSIVE on team_member, org_role_assignment and org_privilege_request
-- (plus a SHARE ROW EXCLUSIVE on team), so for the whole run no role
-- assignment, no privilege request and no dual-control approval can be
-- written anywhere in the deployment. The two org_* blocks sit LAST
-- deliberately, so their locks are taken as late as possible. `SET lock_timeout`
-- bounds lock ACQUISITION, not the hold. Time the WHOLE file against
-- team_member's row count.
--
-- NOT in this delta, deliberately: row-level security. The plan has
-- team_member reaching FORCE RLS strict-org, and the predicate works, but
-- team-repository reads this table (and writes it) on the bare app pool with
-- no tenant frame — measured, a read without app.current_org_id sees 0 rows —
-- so the policy would blank the Teams surface rather than isolate it. It waits
-- for the repository conversion (see rls-coverage-ledger).
--
-- db/1.25.0/schema.sql carries the same columns, indexes and constraint for
-- fresh installs.

ALTER TABLE team_member
  ADD COLUMN IF NOT EXISTS organization_id uuid,
  ADD COLUMN IF NOT EXISTS membership_id uuid;

UPDATE team_member tm
   SET organization_id = t.organization_id
  FROM team t
 WHERE tm.team_id = t.id
   AND tm.organization_id IS NULL;

UPDATE team_member tm
   SET membership_id = om.id
  FROM organization_member om
 WHERE om.organization_id = tm.organization_id
   AND om.user_id = tm.user_id
   AND tm.membership_id IS NULL;

DO $$
DECLARE
  orphan_membership bigint;
  orphan_tenant bigint;
  sample text;
BEGIN
  SELECT count(*) INTO orphan_tenant
    FROM team_member WHERE organization_id IS NULL;
  SELECT count(*) INTO orphan_membership
    FROM team_member WHERE membership_id IS NULL;
  IF orphan_tenant > 0 OR orphan_membership > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('(team_member=%s, team=%s, user=%s, org=%s)',
                    tm.id, tm.team_id, tm.user_id,
                    coalesce(tm.organization_id::text, 'unresolved')) AS k
        FROM team_member tm
       WHERE tm.organization_id IS NULL OR tm.membership_id IS NULL
       LIMIT 5
    ) s;
    RAISE EXCEPTION
      'migration 0011 STOPPED: % team_member row(s) resolve to no organization and % to no organization_member, so organization_id/membership_id cannot be made NOT NULL',
      orphan_tenant, orphan_membership
      USING
        DETAIL = 'first offending rows: ' || sample,
        HINT = 'A team member must already be an org member (the org teams route, group-sync, SCIM and team-invite acceptance all enforce it). Enrol each user in the team''s organization, or remove the team membership, then re-run this migration. It will neither invent an organization_member row nor delete a team_member row for you.';
  END IF;
END $$;

ALTER TABLE team_member ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE team_member ALTER COLUMN membership_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS team_member_org_team_idx ON team_member (organization_id, team_id);

CREATE UNIQUE INDEX IF NOT EXISTS team_org_id_unique ON team (organization_id, id);

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'team_member_team_org_fk'
      AND conrelid = 'team_member'::regclass
  ) THEN
    ALTER TABLE team_member ADD CONSTRAINT team_member_team_org_fk
      FOREIGN KEY (organization_id, team_id)
      REFERENCES team (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'team_member_team_org_fk'
      AND conrelid = 'team_member'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE team_member VALIDATE CONSTRAINT team_member_team_org_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_team_org_fk'
      AND conrelid = 'org_role_assignment'::regclass
  ) THEN
    ALTER TABLE org_role_assignment ADD CONSTRAINT org_role_assignment_team_org_fk
      FOREIGN KEY (organization_id, team_id)
      REFERENCES team (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_assignment_team_org_fk'
      AND conrelid = 'org_role_assignment'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_role_assignment VALIDATE CONSTRAINT org_role_assignment_team_org_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_privilege_request_team_org_fk'
      AND conrelid = 'org_privilege_request'::regclass
  ) THEN
    ALTER TABLE org_privilege_request ADD CONSTRAINT org_privilege_request_team_org_fk
      FOREIGN KEY (organization_id, team_id)
      REFERENCES team (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_privilege_request_team_org_fk'
      AND conrelid = 'org_privilege_request'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_privilege_request VALIDATE CONSTRAINT org_privilege_request_team_org_fk;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0012_permission_catalog.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- permission_catalog + the three slug foreign keys + CATALOG_VERSION/stage
-- (plan §P4-T5). Statement-identical to the journaled file; its operator
-- header (WHY / lock posture / the org_permission_usage hold) lives there.
-- Applies on the rolling path: additive table, and additive constraints
-- validated against the rows already here. The one ALTER COLUMN TYPE
-- (varchar(100) -> text on org_permission_usage.permission) rewrites no heap
-- but DOES rebuild the two unique indexes that contain the column, inside this
-- same transaction and under the same lock — ~3 s per 300 000 rows, measured;
-- the journaled file's LOCK POSTURE note carries the numbers. It can REFUSE on
-- live data in exactly one way — an orphan slug in one of the three FK'd
-- columns — and the census RAISEs with the offending values before any
-- constraint binds, rolling the whole file back.

SET lock_timeout = '5s';

-- ── The reference table ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS permission_catalog (
  slug text PRIMARY KEY,
  resource text NOT NULL,
  action text NOT NULL,
  risk_tier text NOT NULL,
  domain text NOT NULL,
  axis text NOT NULL,
  stage text NOT NULL CHECK (stage IN ('alpha','beta','ga','deprecated','retired')),
  since_version int NOT NULL,
  retired_version int,
  replaced_by text REFERENCES permission_catalog(slug),
  i18n_key text
);

-- ── The vocabulary, projected from the code that owns it ──────────────────
-- 78 rows = ALL_PERMISSIONS, each carrying the manifest's own
-- resource/action/risk_tier/domain/axis/stage/since_version/i18n_key. The
-- upsert makes a re-run a no-op AND lets a later catalog version re-stage a
-- slug in place; since_version keeps the EARLIEST introduction (least), and
-- retired_version/replaced_by are never touched here — a retirement is a
-- later migration's statement, not a side effect of re-seeding.
INSERT INTO permission_catalog
  (slug, resource, action, risk_tier, domain, axis, stage, since_version, i18n_key)
VALUES
  ('members:view', 'members', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.members.view'),
  ('members:invite', 'members', 'invite', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.members.invite'),
  ('members:edit', 'members', 'edit', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.members.edit'),
  ('members:remove', 'members', 'remove', 'destructive', 'org', 'org', 'ga', 1, 'Rbac.permissions.members.remove'),
  ('members:suspend', 'members', 'suspend', 'destructive', 'org', 'org', 'ga', 1, 'Rbac.permissions.members.suspend'),
  ('teams:view', 'teams', 'view', 'read', 'org', 'org', 'beta', 1, 'Rbac.permissions.teams.view'),
  ('teams:create', 'teams', 'create', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.teams.create'),
  ('teams:edit', 'teams', 'edit', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.teams.edit'),
  ('teams:delete', 'teams', 'delete', 'destructive', 'org', 'org', 'ga', 1, 'Rbac.permissions.teams.delete'),
  ('teams:manage_members', 'teams', 'manage_members', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.teams.manage_members'),
  ('roles:view', 'roles', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.roles.view'),
  ('roles:create', 'roles', 'create', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.roles.create'),
  ('roles:edit', 'roles', 'edit', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.roles.edit'),
  ('roles:delete', 'roles', 'delete', 'destructive', 'org', 'org', 'ga', 1, 'Rbac.permissions.roles.delete'),
  ('roles:assign', 'roles', 'assign', 'write', 'org', 'org', 'ga', 1, 'Rbac.permissions.roles.assign'),
  ('settings:view', 'settings', 'view', 'read', 'org', 'org', 'beta', 1, 'Rbac.permissions.settings.view'),
  ('settings:manage', 'settings', 'manage', 'admin', 'org', 'org', 'ga', 1, 'Rbac.permissions.settings.manage'),
  ('billing:view', 'billing', 'view', 'read', 'org', 'org', 'beta', 1, 'Rbac.permissions.billing.view'),
  ('billing:manage', 'billing', 'manage', 'admin', 'org', 'org', 'ga', 1, 'Rbac.permissions.billing.manage'),
  ('audit:view', 'audit', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.audit.view'),
  ('recertification:view', 'recertification', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.recertification.view'),
  ('recertification:manage', 'recertification', 'manage', 'admin', 'org', 'org', 'ga', 1, 'Rbac.permissions.recertification.manage'),
  ('analytics:view', 'analytics', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.analytics.view'),
  ('security:view', 'security', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.security.view'),
  ('security:manage', 'security', 'manage', 'admin', 'org', 'org', 'ga', 1, 'Rbac.permissions.security.manage'),
  ('storage:view', 'storage', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.storage.view'),
  ('storage:manage', 'storage', 'manage', 'admin', 'org', 'org', 'deprecated', 1, 'Rbac.permissions.storage.manage'),
  ('knowledge:view', 'knowledge', 'view', 'read', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.view'),
  ('knowledge:create', 'knowledge', 'create', 'write', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.create'),
  ('knowledge:edit', 'knowledge', 'edit', 'write', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.edit'),
  ('knowledge:delete', 'knowledge', 'delete', 'destructive', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.delete'),
  ('knowledge:transfer', 'knowledge', 'transfer', 'write', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.transfer'),
  ('knowledge:search', 'knowledge', 'search', 'read', 'knowledge', 'org', 'beta', 1, 'Rbac.permissions.knowledge.search'),
  ('knowledge:publish', 'knowledge', 'publish', 'write', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.publish'),
  ('knowledge:admin', 'knowledge', 'admin', 'admin', 'knowledge', 'org', 'ga', 1, 'Rbac.permissions.knowledge.admin'),
  ('assistants:view', 'assistants', 'view', 'read', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.view'),
  ('assistants:create', 'assistants', 'create', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.create'),
  ('assistants:edit', 'assistants', 'edit', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.edit'),
  ('assistants:delete', 'assistants', 'delete', 'destructive', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.delete'),
  ('assistants:deploy', 'assistants', 'deploy', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.deploy'),
  ('assistants:approve', 'assistants', 'approve', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.approve'),
  ('assistants:disable', 'assistants', 'disable', 'destructive', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.disable'),
  ('assistants:transfer', 'assistants', 'transfer', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.transfer'),
  ('assistants:publish', 'assistants', 'publish', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.assistants.publish'),
  ('agents:view', 'agents', 'view', 'read', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.view'),
  ('agents:create', 'agents', 'create', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.create'),
  ('agents:edit', 'agents', 'edit', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.edit'),
  ('agents:delete', 'agents', 'delete', 'destructive', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.delete'),
  ('agents:approve', 'agents', 'approve', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.approve'),
  ('agents:disable', 'agents', 'disable', 'destructive', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.disable'),
  ('agents:transfer', 'agents', 'transfer', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.transfer'),
  ('agents:publish', 'agents', 'publish', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.agents.publish'),
  ('skills:view', 'skills', 'view', 'read', 'agent', 'org', 'ga', 1, 'Rbac.permissions.skills.view'),
  ('skills:create', 'skills', 'create', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.skills.create'),
  ('skills:approve', 'skills', 'approve', 'write', 'agent', 'org', 'ga', 1, 'Rbac.permissions.skills.approve'),
  ('skills:certify', 'skills', 'certify', 'admin', 'agent', 'org', 'ga', 1, 'Rbac.permissions.skills.certify'),
  ('skills:disable', 'skills', 'disable', 'destructive', 'agent', 'org', 'ga', 1, 'Rbac.permissions.skills.disable'),
  ('skills:manage', 'skills', 'manage', 'admin', 'agent', 'org', 'ga', 1, 'Rbac.permissions.skills.manage'),
  ('skills:execute', 'skills', 'execute', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.skills.execute'),
  ('workflows:view', 'workflows', 'view', 'read', 'agent', 'org', 'beta', 1, 'Rbac.permissions.workflows.view'),
  ('workflows:create', 'workflows', 'create', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.workflows.create'),
  ('workflows:edit', 'workflows', 'edit', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.workflows.edit'),
  ('workflows:delete', 'workflows', 'delete', 'destructive', 'agent', 'org', 'beta', 1, 'Rbac.permissions.workflows.delete'),
  ('mcp:view', 'mcp', 'view', 'read', 'mcp', 'org', 'ga', 1, 'Rbac.permissions.mcp.view'),
  ('mcp:create', 'mcp', 'create', 'write', 'mcp', 'org', 'beta', 1, 'Rbac.permissions.mcp.create'),
  ('mcp:edit', 'mcp', 'edit', 'write', 'mcp', 'org', 'beta', 1, 'Rbac.permissions.mcp.edit'),
  ('mcp:delete', 'mcp', 'delete', 'destructive', 'mcp', 'org', 'beta', 1, 'Rbac.permissions.mcp.delete'),
  ('memory:view', 'memory', 'view', 'read', 'agent', 'org', 'beta', 1, 'Rbac.permissions.memory.view'),
  ('memory:create', 'memory', 'create', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.memory.create'),
  ('memory:edit', 'memory', 'edit', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.memory.edit'),
  ('memory:delete', 'memory', 'delete', 'destructive', 'agent', 'org', 'beta', 1, 'Rbac.permissions.memory.delete'),
  ('memory:share', 'memory', 'share', 'write', 'agent', 'org', 'beta', 1, 'Rbac.permissions.memory.share'),
  ('marketplace:view', 'marketplace', 'view', 'read', 'marketplace', 'org', 'ga', 1, 'Rbac.permissions.marketplace.view'),
  ('marketplace:moderate', 'marketplace', 'moderate', 'admin', 'marketplace', 'org', 'ga', 1, 'Rbac.permissions.marketplace.moderate'),
  ('models:view', 'models', 'view', 'read', 'agent', 'org', 'ga', 1, 'Rbac.permissions.models.view'),
  ('models:manage', 'models', 'manage', 'admin', 'agent', 'org', 'ga', 1, 'Rbac.permissions.models.manage'),
  ('policies:view', 'policies', 'view', 'read', 'org', 'org', 'ga', 1, 'Rbac.permissions.policies.view'),
  ('policies:manage', 'policies', 'manage', 'admin', 'org', 'org', 'ga', 1, 'Rbac.permissions.policies.manage')
ON CONFLICT (slug) DO UPDATE SET
  resource = EXCLUDED.resource,
  action = EXCLUDED.action,
  risk_tier = EXCLUDED.risk_tier,
  domain = EXCLUDED.domain,
  axis = EXCLUDED.axis,
  stage = EXCLUDED.stage,
  since_version = least(permission_catalog.since_version, EXCLUDED.since_version),
  i18n_key = EXCLUDED.i18n_key;

-- ── Orphan census, one per column about to gain a foreign key ─────────────
DO $$
DECLARE
  orphan_rows bigint;
  sample text;
BEGIN
  SELECT count(*) INTO orphan_rows
    FROM org_role_permission t
   WHERE NOT EXISTS (
     SELECT 1 FROM permission_catalog c WHERE c.slug = t.permission
   );
  RAISE NOTICE 'migration 0012: % org_role_permission row(s) name a permission absent from permission_catalog', orphan_rows;
  IF orphan_rows > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('%s x%s', t.permission, count(*)) AS k
        FROM org_role_permission t
       WHERE NOT EXISTS (
         SELECT 1 FROM permission_catalog c WHERE c.slug = t.permission
       )
       GROUP BY t.permission
       LIMIT 10
    ) s;
    RAISE EXCEPTION
      'migration 0012 STOPPED: % org_role_permission row(s) name a permission the catalog does not contain, so org_role_permission_permission_catalog_fk cannot be validated',
      orphan_rows
      USING
        DETAIL = 'orphan slugs: ' || sample,
        HINT = 'These rows are DATA. Either restore the slug to PERMISSION_RESOURCES (then render a NEW migration), or remove the rows in the product, then re-run. This migration deletes orphans only for slugs a previous CATALOG_VERSION had already staged deprecated/retired — none at version 1.';
  END IF;
END $$;

DO $$
DECLARE
  orphan_rows bigint;
  sample text;
BEGIN
  SELECT count(*) INTO orphan_rows
    FROM org_permission_group_item t
   WHERE NOT EXISTS (
     SELECT 1 FROM permission_catalog c WHERE c.slug = t.permission
   );
  RAISE NOTICE 'migration 0012: % org_permission_group_item row(s) name a permission absent from permission_catalog', orphan_rows;
  IF orphan_rows > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('%s x%s', t.permission, count(*)) AS k
        FROM org_permission_group_item t
       WHERE NOT EXISTS (
         SELECT 1 FROM permission_catalog c WHERE c.slug = t.permission
       )
       GROUP BY t.permission
       LIMIT 10
    ) s;
    RAISE EXCEPTION
      'migration 0012 STOPPED: % org_permission_group_item row(s) name a permission the catalog does not contain, so org_permission_group_item_permission_catalog_fk cannot be validated',
      orphan_rows
      USING
        DETAIL = 'orphan slugs: ' || sample,
        HINT = 'These rows are DATA. Either restore the slug to PERMISSION_RESOURCES (then render a NEW migration), or remove the rows in the product, then re-run. This migration deletes orphans only for slugs a previous CATALOG_VERSION had already staged deprecated/retired — none at version 1.';
  END IF;
END $$;

DO $$
DECLARE
  orphan_rows bigint;
  sample text;
BEGIN
  SELECT count(*) INTO orphan_rows
    FROM org_resource_grant t
   WHERE NOT EXISTS (
     SELECT 1 FROM permission_catalog c WHERE c.slug = t.permission
   );
  RAISE NOTICE 'migration 0012: % org_resource_grant row(s) name a permission absent from permission_catalog', orphan_rows;
  IF orphan_rows > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('%s x%s', t.permission, count(*)) AS k
        FROM org_resource_grant t
       WHERE NOT EXISTS (
         SELECT 1 FROM permission_catalog c WHERE c.slug = t.permission
       )
       GROUP BY t.permission
       LIMIT 10
    ) s;
    RAISE EXCEPTION
      'migration 0012 STOPPED: % org_resource_grant row(s) name a permission the catalog does not contain, so org_resource_grant_permission_catalog_fk cannot be validated',
      orphan_rows
      USING
        DETAIL = 'orphan slugs: ' || sample,
        HINT = 'These rows are DATA. Either restore the slug to PERMISSION_RESOURCES (then render a NEW migration), or remove the rows in the product, then re-run. This migration deletes orphans only for slugs a previous CATALOG_VERSION had already staged deprecated/retired — none at version 1.';
  END IF;
END $$;

-- ── The foreign keys (NOT VALID, then VALIDATE: the proof no row violates them) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_permission_catalog_fk'
      AND conrelid = 'org_role_permission'::regclass
  ) THEN
    ALTER TABLE org_role_permission ADD CONSTRAINT org_role_permission_permission_catalog_fk
      FOREIGN KEY (permission) REFERENCES permission_catalog (slug) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_permission_catalog_fk'
      AND conrelid = 'org_role_permission'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_role_permission VALIDATE CONSTRAINT org_role_permission_permission_catalog_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_permission_group_item_permission_catalog_fk'
      AND conrelid = 'org_permission_group_item'::regclass
  ) THEN
    ALTER TABLE org_permission_group_item ADD CONSTRAINT org_permission_group_item_permission_catalog_fk
      FOREIGN KEY (permission) REFERENCES permission_catalog (slug) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_permission_group_item_permission_catalog_fk'
      AND conrelid = 'org_permission_group_item'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_permission_group_item VALIDATE CONSTRAINT org_permission_group_item_permission_catalog_fk;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_resource_grant_permission_catalog_fk'
      AND conrelid = 'org_resource_grant'::regclass
  ) THEN
    ALTER TABLE org_resource_grant ADD CONSTRAINT org_resource_grant_permission_catalog_fk
      FOREIGN KEY (permission) REFERENCES permission_catalog (slug) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_resource_grant_permission_catalog_fk'
      AND conrelid = 'org_resource_grant'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_resource_grant VALIDATE CONSTRAINT org_resource_grant_permission_catalog_fk;
  END IF;
END $$;

-- ── org_permission_usage.permission: varchar(100) -> text, and NO foreign key ──
-- The widening is the FK's prerequisite and the type every other slug column
-- already carries; re-running it is a no-op. The CONSTRAINT is deliberately
-- not added, because this column does not hold a catalog slug: the PDP's
-- manager arm records the '__manager__' pseudo-slug through
-- recordPermissionUse (lib/organizations/rbac/permission-usage.ts), so the
-- column's vocabulary is "a catalog slug OR a declared pseudo-slug". An FK
-- here would 23503 that INSERT, and the recorder is telemetry-grade — its
-- catch logs at debug and returns — so the loss would be SILENT: the
-- bypass-visibility thread (W-S4) would stop recording with no error
-- anywhere. Measured on this lane's scratch database with the FK present: the
-- pseudo-slug INSERT fails 23503. Giving the pseudo-slug vocabulary a referent
-- is a design decision, so it gets its own brief rather than a row invented
-- here to make a constraint pass. RATIFIED as a three-column scope (Phase-4
-- controller, 2026-09-17) with the hand-off recorded: the hold CLOSES IN
-- PHASE 5, when the decision log records bypass admissions as
-- authority: manager_bypass and these usage rows are retired (plan §P5-T2/T3),
-- leaving a column that holds catalog slugs only — at which point the fourth
-- foreign key is added and permission-catalog-usage-fk-hold.guard.test.ts,
-- which reds from both sides, comes down with it.
ALTER TABLE org_permission_usage ALTER COLUMN permission TYPE text;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0013_org_member_deny.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- org_member_deny — the PRINCIPAL deny layer (plan §P4-T6). One row per
-- (member, permission), folded LAST in buildMemberPermissions and refused by
-- the PDP as principal_denied before the allow path; until it there was only
-- one deny axis (org_role_permission.denied), which is a statement a ROLE
-- makes and which another assigned role re-grants. Statement-identical to the
-- journaled file APART FROM ITS RLS BLOCK, which this delta deliberately does
-- not carry — see the last block of this section, which says why in full.
-- The journaled file's operator header (WHY / who it binds / lock posture /
-- why the policy is in the migration) lives there.
--
-- Applies on the rolling path with no maintenance window: it CREATEs a table
-- and then only ALTERs that same empty table, so every ACCESS EXCLUSIVE lock
-- is on a relation no other session can be reading and both VALIDATEs scan
-- zero rows. It can refuse on live data in NO way — there are no rows to
-- violate a constraint and nothing to back-fill. The two FK targets
-- (organization_member, permission_catalog) take a brief SHARE ROW EXCLUSIVE,
-- which is the one thing that can queue behind a long-running writer there.
--
-- RLS: this delta carries the TABLE but not its policy — see the block at the
-- end of it, which says why in full. Every deployment shape gets the policy
-- the same way it gets the other 57: from the RLS runner
-- (src/lib/db/rls/0023_org_member_deny.sql, identical and idempotent).

SET lock_timeout = '5s';

-- ── The table ─────────────────────────────────────────────────────────────
-- The single-column foreign keys carry the names drizzle-kit derives from
-- schema.pg.ts (table_column_reftable_refcolumn_fk), so db:push against a dev
-- database diffs to nothing.
CREATE TABLE IF NOT EXISTS org_member_deny (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid NOT NULL CONSTRAINT org_member_deny_organization_id_organization_id_fk REFERENCES organization (id) ON DELETE CASCADE,
  membership_id uuid NOT NULL CONSTRAINT org_member_deny_membership_id_organization_member_id_fk REFERENCES organization_member (id) ON DELETE CASCADE,
  permission text NOT NULL,
  reason text,
  created_by uuid CONSTRAINT org_member_deny_created_by_user_id_fk REFERENCES "user" (id) ON DELETE SET NULL,
  created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  expires_at timestamp,
  -- ONE statement per (member, slug): re-denying is an upsert, not a second
  -- row, and the repository's add() targets exactly this constraint.
  CONSTRAINT org_member_deny_unique UNIQUE (membership_id, permission)
);

-- ── Indexes: one per reader ───────────────────────────────────────────────
-- membership: the snapshot loader's read (every authorization decision).
-- organization: the RLS predicate and the org-wide administrative listing.
-- No expiry index, and the omission is deliberate: org_role_assignment's
-- partial one exists for the daily sweep that garbage-collects lapsed rows,
-- and no sweep scans this table — a lapsed deny is filtered at read time and
-- is harmless until someone deletes it.
CREATE INDEX IF NOT EXISTS org_member_deny_membership_idx ON org_member_deny (membership_id);
CREATE INDEX IF NOT EXISTS org_member_deny_org_idx ON org_member_deny (organization_id);

-- ── The composite tenancy FK (0010's house style) ─────────────────────────
-- organization_id and membership_id were checked INDEPENDENTLY by the two
-- single-column references above: one says "this membership exists", the other
-- "this org exists", and neither says they belong together. On an assignment
-- table that admits a cross-tenant GRANT; on a deny table it admits a
-- cross-tenant REFUSAL — a denial of service against a stranger's account,
-- invisible to that org's own reads. NOT VALID then VALIDATE, which is the
-- proof no row already violates it (trivially true on a table this file just
-- created, and the posture 0010/0011/0012 established for the case where it is
-- not).
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_member_deny_member_org_fk'
      AND conrelid = 'org_member_deny'::regclass
  ) THEN
    ALTER TABLE org_member_deny ADD CONSTRAINT org_member_deny_member_org_fk
      FOREIGN KEY (organization_id, membership_id)
      REFERENCES organization_member (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_member_deny_member_org_fk'
      AND conrelid = 'org_member_deny'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_member_deny VALIDATE CONSTRAINT org_member_deny_member_org_fk;
  END IF;
END $$;

-- ── The slug must be one the catalog declares (0012) ──────────────────────
-- Same key the three grant/matrix columns gained in 0012, and the same
-- reasoning: a refusal naming a slug nothing knows is inert — it refuses
-- nothing and reports nothing — which on this table reads as "the deny is in
-- place" while the member keeps the capability. NO cascade: retiring a slug
-- must not silently DELETE a tenant's refusals, which would hand back access
-- nobody re-granted.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_member_deny_permission_catalog_fk'
      AND conrelid = 'org_member_deny'::regclass
  ) THEN
    ALTER TABLE org_member_deny ADD CONSTRAINT org_member_deny_permission_catalog_fk
      FOREIGN KEY (permission) REFERENCES permission_catalog (slug) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'org_member_deny_permission_catalog_fk'
      AND conrelid = 'org_member_deny'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE org_member_deny VALIDATE CONSTRAINT org_member_deny_permission_catalog_fk;
  END IF;
END $$;

-- ── The generation bump, in the same transaction as the row (0007) ────────
DROP TRIGGER IF EXISTS authz_gen_bump ON org_member_deny;
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_member_deny FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

-- ── RLS is NOT in this packaged delta, and that is deliberate ────────────
-- The journaled migration DOES turn strict-org FORCE RLS on for this table
-- (its own header says why), and src/lib/db/rls/0023_org_member_deny.sql
-- carries the identical policy for the RLS runner. This delta carries
-- NEITHER, because the PACKAGED lineage delivers no row-level security at
-- all: schema.sql is a pg_dump and dumps no policies, no packaged delta has
-- ever enabled RLS on any table, and the compliance register's CC6.1 control
-- discloses exactly that to the operator — a disclosure
-- src/lib/guardian/compliance-register-ledger.guard.test.ts MEASURES against
-- this bundle's own .sql files (`packagedRlsTables`). Shipping one policy
-- here would make that disclosure false for one table out of ninety while
-- changing nothing about how an operator actually gets RLS: through the
-- runner, i.e. docs/runbooks/production-rls-enablement.md, which applies
-- src/lib/db/rls/*.sql — rls/0023 among them — exactly as it does for the 57
-- other covered tables. So the deployment shapes converge on the runner
-- rather than diverging here.

-- ── 0014_resource_visibility_check (the THIRD source migration of this delta) ──
SET lock_timeout = '5s';

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0014_resource_visibility_check.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0014 — ONE stored visibility vocabulary, CHECKed on every visibility column
-- there is: agent, skill, mcp_server, workflow, a2a_capability_card,
-- knowledge_base, team, assistant, prompt_template. FOUR of them (mcp_server,
-- workflow, a2a_capability_card, team) carried NO database constraint at all
-- until this delta — the application's varchar enum was the only thing that
-- had ever said what they may hold — and an out-of-vocabulary value is
-- SILENT: every reader normalises through the access layer, which fails an
-- unrecognised value closed to 'private', so a resource an operator meant to
-- SHARE reads as owner-only and nothing is logged. Rows already outside a
-- column's vocabulary are normalised to 'private' (the value the read layer
-- was already answering for them, so no decision changes), then each CHECK is
-- added NOT VALID and VALIDATEd — the VALIDATE is the proof that no row in
-- the database already violates it.
--
-- The legacy spellings 'org' and 'readonly' are deliberately STILL ADMITTED.
-- Rewriting them is a behaviour change on this codebase and, for 'readonly',
-- a privilege escalation (a repository reads the stored string itself as a
-- non-owner write DENIAL), so retiring them is a product-vocabulary sweep
-- that moves code and data in one change, not a schema delta.
--
-- Idempotent: every UPDATE is WHERE visibility NOT IN (its own set), every
-- ADD CONSTRAINT sits behind a pg_constraint existence check and every
-- VALIDATE behind NOT convalidated. An existing CHECK is left alone rather
-- than dropped and re-added. Re-running the file is a no-op.
--
-- IF A VALIDATE REFUSES (23514): the data is outside the vocabulary and the
-- UPDATE above it did not catch it, which can only mean the column's declared
-- set and the constraint disagree. Triage, per table:
--   select visibility, count(*) from agent group by 1 order by 2 desc;
-- and fix the SET, not the rows.
--
-- One transaction: lib.sh applies this file with psql -1, so every ADD
-- CONSTRAINT's ACCESS EXCLUSIVE lock is held to COMMIT, through all four
-- VALIDATEs. SET lock_timeout bounds lock ACQUISITION, not the hold. Time the
-- whole file against the widest table (agent).
-- db/1.25.0/schema.sql carries the same nine constraints for fresh installs.

-- ── agent: public | private | readonly | team | organization | official ────
UPDATE agent
   SET visibility = 'private'
 WHERE visibility NOT IN ('public','private','readonly','team','organization','official');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'agent_visibility_check'
      AND conrelid = 'agent'::regclass
  ) THEN
    ALTER TABLE agent ADD CONSTRAINT agent_visibility_check
      CHECK (visibility IN ('public','private','readonly','team','organization','official')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'agent_visibility_check'
      AND conrelid = 'agent'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE agent VALIDATE CONSTRAINT agent_visibility_check;
  END IF;
END $$;

-- ── skill: public | private | readonly ─────────────────────────────────────
UPDATE skill
   SET visibility = 'private'
 WHERE visibility NOT IN ('public','private','readonly');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'skill_visibility_check'
      AND conrelid = 'skill'::regclass
  ) THEN
    ALTER TABLE skill ADD CONSTRAINT skill_visibility_check
      CHECK (visibility IN ('public','private','readonly')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'skill_visibility_check'
      AND conrelid = 'skill'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE skill VALIDATE CONSTRAINT skill_visibility_check;
  END IF;
END $$;

-- ── mcp_server: public | private  (NO CHECK before this file) ──────────────
UPDATE mcp_server
   SET visibility = 'private'
 WHERE visibility NOT IN ('public','private');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mcp_server_visibility_check'
      AND conrelid = 'mcp_server'::regclass
  ) THEN
    ALTER TABLE mcp_server ADD CONSTRAINT mcp_server_visibility_check
      CHECK (visibility IN ('public','private')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mcp_server_visibility_check'
      AND conrelid = 'mcp_server'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE mcp_server VALIDATE CONSTRAINT mcp_server_visibility_check;
  END IF;
END $$;

-- ── workflow: public | private | readonly  (NO CHECK before this file) ─────
-- The one whose stored 'readonly' is read as a WRITE DENIAL by
-- workflow-repository.checkAccess — see the header's held-rewrite note.
UPDATE workflow
   SET visibility = 'private'
 WHERE visibility NOT IN ('public','private','readonly');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'workflow_visibility_check'
      AND conrelid = 'workflow'::regclass
  ) THEN
    ALTER TABLE workflow ADD CONSTRAINT workflow_visibility_check
      CHECK (visibility IN ('public','private','readonly')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'workflow_visibility_check'
      AND conrelid = 'workflow'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE workflow VALIDATE CONSTRAINT workflow_visibility_check;
  END IF;
END $$;

-- ── a2a_capability_card: the agent set, NULLABLE  (NO CHECK before this) ───
-- The card MIRRORS its agent's visibility and may hold NULL (no mirror yet),
-- so the CHECK admits NULL explicitly. Postgres would accept a null row
-- either way — IN (...) is NULL, not false, for one — but saying it keeps the
-- constraint readable as the vocabulary it is, and stops the next author
-- reading the omission as an oversight.
UPDATE a2a_capability_card
   SET visibility = 'private'
 WHERE visibility IS NOT NULL
   AND visibility NOT IN ('public','private','readonly','team','organization','official');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'a2a_capability_card_visibility_check'
      AND conrelid = 'a2a_capability_card'::regclass
  ) THEN
    ALTER TABLE a2a_capability_card ADD CONSTRAINT a2a_capability_card_visibility_check
      CHECK (visibility IS NULL OR visibility IN ('public','private','readonly','team','organization','official')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'a2a_capability_card_visibility_check'
      AND conrelid = 'a2a_capability_card'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE a2a_capability_card
      VALIDATE CONSTRAINT a2a_capability_card_visibility_check;
  END IF;
END $$;

-- ── knowledge_base: private | team | org | public ──────────────────────────
UPDATE knowledge_base
   SET visibility = 'private'
 WHERE visibility NOT IN ('private','team','org','public');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'knowledge_base_visibility_check'
      AND conrelid = 'knowledge_base'::regclass
  ) THEN
    ALTER TABLE knowledge_base ADD CONSTRAINT knowledge_base_visibility_check
      CHECK (visibility IN ('private','team','org','public')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'knowledge_base_visibility_check'
      AND conrelid = 'knowledge_base'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE knowledge_base
      VALIDATE CONSTRAINT knowledge_base_visibility_check;
  END IF;
END $$;

-- ── team: private | organization  (NO CHECK before this file) ──────────────
UPDATE team
   SET visibility = 'private'
 WHERE visibility NOT IN ('private','organization');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'team_visibility_check'
      AND conrelid = 'team'::regclass
  ) THEN
    ALTER TABLE team ADD CONSTRAINT team_visibility_check
      CHECK (visibility IN ('private','organization')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'team_visibility_check'
      AND conrelid = 'team'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE team VALIDATE CONSTRAINT team_visibility_check;
  END IF;
END $$;

-- ── assistant: private | team | org | official ─────────────────────────────
UPDATE assistant
   SET visibility = 'private'
 WHERE visibility NOT IN ('private','team','org','official');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'assistant_visibility_check'
      AND conrelid = 'assistant'::regclass
  ) THEN
    ALTER TABLE assistant ADD CONSTRAINT assistant_visibility_check
      CHECK (visibility IN ('private','team','org','official')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'assistant_visibility_check'
      AND conrelid = 'assistant'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE assistant VALIDATE CONSTRAINT assistant_visibility_check;
  END IF;
END $$;

-- ── prompt_template: private | org | public ────────────────────────────────
UPDATE prompt_template
   SET visibility = 'private'
 WHERE visibility NOT IN ('private','org','public');

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'prompt_template_visibility_check'
      AND conrelid = 'prompt_template'::regclass
  ) THEN
    ALTER TABLE prompt_template ADD CONSTRAINT prompt_template_visibility_check
      CHECK (visibility IN ('private','org','public')) NOT VALID;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'prompt_template_visibility_check'
      AND conrelid = 'prompt_template'::regclass AND NOT convalidated
  ) THEN
    ALTER TABLE prompt_template
      VALIDATE CONSTRAINT prompt_template_visibility_check;
  END IF;
END $$;

-- ── 0015_org_resource_grant_partitioned (the FOURTH source migration of this delta) ──
SET lock_timeout = '5s';

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0015_org_resource_grant_partitioned.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0015 — org_resource_grant is REBUILT as PARTITION BY LIST (resource_type),
-- one partition per instance resource type (agents, assistants, knowledge,
-- mcp, teams, workflows), each owning its own
-- resource_id uuid REFERENCES <that type's table>(id) ON DELETE CASCADE.
--
-- WHY: resource_id was polymorphic TEXT with no foreign key anywhere, so
-- nothing in the database connected a per-instance grant to the thing it
-- grants access to. Measured before this delta: a grant SURVIVED the deletion
-- of its knowledge base (pointing at nothing), a grant for an agent id that
-- never existed was accepted, and so was one carrying a resource_type outside
-- the closed set together with a resource_id that is not a uuid. Per-instance
-- grants are consulted BEFORE the visibility tier on every resource access,
-- which is what makes that gap worth a rebuild.
--
-- ROW-PRESERVING, and it proves it: the block copies every row and compares
-- COUNT plus an order-independent md5 checksum over every column of every row
-- BEFORE dropping the old table. A mismatch RAISEs, the transaction rolls
-- back and the old table is untouched.
--
-- THE THREE PRE-FLIGHTS below STOP on data the new shape cannot carry and
-- NAME the offending rows in DETAIL: a resource_type with no partition, a
-- resource_id that is not a uuid, and a resource_id matching no row in its
-- type's table (a grant that outlived its resource). Each is DATA, so the
-- remediation is in the product — revoke the grant or restore the resource,
-- then re-run. This delta will not DELETE a tenant's rows to make itself
-- pass.
--
-- CARRIED OVER EXPLICITLY, because a DROP TABLE takes all three with it: the
-- app role's DML privileges (without them the site cannot read authorization
-- at all), the tenant-isolation policies and RLS posture (without them a
-- grant is visible cross-tenant on a database where RLS is enabled), and the
-- authz-generation trigger (without it a decision is served from a stale
-- snapshot cache after a grant changes). All three are captured from the old
-- table and re-applied to the new parent AND to every partition — a
-- partitioned parent does not hand its RLS posture down, and a partition
-- addressed directly answers to its own policies.
--
-- WHAT THIS NARROWS, stated rather than discovered. Postgres requires every
-- unique constraint on a partitioned table to CONTAIN the partition key, so
-- the primary key becomes (id, resource_type) and id alone is unique only
-- within a partition; with gen_random_uuid() ids that is not a reachable
-- collision, and both readers that address a grant by id also scope by
-- organization_id. org_resource_grant_unique already contained the partition
-- key and is unchanged. The database now also REFUSES three things it used to
-- accept, each of them a state the application already refuses at its own
-- boundary: an unknown resource_type (23514 — no partition), a resource_id
-- matching no row (23503), a non-uuid resource_id (22P02).
--
-- RE-RUNNABLE: the rebuild is guarded on org_resource_grant still being a
-- PLAIN table, so a second apply returns immediately. One transaction on both
-- paths (lib.sh applies this file with psql -1; drizzle sends it whole), so a
-- partially-rebuilt table is not a reachable state and no staging table can
-- outlive a failure. Lock posture: ACCESS EXCLUSIVE on org_resource_grant
-- from the DROP to COMMIT — size it with
-- `select count(*) from org_resource_grant` (the product writes grants from
-- one screen; the reference database carries 0).
-- db/1.25.0/schema.sql carries the partitioned shape for fresh installs.

-- ── PRE-FLIGHT 1: a resource_type with no partition ───────────────────────
-- LIST partitioning has no home for a row outside the closed set, and the
-- INSERT ... SELECT below would fail 23514 naming the TABLE and saying
-- nothing about the DATA. So: name the offending types and STOP. The
-- remediation is in the PRODUCT (revoke the grants, or add the type to
-- INSTANCE_RESOURCE_TYPES and give it a partition); a migration never DELETEs
-- a tenant's rows to make itself pass.
DO $$
DECLARE
  bad_rows bigint;
  sample text;
BEGIN
  SELECT count(*) INTO bad_rows
    FROM org_resource_grant
   WHERE resource_type NOT IN
         ('agents','assistants','knowledge','mcp','teams','workflows');
  IF bad_rows > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('%s x%s', resource_type, count(*)) AS k
        FROM org_resource_grant
       WHERE resource_type NOT IN
             ('agents','assistants','knowledge','mcp','teams','workflows')
       GROUP BY resource_type
       LIMIT 10
    ) s;
    RAISE EXCEPTION
      'migration 0015 STOPPED: % org_resource_grant row(s) carry a resource_type outside INSTANCE_RESOURCE_TYPES, so no LIST partition can hold them',
      bad_rows
      USING
        DETAIL = 'offending types: ' || sample,
        HINT = 'Revoke those grants in the product, or add the type to INSTANCE_RESOURCE_TYPES and give this migration a partition for it. It will not DELETE them for you.';
  END IF;
END $$;

-- ── PRE-FLIGHT 2: a resource_id that is not a uuid ────────────────────────
-- The column becomes uuid, so a non-uuid value would fail 22P02 mid-copy
-- naming neither the row nor the table. Reachable only past the service
-- (resourceExistsInOrg compares against a uuid id column and would itself
-- 22P02), i.e. by a direct write — which is exactly the class this file
-- closes.
DO $$
DECLARE
  bad_rows bigint;
  sample text;
BEGIN
  SELECT count(*) INTO bad_rows
    FROM org_resource_grant
   WHERE resource_id::text !~*
         '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
  IF bad_rows > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('(org=%s, type=%s, id=%s)',
                    organization_id, resource_type, resource_id) AS k
        FROM org_resource_grant
       WHERE resource_id::text !~*
             '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       LIMIT 5
    ) s;
    RAISE EXCEPTION
      'migration 0015 STOPPED: % org_resource_grant row(s) carry a resource_id that is not a uuid, so the column cannot become uuid',
      bad_rows
      USING
        DETAIL = 'first offending rows: ' || sample,
        HINT = 'These grants point at nothing addressable. Revoke them in the product, then re-run. This migration will not DELETE them for you.';
  END IF;
END $$;

-- ── PRE-FLIGHT 3: a resource_id that matches no row in its type's table ───
-- The per-partition FK would refuse these 23503, naming the CONSTRAINT and
-- not the rows. They are DATA — a grant that outlived its resource — and the
-- ruling on whether to revoke them belongs to the owner, not to this file.
DO $$
DECLARE
  pair record;
  n bigint;
  ids text;
  total bigint := 0;
  detail text := '';
BEGIN
  FOR pair IN
    SELECT * FROM (VALUES
      ('agents', 'agent'),
      ('assistants', 'assistant'),
      ('knowledge', 'knowledge_base'),
      ('mcp', 'mcp_server'),
      ('teams', 'team'),
      ('workflows', 'workflow')
    ) AS t(resource_type, target_table)
  LOOP
    EXECUTE format(
      'SELECT count(*), coalesce(left(string_agg(DISTINCT g.resource_id::text, '', ''), 300), '''') '
      '  FROM org_resource_grant g '
      ' WHERE g.resource_type = %L '
      '   AND NOT EXISTS (SELECT 1 FROM %I t WHERE t.id = g.resource_id::uuid)',
      pair.resource_type, pair.target_table)
      INTO n, ids;
    IF n > 0 THEN
      total := total + n;
      detail := detail || format('%s -> %s: %s row(s) [%s]; ',
                                 pair.resource_type, pair.target_table, n, ids);
    END IF;
  END LOOP;
  IF total > 0 THEN
    RAISE EXCEPTION
      'migration 0015 STOPPED: % org_resource_grant row(s) point at a resource that no longer exists, so the per-partition foreign key cannot be created',
      total
      USING
        DETAIL = 'orphans by type: ' || detail,
        HINT = 'This is DATA, not schema: decide per row whether to revoke the grant (the product) or restore the resource, then re-run. This migration will not DELETE them for you.';
  END IF;
END $$;

-- ── THE REBUILD ───────────────────────────────────────────────────────────
-- Runs only while org_resource_grant is still a PLAIN table; once it is
-- partitioned the block returns at its first statement, which is what makes
-- this file re-runnable (the shape rail's idempotency arm reds a bare
-- rename-swap, correctly — a second apply of one would rename the wrong
-- table).
DO $$
DECLARE
  pair record;
  part text;
  i int;
  old_count bigint;
  new_count bigint;
  old_sum text;
  new_sum text;
  extra_cols text;
  had_rls boolean;
  had_force boolean;
  pol_names text[];
  pol_cmds text[];
  pol_roles text[];
  pol_quals text[];
  pol_checks text[];
  pol_kinds text[];
  grant_tos text[];
  grant_privs text[];
  targets text[];
  tgt text;
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relname = 'org_resource_grant'
       AND n.nspname = current_schema()
       AND c.relkind = 'p'
  ) THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relname = 'org_resource_grant'
       AND n.nspname = current_schema()
       AND c.relkind = 'r'
  ) THEN
    RAISE EXCEPTION
      'migration 0015 STOPPED: org_resource_grant is neither a plain table nor a partitioned one in schema %',
      current_schema()
      USING HINT = 'Restore the table from 0000_baseline before applying this migration.';
  END IF;

  -- 1. Capture everything a DROP TABLE would take with it.
  SELECT c.relrowsecurity, c.relforcerowsecurity INTO had_rls, had_force
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE c.relname = 'org_resource_grant' AND n.nspname = current_schema();

  SELECT coalesce(array_agg(policyname::text), '{}'),
         coalesce(array_agg(cmd::text), '{}'),
         -- Each role is quoted HERE, per element, so a deployment whose app
         -- role needs quoting (mixed case, a hyphen) survives the re-apply
         -- below instead of aborting the migration on a syntax error
         -- (review round 1, m-3). PUBLIC is a keyword and not an identifier,
         -- the same carve-out the GRANT loop makes; array_to_string(roles,
         -- ', ') interpolated the names raw.
         coalesce(array_agg((
           SELECT string_agg(CASE WHEN upper(r) = 'PUBLIC' THEN 'PUBLIC'
                                  ELSE quote_ident(r) END, ', ' ORDER BY o)
             FROM unnest(p.roles) WITH ORDINALITY AS u(r, o)
         )), '{}'),
         coalesce(array_agg(coalesce(qual, '')), '{}'),
         coalesce(array_agg(coalesce(with_check, '')), '{}'),
         coalesce(array_agg(CASE WHEN permissive = 'PERMISSIVE'
                                 THEN 'PERMISSIVE' ELSE 'RESTRICTIVE' END), '{}')
    INTO pol_names, pol_cmds, pol_roles, pol_quals, pol_checks, pol_kinds
    FROM pg_policies p
   WHERE p.schemaname = current_schema() AND p.tablename = 'org_resource_grant';

  -- EVERY privilege the catalog reports, not the four DML verbs only: a
  -- deployment that granted TRUNCATE, REFERENCES or TRIGGER on this table
  -- lost it across the rebuild with nothing said (review round 1, m-4).
  -- Every privilege_type information_schema reports for a table is a verb
  -- GRANT accepts, so the re-apply loop below needs no widening of its own.
  SELECT coalesce(array_agg(grantee), '{}'), coalesce(array_agg(privilege_type), '{}')
    INTO grant_tos, grant_privs
    FROM (
      SELECT DISTINCT grantee, privilege_type
        FROM information_schema.role_table_grants
       WHERE table_schema = current_schema()
         AND table_name = 'org_resource_grant'
         AND grantee <> current_user
    ) g;

  -- 2. The COLUMN CONTRACT, and then the row census.
  --
  --    The contract first, because the census depends on it: the CREATE
  --    TABLE below, the INSERT ... SELECT that fills it and BOTH halves of
  --    the census name the same HAND-WRITTEN list of nine columns. A column
  --    that exists on the live table but not in that list would be silently
  --    DROPPED by the rebuild AND the checksum would still match, because
  --    the census never reads it (review round 1, m-1) — the one thing a
  --    checksum exists not to be. So assert the source table's column SET
  --    and STOP, naming the columns this rebuild does not copy.
  SELECT string_agg(c, ', ' ORDER BY c) INTO extra_cols FROM (
    SELECT attname::text AS c
      FROM pg_attribute
     WHERE attrelid = 'org_resource_grant'::regclass
       AND attnum > 0 AND NOT attisdropped
    EXCEPT
    SELECT unnest(ARRAY['id','organization_id','membership_id','resource_type',
                        'resource_id','permission','granted_by','granted_at',
                        'expires_at'])
  ) x;
  IF extra_cols IS NOT NULL THEN
    RAISE EXCEPTION
      'migration 0015 STOPPED: org_resource_grant carries % column(s) this rebuild does not copy',
      cardinality(string_to_array(extra_cols, ', '))
      USING
        DETAIL = 'columns absent from the copy list: ' || extra_cols,
        HINT = 'A later migration added a column to this table. Add it to the CREATE TABLE, to the INSERT ... SELECT and to BOTH halves of the row census in this file before re-running — a checksum cannot see a column it never reads. Nothing has been dropped: this transaction rolls back.';
  END IF;

  --    The census: count plus an order-independent checksum over every
  --    column of every row. resource_id is lowercased on both
  --    sides because a uuid rendered back to text is canonical lowercase,
  --    while the old TEXT column could have held any spelling of the same
  --    uuid — the same value, not a lost row.
  SELECT count(*), coalesce(md5(string_agg(t.r, '' ORDER BY t.r)), '')
    INTO old_count, old_sum
    FROM (
      SELECT concat_ws('|', id, organization_id, membership_id, resource_type,
                       lower(resource_id::text), permission, granted_by,
                       granted_at, expires_at) AS r
        FROM org_resource_grant
    ) t;

  -- 3. The new parent. No primary key, no unique constraint and no indexes
  --    yet: those carry the FINAL index names, which are still taken by the
  --    table this one replaces (index names are unique per SCHEMA, unlike
  --    constraint names), so they are added after the swap.
  CREATE TABLE org_resource_grant_p4t7 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    resource_type text NOT NULL,
    resource_id uuid NOT NULL,
    permission text NOT NULL,
    granted_by uuid,
    granted_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp
  ) PARTITION BY LIST (resource_type);

  -- 4. One partition per instance resource type, each owning the FK that
  --    makes its resource_id mean something.
  -- The partition NAMES are spelled out rather than composed from the type,
  -- so that every object this file creates is greppable in the file — and in
  -- the packaged delta, where `schema-sentinels.packaging.guard` requires the
  -- delta to NAME each object a boot sentinel probes (it reds a delta that
  -- only builds the name at run time, correctly: an operator cannot search a
  -- string that does not exist).
  FOR pair IN
    SELECT * FROM (VALUES
      ('agents', 'agent', 'org_resource_grant_agents'),
      ('assistants', 'assistant', 'org_resource_grant_assistants'),
      ('knowledge', 'knowledge_base', 'org_resource_grant_knowledge'),
      ('mcp', 'mcp_server', 'org_resource_grant_mcp'),
      ('teams', 'team', 'org_resource_grant_teams'),
      ('workflows', 'workflow', 'org_resource_grant_workflows')
    ) AS t(resource_type, target_table, partition_name)
  LOOP
    part := pair.partition_name;
    EXECUTE format(
      'CREATE TABLE %I PARTITION OF org_resource_grant_p4t7 FOR VALUES IN (%L)',
      part, pair.resource_type);
    -- Validated on creation rather than NOT VALID + VALIDATE: the partition
    -- is EMPTY at this point, so there is nothing to scan, and pre-flight 3
    -- has already proved the rows about to arrive satisfy it.
    EXECUTE format(
      'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (resource_id) '
      'REFERENCES %I (id) ON DELETE CASCADE',
      part, part || '_resource_fk', pair.target_table);
  END LOOP;

  -- 5. Copy. The trigger is deliberately NOT on the new table yet: an
  --    AFTER INSERT ... FOR EACH ROW authz_gen_bump would bump every affected
  --    organization's authz_generation once per copied row, invalidating
  --    caches for a migration that changes no decision.
  INSERT INTO org_resource_grant_p4t7
    (id, organization_id, membership_id, resource_type, resource_id,
     permission, granted_by, granted_at, expires_at)
  SELECT id, organization_id, membership_id, resource_type, resource_id::uuid,
         permission, granted_by, granted_at, expires_at
    FROM org_resource_grant;

  SELECT count(*), coalesce(md5(string_agg(t.r, '' ORDER BY t.r)), '')
    INTO new_count, new_sum
    FROM (
      SELECT concat_ws('|', id, organization_id, membership_id, resource_type,
                       lower(resource_id::text), permission, granted_by,
                       granted_at, expires_at) AS r
        FROM org_resource_grant_p4t7
    ) t;

  IF old_count <> new_count OR old_sum <> new_sum THEN
    RAISE EXCEPTION
      'migration 0015 ABORTED: the partitioned copy does not match the source (% rows, checksum %) versus (% rows, checksum %)',
      old_count, old_sum, new_count, new_sum
      USING HINT = 'Nothing has been dropped — this transaction rolls back and org_resource_grant is untouched. Report this: a row-preserving copy that does not preserve rows is a defect in the migration, not in the data.';
  END IF;

  -- 6. The swap.
  DROP TABLE org_resource_grant;
  ALTER TABLE org_resource_grant_p4t7 RENAME TO org_resource_grant;

  -- 7. The constraints and indexes, with their final names now free. The
  --    primary key MUST contain the partition key (Postgres refuses a unique
  --    constraint that does not) — see the header's note on what that costs.
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_pkey PRIMARY KEY (id, resource_type);
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_unique
    UNIQUE (membership_id, resource_type, resource_id, permission);
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_organization_id_organization_id_fk
    FOREIGN KEY (organization_id) REFERENCES organization (id) ON DELETE CASCADE;
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_membership_id_organization_member_id_fk
    FOREIGN KEY (membership_id) REFERENCES organization_member (id) ON DELETE CASCADE;
  -- 0000_baseline's granted_by FK, which the DROP TABLE took with it and the
  -- first draft of this file never put back (review round 1, I-3). Without
  -- it, deleting the user who granted a permission leaves granted_by pointing
  -- at a row that no longer exists — the user-deletion dangling-reference
  -- class, re-opened by the migration that exists to close the resource half
  -- of it. schema.pg.ts declares it with onDelete "set null" and the packaged
  -- schema.sql ships it, so a database missing it disagrees with both.
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_granted_by_user_id_fk
    FOREIGN KEY (granted_by) REFERENCES "user" (id) ON DELETE SET NULL;
  -- 0010's composite tenancy FK, re-established on the PARENT: Postgres 17
  -- admits a foreign key on a partitioned table and clones it to every
  -- partition, so one declaration covers all six. Without it a grant tagged
  -- with one org for a membership in another is accepted again — the exact
  -- hole 0010 measured and closed.
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_member_org_fk
    FOREIGN KEY (organization_id, membership_id)
    REFERENCES organization_member (organization_id, id) ON DELETE CASCADE;
  -- 0012's catalog FK, re-established on the PARENT (journal order 0012 < 0015;
  -- merge repair 2026-09-17 — see the journaled file).
  ALTER TABLE org_resource_grant
    ADD CONSTRAINT org_resource_grant_permission_catalog_fk
    FOREIGN KEY (permission) REFERENCES permission_catalog (slug);

  CREATE INDEX org_resource_grant_membership_idx
    ON org_resource_grant (membership_id);
  CREATE INDEX org_resource_grant_resource_idx
    ON org_resource_grant (resource_type, resource_id);
  CREATE INDEX org_resource_grant_org_idx
    ON org_resource_grant (organization_id);
  CREATE INDEX org_resource_grant_expires_at_idx
    ON org_resource_grant (expires_at) WHERE expires_at IS NOT NULL;

  -- 8. 0007's authz-generation trigger. Created on the parent, which Postgres
  --    clones to every partition (and to any partition added later).
  CREATE TRIGGER authz_gen_bump
    AFTER INSERT OR UPDATE OR DELETE ON org_resource_grant
    FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

  -- 9. Privileges, policies and RLS posture, on the parent AND every
  --    partition. A partition addressed directly answers to its OWN policies,
  --    so forcing RLS on the parent alone would leave six unguarded doors.
  targets := ARRAY['org_resource_grant',
                   'org_resource_grant_agents',
                   'org_resource_grant_assistants',
                   'org_resource_grant_knowledge',
                   'org_resource_grant_mcp',
                   'org_resource_grant_teams',
                   'org_resource_grant_workflows'];

  FOREACH tgt IN ARRAY targets LOOP
    FOR i IN 1 .. coalesce(array_length(grant_tos, 1), 0) LOOP
      -- PUBLIC is a keyword, not an identifier: quoting it would grant to a
      -- role literally named "PUBLIC", which does not exist.
      EXECUTE format('GRANT %s ON %I TO %s',
                     grant_privs[i], tgt,
                     CASE WHEN upper(grant_tos[i]) = 'PUBLIC' THEN 'PUBLIC'
                          ELSE quote_ident(grant_tos[i]) END);
    END LOOP;

    IF had_rls THEN
      EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tgt);
    END IF;
    IF had_force THEN
      EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', tgt);
    END IF;

    FOR i IN 1 .. coalesce(array_length(pol_names, 1), 0) LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol_names[i], tgt);
      -- pol_roles[i] is ALREADY quoted, element by element, at capture time
      -- (m-3): quoting the joined string again here would name one role
      -- "role_a, role_b" instead of two.
      EXECUTE format('CREATE POLICY %I ON %I AS %s FOR %s TO %s%s%s',
                     pol_names[i], tgt, pol_kinds[i], pol_cmds[i],
                     pol_roles[i],
                     CASE WHEN pol_quals[i] <> ''
                          THEN format(' USING (%s)', pol_quals[i]) ELSE '' END,
                     CASE WHEN pol_checks[i] <> ''
                          THEN format(' WITH CHECK (%s)', pol_checks[i])
                          ELSE '' END);
    END LOOP;
  END LOOP;

  -- 10. A policy count that silently dropped to zero would be an isolation
  --     regression on a database where RLS is enabled, so prove it landed.
  IF coalesce(array_length(pol_names, 1), 0) > 0
     AND (SELECT count(*) FROM pg_policies
           WHERE schemaname = current_schema()
             AND tablename = 'org_resource_grant')
         <> coalesce(array_length(pol_names, 1), 0) THEN
    RAISE EXCEPTION
      'migration 0015 ABORTED: % policy/policies were captured from org_resource_grant but the rebuilt parent carries a different number',
      coalesce(array_length(pol_names, 1), 0)
      USING HINT = 'This transaction rolls back and the table is untouched. Re-apply rls/0022 after investigating.';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0016_virtual_system_roles_cleanup.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Virtual system roles: a system role's org_role_permission rows and a system
-- pack's org_permission_group_item rows become DELTAS, and the catalog
-- supplies the defaults at resolve time (plan §P4-T8). Statement-identical to
-- the journaled file; its operator header (WHY / what it must not touch / lock
-- posture) lives there. Applies on the rolling path: one additive column
-- (metadata-only), then deletes matched by EQUALITY against the catalog's own
-- 146 role defaults and 56 pack defaults, batched 200 organizations at a
-- time. It can REFUSE on live data in no way at all — every statement is a
-- guarded DDL or a predicate-matched DELETE — and every predicate is
-- idempotent, so a re-run changes nothing.

SET lock_timeout = '5s';

-- ── org_permission_group_item.denied ─────────────────────────────────────
-- The deny axis org_role_permission has carried since 0081, brought one table
-- over. It is what makes the DELETE below say what it means: a system pack's
-- default items are deleted because the catalog supplies them, and a row that
-- is a REFUSAL is a statement the catalog cannot supply. Without the column,
-- "absent" and "revoked by an administrator" are the same fact — the exact
-- ambiguity that kept ADR-0091's pack sweep add-only.
--
-- Additive, NOT NULL DEFAULT false, so every existing row keeps its meaning
-- and no writer changes: no product path writes true today (G11 locks a
-- system pack's contents in both directions at the service layer).
ALTER TABLE org_permission_group_item ADD COLUMN IF NOT EXISTS denied boolean NOT NULL DEFAULT false;

-- ── system_role_default: the 146 (role key, permission) pairs ensureSystemRoles used to write ──
DROP TABLE IF EXISTS pg_temp.system_role_default;
CREATE TEMP TABLE IF NOT EXISTS system_role_default (
  key text NOT NULL,
  permission text NOT NULL,
  PRIMARY KEY (key, permission)
) ON COMMIT DROP;
INSERT INTO system_role_default (key, permission) VALUES
  ('org-admin', 'members:view'),
  ('org-admin', 'members:invite'),
  ('org-admin', 'members:edit'),
  ('org-admin', 'members:remove'),
  ('org-admin', 'members:suspend'),
  ('org-admin', 'teams:view'),
  ('org-admin', 'teams:create'),
  ('org-admin', 'teams:edit'),
  ('org-admin', 'teams:delete'),
  ('org-admin', 'teams:manage_members'),
  ('org-admin', 'roles:view'),
  ('org-admin', 'roles:create'),
  ('org-admin', 'roles:edit'),
  ('org-admin', 'roles:delete'),
  ('org-admin', 'roles:assign'),
  ('org-admin', 'settings:view'),
  ('org-admin', 'settings:manage'),
  ('org-admin', 'billing:view'),
  ('org-admin', 'billing:manage'),
  ('org-admin', 'audit:view'),
  ('org-admin', 'recertification:view'),
  ('org-admin', 'recertification:manage'),
  ('org-admin', 'analytics:view'),
  ('org-admin', 'security:view'),
  ('org-admin', 'security:manage'),
  ('org-admin', 'storage:view'),
  ('org-admin', 'storage:manage'),
  ('org-admin', 'knowledge:view'),
  ('org-admin', 'knowledge:create'),
  ('org-admin', 'knowledge:edit'),
  ('org-admin', 'knowledge:delete'),
  ('org-admin', 'knowledge:transfer'),
  ('org-admin', 'knowledge:search'),
  ('org-admin', 'knowledge:publish'),
  ('org-admin', 'knowledge:admin'),
  ('org-admin', 'assistants:view'),
  ('org-admin', 'assistants:create'),
  ('org-admin', 'assistants:edit'),
  ('org-admin', 'assistants:delete'),
  ('org-admin', 'assistants:deploy'),
  ('org-admin', 'assistants:approve'),
  ('org-admin', 'assistants:disable'),
  ('org-admin', 'assistants:transfer'),
  ('org-admin', 'assistants:publish'),
  ('org-admin', 'agents:view'),
  ('org-admin', 'agents:create'),
  ('org-admin', 'agents:edit'),
  ('org-admin', 'agents:delete'),
  ('org-admin', 'agents:approve'),
  ('org-admin', 'agents:disable'),
  ('org-admin', 'agents:transfer'),
  ('org-admin', 'agents:publish'),
  ('org-admin', 'skills:view'),
  ('org-admin', 'skills:create'),
  ('org-admin', 'skills:approve'),
  ('org-admin', 'skills:certify'),
  ('org-admin', 'skills:disable'),
  ('org-admin', 'skills:manage'),
  ('org-admin', 'skills:execute'),
  ('org-admin', 'workflows:view'),
  ('org-admin', 'workflows:create'),
  ('org-admin', 'workflows:edit'),
  ('org-admin', 'workflows:delete'),
  ('org-admin', 'mcp:view'),
  ('org-admin', 'mcp:create'),
  ('org-admin', 'mcp:edit'),
  ('org-admin', 'mcp:delete'),
  ('org-admin', 'memory:view'),
  ('org-admin', 'memory:create'),
  ('org-admin', 'memory:edit'),
  ('org-admin', 'memory:delete'),
  ('org-admin', 'memory:share'),
  ('org-admin', 'marketplace:view'),
  ('org-admin', 'marketplace:moderate'),
  ('org-admin', 'models:view'),
  ('org-admin', 'models:manage'),
  ('org-admin', 'policies:view'),
  ('org-admin', 'policies:manage'),
  ('ai-admin', 'agents:delete'),
  ('ai-admin', 'agents:approve'),
  ('ai-admin', 'agents:disable'),
  ('ai-admin', 'agents:transfer'),
  ('ai-admin', 'agents:publish'),
  ('ai-admin', 'workflows:delete'),
  ('ai-admin', 'mcp:edit'),
  ('ai-admin', 'mcp:delete'),
  ('ai-admin', 'assistants:create'),
  ('ai-admin', 'assistants:edit'),
  ('ai-admin', 'assistants:delete'),
  ('ai-admin', 'assistants:deploy'),
  ('ai-admin', 'assistants:approve'),
  ('ai-admin', 'assistants:disable'),
  ('ai-admin', 'assistants:transfer'),
  ('ai-admin', 'assistants:publish'),
  ('ai-admin', 'skills:approve'),
  ('ai-admin', 'skills:disable'),
  ('ai-admin', 'skills:manage'),
  ('ai-admin', 'models:manage'),
  ('ai-admin', 'memory:create'),
  ('ai-admin', 'memory:edit'),
  ('ai-admin', 'memory:delete'),
  ('ai-admin', 'memory:share'),
  ('security-admin', 'security:manage'),
  ('security-admin', 'policies:manage'),
  ('security-admin', 'members:edit'),
  ('security-admin', 'members:suspend'),
  ('security-admin', 'recertification:view'),
  ('security-admin', 'recertification:manage'),
  ('security-admin', 'audit:view'),
  ('knowledge-admin', 'knowledge:create'),
  ('knowledge-admin', 'knowledge:edit'),
  ('knowledge-admin', 'knowledge:delete'),
  ('knowledge-admin', 'knowledge:transfer'),
  ('knowledge-admin', 'knowledge:admin'),
  ('knowledge-admin', 'knowledge:publish'),
  ('billing-admin', 'billing:manage'),
  ('billing-admin', 'analytics:view'),
  ('team-manager', 'teams:create'),
  ('team-manager', 'teams:edit'),
  ('team-manager', 'teams:manage_members'),
  ('team-manager', 'members:invite'),
  ('user', 'agents:create'),
  ('user', 'agents:edit'),
  ('user', 'skills:create'),
  ('user', 'workflows:create'),
  ('user', 'workflows:edit'),
  ('user', 'mcp:create'),
  ('user', 'memory:create'),
  ('user', 'memory:edit'),
  ('viewer', 'members:view'),
  ('viewer', 'teams:view'),
  ('viewer', 'roles:view'),
  ('viewer', 'settings:view'),
  ('viewer', 'billing:view'),
  ('viewer', 'security:view'),
  ('viewer', 'knowledge:view'),
  ('viewer', 'assistants:view'),
  ('viewer', 'agents:view'),
  ('viewer', 'skills:view'),
  ('viewer', 'workflows:view'),
  ('viewer', 'mcp:view'),
  ('viewer', 'memory:view'),
  ('viewer', 'marketplace:view'),
  ('viewer', 'models:view'),
  ('viewer', 'policies:view'),
  ('viewer', 'knowledge:search');

-- ── system_group_default: the 56 (pack key, permission) pairs ensureSystemGroups used to write ──
DROP TABLE IF EXISTS pg_temp.system_group_default;
CREATE TEMP TABLE IF NOT EXISTS system_group_default (
  key text NOT NULL,
  permission text NOT NULL,
  PRIMARY KEY (key, permission)
) ON COMMIT DROP;
INSERT INTO system_group_default (key, permission) VALUES
  ('read-only', 'members:view'),
  ('read-only', 'teams:view'),
  ('read-only', 'roles:view'),
  ('read-only', 'settings:view'),
  ('read-only', 'billing:view'),
  ('read-only', 'security:view'),
  ('read-only', 'knowledge:view'),
  ('read-only', 'assistants:view'),
  ('read-only', 'agents:view'),
  ('read-only', 'skills:view'),
  ('read-only', 'workflows:view'),
  ('read-only', 'mcp:view'),
  ('read-only', 'memory:view'),
  ('read-only', 'marketplace:view'),
  ('read-only', 'models:view'),
  ('read-only', 'policies:view'),
  ('ai-builder', 'agents:view'),
  ('ai-builder', 'agents:create'),
  ('ai-builder', 'agents:edit'),
  ('ai-builder', 'agents:delete'),
  ('ai-builder', 'agents:approve'),
  ('ai-builder', 'agents:disable'),
  ('ai-builder', 'agents:transfer'),
  ('ai-builder', 'agents:publish'),
  ('ai-builder', 'assistants:view'),
  ('ai-builder', 'assistants:create'),
  ('ai-builder', 'assistants:edit'),
  ('ai-builder', 'assistants:delete'),
  ('ai-builder', 'assistants:deploy'),
  ('ai-builder', 'assistants:approve'),
  ('ai-builder', 'assistants:disable'),
  ('ai-builder', 'assistants:transfer'),
  ('ai-builder', 'assistants:publish'),
  ('ai-builder', 'workflows:view'),
  ('ai-builder', 'workflows:create'),
  ('ai-builder', 'workflows:edit'),
  ('ai-builder', 'workflows:delete'),
  ('ai-builder', 'mcp:view'),
  ('ai-builder', 'mcp:create'),
  ('ai-builder', 'mcp:edit'),
  ('ai-builder', 'mcp:delete'),
  ('ai-builder', 'knowledge:view'),
  ('ai-builder', 'knowledge:create'),
  ('ai-builder', 'knowledge:edit'),
  ('ai-builder', 'knowledge:search'),
  ('ai-builder', 'models:view'),
  ('people-manager', 'members:view'),
  ('people-manager', 'members:invite'),
  ('people-manager', 'members:edit'),
  ('people-manager', 'members:remove'),
  ('people-manager', 'members:suspend'),
  ('people-manager', 'teams:view'),
  ('people-manager', 'teams:create'),
  ('people-manager', 'teams:edit'),
  ('people-manager', 'teams:delete'),
  ('people-manager', 'teams:manage_members');

-- ── The cleanup, batched by organization ──────────────────────────────────
-- Batched to bound WHAT ONE STATEMENT DOES — not how long a lock is held.
-- The hold is the whole file: it carries no drizzle breakpoint marker, so
-- both paths send it as ONE transaction and every row lock any chunk takes is
-- held to COMMIT. The header's LOCK POSTURE is therefore the number to size a
-- maintenance window from, and batching does not shorten it (review round 1,
-- m-3: this comment used to claim it did).
--
-- What the batching does buy is per-STATEMENT: each DELETE has to WIN its
-- locks over 200 organizations' rows inside lock_timeout = '5s' rather than
-- over every organization at once, so a chunk that meets a live writer fails
-- fast and loudly instead of the whole fleet's worth of rows queueing behind
-- one acquisition; the working set and WAL of a single statement stay bounded
-- on a large fleet; and the walk's progress is observable. 200 organizations
-- per chunk, walked by organization.id (a uuid, so the walk is index-ordered
-- and resumable), with the two deletes and the empty-pack sweep for that
-- chunk issued together.
--
-- The cursor advances by reading the LAST element of the chunk rather than
-- with max(): Postgres has no max(uuid) aggregate (42883, measured on 17.10),
-- and array_agg carries its own ORDER BY so the last element is the greatest
-- id in the chunk by construction rather than by luck. It starts NULL rather
-- than at the all-zero uuid (review round 1, n-4): a strict id > sentinel
-- would never visit an organization whose id IS the all-zero uuid, which
-- gen_random_uuid() cannot mint but a hand-written fixture row can.
--
-- EVERY PREDICATE IS IDEMPOTENT. A second apply matches nothing: the rows it
-- would delete are gone, the packs it would drop are dropped, and a
-- partially-applied file completes on re-run rather than needing repair. The
-- counts are RAISE NOTICEd so an operator sees what the file did.
DO $$
DECLARE
  chunk uuid[];
  cursor_id uuid := NULL;
  removed_permissions bigint := 0;
  removed_items bigint := 0;
  dropped_packs bigint := 0;
  n bigint;
BEGIN
  LOOP
    SELECT array_agg(o.id ORDER BY o.id) INTO chunk
      FROM (
        SELECT id FROM organization
         WHERE cursor_id IS NULL OR id > cursor_id
         ORDER BY id
         LIMIT 200
      ) o;
    EXIT WHEN chunk IS NULL;
    cursor_id := chunk[array_length(chunk, 1)];

    -- A system ROLE's declared defaults. `denied = false` is the whole
    -- safety property: a refusal (ADR-0083) lives in this table beside a
    -- grant, distinguished only by the flag, and it is an administrator's
    -- statement that the catalog cannot supply — so it stays.
    WITH deleted AS (
      DELETE FROM org_role_permission orp
       USING org_role r, system_role_default d
       WHERE orp.role_id = r.id
         AND r.organization_id = ANY(chunk)
         AND r.is_system
         AND r.key = d.key
         AND orp.permission = d.permission
         AND orp.denied = false
      RETURNING 1
    ) SELECT count(*) INTO n FROM deleted;
    removed_permissions := removed_permissions + n;

    -- A system PACK's declared defaults, on the column migration 0016 adds
    -- above so that "absent" and "refused" can be told apart here at all.
    WITH deleted AS (
      DELETE FROM org_permission_group_item i
       USING org_permission_group g, system_group_default d
       WHERE i.group_id = g.id
         AND g.organization_id = ANY(chunk)
         AND g.is_system
         AND g.key = d.key
         AND i.permission = d.permission
         AND i.denied = false
      RETURNING 1
    ) SELECT count(*) INTO n FROM deleted;
    removed_items := removed_items + n;

    -- A system pack that is now EMPTY and UNREFERENCED is deleted: its
    -- contents come from SYSTEM_PERMISSION_GROUPS and `ensureSystemGroups`
    -- re-creates the identity row on the next groups-panel load. Both
    -- conditions are required — a pack still holding an administrator's extra
    -- item keeps its rows, and a pack ATTACHED to a role is a reference an
    -- admin made, so dropping it would silently detach the pack.
    WITH deleted AS (
      DELETE FROM org_permission_group g
       WHERE g.organization_id = ANY(chunk)
         AND g.is_system
         AND g.key IN (SELECT DISTINCT key FROM system_group_default)
         AND NOT EXISTS (
           SELECT 1 FROM org_permission_group_item i WHERE i.group_id = g.id
         )
         AND NOT EXISTS (
           SELECT 1 FROM org_role_permission_group j WHERE j.group_id = g.id
         )
      RETURNING 1
    ) SELECT count(*) INTO n FROM deleted;
    dropped_packs := dropped_packs + n;
  END LOOP;

  RAISE NOTICE 'migration 0016: deleted % org_role_permission row(s), % org_permission_group_item row(s), and % empty unreferenced system pack(s)',
    removed_permissions, removed_items, dropped_packs;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0017_authz_rls_journaled.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0017 — the authorization substrate's row-level security, journaled, and the
-- three RBAC junctions made STRICT-ORG. FORWARD-ONLY: the reverse of a policy
-- is the runbook's own per-table `ALTER TABLE <t> NO FORCE ROW LEVEL
-- SECURITY`, and dropping the three organization_id columns would take the
-- composite tenancy foreign keys with them. See the source migration for the
-- full rationale.
--
-- WHAT THIS PACKAGED BLOCK CARRIES, AND WHAT IT DELIBERATELY DOES NOT. The
-- source migration has two halves: the COLUMNS, indexes and constraints that
-- make the junctions strict-org, and a mirror of `src/lib/db/rls/*.sql` that
-- gives the whole substrate its policies on a `db:migrate` database. Only the
-- first half is here. No artifact in this packaged lineage delivers row-level
-- security — `schema.sql` is a pg_dump, which dumps no policies, and no
-- packaged delta has ever enabled RLS on any table — and the compliance
-- register's CC6.1 control DISCLOSES that to the operator, measured against
-- these very files by `compliance-register-ledger.guard.test.ts`. Shipping one
-- policy here would make that disclosure false. So a VM gets the policies the
-- way it always has: `docs/runbooks/production-rls-enablement.md`, which now
-- also applies `rls/0024_team_member.sql` and
-- `rls/0025_authz_junction_strict_org.sql`. The same ruling was applied to
-- 0013's org_member_deny policy in its own fix round.
--
-- LOCK POSTURE: lib.sh applies this file with `psql -1`, so the whole delta is
-- one transaction. The costly statements are the three
-- `ALTER COLUMN … SET NOT NULL`, each scanning its table under ACCESS
-- EXCLUSIVE — the permission-matrix junctions, so (roles × granted slugs) per
-- tenant — and the seven VALIDATEs: FOUR composite FKs
-- (org_role_permission_group has two legs) and THREE single-column ones. A
-- VALIDATE takes only SHARE UPDATE EXCLUSIVE on its own, and that buys nothing
-- in one transaction: every `ADD CONSTRAINT` above has already taken ACCESS
-- EXCLUSIVE on the same table and HOLDS IT TO COMMIT, so nothing runs beside
-- these VALIDATEs. The split's value is the proof that no existing row
-- violates a constraint before it binds, not a lock reduction — 0010's block
-- header states the same for the identical shape. Time the WHOLE delta.

SET lock_timeout = '5s';

-- The FK TARGET org_permission_group never needed: a composite FOREIGN KEY
-- requires a UNIQUE constraint on exactly the referenced columns (org_role
-- gained its equivalent in 0010).
CREATE UNIQUE INDEX IF NOT EXISTS org_permission_group_org_id_unique
  ON org_permission_group (organization_id, id);

ALTER TABLE org_role_permission ADD COLUMN IF NOT EXISTS organization_id uuid;
UPDATE org_role_permission rp
   SET organization_id = r.organization_id
  FROM org_role r
 WHERE r.id = rp.role_id
   AND rp.organization_id IS DISTINCT FROM r.organization_id;

ALTER TABLE org_permission_group_item ADD COLUMN IF NOT EXISTS organization_id uuid;
UPDATE org_permission_group_item gi
   SET organization_id = g.organization_id
  FROM org_permission_group g
 WHERE g.id = gi.group_id
   AND gi.organization_id IS DISTINCT FROM g.organization_id;

ALTER TABLE org_role_permission_group ADD COLUMN IF NOT EXISTS organization_id uuid;
UPDATE org_role_permission_group rg
   SET organization_id = r.organization_id
  FROM org_role r
 WHERE r.id = rg.role_id
   AND rg.organization_id IS DISTINCT FROM r.organization_id;

-- 0017 PRE-FLIGHT 1: every junction row has a parent (each already carried a
-- single-column FK to one), so the backfills are total by construction — but a
-- NULL left behind would surface as a bare "column contains null values" from
-- the next statement with no row named. This RAISEs with the count and the
-- first offending row instead, and rolls the whole delta back.
DO $$
DECLARE offender record; n bigint;
BEGIN
  SELECT count(*) INTO n FROM org_role_permission WHERE organization_id IS NULL;
  IF n > 0 THEN
    SELECT role_id, permission INTO offender
      FROM org_role_permission WHERE organization_id IS NULL LIMIT 1;
    RAISE EXCEPTION
      '0017: % org_role_permission row(s) have no parent role to take an organization from (first: role_id=%, permission=%)',
      n, offender.role_id, offender.permission;
  END IF;
  SELECT count(*) INTO n FROM org_permission_group_item WHERE organization_id IS NULL;
  IF n > 0 THEN
    SELECT group_id, permission INTO offender
      FROM org_permission_group_item WHERE organization_id IS NULL LIMIT 1;
    RAISE EXCEPTION
      '0017: % org_permission_group_item row(s) have no parent group to take an organization from (first: group_id=%, permission=%)',
      n, offender.group_id, offender.permission;
  END IF;
  SELECT count(*) INTO n FROM org_role_permission_group WHERE organization_id IS NULL;
  IF n > 0 THEN
    SELECT role_id, group_id INTO offender
      FROM org_role_permission_group WHERE organization_id IS NULL LIMIT 1;
    RAISE EXCEPTION
      '0017: % org_role_permission_group row(s) have no parent role to take an organization from (first: role_id=%, group_id=%)',
      n, offender.role_id, offender.group_id;
  END IF;
END $$;

-- ── 0017 PRE-FLIGHT 2: a junction row whose two parents are in DIFFERENT orgs
-- `org_role_permission_group` is the ONE junction with two parents, and the
-- backfill above takes its organization from the ROLE. A row attaching org A's
-- role to org B's permission pack — a state the two single-column references
-- admitted between them and nothing in the database refused until this file —
-- therefore gets org A, and `org_role_permission_group_group_org_fk` cannot
-- validate. Left to the constraint, that failure arrives from a VALIDATE near
-- the END of the file: after the three SET NOT NULL table scans and four other
-- constraints have already bound, and phrased as a key pair rather than as the
-- product state that caused it. So: name the offending rows and STOP — the
-- posture 0010's own pre-flight takes for its duplicate-request class. The
-- remediation is in the PRODUCT; a migration never DELETEs a tenant's rows to
-- make itself pass.
DO $$
DECLARE
  n bigint;
  sample text;
BEGIN
  SELECT count(*) INTO n
    FROM org_role_permission_group rg
    JOIN org_role r ON r.id = rg.role_id
    JOIN org_permission_group g ON g.id = rg.group_id
   WHERE r.organization_id <> g.organization_id;
  IF n > 0 THEN
    SELECT string_agg(k, ' | ' ORDER BY k) INTO sample FROM (
      SELECT format('(role=%s org=%s -> group=%s org=%s)',
                    rg.role_id, r.organization_id,
                    rg.group_id, g.organization_id) AS k
        FROM org_role_permission_group rg
        JOIN org_role r ON r.id = rg.role_id
        JOIN org_permission_group g ON g.id = rg.group_id
       WHERE r.organization_id <> g.organization_id
       LIMIT 5
    ) s;
    RAISE EXCEPTION
      'migration 0017 STOPPED: % org_role_permission_group row(s) attach a role and a permission pack from DIFFERENT organizations, so org_role_permission_group_group_org_fk cannot validate',
      n
      USING
        DETAIL = 'first offending rows: ' || sample,
        HINT = 'Detach the foreign pack from the role in the product, then re-run. This migration will not DELETE a tenant''s rows.';
  END IF;
END $$;

ALTER TABLE org_role_permission ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE org_permission_group_item ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE org_role_permission_group ALTER COLUMN organization_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS org_role_permission_org_idx
  ON org_role_permission (organization_id);
CREATE INDEX IF NOT EXISTS org_permission_group_item_org_idx
  ON org_permission_group_item (organization_id);
CREATE INDEX IF NOT EXISTS org_role_permission_group_org_idx
  ON org_role_permission_group (organization_id);

-- The single-column tenant references, named as drizzle-kit derives them from
-- schema.pg.ts so `db:push` against a dev database diffs to nothing.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_organization_id_organization_id_fk'
      AND conrelid = 'org_role_permission'::regclass) THEN
    ALTER TABLE org_role_permission
      ADD CONSTRAINT org_role_permission_organization_id_organization_id_fk
      FOREIGN KEY (organization_id) REFERENCES organization (id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_organization_id_organization_id_fk'
      AND conrelid = 'org_role_permission'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_role_permission
      VALIDATE CONSTRAINT org_role_permission_organization_id_organization_id_fk;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_permission_group_item_organization_id_organization_id_fk'
      AND conrelid = 'org_permission_group_item'::regclass) THEN
    ALTER TABLE org_permission_group_item
      ADD CONSTRAINT org_permission_group_item_organization_id_organization_id_fk
      FOREIGN KEY (organization_id) REFERENCES organization (id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_permission_group_item_organization_id_organization_id_fk'
      AND conrelid = 'org_permission_group_item'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_permission_group_item
      VALIDATE CONSTRAINT org_permission_group_item_organization_id_organization_id_fk;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_group_organization_id_organization_id_fk'
      AND conrelid = 'org_role_permission_group'::regclass) THEN
    ALTER TABLE org_role_permission_group
      ADD CONSTRAINT org_role_permission_group_organization_id_organization_id_fk
      FOREIGN KEY (organization_id) REFERENCES organization (id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_group_organization_id_organization_id_fk'
      AND conrelid = 'org_role_permission_group'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_role_permission_group
      VALIDATE CONSTRAINT org_role_permission_group_organization_id_organization_id_fk;
  END IF;
END $$;

-- The COMPOSITE tenancy foreign keys (0010's house style): organization_id and
-- the parent id were checked INDEPENDENTLY, so a permission row tagged org A
-- against a role in org B was accepted and invisible to the owning org.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_role_org_fk'
      AND conrelid = 'org_role_permission'::regclass) THEN
    ALTER TABLE org_role_permission ADD CONSTRAINT org_role_permission_role_org_fk
      FOREIGN KEY (organization_id, role_id)
      REFERENCES org_role (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_role_org_fk'
      AND conrelid = 'org_role_permission'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_role_permission VALIDATE CONSTRAINT org_role_permission_role_org_fk;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_permission_group_item_group_org_fk'
      AND conrelid = 'org_permission_group_item'::regclass) THEN
    ALTER TABLE org_permission_group_item ADD CONSTRAINT org_permission_group_item_group_org_fk
      FOREIGN KEY (organization_id, group_id)
      REFERENCES org_permission_group (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_permission_group_item_group_org_fk'
      AND conrelid = 'org_permission_group_item'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_permission_group_item VALIDATE CONSTRAINT org_permission_group_item_group_org_fk;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_group_role_org_fk'
      AND conrelid = 'org_role_permission_group'::regclass) THEN
    ALTER TABLE org_role_permission_group ADD CONSTRAINT org_role_permission_group_role_org_fk
      FOREIGN KEY (organization_id, role_id)
      REFERENCES org_role (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_group_role_org_fk'
      AND conrelid = 'org_role_permission_group'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_role_permission_group VALIDATE CONSTRAINT org_role_permission_group_role_org_fk;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_group_group_org_fk'
      AND conrelid = 'org_role_permission_group'::regclass) THEN
    ALTER TABLE org_role_permission_group ADD CONSTRAINT org_role_permission_group_group_org_fk
      FOREIGN KEY (organization_id, group_id)
      REFERENCES org_permission_group (organization_id, id) ON DELETE CASCADE NOT VALID;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'org_role_permission_group_group_org_fk'
      AND conrelid = 'org_role_permission_group'::regclass AND NOT convalidated) THEN
    ALTER TABLE org_role_permission_group VALIDATE CONSTRAINT org_role_permission_group_group_org_fk;
  END IF;
END $$;
