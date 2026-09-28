-- migrate-1.29.0.sql — schema delta 1.28.0 → 1.29.0 (deep-test campaign DT-H, finding DT-1-v-1): the row security the journaled series has always carried, for the lineage that never had it.
-- REQUIRES-REVIEW: this delta ENFORCES row-level security on 26
-- tables that were unprotected on this lineage. Nothing is dropped and no
-- column changes, but every read and write the APPLICATION role makes against
-- them starts answering to `app.current_org_id` the moment it lands — so it
-- must not ride update.sh's rolling path, whose auto-rollback assumes the
-- previously-running image stays compatible with the schema.
--
-- AND THE PRIVILEGED POOL ANSWERS TO THESE POLICIES TOO — decide this in the
-- same window. This bundle mints ONE database secret (postgres_url, the
-- least-privilege neo_gen role, which has neither SUPERUSER nor BYPASSRLS),
-- and the application falls back to POSTGRES_URL when POSTGRES_PRIVILEGED_URL
-- is unset — which it is on every deployment this package has produced. So
-- from the moment this delta commits, every background cross-tenant pass that
-- uses the privileged pool (the expired role-assignment / resource-grant
-- sweep, the knowledge-document and vector-store GC) matches ZERO rows,
-- SILENTLY: DB_PRIVILEGED_PREFLIGHT_MODE defaults to `warn`, so boot is
-- unchanged and the only signal is a start-up warning in the app log. That is
-- housekeeping and observability, not privilege persistence — every read
-- filters expiry at query time, so an unswept expired row still grants
-- nothing. Either provision a role that can bypass (as neogen_admin inside
-- the postgres container: CREATE ROLE neogen_priv LOGIN BYPASSRLS IN ROLE
-- neo_gen PASSWORD '…'; then mint a postgres_privileged_url secret and set
-- POSTGRES_PRIVILEGED_URL_FILE on the app service — secrets-entrypoint.sh
-- bridges any *_FILE), or accept the stopped sweeps as a known limit and
-- record that decision. See azure-deployment/README.md, the 1.29.0 section.
-- rollback: per statement class. The POLICIES and the RLS posture are
-- reversible in three statements per table (DROP POLICY IF EXISTS
-- tenant_isolation ON <t>; ALTER TABLE <t> NO FORCE ROW LEVEL SECURITY;
-- ALTER TABLE <t> DISABLE ROW LEVEL SECURITY;) and reversing them restores
-- exactly the posture this delta finds: tenant data with no second net. The
-- TRIGGERS and FUNCTIONS are reversible in one statement each (DROP TRIGGER
-- IF EXISTS <n> ON <t>; DROP FUNCTION IF EXISTS <f>();) — and `authz_gen_bump`
-- is what keeps the authorization cache honest, so dropping it serves stale
-- decisions rather than failing loudly. Nothing here is forward-only.
-- Route: ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh   then   ./update.sh
--
-- THE POSTURE THIS INHERITS. 1.26.0 is already flagged REQUIRES-REVIEW (0020
-- made audit_chain_head.chain_key NOT NULL and the previous image's head
-- upsert sends none), so every VM that can reach 1.29.0 has already taken
-- the maintenance path once and is NOT running a pre-programme image. That is
-- the premise this delta needs: the image serving beside it sets the tenant
-- GUC on every request (lib/db/tenant-context.ts), which is what makes the
-- policies below invisible to correct traffic. An image older than 1.26.0
-- cannot be rolled back onto this schema in any case — see DT-1-v-2 and
-- DT-1-v-3 in the campaign's rollback rehearsal.
--
-- WHAT WENT WRONG, stated so the next bundle does not repeat it. Row security
-- on this tree was applied by an app-tree runner (src/lib/db/rls/*.sql) that a
-- sourceless VM has no way to run, and this README said so as though it were a
-- design: "RLS lives in the app-tree runner, not this package". Migrations
-- 0003, 0013, 0017, 0018, 0022 and 0023 journaled the policies for everyone
-- else; no packaged delta ever carried them, and each schema.sql is derived
-- from the previous package, so the absence propagated release by release.
-- Measured on FRESH databases at 1.28.0: the migrator gives 26 RLS tables /
-- 26 policies, db/1.28.0/schema.sql gives 2 / 0.
--
-- GENERATED — do not edit by hand. `pnpm gen:packaged-rls` renders this file
-- from the journaled migrations under src/lib/db/migrations/pg/ (the first
-- packaged one onward), and
-- src/lib/db/migrations/pg/packaged-rls-delta.parity.test.ts re-renders on
-- every run and byte-compares. The statements below are those migrations' own,
-- in journal order, re-spelled idempotently (DROP … IF EXISTS before each
-- CREATE) because a packaged delta is re-run by hand on a VM after a partial
-- failure.
--
-- DERIVED COUNTS: 99 statements from 10 migrations — 26 tables ENABLEd,
-- 26 FORCEd, 26 policies, 13 triggers, 4 functions.
--
-- LOCK POSTURE for the operator sizing this: every statement is a catalog
-- write. ALTER TABLE … ENABLE/FORCE ROW LEVEL SECURITY and CREATE POLICY each
-- take ACCESS EXCLUSIVE on their table for the moment of that write — no table
-- is scanned and no row is rewritten, so the cost is the WAIT for the lock,
-- not the work. CREATE TRIGGER takes the same lock on its table; CREATE OR
-- REPLACE FUNCTION takes none. SET lock_timeout bounds lock ACQUISITION, not
-- the hold: under a long-running reader this delta fails in five seconds
-- rather than queueing every later reader behind it, and is safe to re-run.
SET lock_timeout = '5s';

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0003_tenant_hardening_retrofit.sql
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE knowledge_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE knowledge_embeddings ENABLE ROW LEVEL SECURITY;

ALTER TABLE knowledge_metadata ENABLE ROW LEVEL SECURITY;

ALTER TABLE knowledge_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE knowledge_audit_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE ingestion_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE embedding_config ENABLE ROW LEVEL SECURITY;

ALTER TABLE knowledge_documents FORCE ROW LEVEL SECURITY;

ALTER TABLE knowledge_embeddings FORCE ROW LEVEL SECURITY;

ALTER TABLE knowledge_metadata FORCE ROW LEVEL SECURITY;

ALTER TABLE knowledge_versions FORCE ROW LEVEL SECURITY;

ALTER TABLE knowledge_audit_logs FORCE ROW LEVEL SECURITY;

ALTER TABLE ingestion_jobs FORCE ROW LEVEL SECURITY;

ALTER TABLE embedding_config FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON knowledge_documents;
CREATE POLICY tenant_isolation ON knowledge_documents USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

DROP POLICY IF EXISTS tenant_isolation ON knowledge_embeddings;
CREATE POLICY tenant_isolation ON knowledge_embeddings USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

DROP POLICY IF EXISTS tenant_isolation ON knowledge_metadata;
CREATE POLICY tenant_isolation ON knowledge_metadata USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

DROP POLICY IF EXISTS tenant_isolation ON knowledge_versions;
CREATE POLICY tenant_isolation ON knowledge_versions USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

DROP POLICY IF EXISTS tenant_isolation ON knowledge_audit_logs;
CREATE POLICY tenant_isolation ON knowledge_audit_logs USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

DROP POLICY IF EXISTS tenant_isolation ON ingestion_jobs;
CREATE POLICY tenant_isolation ON ingestion_jobs USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

DROP POLICY IF EXISTS tenant_isolation ON embedding_config;
CREATE POLICY tenant_isolation ON embedding_config USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)) WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid OR (organization_id IS NULL AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid));

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0007_authz_generation_and_key_platform_scopes.sql
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION authz_bump_generation() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE org uuid;
BEGIN
  org := COALESCE(NEW.organization_id, OLD.organization_id);
  UPDATE "organization" SET authz_generation = authz_generation + 1 WHERE id = org;
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_role";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_role FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_role_assignment";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_role_assignment FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_resource_grant";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_resource_grant FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_permission_group";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_permission_group FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

DROP TRIGGER IF EXISTS authz_gen_bump ON "organization_member";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON organization_member FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_policy";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_policy FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

CREATE OR REPLACE FUNCTION authz_bump_generation_via_role() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE org uuid;
BEGIN
  IF TG_TABLE_NAME = 'org_permission_group_item' THEN
    SELECT organization_id INTO org FROM org_permission_group
      WHERE id = COALESCE(NEW.group_id, OLD.group_id);
  ELSE
    SELECT organization_id INTO org FROM org_role
      WHERE id = COALESCE(NEW.role_id, OLD.role_id);
  END IF;
  UPDATE "organization" SET authz_generation = authz_generation + 1 WHERE id = org;
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_role_permission";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_role_permission FOR EACH ROW EXECUTE FUNCTION authz_bump_generation_via_role();

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_permission_group_item";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_permission_group_item FOR EACH ROW EXECUTE FUNCTION authz_bump_generation_via_role();

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_role_permission_group";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_role_permission_group FOR EACH ROW EXECUTE FUNCTION authz_bump_generation_via_role();

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0008_authz_generation_settings_trigger.sql
-- ═══════════════════════════════════════════════════════════════════════════

DROP TRIGGER IF EXISTS authz_gen_bump ON "organization_settings";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON organization_settings FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0013_org_member_deny.sql
-- ═══════════════════════════════════════════════════════════════════════════

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_member_deny";
CREATE TRIGGER authz_gen_bump AFTER INSERT OR UPDATE OR DELETE ON org_member_deny FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

ALTER TABLE org_member_deny ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_member_deny FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_member_deny;
CREATE POLICY tenant_isolation ON org_member_deny
      USING (
        organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid
      )
      WITH CHECK (
        organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid
      );

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0015_org_resource_grant_partitioned.sql
-- ═══════════════════════════════════════════════════════════════════════════

DROP TRIGGER IF EXISTS authz_gen_bump ON "org_resource_grant";
CREATE TRIGGER authz_gen_bump
    AFTER INSERT OR UPDATE OR DELETE ON org_resource_grant
    FOR EACH ROW EXECUTE FUNCTION authz_bump_generation();

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0017_authz_rls_journaled.sql
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE org_member_deny ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_member_deny FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_member_deny;
CREATE POLICY tenant_isolation ON org_member_deny
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_permission_group ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_permission_group FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_permission_group;
CREATE POLICY tenant_isolation ON org_permission_group
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_permission_group_item ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_permission_group_item FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_permission_group_item;
CREATE POLICY tenant_isolation ON org_permission_group_item
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant;
CREATE POLICY tenant_isolation ON org_resource_grant
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant_agents ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant_agents FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant_agents;
CREATE POLICY tenant_isolation ON org_resource_grant_agents
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant_assistants ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant_assistants FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant_assistants;
CREATE POLICY tenant_isolation ON org_resource_grant_assistants
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant_knowledge ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant_knowledge FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant_knowledge;
CREATE POLICY tenant_isolation ON org_resource_grant_knowledge
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant_mcp ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant_mcp FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant_mcp;
CREATE POLICY tenant_isolation ON org_resource_grant_mcp
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant_teams ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant_teams FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant_teams;
CREATE POLICY tenant_isolation ON org_resource_grant_teams
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_resource_grant_workflows ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_resource_grant_workflows FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_resource_grant_workflows;
CREATE POLICY tenant_isolation ON org_resource_grant_workflows
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_role ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_role FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_role;
CREATE POLICY tenant_isolation ON org_role
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_role_assignment ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_role_assignment FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_role_assignment;
CREATE POLICY tenant_isolation ON org_role_assignment
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_role_permission ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_role_permission FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_role_permission;
CREATE POLICY tenant_isolation ON org_role_permission
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_role_permission_group ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_role_permission_group FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_role_permission_group;
CREATE POLICY tenant_isolation ON org_role_permission_group
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE team_member ENABLE ROW LEVEL SECURITY;

ALTER TABLE team_member FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON team_member;
CREATE POLICY tenant_isolation ON team_member
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0018_authz_settings.sql
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE authz_settings ENABLE ROW LEVEL SECURITY;

ALTER TABLE authz_settings FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON authz_settings;
CREATE POLICY tenant_isolation ON authz_settings
  USING (organization_id IS NULL OR organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id IS NULL OR organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0022_org_privilege_activation.sql
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE org_privilege_activation ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_privilege_activation FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_privilege_activation;
CREATE POLICY tenant_isolation ON org_privilege_activation
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

ALTER TABLE org_role_eligibility ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_role_eligibility FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON org_role_eligibility;
CREATE POLICY tenant_isolation ON org_role_eligibility
  USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0023_sod_rule.sql
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE sod_rule ENABLE ROW LEVEL SECURITY;

ALTER TABLE sod_rule FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON sod_rule;
CREATE POLICY tenant_isolation ON sod_rule
  USING (organization_id IS NULL OR organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
  WITH CHECK (organization_id IS NULL OR organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0025_audit_append_only_and_activation_evidence.sql
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION admin_audit_log_immutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted';
  END IF;

  IF (to_jsonb(NEW) - 'actor_id' - 'target_user_id' - 'organization_id')
       IS DISTINCT FROM
     (to_jsonb(OLD) - 'actor_id' - 'target_user_id' - 'organization_id')
     OR NOT (NEW.actor_id        IS NOT DISTINCT FROM OLD.actor_id
             OR (OLD.actor_id        IS NOT NULL AND NEW.actor_id        IS NULL))
     OR NOT (NEW.target_user_id  IS NOT DISTINCT FROM OLD.target_user_id
             OR (OLD.target_user_id  IS NOT NULL AND NEW.target_user_id  IS NULL))
     OR NOT (NEW.organization_id IS NOT DISTINCT FROM OLD.organization_id
             OR (OLD.organization_id IS NOT NULL AND NEW.organization_id IS NULL))
  THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): only FK anonymization (SET NULL) may update a row';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS admin_audit_log_immutable_trg ON "admin_audit_log";
CREATE TRIGGER admin_audit_log_immutable_trg
  BEFORE UPDATE OR DELETE ON "admin_audit_log"
  FOR EACH ROW EXECUTE FUNCTION admin_audit_log_immutable();

CREATE OR REPLACE FUNCTION audit_chain_head_anchor_immutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_chain_head: the % anchor is frozen (ADR-0062): % is not permitted. It is the signature every per-organization chain is rooted in, so moving it re-roots chains that were verified against it.', OLD.chain_key, TG_OP;
END;
$$;

DROP TRIGGER IF EXISTS audit_chain_head_anchor_immutable_trg ON "audit_chain_head";
CREATE TRIGGER audit_chain_head_anchor_immutable_trg
  BEFORE UPDATE OR DELETE ON "audit_chain_head"
  FOR EACH ROW WHEN (OLD.chain_key = '__epoch0')
  EXECUTE FUNCTION audit_chain_head_anchor_immutable();
