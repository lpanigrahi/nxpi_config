-- migrate-1.28.0.sql — schema delta 1.27.0 → 1.28.0 (deep-test campaign DT-A1): 0025, the append-only floor ADR-0037 promised, the frozen epoch-0 anchor, and an activation that outlives its requester.
-- rollback: partly. The two TRIGGERS and their two FUNCTIONS are reversible in
-- one statement each (DROP TRIGGER IF EXISTS admin_audit_log_immutable_trg ON
-- "admin_audit_log"; DROP TRIGGER IF EXISTS
-- audit_chain_head_anchor_immutable_trg ON "audit_chain_head"; DROP FUNCTION
-- IF EXISTS admin_audit_log_immutable(); DROP FUNCTION IF EXISTS
-- audit_chain_head_anchor_immutable();) and reversing them restores exactly
-- the posture this delta finds: an audit log and a chain anchor any session
-- may rewrite. The FOREIGN-KEY half is FORWARD-ONLY once it has fired —
-- restoring ON DELETE CASCADE is one statement, but ALTER COLUMN requested_by
-- SET NOT NULL fails 23502 on precisely the rows this delta preserved (an
-- activation whose requester has since been deleted), and those rows are the
-- evidence. Reverse the triggers if you must; leave the column nullable.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- this delta adds no column, no table and no index, so a pod running the
-- PREVIOUS image names nothing new and keeps serving across the apply. What
-- changes for it is what changes for every image — a write that was silently
-- admitted is refused — and the repository has been insert-only against
-- admin_audit_log since ADR-0055 (pinned by governance-ledger.guard.test.ts),
-- so no shipped image issues one. The one mixed-version note worth having:
-- user deletion still works, because the trigger admits the FK anonymization
-- Postgres performs as SET NULL, and that arm is proven in both directions by
-- src/lib/db/pg/repositories/audit-log-chain.integration.test.ts and
-- audit-log-immutability.integration.test.ts.
--
-- Each source migration of the journaled series under src/lib/db/migrations/pg/
-- gets its own block header below, in journal order. This delta carries exactly
-- one.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0025_audit_append_only_and_activation_evidence.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0025 — the append-only floor at the DATABASE, on every lineage (deep-test
-- campaign DT-A1: findings DT-1-iv-1, DT-1-iv-9, DT-1-iii-8; ADR-0037 LAW 5,
-- ADR-0062, ADR-0110).
--
-- THREE HOLES, ONE FILE, because they are one claim: that this platform's
-- governance trail cannot be edited by the thing it is a trail of.
--
-- 1. LAW 5 WAS NEVER SHIPPED HERE. ADR-0037's append-only trigger was written
--    into the CLOSED legacy series (src/lib/db/pg/migrations/pg/0071), which
--    no packaged bundle and no from-zero journaled database ever runs. Every
--    schema.sql up to and including 1.27.0 therefore installs a database whose
--    admin_audit_log the application role may UPDATE and DELETE, while
--    ADR-0109 and the decision-log DPA note both state that it may not.
-- 2. THE TRUST ROOT WAS A PLAIN ROW. audit_chain_head's '__epoch0' row is the
--    signature the pre-split global chain ended at (0020 / 1.26.0), and every
--    per-organization chain links its first row to it. With no policy, no
--    CHECK and no trigger, moving it re-roots every chain that was verified
--    against it — and the verifier cannot see this, because the anchor is its
--    axiom.
-- 3. AN ACTIVATION DIED WITH ITS REQUESTER. 1.27.0's org_privilege_activation
--    declared requested_by ON DELETE CASCADE, so deleting a user deleted every
--    elevation they had filed, in every tenant; countActivations then reached
--    zero and the ON DELETE RESTRICT that makes an activation EVIDENCE stopped
--    holding its rule down.
--
-- LOCK POSTURE for the operator sizing this: two CREATE FUNCTION statements
-- (no lock on any table), two CREATE TRIGGER statements (ACCESS EXCLUSIVE on
-- admin_audit_log and audit_chain_head for the moment of the catalog write),
-- and one ALTER TABLE on org_privilege_activation that drops and re-adds a
-- foreign key — ACCESS EXCLUSIVE on that table plus a validating scan of it
-- and a reference check against "user". Size it as that scan. SET lock_timeout
-- bounds lock ACQUISITION, not the hold.
--
-- AND "user" IS LOCKED TOO for that window, which the ROLLING-SAFE paragraph
-- above would be dishonest without. Measured with pg_locks on a post-0025
-- database: ADD CONSTRAINT … REFERENCES "user" takes SHARE ROW EXCLUSIVE on
-- the referenced table (writes block, reads do not), but DROP CONSTRAINT takes
-- ACCESS EXCLUSIVE on it — it is dropping the RI triggers that live there —
-- and both halves are sub-commands of ONE ALTER TABLE, so the strongest lock
-- is held until the statement ends. For the length of the validating scan,
-- every session touching "user" waits: sign-in, sign-up, every read of the
-- table. org_privilege_activation is small by construction (elevations are
-- TTL-bounded), so that scan is short — but size that window against YOUR row
-- count before applying at peak.
--
-- RE-RUNNABILITY: every statement is CREATE OR REPLACE, DROP … IF EXISTS,
-- DROP CONSTRAINT IF EXISTS or ALTER COLUMN, so a second apply by hand after a
-- partial failure is a no-op that lands on the same state.
SET lock_timeout = '5s';

-- ── Part A — LAW 5 at the database (ADR-0037) ──────────────────────────────
-- The function is 0071's body VERBATIM, so the legacy and the journaled
-- lineage cannot drift apart. Two properties are load-bearing:
--
--   * THE CARVE-OUT. actor_id / target_user_id / organization_id are declared
--     ON DELETE SET NULL, and PostgreSQL executes that referential action as
--     an implicit UPDATE on the audit rows — so a naive BEFORE UPDATE trigger
--     would make every user and organization deletion fail platform-wide. An
--     UPDATE is admitted ONLY when it is pure anonymization.
--   * THE STRUCTURAL COMPARISON. "Everything else unchanged" is whole-row
--     jsonb minus the three FK columns, never a hand-enumerated column list,
--     so columns added later are covered automatically.
--
-- DECLARED BOUNDARY: TRUNCATE is NOT blocked — row triggers do not fire on it.
-- The control targets row tampering, not a database reset.
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

-- ── Part B — the epoch-0 anchor is frozen (ADR-0062) ───────────────────────
-- ONE row of audit_chain_head is not a head at all: '__epoch0' is the
-- signature the chain was SPLIT at, written once by 1.26.0's seed.sql on a
-- fresh install or by its delta on an upgrade, and never written again. Every
-- other row IS a head and is advanced by the writer on every audit insert, so
-- the guard is a WHEN clause on the row rather than a rule about the table: an
-- ordinary upsert never calls the function at all.
--
-- DECLARED BOUNDARY: INSERT is not covered, and necessarily so — a fresh
-- install receives the anchor from seed.sql, which runs AFTER schema.sql, and
-- a trigger refusing inserts would refuse the anchor's own creation. The
-- unique index audit_chain_head_key already makes a SECOND anchor impossible.
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

-- ── Part C — an activation outlives the requester (ADR-0110) ───────────────
-- The column becomes nullable and its foreign key becomes ON DELETE SET NULL —
-- the posture approved_by has carried since 1.27.0. The row survives and says
-- honestly that the person who filed it is gone, instead of pointing at a user
-- id that resolves to nothing.
--
-- The approved_by <> requested_by CHECK needs no edit: it reads
-- "approved_by IS NULL OR approved_by <> requested_by", so with requested_by
-- NULL the comparison yields NULL, which a CHECK treats as satisfied.
--
-- NOT DONE HERE, stated rather than left to be rediscovered:
-- platform_privilege_activation.user_id keeps ON DELETE CASCADE (that row IS
-- the lateral grant ON that user), and org_privilege_activation.membership_id
-- keeps it too (nulling it would erase the SUBJECT from the evidence, and
-- organization_member cascades from "user", so deleting the member the row is
-- about still takes the row — what survives that is the audit trail Part A
-- makes append-only).
ALTER TABLE org_privilege_activation
  ALTER COLUMN requested_by DROP NOT NULL,
  DROP CONSTRAINT IF EXISTS org_privilege_activation_requested_by_user_id_fk,
  ADD CONSTRAINT org_privilege_activation_requested_by_user_id_fk
    FOREIGN KEY (requested_by) REFERENCES "user" (id) ON DELETE SET NULL;
