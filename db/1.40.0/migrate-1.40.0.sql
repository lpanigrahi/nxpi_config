-- migrate-1.40.0.sql — schema delta 1.39.0 → 1.40.0 (R14 QA campaign, plane P14, finding F4): on the two PLATFORM-GOVERNANCE tables the org-or-platform row-security predicate is a READ latitude, and writes are bound to the connection's own frame. Source migration 0041 (journaled migration 0041_authz_platform_write_frame.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- `authz_settings` (the deployment's authorization knobs) and `sod_rule` (the
-- separation-of-duties toxic sets) each hold two kinds of row: an ORG row, one
-- tenant's override, and a PLATFORM row (`organization_id IS NULL`), the
-- deployment-wide decision every tenant inherits. Both tables carry ONE row
-- security policy, `tenant_isolation`, declared `FOR ALL` with the same
-- predicate on its `USING` and its `WITH CHECK` arm:
--
--     organization_id IS NULL OR organization_id = <current org>
--
-- The first arm is FRAME-INDEPENDENT — it is true whatever
-- `app.current_org_id` holds — and `FOR ALL` hands that latitude to INSERT,
-- UPDATE and DELETE as well as to SELECT. Measured on a database this
-- lineage's own artifacts build, as the least-privilege application role,
-- inside ONE organization's frame: an INSERT of a platform `authz_settings`
-- row succeeded; an UPDATE rewrote every platform row; and a DELETE removed
-- the four seeded `sod_rule` platform defaults — the maker/checker separations
-- that govern EVERY organization on the installation. No live exploit is
-- known: today's application writers are all org-qualified and scope-validated.
-- What was missing is the SECOND NET, on the two tables whose rows are
-- platform governance, and the loss is quiet: the rule loader's documented
-- fallback answers with its compiled-in constants when it finds no platform
-- rows, so a DELETED default reads as an unseeded database rather than as
-- tampering.
--
-- WHAT MOVES. Six policies, no data, no columns, no indexes.
--
--   * `write_frame_insert`, `write_frame_update` and `write_frame_delete` on
--     each of the two tables, each declared `AS RESTRICTIVE` and scoped to its
--     one command. PostgreSQL ANDs restrictive policies onto the permissive
--     result and ORs permissive ones together, so SELECT — which gets no
--     restrictive policy here — reads EXACTLY what it read before, and the
--     three write commands answer to
--
--         organization_id = <current org>
--         OR (organization_id IS NULL AND <current org> IS NOT SET)
--
--     A PLATFORM row is therefore writable only from a FRAMELESS connection —
--     which is what the platform settings console and every background pass
--     already are — and never from inside a tenant's frame. An ORG row is
--     writable only from its own frame, exactly as before.
--   * `tenant_isolation` IS NOT TOUCHED. Its bytes, its name and both its arms
--     are unchanged on both tables, which is deliberate: the RLS runner step in
--     docs/runbooks/production-rls-enablement.md re-creates the policy of that
--     NAME, so a rewrite under it would be reverted the next time an operator
--     ran the runner, while a differently-named restrictive policy survives.
--   * `ENABLE`/`FORCE ROW LEVEL SECURITY` are re-asserted on both tables.
--     No-ops on any database that took db/1.29.0 or the journaled series; they
--     are here so the policies cannot land on a table whose posture is off.
--
-- WHO COULD NOTICE. Only a writer that names a PLATFORM row from inside a
-- tenant's frame, and there is none: the settings writer opens its transaction
-- with no organization for a platform row (the frameless arm above), and the
-- SoD editor frames on the organization it is editing AND names
-- `organization_id = <that org>` in its own predicate. A background pass on the
-- privileged pool sets no tenant GUC at all, which is also the frameless arm.
-- If you have local code that writes either table, check it sets no
-- organization GUC when it writes a row whose `organization_id` is NULL.
--
-- VERIFY (read-only, after applying; run as the APPLICATION role, not as a
-- superuser — a superuser bypasses every policy and would tell you nothing):
--     SELECT tablename, policyname, permissive, cmd
--       FROM pg_policies
--      WHERE tablename IN ('authz_settings','sod_rule')
--      ORDER BY tablename, policyname;
--     -- expect 8 rows: tenant_isolation (PERMISSIVE, ALL) and the three
--     -- write_frame_* (RESTRICTIVE; INSERT, UPDATE, DELETE) per table.
--     SELECT count(*) FROM sod_rule WHERE organization_id IS NULL;  -- 4
--
-- NOT A DESTRUCTIVE DELTA and deliberately not marked REQUIRES-REVIEW: nothing
-- is dropped, no row is read or rewritten, and no lock is held for longer than
-- a catalogue write. `SET lock_timeout` bounds lock ACQUISITION; each CREATE
-- POLICY takes ACCESS EXCLUSIVE on its own table for that write, and both
-- tables are read on the authorization path, so a long-running reader is the
-- only thing that can queue this.
--
-- RE-RUNNABLE. Every CREATE POLICY is preceded by its own DROP POLICY IF
-- EXISTS on the same table, inside one DO block, so applying this file twice —
-- or by hand after a partial failure — lands the same six policies.
--
-- ROLLBACK: as a superuser or the table owner,
--     DROP POLICY IF EXISTS write_frame_insert ON authz_settings;
--     DROP POLICY IF EXISTS write_frame_update ON authz_settings;
--     DROP POLICY IF EXISTS write_frame_delete ON authz_settings;
--     DROP POLICY IF EXISTS write_frame_insert ON sod_rule;
--     DROP POLICY IF EXISTS write_frame_update ON sod_rule;
--     DROP POLICY IF EXISTS write_frame_delete ON sod_rule;
-- The tables return EXACTLY to their 1.39.0 posture — no data is touched and
-- `tenant_isolation` was never altered. What the rollback COSTS is the second
-- net itself: a tenant-framed connection can again create, rewrite and delete
-- the deployment-wide rows of both tables.
--
-- Apply with psql -1 (ON_ERROR_STOP) so the block lands or nothing does.

SET lock_timeout = '5s';

DO $$
DECLARE
  t text;
  frame text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid'
    || ' OR (organization_id IS NULL AND NULLIF(current_setting(''app.current_org_id'', true), '''') IS NULL)';
BEGIN
  FOREACH t IN ARRAY ARRAY['authz_settings', 'sod_rule'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS write_frame_insert ON %I', t);
    EXECUTE format('CREATE POLICY write_frame_insert ON %I AS RESTRICTIVE FOR INSERT WITH CHECK (%s)', t, frame);
    EXECUTE format('DROP POLICY IF EXISTS write_frame_update ON %I', t);
    EXECUTE format('CREATE POLICY write_frame_update ON %I AS RESTRICTIVE FOR UPDATE USING (%s) WITH CHECK (%s)', t, frame, frame);
    EXECUTE format('DROP POLICY IF EXISTS write_frame_delete ON %I', t);
    EXECUTE format('CREATE POLICY write_frame_delete ON %I AS RESTRICTIVE FOR DELETE USING (%s)', t, frame);
  END LOOP;
END $$;
