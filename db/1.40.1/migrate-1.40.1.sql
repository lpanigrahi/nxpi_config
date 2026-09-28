-- migrate-1.40.1.sql — data PATCH 1.40.0 → 1.40.1 (R14 QA campaign, plane P14 week 4, finding NF3): an installation that came up on any bundle from 1.22.0 through 1.39.0 holds an EMPTY permission_catalog and no platform sod_rule, and no delta had ever healed it. This file carries those two journaled DATA migrations' own statements (0012_permission_catalog, 0023_sod_rule) so ./update.sh repairs the installation it upgrades.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
-- A PATCH version, not a minor one, and that is a REACH decision rather than a
-- cosmetic one: `assert_version_alignment` ties DB_VERSION to the APP_IMAGE tag,
-- so a bundle named 1.41.0 could not be applied until a minor app release was
-- published, and every 1.22.0–1.39.0 deployment would stay broken until it
-- accepted a feature release. 1.40.1 pairs with a no-code 1.40.1 patch image —
-- the release class an operator accepts for a repair. This file changes no
-- schema and no behaviour; it repairs data db/1.40.0's own seed.sql already
-- declares correct.
--
-- WHAT WENT WRONG, IN ONE PARAGRAPH.
--
-- `install.sh`'s FRESH path applies `schema.sql`, then STAMPS the migration
-- journal (`stamp_migrations_through`) instead of running it, then applies
-- `seed.sql`. Stamping means a journaled migration whose payload is DATA — not
-- DDL — never executes on a fresh install, so its rows exist only if
-- `seed.sql` carries them. Two such migrations exist: 0012 seeds the 78-slug
-- `permission_catalog`, the vocabulary every role grant is a foreign key into,
-- and 0023 seeds the four platform `sod_rule` separation-of-duties defaults.
-- Every bundle from 1.22.0 (the first to carry 0012's TABLE in schema.sql)
-- through 1.39.0 carried NEITHER set of rows, because `seed.sql` has been
-- carried forward from an older bundle rather than re-dumped. db/1.40.0 is the
-- first bundle whose `seed.sql` carries them, which fixes every FUTURE install
-- and nothing that is already installed: `apply_migrations` applies each
-- unapplied `migrate-*.sql` and re-applies `grants.sql`, and never re-applies
-- `seed.sql` — a seed is the fresh path's file. Measured on a db/1.39.0 install
-- taken to db/1.40.0 exactly the way ./update.sh takes it: the schema converges
-- on every counter (policies 29 → 35, restrictive 0 → 6, 445 foreign keys, 772
-- constraints) and `permission_catalog` is still 0, `sod_rule` still 0, and the
-- seed's own 286 `org_role_permission` + 118 `org_permission_group_item` rows
-- still reference a vocabulary that is not there.
--
-- WHAT THAT COSTS A RUNNING DEPLOYMENT. The RBAC matrix renders empty (every
-- grant joins to nothing); the first permission an organization admin toggles
-- fails with
--
--     ERROR: insert or update on table "org_role_permission" violates foreign
--            key constraint "org_role_permission_permission_catalog_fk"
--     DETAIL: Key (permission)=(knowledge:view) is not present in table
--             "permission_catalog".
--
-- and no maker/checker separation is enforced in any tenant, silently: the SoD
-- loader's documented fallback answers with its compiled-in constants when it
-- finds no platform rows, so an unseeded table reads exactly like a deliberate
-- configuration. The 404 dangling rows loaded at install only because
-- `seed.sql` opens with `SET session_replication_role = replica`, which defers
-- every foreign-key check for the whole file.
--
-- WHAT MOVES. Rows, and only rows. No table, column, index, constraint,
-- policy, trigger or function is created, altered or dropped by this file.
--
--   * `permission_catalog` — 78 rows, 0012's own statement, `ON CONFLICT (slug)
--     DO UPDATE` (the upsert keeps a re-run a no-op and lets a later catalog
--     version re-stage a slug in place; `since_version` takes the EARLIEST of
--     the two, and `retired_version`/`replaced_by` are never touched here).
--   * `sod_rule` — the 4 PLATFORM rows (`organization_id IS NULL`), 0023's own
--     statement, `ON CONFLICT (organization_id, name) DO NOTHING`. An
--     organization's own SoD rules are never read or written by this file.
--
-- Both statements are carried VERBATIM from the journaled migrations, rendered
-- by `scripts/packaging/render-seed-data-migrations.ts` — the same derivation
-- that produced the block in db/1.40.0/seed.sql, so the two paths install the
-- same rows by construction rather than by review.
--
-- RE-RUNNABLE, AND HARMLESS ON A HEALTHY DATABASE. Every statement is an
-- upsert. On an installation that already has the rows — one that rolled
-- forward from a bundle older than 1.22.0, or a fresh install of db/1.40.0 or
-- later — this file writes the values it finds and changes nothing. On one
-- whose catalog is empty it fills it and the 404 dangling rows above start
-- joining. Applying it twice, or by hand after a partial failure, lands the
-- same rows.
--
-- WHO COULD NOTICE. A deployment that has DELIBERATELY removed catalog slugs
-- gets them back (there is no product path that deletes them: the catalog is
-- platform reference data, the application only ever reads it, and its writers
-- are these two migrations). Nothing else: no enforcement changes, no lock is
-- held beyond the row writes on two small reference tables, and an old
-- container still serving during a rolling update reads the same catalog plus
-- whatever rows it was missing.
--
-- NOT A DESTRUCTIVE DELTA and deliberately NOT marked REQUIRES-REVIEW. Two
-- reasons, and the second is decisive: nothing is dropped, narrowed or
-- rewritten from existing state; and `update.sh` REFUSES a flagged delta on
-- the rolling path (`has_pending_destructive`), so flagging this one would keep
-- the heal away from precisely the installations it exists to repair until an
-- operator opted into a maintenance window they have no way to know they need.
--
-- VERIFY (read-only, after applying):
--     SELECT count(*) FROM permission_catalog;                        -- 78
--     SELECT count(*) FROM sod_rule WHERE organization_id IS NULL;    -- 4
--     SELECT count(*) FROM org_role_permission o
--       WHERE NOT EXISTS (SELECT 1 FROM permission_catalog c
--                          WHERE c.slug = o.permission);              -- 0
--     -- and, with the source tree, `pnpm db:preflight` — its
--     -- 0012-catalog-unseeded and 0023-sod-rule-unseeded gates are the two
--     -- that refused before this file ran.
--
-- ROLLBACK: there is nothing to roll back that is safe to roll back, and that
-- is the honest posture rather than an omission. DELETE-ing the 78 catalog rows
-- would break every `org_role_permission` row that references them (the same
-- 23503 above, from the other side) and DELETE-ing the four platform SoD rows
-- would return the deployment to inheriting the loader's compiled-in defaults.
-- If a row must go, retire it in the product's own vocabulary
-- (`retired_version` / `replaced_by`) rather than by deleting it here. Nothing
-- in the SCHEMA changed, so the rollback of a failed application is the
-- transaction's own: apply with psql -1 (ON_ERROR_STOP), which ./update.sh
-- does, and the file lands whole or not at all.

SET lock_timeout = '5s';

-- The statements below name their tables UNQUALIFIED, exactly as the journaled
-- migrations wrote them. ./update.sh runs each delta as its own `psql -1`, whose
-- search_path is the default and resolves them — this line is here so the file
-- is also correct when an operator applies it by hand in a session a pg_dump
-- (`set_config('search_path', '', false)`) has already zeroed, which is the
-- session an operator who has just run seed.sql is sitting in.
SET search_path = public;

-- 0012_permission_catalog (permission_catalog, 9 columns)
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

-- 0023_sod_rule (sod_rule, 5 columns)
INSERT INTO sod_rule (organization_id, name, toxic_set, mode, reason)
VALUES
  (NULL, 'agents-maker-checker', ARRAY['agents:create','agents:approve']::text[], 'inherit', 'An agent author who can approve agents reviews their own work — the approval gate stops gating.'),
  (NULL, 'assistants-maker-checker', ARRAY['assistants:create','assistants:approve']::text[], 'inherit', 'An assistant author who can approve assistants reviews their own work.'),
  (NULL, 'skills-maker-checker', ARRAY['skills:create','skills:approve']::text[], 'inherit', 'A skill author who can approve skills reviews their own work.'),
  (NULL, 'provisioning-spend', ARRAY['members:invite','billing:manage']::text[], 'inherit', 'Provisioning users AND controlling billing concentrates spend authority in one member (the HR/finance separation).')
ON CONFLICT (organization_id, name) DO NOTHING;

