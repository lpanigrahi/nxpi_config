-- migrate-1.11.0.sql — schema delta 1.10.0 → 1.11.0 (source migrations 0078, 0079).
--
-- ADDITIVE-ONLY: one new empty table and two new UNIQUE indexes. No column is
-- dropped or narrowed and no row is written, so `./update.sh`'s rolling
-- (additive-only) path applies it with no maintenance window.
--
-- !! DO NOT write the destructive-review marker anywhere in the first SIX
-- lines of this file. `apply_migrations` detects it with a bare
-- `head -n 6 | grep -q` (lib.sh:612, :669) — a naive substring match that
-- cannot tell a flag from prose about a flag. Even the sentence you are
-- reading would re-arm the maintenance-window gate if it sat six lines higher.
--
-- WHY THIS FILE MUST SHIP WITH THE IMAGE: db/1.10.0 composes source migrations
-- through 0077 only. Any image carrying 0078/0079 therefore rolls AHEAD of the
-- packaged delta, and `resolveOrgEntitlement` — which sits on the org-quota
-- path every inference request walks — 42P01s on the absent
-- `organization_entitlement`. That is the FIFTH occurrence of this incident
-- class (1.6.0 `qa_baseline_hash`, 1.8.0 `skill.deployed`, 1.10.0
-- `session.mfa_verified_at`, and the 2026-07-28 `skill.scope` outage before
-- them). `src/lib/db/schema-sentinels.ts` carries matching probes so a
-- mismatched VM says so at boot rather than at the first request, and
-- `schema-sentinels.packaging.test.ts` now fails the build when a sentinel's
-- migration has no packaged delta behind it — the recurrence guard this class
-- of incident lacked for five releases.
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas — every step is existence-guarded, so re-running is a no-op:
--   0078_organization_entitlement.sql        (organization_entitlement)
--   0079_billing_and_invite_idempotency.sql  (two partial UNIQUE indexes)
-- with ONE addition that has no counterpart in the source tree: the pre-flight
-- duplicate checks below. See the note above section (b).
--
-- Verified by applying it twice consecutively against a database built from
-- db/1.10.0/schema.sql, then diffing the resulting catalog against a database
-- built fresh from this directory's schema.sql — the two lineages are
-- identical (columns, constraints, indexes, defaults; see the header note in
-- schema.sql about constraint NAMES, which is why that check is not vacuous).
--
-- rollback:
--   DROP INDEX IF EXISTS "org_invite_pending_email_uq";
--   DROP INDEX IF EXISTS "invoice_org_external_id_uq";
--   DROP TABLE IF EXISTS "organization_entitlement";
BEGIN;

-- ── (a) 0078 — per-ORGANIZATION entitlement override (ADR-0073) ──────────────
-- A super-admin grant that REPLACES the plan's three limits for one
-- organization, so a cap can be RAISED above the plan's and not only tightened
-- (organization_settings.max_monthly_tokens already tightens, via minQuota, and
-- keeps doing so on top of this).
--
-- ROW PRESENCE is the override switch: a row means all three of its values are
-- authoritative, no row means the org inherits its plan entirely. `null`
-- therefore means UNLIMITED here, exactly as on plan_entitlement — it cannot
-- ALSO mean "not overridden" without fusing two meanings into one column.
--
-- Additive and EMPTY on arrival: with no rows, every organization resolves
-- precisely as it did before this delta, so the change is inert until an
-- operator uses it. No backfill is possible or wanted.
--
-- RLS is NOT created here, matching every other table in this package: the
-- sourceless deployment ships policies-off by documented design (see
-- docs/SOURCELESS-DEPLOYMENT-PLAN.md §1a "RLS: default off"). The application
-- repository's rls/0018_organization_entitlement.sql is the opt-in hardening
-- for deployments that run RLS; the repository sets an org context explicitly
-- from the orgId it is handed either way.
CREATE TABLE IF NOT EXISTS "organization_entitlement" (
  "organization_id" uuid PRIMARY KEY
    REFERENCES "organization" ("id") ON DELETE CASCADE,
  "max_members" integer,
  "max_agents" integer,
  "monthly_token_quota" integer,
  -- Attribution for an audited, privilege-bearing write. SET NULL rather than
  -- CASCADE: deleting the operator must not delete the grant they made.
  "updated_by" uuid REFERENCES "user" ("id") ON DELETE SET NULL,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── (b) 0079 — billing-webhook + invite idempotency ──────────────────────────
-- PRE-FLIGHT DUPLICATE CHECKS — no counterpart in the source migration, and
-- deliberately so. In the app repository 0079 runs against developer databases
-- that cannot hold a conflicting row; here it runs against LIVE production
-- data, where a UNIQUE index over existing duplicates aborts with a raw
-- "could not create unique index … Key …=(…) is duplicated" in the middle of a
-- deploy. For org_invite that is not a corner case: 0079's own header records
-- that invite-service.create RE-INVITES when a previous pending invite has
-- EXPIRED, so two rows with accepted_at IS NULL for one (organization_id,
-- invited_email) is documented NORMAL behaviour on any VM with invite churn.
--
-- These blocks refuse to DELETE anything. migrate.sh's contract is additive
-- only — "never seeds or overwrites rows — your data is not touched" — and
-- silently discarding an invite or an invoice to make an index build would
-- break it. They fail CLOSED instead, naming the offending groups and the
-- query that lists them, so the operator resolves the data deliberately and
-- re-runs. Both are no-ops once the corresponding index exists (a duplicate
-- cannot survive it), so re-running this file stays a no-op.
DO $$
DECLARE
  grp integer;
  surplus bigint;
BEGIN
  SELECT count(*), coalesce(sum(c) - count(*), 0) INTO grp, surplus
  FROM (
    SELECT count(*) AS c
      FROM "invoice"
     WHERE "external_invoice_id" IS NOT NULL
     GROUP BY "organization_id", "external_invoice_id"
    HAVING count(*) > 1
  ) d;
  IF grp > 0 THEN
    RAISE EXCEPTION
      'invoice_org_external_id_uq cannot be created: % (organization_id, external_invoice_id) group(s) already hold duplicate invoices (% surplus row(s)).',
      grp, surplus
      USING HINT =
        'These are the duplicate open invoices the replay guard exists to prevent, minted before it existed. List them with:  SELECT organization_id, external_invoice_id, count(*), min(id), max(id) FROM invoice WHERE external_invoice_id IS NOT NULL GROUP BY 1,2 HAVING count(*)>1;  keep ONE row per group (normally the earliest), void/delete the rest, then re-run ./migrate.sh. This delta will not modify invoice rows for you: migrate.sh is additive-only by contract.';
  END IF;
END $$;

DO $$
DECLARE
  grp integer;
  surplus bigint;
BEGIN
  SELECT count(*), coalesce(sum(c) - count(*), 0) INTO grp, surplus
  FROM (
    SELECT count(*) AS c
      FROM "org_invite"
     WHERE "accepted_at" IS NULL
     GROUP BY "organization_id", "invited_email"
    HAVING count(*) > 1
  ) d;
  IF grp > 0 THEN
    RAISE EXCEPTION
      'org_invite_pending_email_uq cannot be created: % (organization_id, invited_email) group(s) already hold more than one PENDING invite (% surplus row(s)).',
      grp, surplus
      USING HINT =
        'Expected on a VM with invite churn: re-inviting after a pending invite EXPIRED left both rows pending. List them with:  SELECT organization_id, invited_email, count(*) FROM org_invite WHERE accepted_at IS NULL GROUP BY 1,2 HAVING count(*)>1;  delete the superseded rows (the smaller expires_at) keeping the newest per group, then re-run ./migrate.sh. This delta will not delete invite rows for you: migrate.sh is additive-only by contract.';
  END IF;
END $$;

-- (b.1) invoice_org_external_id_uq: replay protection for the billing webhook.
-- The processor-agnostic payload carries NO event id, so the processor's
-- invoice id is the only replay key: one invoice per (organization_id,
-- external_invoice_id). Without it, a captured signed invoice.created body
-- replayed against the endpoint minted unlimited duplicate open invoices —
-- insertInvoice inserted unconditionally. PARTIAL on external_invoice_id IS
-- NOT NULL: internally-generated invoices (generateInvoiceForPlan) have no
-- external id and stay unconstrained. insertInvoice pairs this index with
-- ON CONFLICT DO NOTHING and reports null for a swallowed replay, which the
-- service logs and answers with 200 (the processor must not retry forever).
CREATE UNIQUE INDEX IF NOT EXISTS "invoice_org_external_id_uq"
  ON "invoice" ("organization_id", "external_invoice_id")
  WHERE "external_invoice_id" IS NOT NULL;

-- (b.2) org_invite_pending_email_uq: one PENDING invite per (organization_id,
-- invited_email). PARTIAL on accepted_at IS NULL: accepted invites are history
-- and exempt. A missing UNIQUE index here does not 42P01 — it silently
-- readmits the duplicate rows the migration exists to block, which is why the
-- schema sentinel probes pg_indexes rather than information_schema.
CREATE UNIQUE INDEX IF NOT EXISTS "org_invite_pending_email_uq"
  ON "org_invite" ("organization_id", "invited_email")
  WHERE "accepted_at" IS NULL;

COMMIT;
