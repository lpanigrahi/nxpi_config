-- migrate-1.26.0.sql — schema delta 1.25.0 → 1.26.0 (Phase 5, authz programme): 0018 authz_settings, 0020 audit_chain_per_org and 0021 admin_audit_log_reference_fields, in journal order; 0019 lands with P5-T4.
-- REQUIRES-REVIEW: once audit_chain_head.chain_key is NOT NULL the PREVIOUS app
-- image cannot write ANY audit row (23502 on that column — see the
-- ROLL-FORWARD-ONLY block below), so update.sh's rolling path is NOT safe for
-- this delta: its auto-rollback assumes the old image stays schema-compatible.
-- Route: ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh   then   ./update.sh
--
-- Each source migration of the journaled series under src/lib/db/migrations/pg/
-- gets its own block header below, in journal order.
-- The audit hash chain becomes ONE CHAIN PER ORGANIZATION
-- (0020_audit_chain_per_org): audit_chain_head gains a NOT NULL chain_key with a
-- unique index, admin_audit_log gains the nullable chain_key its rows are
-- stamped with plus the (chain_key, created_at, id) index the per-chain verifier
-- reads, and the pre-split global head is frozen as the '__epoch0' anchor row
-- every later chain's first row links to (plan §P5-T7; ADR-0062 re-mechanised).
-- Additive to the SCHEMA — no table is rewritten and no constraint is tightened
-- on existing data (audit_chain_head is a singleton) — and the one cost to size
-- is the index build on admin_audit_log. It is NOT rolling-safe for the APP,
-- which is what the REQUIRES-REVIEW marker on line 2 encodes for lib.sh: read
-- the ROLL-FORWARD-ONLY block below before you deploy it.
-- Also in this delta, source migration 0019 (between 0018 and 0020 below):
-- TWO new tables: authz_outbox, the staging queue the authorization hot path
-- writes in one batched insert, and authz_decision_log, the durable record of
-- every enforcing decision — PARTITIONED BY RANGE ("at"), with the DEFAULT
-- partition that can never lose an insert, the three month partitions around
-- the migration's authoring date, and the two indexes the review and incident
-- reads need (plan §P5-T4).
-- Neither table carries a row-level policy and this delta enables none: the
-- packaged lineage ships no row-level security and the compliance register's
-- CC6.1 control discloses that. The decision log is platform-tier append-only
-- evidence (RLS_LEDGER "platform") rather than tenant data, which is stated in
-- the source migration's header along with the three structural reasons a
-- tenant predicate is inexpressible on it.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0018_authz_settings.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0018 — authz_settings. ROLLBACK: DROP TABLE IF EXISTS authz_settings
-- CASCADE; — the table is NEW, nothing in the schema references it, and a
-- rollback loses only the settings an operator or an org entered: every reader
-- falls back to the declared default, which is today's behaviour by
-- construction (src/lib/authz/settings/keys.ts), so the deployment keeps
-- serving.
--
-- WHAT IT IS FOR. Authorization's governance knobs live in three shapes today
-- (a jsonb object inside organization_settings.features, `app_settings` text
-- rows, environment variables), with three validation stories and no single
-- answer to "what is this setting for this org?". This table is that answer:
-- the reader resolves the org's row, then the platform row, then the legacy key
-- the setting used to live under, then the declared default.
--
-- THE TWO CHECKS are not decoration. The first states the scope vocabulary (a
-- `text` column is plain text at the DB level without it). The second ties the
-- scope to the tenancy column, so a platform row belonging to one org and an
-- org row belonging to nobody are both unrepresentable — and THAT is the
-- premise the row-level policy's NULL arm rests on, because it is what makes
-- `organization_id IS NULL` mean `scope = 'platform'`.
--
-- UNIQUE NULLS NOT DISTINCT, and why the default would be a bug: Postgres
-- treats NULLs as DISTINCT in a unique index, so a plain UNIQUE would constrain
-- org rows and let PLATFORM rows accumulate — every operator save inserting a
-- second row instead of updating the first, with the reader answering from
-- whichever one it happened to see, and nothing raising anywhere. Postgres 15
-- or newer is therefore required for this delta (the packaged lineage has
-- shipped 17 since 1.2.0).
--
-- THIS DELTA CARRIES NO POLICY, deliberately: no packaged artifact in this
-- lineage delivers row-level security (schema.sql is a pg_dump, which dumps no
-- policies), and the compliance register's CC6.1 control DISCLOSES exactly
-- that to the operator. Apply src/lib/db/rls/0026_authz_settings.sql through
-- the runbook's RLS step (docs/runbooks/production-rls-enablement.md) to get
-- the policy, as for every other covered table.
--
-- Re-runnable as written (CREATE TABLE / CREATE INDEX IF NOT EXISTS), so a
-- re-applied file is a no-op rather than an error mid-series. lib.sh applies
-- this file with psql -1: one transaction.

SET lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS authz_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  scope text NOT NULL,
  organization_id uuid CONSTRAINT authz_settings_organization_id_organization_id_fk REFERENCES organization (id) ON DELETE CASCADE,
  key text NOT NULL,
  value jsonb NOT NULL,
  updated_by uuid CONSTRAINT authz_settings_updated_by_user_id_fk REFERENCES "user" (id) ON DELETE SET NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT authz_settings_scope_check CHECK (scope IN ('platform','org')),
  CONSTRAINT authz_settings_scope_org_check CHECK ((scope = 'platform' AND organization_id IS NULL) OR (scope = 'org' AND organization_id IS NOT NULL)),
  CONSTRAINT authz_settings_scope_org_key_unique UNIQUE NULLS NOT DISTINCT (scope, organization_id, key)
);

CREATE INDEX IF NOT EXISTS authz_settings_org_idx ON authz_settings (organization_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0019_authz_decision_log.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0019 — authz_outbox + authz_decision_log. FORWARD-ONLY: the DROP that would
-- undo this is not a rollback but DELETION OF EVIDENCE — the rows are
-- authorization decisions held for an operator-set retention window and
-- nothing else in the deployment holds a second copy. Reverting the CODE is
-- free and needs no schema change: with no writer the outbox stays empty and
-- the log stops growing, which is where an un-configured deployment already
-- sits (`authz.decisionLog` defaults to `off`).
--
-- WHAT IT IS FOR. The platform can answer "who HAS this permission?" and not
-- "who used it, and what did the system decide?". The audit chain records
-- privileged WRITES synchronously (an advisory lock per row, so it can never
-- be turned on for allows) and org_permission_usage keeps a counter it
-- overwrites. This is the missing record: one row per enforcing decision,
-- written off the hot path.
--
-- TWO TABLES BECAUSE THEY HAVE OPPOSITE SHAPES. The hot path needs a write it
-- can batch and never waits for (authz_outbox: the emitter flushes up to 200
-- records in ONE insert every 100 ms). The evidence needs a table that can be
-- pruned by DROPPING a partition instead of by deleting a hundred million rows
-- (authz_decision_log, RANGE by "at" — the moment the decision was taken,
-- which is also the axis every read and the retention rule use).
--
-- THE DEFAULT PARTITION IS LOAD-BEARING. Without it, a row dated in a month no
-- partition covers fails 23514 — and because the drain moves a BATCH in one
-- statement, one such row rolls back the whole batch and keeps rolling it
-- back, stalling the log behind it. With it, a late partition sweep is an
-- operational nuisance instead of evidence loss.
--
-- NO FOREIGN KEY, ANYWHERE, and organization_id NULLABLE — both deliberate.
-- Every entity a decision names (org, user, api key, resource) can be deleted
-- by an ordinary product action; with FKs that deletion would cascade the
-- authorization history away exactly when an incident review wants it, or make
-- the tenant undeletable. A NULL organization is a real decision: a platform
-- console read and a job's decision belong to no tenant. The retention sweep
-- is the only thing that removes a row.
--
-- subject_kind's CHECK carries all SIX SubjectKind members, `service`
-- included. The plan's data model listed five; the sampler emits `service`
-- reads, so a five-member CHECK would refuse them and take the rest of the
-- batch with them.
--
-- IDEMPOTENT: every statement is IF NOT EXISTS, including the partitions
-- (CREATE TABLE IF NOT EXISTS … PARTITION OF is a no-op when the partition is
-- already attached). Applied by azure-deployment/lib.sh with psql -1, so a
-- failed apply leaves nothing behind. LOCK POSTURE: nothing here locks
-- anything an existing reader can see — every object is created fresh, there
-- is no backfill, no constraint to validate and not even a foreign-key target
-- to read-lock. Safe at any tenant size.

SET lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS authz_outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  payload jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  attempts integer DEFAULT 0 NOT NULL,
  last_error text
);

-- The drain's access path, partial on the attempt budget so the dead-lettered
-- rows an operator is still inspecting cost the ordinary drain nothing. The
-- literal 5 is AUTHZ_OUTBOX_MAX_ATTEMPTS in
-- src/lib/authz/decision-log/drain.ts; an index predicate must be immutable,
-- so the budget cannot be an env var, and a drain whose WHERE disagreed with
-- this predicate would quietly stop using the index.
CREATE INDEX IF NOT EXISTS authz_outbox_pending_idx
  ON authz_outbox (id) WHERE attempts < 5;

CREATE TABLE IF NOT EXISTS authz_decision_log (
  id bigint GENERATED ALWAYS AS IDENTITY,
  "at" timestamp with time zone NOT NULL,
  request_id text NOT NULL,
  trace_id text,
  subject_id uuid,
  subject_kind text NOT NULL,
  on_behalf_of uuid,
  api_key_id text,
  organization_id uuid,
  team_id uuid,
  surface_id text NOT NULL,
  action text NOT NULL,
  resource_type text,
  resource_id text,
  decision text NOT NULL,
  reason text NOT NULL,
  authority text NOT NULL,
  obligations text[] DEFAULT '{}'::text[] NOT NULL,
  catalog_version integer NOT NULL,
  manifest_version integer NOT NULL,
  policy_ids uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  ip inet,
  user_agent text,
  latency_ms integer,
  CONSTRAINT authz_decision_log_pkey PRIMARY KEY (id, "at"),
  CONSTRAINT authz_decision_log_subject_kind_check
    CHECK (subject_kind IN ('human','impersonated','api_key','job','service','anonymous')),
  CONSTRAINT authz_decision_log_decision_check
    CHECK (decision IN ('allow','deny'))
) PARTITION BY RANGE ("at");

-- The DEFAULT partition first, so that even a mid-apply insert cannot fail to
-- find a home.
CREATE TABLE IF NOT EXISTS authz_decision_log_default
  PARTITION OF authz_decision_log DEFAULT;

-- The months around this migration's authoring date, month-aligned in UTC and
-- spelled out as literals so an operator can grep this file for an object a
-- boot sentinel names. They age, and that is fine:
-- ensureDecisionLogPartitions (src/lib/authz/decision-log/partitions.ts),
-- which the daily sweep calls, creates the current month and the next two on
-- any database whenever it was provisioned — a deployment installed in 2027
-- gets these three empty partitions, the sweep's own, and the DEFAULT, never a
-- failing insert.
CREATE TABLE IF NOT EXISTS authz_decision_log_y2026m09
  PARTITION OF authz_decision_log
  FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS authz_decision_log_y2026m10
  PARTITION OF authz_decision_log
  FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS authz_decision_log_y2026m11
  PARTITION OF authz_decision_log
  FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');

-- Both indexes on the PARENT: Postgres clones a parent index to every
-- partition, including the ones the sweep attaches later, so the sweep never
-- has to remember to index what it creates.
CREATE INDEX IF NOT EXISTS authz_decision_log_org_at
  ON authz_decision_log (organization_id, "at" DESC);

CREATE INDEX IF NOT EXISTS authz_decision_log_request
  ON authz_decision_log (request_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0020_audit_chain_per_org.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0020 — the audit chain, split per organization. FORWARD-ONLY: both columns
-- are additive and drop cleanly (ALTER TABLE admin_audit_log DROP COLUMN IF
-- EXISTS chain_key; ALTER TABLE audit_chain_head DROP COLUMN IF EXISTS
-- chain_key, which takes audit_chain_head_key with it), but running that after
-- any post-split write LOSES the mapping from a row to the chain that signed
-- it, so every org's and the platform's rows collapse into one set that
-- verifies as a fork. Recovery after the split has been written to is
-- restore-from-backup. See the source migration for the full rationale,
-- including why a NULL chain_key on admin_audit_log is MEANINGFUL (it is the
-- pre-split global epoch, verified by
-- `tsx scripts/verify-audit-chain.ts --legacy`) and is deliberately not
-- backfilled.
--
-- ROLL-FORWARD-ONLY FOR THE AUDIT WRITER — READ BEFORE DEPLOYING. Once
-- audit_chain_head.chain_key is NOT NULL, the PREVIOUS app image cannot write
-- ANY audit row: its head upsert is
--   insert into audit_chain_head (id, head_signature, updated_at) values (…)
--     on conflict (id) do update set head_signature = …, updated_at = …
-- and Postgres enforces NOT NULL on the PROPOSED tuple before it arbitrates
-- ON CONFLICT, so the statement fails
--   23502 null value in column "chain_key" of relation "audit_chain_head"
-- even though the id = 1 row exists. On an old pod that means ordinary audit
-- rows are SILENTLY LOST (the non-blocking writer swallows the throw) and the
-- blocking ones FAIL the request (ROLE_CHANGED, USER_BANNED/UNBANNED,
-- impersonation). So: apply this delta together with the 1.26.0 image, do NOT
-- roll the app back and do NOT run mixed-version while the columns are
-- present. A rollback means dropping both columns, which loses the row→chain
-- mapping (above). `SET DEFAULT 'platform'` is NOT the escape hatch and is
-- deliberately absent — it lets the old writer advance the platform head while
-- stamping its row NULL, which breaks the legacy epoch AND the platform chain
-- permanently from one write; the loud 23502 is the better failure.
--
-- WHICH ROUTE, and what the marker does NOT buy you. That posture is why line 2
-- carries REQUIRES-REVIEW: update.sh's rolling path applies the delta while the
-- OLD container is still serving and, if the new image then fails the health
-- gate, AUTO-ROLLS BACK onto it and reports it compatible — an image whose every
-- audit write 23502s, indefinitely and with no health check that would notice.
-- The marker makes update.sh refuse this delta and send it to
-- ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh (backup first, no auto-rollback).
-- That does NOT eliminate the window, it makes it DELIBERATE and short: on the
-- migrate.sh route the old image is still up between this file and the image
-- roll, so audit writes fail for that interval. Bound it by running ./update.sh
-- immediately afterwards, which is what migrate.sh prints when it finishes —
-- and do not read its health check as an all-clear: the old image BOOTS and
-- serves fine against this schema (only the audit writer 23502s), so the gate
-- passes and nothing reports the open window.
--
-- RE-RUNNABLE, including the anchor. The anchor INSERT is guarded by two NOT
-- EXISTS clauses, not by its primary key: on a database provisioned from the
-- journaled series there is no id = 1 row when the delta first runs, so the
-- first apply creates NO anchor, the app's first platform write then takes
-- id = 1 with an ALREADY-ADVANCED head, and a second apply stopped only by
-- ON CONFLICT (id) would freeze THAT as the genesis — reporting success while
-- every chain silently becomes BROKEN. The load-bearing clause is the absence
-- of any chain_key-stamped admin_audit_log row, which is why that column is
-- added FIRST below. Re-run the WHOLE file, never a slice: a hand-applied
-- partial run that lands the columns but not the anchor INSERT, followed by
-- new-image writes, skips the anchor forever and leaves an upgraded database's
-- platform chain permanently BROKEN. lib.sh applies it psql -1 (one
-- transaction), so neither supported path can reach that state.
--
-- LOCK POSTURE for the operator: the two ADD COLUMNs carry no DEFAULT, so they
-- are metadata-only (no heap rewrite). Two statements touch the audit log at
-- its full size: the anchor INSERT's second guard proves the ABSENCE of any
-- chain_key-stamped row, which on the upgrade path (every row NULL, the index
-- on that column not built yet) is a full READ of admin_audit_log; and the last
-- statement, a full index BUILD on it, holding ACCESS EXCLUSIVE for its
-- duration. The build dominates, so time the window by it. It is a plain
-- CREATE INDEX, not CONCURRENTLY, because lib.sh applies this file with psql -1
-- (one transaction), where CONCURRENTLY fails 25001.

SET lock_timeout = '5s';

ALTER TABLE audit_chain_head ADD COLUMN IF NOT EXISTS chain_key text;

-- Added ahead of the anchor INSERT because that INSERT's re-runnability guard
-- reads admin_audit_log.chain_key on the very first apply.
ALTER TABLE admin_audit_log ADD COLUMN IF NOT EXISTS chain_key text;

-- The legacy singleton head IS the platform chain: same row, same signature,
-- now named. Re-running writes the same value.
UPDATE audit_chain_head SET chain_key = 'platform' WHERE id = 1;

-- The frozen fork point: a copy of the global head at the moment of the split,
-- which every chain cut afterwards links its first row to, so a per-org chain
-- is rooted in the history that preceded it instead of starting from nothing.
-- Nothing is inserted on a database that never seeded id = 1, and nothing is
-- inserted once the split has been WRITTEN TO — the second NOT EXISTS is what
-- keeps a re-apply from freezing the anchor against an already-advanced head
-- (see RE-RUNNABLE above; the primary key does not cover that case).
INSERT INTO audit_chain_head (id, chain_key, head_signature)
SELECT 0, '__epoch0', head_signature FROM audit_chain_head WHERE id = 1
  AND NOT EXISTS (SELECT 1 FROM audit_chain_head WHERE chain_key = '__epoch0')
  AND NOT EXISTS (SELECT 1 FROM admin_audit_log WHERE chain_key IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- Pre-flight: audit_chain_head is a singleton by construction, so a row this
-- delta has not named can only exist on a database where that assumption was
-- already broken. Name the rows instead of failing with a bare 23502.
DO $$
DECLARE orphans text;
BEGIN
  SELECT string_agg(id::text, ', ' ORDER BY id) INTO orphans
    FROM audit_chain_head WHERE chain_key IS NULL;
  IF orphans IS NOT NULL THEN
    RAISE EXCEPTION 'audit_chain_head rows carry no chain_key after the 0020 '
      'backfill (ids: %). This table is a singleton by construction, so these '
      'rows were written by something else. Decide what chain each one heads '
      '(an organization id, or platform) and set chain_key before re-running.',
      orphans;
  END IF;
END $$;

ALTER TABLE audit_chain_head ALTER COLUMN chain_key SET NOT NULL;

-- chain_key is the REAL key of this table (id is the surrogate the singleton
-- was born with). The unique index is what makes the writer's upsert
-- ON CONFLICT (chain_key) a safe seed-or-advance of exactly one head.
CREATE UNIQUE INDEX IF NOT EXISTS audit_chain_head_key
  ON audit_chain_head (chain_key);

-- The verifier's read: one chain, in insertion order. Without it, verifying a
-- single organization's chain scans every organization's rows.
CREATE INDEX IF NOT EXISTS admin_audit_log_chain_created
  ON admin_audit_log (chain_key, created_at, id);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0021_admin_audit_log_reference_fields.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0021 — the audit row's REFERENCE FIELDS. ROLLBACK: ALTER TABLE
-- admin_audit_log DROP COLUMN IF EXISTS request_id, DROP COLUMN IF EXISTS
-- on_behalf_of, DROP COLUMN IF EXISTS catalog_version, DROP COLUMN IF EXISTS
-- ip, DROP COLUMN IF EXISTS user_agent; DROP INDEX IF EXISTS
-- admin_audit_log_org_created_desc; DROP INDEX IF EXISTS
-- admin_audit_log_team_expr; — reversible, unlike the 0020 block above: the
-- five columns are OUTSIDE the hash chain (no signature commits to them) and
-- the two indexes are read paths, not constraints, so dropping them loses the
-- attribution recorded since the apply and nothing that verifies.
--
-- THIS BLOCK IS ROLLING-SAFE TO APPLY. Every column is nullable with no
-- DEFAULT and the previous app image simply names none of them, so it keeps
-- writing audit rows normally across the forward apply. The REQUIRES-REVIEW
-- marker on line 2 of this file is the 0020 block's, not this one's — but the
-- file applies as a unit, so this delta travels the
-- ALLOW_DESTRUCTIVE_MIGRATION route with it.
--
-- THE ROLLBACK ABOVE HAS AN ORDERING CONSTRAINT: reverse ONLY with the app
-- image rolled back FIRST. A post-0021 image names all five columns in EVERY
-- audit INSERT (the writer fills them unconditionally), so on a pre-0021
-- schema every audit write fails 42703 — silently on the fire-and-forget
-- path, which loses the ROWS rather than the request. The app's boot-time
-- schema probes refuse an image that is ahead of the schema, which is what
-- contains it; dropping the columns under a running post-0021 image is the
-- one order that does not self-protect.
--
-- WHAT IT IS FOR. An audit row said what happened, to whom and in which
-- organization — not which REQUEST wrote it (so the rows of one request cannot
-- be collected), not who was really at the keyboard when the session was an
-- impersonation (so an admin acting as a user is indistinguishable from the
-- user), not which permission catalog was in force, and neither address nor
-- agent. `insertAuditLog` is the one writer every audit row goes through, so
-- the five values are filled there from the request identity and every call
-- site gains them with no change of its own. Nothing is backfilled: a row
-- written before this apply had no identity recorded anywhere, so a NULL here
-- means exactly "written before 0021, or outside a request".
--
-- `on_behalf_of` is `session.impersonatedBy` — the admin whose session is
-- impersonating `actor_id` — and carries NO foreign key on purpose: the three
-- FKs this table already has are ON DELETE SET NULL, so deleting a user erases
-- their trace, and an attribution column that did the same would erase the
-- accountability it exists to carry.
--
-- `ip` is `inet` rather than `text` because the type is the check — the column
-- cannot fill up with "unknown" or "1.2.3.4:5678" and be queried as if it held
-- addresses, and it compares against a CIDR block, which is the question an
-- investigation asks. The app normalises the value before it arrives (a
-- non-address becomes NULL), because a 22P02 here is a LOST row: the
-- fire-and-forget writer swallows the throw.
--
-- OUTSIDE THE HASH CHAIN, deliberately: widening the signed payload to cover
-- these columns would invalidate every row ever signed (the ruling the 0020
-- block took for chain_key). So a later rewrite of a row's `ip` is not
-- chain-detectable; what the chain still detects is a deleted, inserted,
-- reordered or content-edited row. ADR-0109 records it, and the columns are
-- written by one writer under the immutability trigger that blocks UPDATE for
-- every role.
--
-- LOCK POSTURE for the operator: the five ADD COLUMNs carry no DEFAULT, so
-- they are metadata-only (no heap rewrite). The cost is the TWO INDEX BUILDS
-- on admin_audit_log, each holding ACCESS EXCLUSIVE for its duration — time
-- this block as those two builds against the audit log's real size. They are
-- plain CREATE INDEX, not CONCURRENTLY, because lib.sh applies this file with
-- psql -1 (one transaction), where CONCURRENTLY fails 25001.
--
-- RE-RUNNABLE: every statement is guarded with IF NOT EXISTS and there is no
-- data statement at all.

SET lock_timeout = '5s';

ALTER TABLE admin_audit_log
  ADD COLUMN IF NOT EXISTS request_id text,
  ADD COLUMN IF NOT EXISTS on_behalf_of uuid,
  ADD COLUMN IF NOT EXISTS catalog_version integer,
  ADD COLUMN IF NOT EXISTS ip inet,
  ADD COLUMN IF NOT EXISTS user_agent text;

-- The ORG TRAIL, and the exact key of the streamed keyset export: WHERE
-- (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC. `id DESC` is
-- the tiebreak, not padding — created_at is not unique, so without it a keyset
-- cursor can skip or repeat a row at a page boundary.
CREATE INDEX IF NOT EXISTS admin_audit_log_org_created_desc
  ON admin_audit_log (organization_id, created_at DESC, id DESC);

-- The TEAM tab. Team mutations tag their rows with metadata.teamId, and an
-- expression index is the only shape Postgres will use for that jsonb path —
-- without one every page of a team's audit list is a full scan of the
-- organization's rows.
CREATE INDEX IF NOT EXISTS admin_audit_log_team_expr
  ON admin_audit_log ((metadata->>'teamId'), created_at DESC);
