-- migrate-1.9.0.sql — schema delta 1.8.0 → 1.9.0 (source migrations 0071–0076).
-- REQUIRES-REVIEW: 0073 drops and re-creates the document_chunk organization
-- FK as ON DELETE CASCADE (was SET NULL) — deleting an organization now
-- DELETES its RAG corpus instead of re-homing it. Review + take a backup,
-- then apply via ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh (update.sh's
-- rolling path refuses REQUIRES-REVIEW deltas by design).
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas, in order — every step is existence-guarded, so re-running is a no-op:
--   0071_governance_engine.sql             (org_policy_version trail + the ADR-0037
--                                           admin_audit_log append-only trigger)
--   0072_cron_run_log_single_running_claim (partial UNIQUE claim index)
--   0073_document_chunk_org_cascade        (org FK SET NULL → CASCADE — the
--                                           REQUIRES-REVIEW trigger of this delta)
--   0074_queue_idempotency_chokepoint      (job_execution ledger + event_outbox)
--   0075_audit_hash_chain                  (audit_chain_head + prev_signature)
--   0076_agent_deployment_owner            (agent_deployment.owner_user_id + backfill)
-- plus a final metadata-only constraint-NAME convergence section (see below).
--
-- This delta REPLACES an earlier machine-generated (migra) 1.9.0 delta that
-- was never deployed anywhere. That file (a) dropped skill_undeployed_idx — a
-- live index created by 0070 that the drizzle-derived export baseline simply
-- did not know about — (b) was not idempotent (bare CREATE TABLE), and
-- (c) dropped ten skill_qa_* FK constraints by their delta-lineage names
-- unconditionally, which fails outright on a database fresh-provisioned from
-- the 1.5.0–1.8.0 schema.sql (those carry the drizzle-generated names).
--
-- NOTE this delta also brings the ADR-0037 admin_audit_log immutability
-- trigger to sourceless deployments for the first time: drizzle-kit push
-- cannot express functions/triggers, so no packaged schema.sql before 1.9.0
-- (patched) ever carried it. The app's own write path is INSERT-only and is
-- certified against the trigger being active.


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0071_governance_engine.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 0071 — Enterprise Governance Engine (ADR-0037). Idempotent; re-runnable.
--
-- Part A — LAW 4 ("Every policy is versioned"): org_policy_version, the
-- immutable snapshot trail written by the repository mutators in the same
-- transaction as every org_policy mutation. policy_id deliberately carries NO
-- foreign key: a cascade would erase the trail at exactly the moment it
-- matters (the policy's deletion) — the terminal snapshot must outlive its
-- subject. organization_id keeps the cascade: org deletion legitimately ends
-- the org's whole record. No FIFO retention — trimming an immutability trail
-- would contradict it.

CREATE TABLE IF NOT EXISTS "org_policy_version" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL REFERENCES "organization"("id") ON DELETE CASCADE,
  "policy_id" uuid NOT NULL,
  "version_number" integer NOT NULL,
  "action" varchar NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "type" varchar NOT NULL,
  "effect" varchar NOT NULL,
  "priority" integer NOT NULL,
  "definition" jsonb NOT NULL,
  "enabled" boolean NOT NULL,
  "changed_by" uuid REFERENCES "user"("id") ON DELETE SET NULL,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT "org_policy_version_number_unique" UNIQUE ("policy_id", "version_number"),
  CONSTRAINT "org_policy_version_action_check"
    CHECK ("action" in ('create','update','enable','disable','delete'))
);

CREATE INDEX IF NOT EXISTS "org_policy_version_policy_idx"
  ON "org_policy_version" ("policy_id");
CREATE INDEX IF NOT EXISTS "org_policy_version_org_idx"
  ON "org_policy_version" ("organization_id");

-- Part B — LAW 5 ("Audit logs are immutable"): admin_audit_log becomes
-- append-only AT THE DATABASE. Until now immutability was a repository
-- convention (insert-only by habit) that any bug, compromised session, or
-- ad-hoc SQL could silently violate.
--
-- The carve-out is load-bearing: actor_id / target_user_id / organization_id
-- are declared ON DELETE SET NULL, and PostgreSQL executes that referential
-- action as an implicit UPDATE on the audit rows — a naive trigger would make
-- every user/org deletion fail platform-wide. An UPDATE is therefore allowed
-- ONLY when it is pure anonymization: each of the three FK columns is either
-- unchanged or non-null -> NULL, and every other column IS NOT DISTINCT FROM
-- its old value. Everything else raises.
--
-- Declared boundary: TRUNCATE is not blocked (row triggers do not fire on
-- it) — the control targets row tampering, not database resets.

CREATE OR REPLACE FUNCTION admin_audit_log_immutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted';
  END IF;

  -- "Every other column unchanged" is checked structurally (whole-row jsonb
  -- minus the three FK columns), NOT by enumerating column names: a
  -- hand-mirrored column list would silently stop covering columns added
  -- later (the ADR-0031 drift class). Only the carve-out itself names
  -- columns, because the three FK columns ARE its definition.
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


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0072_cron_run_log_single_running_claim.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- rollback: DROP INDEX IF EXISTS cron_run_log_one_running_per_job; -- reverts
-- the F15 atomic-claim guard, restoring the pre-0072 shape where a cron job
-- could hold more than one concurrent 'running' run-log row.
--
-- 0072 — Cron run-log single-running claim (ADR-0044, F15). Idempotent;
-- re-runnable. Backs the scheduler's cross-replica double-run guard with a
-- partial UNIQUE index so at most one RUNNING run-log row exists per cron job.
-- The dispatch/cron-worker inserts use ON CONFLICT (cron_job_id) WHERE
-- status='running' DO NOTHING; the predicate MUST match this index's predicate
-- exactly or Postgres rejects the ON CONFLICT ("no unique/exclusion constraint
-- matching"). Partial, so completed/failed/skipped history rows are
-- unconstrained.
BEGIN;

DO $$ BEGIN
  BEGIN
    CREATE UNIQUE INDEX IF NOT EXISTS cron_run_log_one_running_per_job
      ON cron_run_log (cron_job_id)
      WHERE status = 'running';
  EXCEPTION WHEN unique_violation THEN
    -- Pre-existing duplicate 'running' rows (from the very race this closes, or
    -- from crashed runs) block the build. cleanupStaleLogs finalizes stale
    -- 'running' rows every tick; let it sweep, then re-run this migration.
    RAISE NOTICE 'cron_run_log_one_running_per_job NOT created: pre-existing duplicate running rows; finalize duplicates (cleanupStaleLogs) then re-run.';
  END;
END $$;

COMMIT;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0073_document_chunk_org_cascade.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- rollback: re-create the FK with ON DELETE SET NULL (see the DO block below,
-- swapping CASCADE for SET NULL) to restore the pre-0073 re-homing behavior.
--
-- 0073 — document_chunk org FK cascade (ADR-0045, F50). Idempotent;
-- re-runnable. document_chunk was the only RAG table whose organization_id FK
-- was ON DELETE SET NULL, so deleting an org re-homed its corpus (an org-null
-- chunk reads as personal/global). Switch it to ON DELETE CASCADE so an org's
-- corpus dies with the org. The FK's generated name is discovered dynamically
-- so the migration is name-agnostic.
BEGIN;

DO $$
DECLARE c text;
BEGIN
  SELECT con.conname INTO c
  FROM pg_constraint con
  JOIN pg_attribute a
    ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
  WHERE con.conrelid = 'document_chunk'::regclass
    AND con.contype = 'f'
    AND a.attname = 'organization_id';

  IF c IS NOT NULL THEN
    EXECUTE format('ALTER TABLE document_chunk DROP CONSTRAINT %I', c);
  END IF;

  ALTER TABLE document_chunk
    ADD CONSTRAINT document_chunk_organization_id_organization_id_fk
    FOREIGN KEY (organization_id) REFERENCES organization(id)
    ON DELETE CASCADE;
END $$;

COMMIT;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0074_queue_idempotency_chokepoint.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- rollback: DROP TABLE IF EXISTS event_outbox; DROP TABLE IF EXISTS
-- job_execution; -- reverts the Class-7 idempotency chokepoint (#172,
-- ADR-0052) — the per-handler idempotency ledger and the transactional outbox.
-- Both are operational scratch (drained / GC'd continuously); no data migration.
--
-- 0074 — Queue idempotency chokepoint (#172; generalizes ADR-0044 F15/F12).
-- Idempotent; re-runnable.
--
-- job_execution: one atomic CLAIM row per idempotency_key, so a handler runs
-- its side effects exactly once across BullMQ's at-least-once retries/replays
-- (generalizes F15's cron partial-unique claim to every worker via
-- defineWorker). event_outbox: the fan-out (event-bus publish / webhook enqueue
-- / agent dispatch) is written IN the same claim transaction and drained by a
-- separate dispatcher keyed by dedup_key — so the WRITE is exactly-once (unique
-- dedup_key) and DELIVERY is at-least-once with each consumer keyed to dedup
-- (generalizes F12's deterministic jobId to all three channels) → exactly-once.
BEGIN;

CREATE TABLE IF NOT EXISTS job_execution (
  idempotency_key  text PRIMARY KEY,
  queue            text NOT NULL,
  status           text NOT NULL DEFAULT 'running', -- running | completed | failed
  organization_id  uuid REFERENCES organization(id) ON DELETE CASCADE,
  claimed_at       timestamptz NOT NULL DEFAULT now(),
  completed_at     timestamptz,
  attempts         integer NOT NULL DEFAULT 1,
  last_error       text
);
-- Stale-claim reclaim scan: find 'running' rows whose lease has expired.
CREATE INDEX IF NOT EXISTS job_execution_running_claimed_at
  ON job_execution (claimed_at) WHERE status = 'running';

CREATE TABLE IF NOT EXISTS event_outbox (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_type   text NOT NULL,
  aggregate_id     text NOT NULL,
  channel          text NOT NULL, -- event_bus | webhook | agent_queue
  payload          jsonb NOT NULL,
  organization_id  uuid REFERENCES organization(id) ON DELETE CASCADE,
  status           text NOT NULL DEFAULT 'pending', -- pending | dispatched
  dedup_key        text NOT NULL,
  attempts         integer NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now(),
  dispatched_at    timestamptz,
  last_error       text
);
-- Exactly-once WRITE: a replayed handler emitting the same dedup_key is a no-op.
CREATE UNIQUE INDEX IF NOT EXISTS event_outbox_dedup_key ON event_outbox (dedup_key);
-- Dispatcher drain scan (FOR UPDATE SKIP LOCKED over the pending set).
CREATE INDEX IF NOT EXISTS event_outbox_pending
  ON event_outbox (created_at) WHERE status = 'pending';

COMMIT;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0075_audit_hash_chain.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- rollback: DROP TABLE IF EXISTS audit_chain_head; and
-- ALTER TABLE admin_audit_log DROP COLUMN IF EXISTS prev_signature;
-- The event_signature column predates this migration and is left in place.
--
-- 0075 — audit hash chain (ADR-0062, enterprise-readiness #13). Idempotent;
-- re-runnable. Adds the prev_signature link to admin_audit_log and the
-- single-row audit_chain_head pointer that serialises chained inserts. The
-- chain begins at the first row written AFTER this migration (existing rows
-- keep a NULL signature and are treated as legacy/pre-chain by the verifier),
-- so no backfill is required. Deliberately NO row-level security — like
-- admin_audit_log, these are platform-tier records.
BEGIN;

ALTER TABLE admin_audit_log
  ADD COLUMN IF NOT EXISTS prev_signature text;

CREATE TABLE IF NOT EXISTS audit_chain_head (
  id integer PRIMARY KEY,
  head_signature text NOT NULL DEFAULT '',
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- The lone head row. ON CONFLICT keeps a re-run from resetting an existing head.
INSERT INTO audit_chain_head (id, head_signature)
VALUES (1, '')
ON CONFLICT (id) DO NOTHING;

COMMIT;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0076_agent_deployment_owner.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- rollback: ALTER TABLE agent_deployment DROP COLUMN IF EXISTS owner_user_id;
--
-- 0076 — agent_deployment owner column (ADR-0070). Idempotent; re-runnable.
-- Adds owner_user_id so a PERSONAL (org-null) deployment can be RLS-scoped to
-- its owner — the user whose agent it deploys. `created_by` was only
-- attribution (set-null on delete) and could not serve. Backfills existing rows
-- from the deploying agent's owner (agent.user_id), which for a personal
-- deployment IS the owner. Org-scoped rows are covered by the policy's org
-- branch and do not require it, but the backfill sets them too for consistency.
BEGIN;

ALTER TABLE agent_deployment
  ADD COLUMN IF NOT EXISTS owner_user_id uuid REFERENCES "user"(id) ON DELETE CASCADE;

UPDATE agent_deployment d
  SET owner_user_id = a.user_id
  FROM agent a
  WHERE a.id = d.agent_id
    AND d.owner_user_id IS NULL;

COMMIT;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> constraint-name convergence (metadata-only; no schema change)
-- ═══════════════════════════════════════════════════════════════════════════
-- Two provisioning lineages name the SAME foreign keys differently:
--   · delta-migrated databases carry the names hand-written in 0068/0069
--     (…_issued_by_fk) and the Postgres auto-names from the inline REFERENCES
--     in 0071/0074/0076 above (…_organization_id_fkey);
--   · databases fresh-provisioned from a packaged schema.sql carry the
--     drizzle-generated names (…_issued_by_user_id_fk,
--     …_organization_id_organization_id_fk).
-- The definitions are IDENTICAL (verified column-by-column incl. ON DELETE
-- action) — only the names drifted, which makes every future schema diff
-- report phantom drops/creates. Converge on the drizzle names with guarded
-- RENAMEs: metadata-only (no table rewrite, no FK re-validation, no lock
-- beyond a brief ACCESS EXCLUSIVE on the catalog row), idempotent, and a
-- no-op on the fresh-provisioned lineage. Guards are scoped by conrelid —
-- a name-only pg_constraint probe breaks under name recycling (the 0059/0060
-- lesson).

BEGIN;

DO $$
DECLARE m record;
BEGIN
  FOR m IN
    SELECT * FROM (VALUES
      -- 0068/0069 hand-written names → drizzle names (skill_qa_*)
      ('skill_qa_run',           'skill_qa_run_skill_id_fk',            'skill_qa_run_skill_id_skill_id_fk'),
      ('skill_qa_run',           'skill_qa_run_requested_by_fk',        'skill_qa_run_requested_by_user_id_fk'),
      ('skill_qa_check_result',  'skill_qa_check_result_run_id_fk',     'skill_qa_check_result_run_id_skill_qa_run_id_fk'),
      ('skill_qa_check_result',  'skill_qa_check_result_skill_id_fk',   'skill_qa_check_result_skill_id_skill_id_fk'),
      ('skill_qa_certification', 'skill_qa_certification_skill_id_fk',  'skill_qa_certification_skill_id_skill_id_fk'),
      ('skill_qa_certification', 'skill_qa_certification_run_id_fk',    'skill_qa_certification_run_id_skill_qa_run_id_fk'),
      ('skill_qa_certification', 'skill_qa_certification_issued_by_fk', 'skill_qa_certification_issued_by_user_id_fk'),
      ('skill_qa_certification', 'skill_qa_certification_revoked_by_fk','skill_qa_certification_revoked_by_user_id_fk'),
      ('skill_qa_recording',     'skill_qa_recording_run_id_fk',        'skill_qa_recording_run_id_skill_qa_run_id_fk'),
      ('skill_qa_recording',     'skill_qa_recording_skill_id_fk',      'skill_qa_recording_skill_id_skill_id_fk'),
      -- inline-REFERENCES auto-names from 0071/0074/0076 → drizzle names
      ('org_policy_version',     'org_policy_version_organization_id_fkey', 'org_policy_version_organization_id_organization_id_fk'),
      ('org_policy_version',     'org_policy_version_changed_by_fkey',      'org_policy_version_changed_by_user_id_fk'),
      ('job_execution',          'job_execution_organization_id_fkey',      'job_execution_organization_id_organization_id_fk'),
      ('event_outbox',           'event_outbox_organization_id_fkey',       'event_outbox_organization_id_organization_id_fk'),
      ('agent_deployment',       'agent_deployment_owner_user_id_fkey',     'agent_deployment_owner_user_id_user_id_fk')
    ) AS t(tbl, old_name, new_name)
  LOOP
    IF EXISTS (SELECT 1 FROM pg_constraint
               WHERE conname = m.old_name
                 AND conrelid = ('public.' || quote_ident(m.tbl))::regclass)
       AND NOT EXISTS (SELECT 1 FROM pg_constraint
               WHERE conname = m.new_name
                 AND conrelid = ('public.' || quote_ident(m.tbl))::regclass)
    THEN
      EXECUTE format('ALTER TABLE public.%I RENAME CONSTRAINT %I TO %I',
                     m.tbl, m.old_name, m.new_name);
    END IF;
  END LOOP;
END $$;

-- 0071's hand-written CHECK ("action" in (...)) parses to a different internal
-- form than the drizzle-generated one (`= ANY ((ARRAY[..varchar..])::text[])`
-- vs `= ANY (ARRAY[(..varchar)::text, ..])`) — semantically identical, but
-- schema diffs would report it as phantom drift forever. Re-create it in the
-- canonical (bootstrap-dump) form; re-runnable, trivial re-validation.
ALTER TABLE public.org_policy_version DROP CONSTRAINT IF EXISTS org_policy_version_action_check;
ALTER TABLE public.org_policy_version ADD CONSTRAINT org_policy_version_action_check
  CHECK (((action)::text = ANY (ARRAY[('create'::character varying)::text, ('update'::character varying)::text, ('enable'::character varying)::text, ('disable'::character varying)::text, ('delete'::character varying)::text])));

COMMIT;
