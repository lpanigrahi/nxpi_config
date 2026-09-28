-- optional-0003-tenant-hardening-retrofit.sql — OPTIONAL operator step, NOT
-- applied by ./update.sh or ./migrate.sh (they only pick up `migrate-*.sql`;
-- the 0082 / 0094 precedent). Row security is not applied by the packaged
-- deployment (compliance register) — the packaged path ships schema, grants
-- and seed only, and DB-level RLS is applied post-restore by the
-- src/lib/db/rls/ runner. This file is the operator-run mirror of that runner
-- for the seven knowledge/ingestion/embedding tables, kept here so a
-- sourceless VM adopting DB-level tenant isolation applies EXACTLY what the
-- journaled series applies.
--
-- Source migration 0003_tenant_hardening_retrofit
-- (src/lib/db/migrations/pg/0003_tenant_hardening_retrofit.sql): the retrofit
-- that re-declares 0001_tenant_hardening's RLS enable+FORCE, `tenant_isolation`
-- policies, and app-role grants on a pre-#158 legacy database — one stamped at
-- exactly the legacy watermark, which drizzle's strict-greater-than check never
-- re-applies 0001 to, leaving it with zero tenant_isolation policies. On the
-- SOURCE (checkout) path that database converges through `pnpm db:migrate`;
-- this file is the equivalent for a sourceless deployment that chooses to turn
-- the database backstop on. Idempotent by construction — DROP POLICY IF EXISTS
-- + CREATE, ENABLE/FORCE (no-ops when already set), GRANT (idempotent) — so
-- re-running converges and never errors.
--
-- Apply with the privileged role, e.g. from the deployment folder:
--   ./compose.sh exec -T postgres psql -U "$POSTGRES_ADMIN_USER" -d "$POSTGRES_DB" \
--     -v ON_ERROR_STOP=1 < db/1.22.0/optional-0003-tenant-hardening-retrofit.sql
-- Rollback (per table): NO FORCE / DISABLE ROW LEVEL SECURITY + DROP POLICY IF
--   EXISTS tenant_isolation; the grants are additive and harmless to leave.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'neo_gen') THEN
    CREATE ROLE neo_gen NOLOGIN;
  END IF;
END $$;

DO $$
DECLARE
  t text;
  pred text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid'
    || ' OR (organization_id IS NULL AND user_id = NULLIF(current_setting(''app.current_user_id'', true), '''')::uuid)';
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'knowledge_documents','knowledge_embeddings','knowledge_metadata',
    'knowledge_versions','knowledge_audit_logs',
    'ingestion_jobs','embedding_config'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t, pred, pred);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO neo_gen', t);
  END LOOP;
END $$;
