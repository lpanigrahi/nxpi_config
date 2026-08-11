-- Bootstrap script for the non-privileged app DB role used with RLS enforcement.
-- Run this ONCE as a superuser on any new environment before starting the app:
--   psql -h <host> -U <superuser> -d <dbname> -f scripts/setup-app-db-role.sql
--
-- NOTE: `pnpm db:init` automates this (the ensureAppRole step in
-- scripts/db-init/steps.ts) whenever POSTGRES_URL and POSTGRES_PRIVILEGED_URL
-- name different users — the Azure/verify compose stacks rely on that. This
-- file remains the manual/local equivalent and the reference for the grants.
--
-- The app connects as neo_gen (POSTGRES_URL). The superuser connection is kept
-- in POSTGRES_PRIVILEGED_URL for migrations, background workers, and admin ops.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'neo_gen') THEN
    CREATE ROLE neo_gen LOGIN;
  END IF;
END
$$;

-- Ensure login is enabled even if the role already existed without it.
ALTER ROLE neo_gen LOGIN;

-- Grant schema access and full DML on all application tables
GRANT USAGE ON SCHEMA public TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO neo_gen;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO neo_gen;

-- Future tables/sequences created by the superuser will also be accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO neo_gen;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO neo_gen;

-- Apply RLS policies (run after the app schema is fully migrated):
--   psql ... -f src/lib/db/rls/0001_org_tenant_isolation.sql

-- SGTF (0066): the two governance tables the app role writes. Table-level
-- GRANTs are not carried by pg_dump --no-privileges, so they live here with
-- the rest of the neo_gen bootstrap.
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_scan" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_attestation" TO neo_gen;

-- SQAF (0068): the three quality tables the app role writes. Same reasoning as
-- the SGTF block above — `pg_dump --no-privileges` does not carry table-level
-- GRANTs, so a schema.sql restore leaves neo_gen unable to write them and every
-- QA run fails with a permission error that looks nothing like a missing grant.
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_run" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_check_result" TO neo_gen;
GRANT SELECT, INSERT, UPDATE, DELETE ON "skill_qa_certification" TO neo_gen;
