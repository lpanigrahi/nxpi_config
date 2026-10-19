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

-- Migration-journal access (ADR-0038): the boot-compat stamp written by
-- db:init lives in schema `drizzle`, created by the privileged role. Without
-- these grants an app-role boot with AUTO_DB_MIGRATE unset dies on
-- `permission denied for schema drizzle` before the stamp can make migrate a
-- no-op. Create-if-absent so this file works before db:init's stamp step.
CREATE SCHEMA IF NOT EXISTS drizzle;
CREATE TABLE IF NOT EXISTS drizzle.__drizzle_migrations
  (id SERIAL PRIMARY KEY, hash text NOT NULL, created_at bigint);
GRANT USAGE ON SCHEMA drizzle TO neo_gen;
GRANT SELECT, INSERT ON drizzle.__drizzle_migrations TO neo_gen;
GRANT USAGE, SELECT ON SEQUENCE drizzle.__drizzle_migrations_id_seq TO neo_gen;

-- ── THE AUDIT QUARANTINE IS NOT THE APPLICATION'S (1.33.0, DT-5-iv-2) ──────
-- `admin_audit_log_quarantine` and `audit_quarantine_row()` are the OWNER's
-- repair for a row the chain cannot verify, and they are the one place the
-- append-only floor admits a DELETE — for a row the quarantine table already
-- holds byte for byte. So the application role must not be able to WRITE that
-- table (it could then manufacture the precondition and delete any audit row)
-- and must not be able to CALL that function.
--
-- It DOES keep SELECT: the chain verifier crosses the gap a quarantined row
-- leaves, and the evidence pack reports it — both run as the application.
--
-- The GRANT above is `ON ALL TABLES`, and ALTER DEFAULT PRIVILEGES covers
-- tables created later, so this REVOKE must come after both and must be
-- re-applied whenever this file is. `IF EXISTS`-shaped through to_regclass so
-- the file still runs on a database that has not reached 1.33.0.
DO $$
BEGIN
  IF to_regclass('public.admin_audit_log_quarantine') IS NOT NULL THEN
    REVOKE ALL ON TABLE public.admin_audit_log_quarantine FROM PUBLIC;
    REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
      ON TABLE public.admin_audit_log_quarantine FROM neo_gen;
    GRANT SELECT ON TABLE public.admin_audit_log_quarantine TO neo_gen;
  END IF;
  IF to_regprocedure('public.audit_quarantine_row(uuid, text, text)') IS NOT NULL THEN
    REVOKE ALL ON FUNCTION public.audit_quarantine_row(uuid, text, text)
      FROM PUBLIC;
    REVOKE ALL ON FUNCTION public.audit_quarantine_row(uuid, text, text)
      FROM neo_gen;
  END IF;
END
$$;

-- Apply RLS policies (run after the app schema is fully migrated):
--   psql ... -f src/lib/db/rls/0001_org_tenant_isolation.sql
