-- migrate-1.39.0.sql — schema delta 1.38.0 → 1.39.0 (R14 QA campaign, plane P8, finding F1): `token_usage` learns WHICH TENANT PAID. Source migration 0040 (journaled migration 0040_token_usage_org_attribution.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- LINEAGE NOTE: this bundle was cut in a QA lane as 1.39.0 while its tree still
-- ended at 1.37.0, and was RE-RENDERED at the campaign rebase once T-AD's
-- 1.38.0 landed — `schema.sql`, `seed.sql` and `grants.sql` beside it are now
-- the 1.38.0 artefacts plus this delta (seed.sql stamps 41 journal rows, this
-- migration being id 41), and the journaled source file was renumbered
-- 0039 → 0040 behind T-AD's `0039_integration_event_idempotency` with its
-- `when` unchanged at 1790700000007, which was already strictly greater than
-- T-AD's …0006. The SQL below did not change at that rebase.
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- `token_usage` had no tenant column at all. The ENFORCED organization plan
-- token quota therefore scoped itself by the organization's MEMBER USER IDS and
-- summed every row those people had written ANYWHERE — in another organization
-- on the same installation, and in their own personal workspace. Every account
-- holds a second membership by construction (a personal organization is created
-- at signup), so this was the DEFAULT state rather than an edge case, and it
-- turned one tenant's cap into a control a DIFFERENT tenant could move: one
-- member's personal experimentation consumes the plan's monthly allowance, and
-- every member of that organization is answered **429** for the rest of the
-- month, with nothing in the organization's own Cost Governance dashboard able
-- to show where the tokens went — the rows are not its rows. The same missing
-- column is why that dashboard's per-user and per-model breakdowns reported
-- each member's spend, and the model ids they used, from their other tenants.
--
-- WHAT MOVES. Three DDL statements and ONE data statement.
--
--   * `organization_id uuid` — nullable, because a personal-workspace run
--     belongs to no tenant and NOT NULL would have no honest value to write for
--     it. The application stamps it on every insert from the org the request's
--     own tenant frame resolved, so AN IMAGE ROLLED AHEAD OF THIS FILE WRITES
--     NO USAGE ROWS AT ALL: the insert 42703s inside a fire-and-forget handler
--     that only logs, so the visible symptom is not an error but quotas that
--     quietly stop moving. The image carries a boot sentinel for this column
--     and for its index, so that skew fails the boot probe by name instead.
--   * the foreign key to `organization`, ON DELETE SET NULL — deleting an
--     organization must not delete the usage history each member's OWN monthly
--     quota is still computed from. Guarded on (conname, conrelid), so a
--     database that already carries the key executes nothing.
--   * `token_usage_organization_id_created_at_idx` — the org quota's own access
--     path, on a table that grows by one row per model call.
--   * the BACKFILL: for every historic row whose organization is DERIVABLE from
--     the chat thread it belongs to, that organization is written. Its bounds
--     are deliberate and are the whole of its safety: it never touches a row
--     the application has already stamped (`tu.organization_id IS NULL`), it
--     leaves a PERSONAL thread's rows NULL (the org IS derivable there and the
--     derived answer is "no tenant"), and it leaves a workflow/cron/agent row
--     that never had a thread NULL rather than inferring an organization from
--     the user's memberships — that inference would re-home deliberately
--     personal work into a tenant's dashboard and charge it against that
--     tenant's cap. Rows left NULL are counted, not hidden: the two triage
--     queries below report them before and after.
--
-- The backfill cannot widen any cap. A row moving from NULL to an organization
-- only ADDS to that organization's total, and the per-user totals are the same
-- rows they always were.
--
-- TRIAGE (read-only; run before and after):
--     SELECT count(*) FILTER (WHERE organization_id IS NOT NULL) AS attributed,
--            count(*) FILTER (WHERE organization_id IS NULL)     AS unattributed,
--            count(*) AS total
--       FROM token_usage;
--     SELECT count(*) AS derivable
--       FROM token_usage tu JOIN chat_thread ct ON ct.id = tu.thread_id
--      WHERE tu.organization_id IS NULL AND ct.organization_id IS NOT NULL;
--
-- THE OTHER USAGE TABLE, AND THE DIRECTION OF ERROR (read this before the
-- first billing period after the upgrade). The application change that ships
-- with this delta also applies an `organization_id` predicate to the
-- ORGANIZATION-scoped reads of `inference_request_log` — the Cost Governance
-- dashboard, the org and team analytics, and the org/member BUDGETS, including
-- the 429 those budgets raise. That column is FORWARD-ONLY on that table: it is
-- populated at chat time and is NOT backfilled by this file or any other. So
-- for the remainder of the current period, every row written before it existed
-- leaves the arithmetic:
--
--   * budgets and the member cap UNDER-count — a budget that used to block may
--     stop blocking until stamped rows accumulate;
--   * Cost Governance / analytics UNDER-report the same rows.
--
-- This is the safe direction and the deliberate one: a cost control that fails
-- OPEN never over-charges and never wrongly refuses. The direction that was
-- replaced does not under-count — it counted every member's spend and model ids
-- from OTHER tenants and from their personal workspaces as this organization's.
-- Measure the size before you deploy, with `pnpm preflight` (its
-- `org usage attribution` row prints both counts) or by hand:
--
--     SELECT count(*) FILTER (WHERE organization_id IS NULL) AS unattributed,
--            count(*) AS total
--       FROM inference_request_log
--      WHERE created_at >= date_trunc('month', now());
--
-- If that number is material for an organization that relies on a hard budget,
-- raise the budget for one period or accept the gap knowingly — do not restore
-- the cohort-only scope.
--
-- SIZE IT FIRST. `SET lock_timeout` bounds lock ACQUISITION, not the hold: the
-- ADD COLUMN and the FK take ACCESS EXCLUSIVE on `token_usage`, and applying
-- this file with `psql -1` holds them through the index build and the UPDATE.
-- `token_usage` is write-hot (one row per model call) and the UPDATE touches
-- one row per historic chat-sourced row, so on a large installation this is the
-- long part of the run — use the `derivable` count above and take a maintenance
-- window if it is large. Nothing reads a column that does not exist yet, so the
-- application image is safe at every point during the run.
--
-- RE-RUNNABLE. `ADD COLUMN IF NOT EXISTS`, the FK inside its own existence
-- guard, `CREATE INDEX IF NOT EXISTS`, and an UPDATE whose `IS NULL` predicate
-- makes a second apply a no-op. Applying this file twice lands the same
-- database. NOT a REQUIRES-REVIEW delta: nothing is dropped and nothing already
-- written is rewritten — the only rows it touches are the ones whose tenant
-- column is NULL because the column did not exist when they were written.
--
-- ROLLBACK: `DROP INDEX IF EXISTS token_usage_organization_id_created_at_idx;
-- ALTER TABLE token_usage DROP CONSTRAINT IF EXISTS
-- token_usage_organization_id_organization_id_fk; ALTER TABLE token_usage DROP
-- COLUMN IF EXISTS organization_id;`. What it costs is stated rather than
-- discovered: every organization's plan quota goes back to counting its
-- members' usage in other tenants and in their personal workspaces. The
-- backfilled values are re-derivable — re-add the column and re-apply this
-- file.
--
-- Apply with psql -1 (ON_ERROR_STOP) so all four statements land or none do.

SET lock_timeout = '5s';

ALTER TABLE token_usage ADD COLUMN IF NOT EXISTS organization_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'token_usage_organization_id_organization_id_fk'
      AND conrelid = to_regclass('token_usage')
  ) THEN
    ALTER TABLE token_usage
      ADD CONSTRAINT token_usage_organization_id_organization_id_fk
      FOREIGN KEY (organization_id) REFERENCES organization(id)
      ON DELETE SET NULL ON UPDATE NO ACTION;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS token_usage_organization_id_created_at_idx ON token_usage USING btree (organization_id, created_at);

UPDATE token_usage tu
   SET organization_id = ct.organization_id
  FROM chat_thread ct
 WHERE tu.thread_id = ct.id
   AND tu.organization_id IS NULL
   AND ct.organization_id IS NOT NULL;
