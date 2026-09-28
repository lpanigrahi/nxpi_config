-- migrate-1.30.0.sql — schema delta 1.29.0 → 1.30.0 (deep-test campaign round 2, DT-L): 0026, the audit chain survives the erasure the schema is declared to perform, and the epoch-0 anchor may only be created before there is history.
-- rollback: both halves are reversible. ALTER TABLE "admin_audit_log" DROP
-- COLUMN IF EXISTS "subject_digest"; DROP TRIGGER IF EXISTS
-- audit_chain_head_anchor_insert_trg ON "audit_chain_head"; DROP FUNCTION IF
-- EXISTS audit_chain_head_anchor_insert_guard(); — and reversing them restores
-- exactly the posture this delta finds: an audit row whose signature depends
-- on three columns the schema may erase, and an anchor any session may create
-- at any time. WHAT A REVERSE COSTS IS STATED RATHER THAN DISCOVERED: every
-- audit row written while this delta was applied signs a payload that includes
-- `subject_digest`, and an image older than it recomputes that row under the
-- old payload and reports `content tampered or signature mismatch`. Dropping
-- the COLUMN destroys the only value under which those rows verify — so
-- reverse the trigger if you must; leave the column.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- the column is ADDITIVE and NULLABLE, so a pod running the previous image
-- names nothing new, writes rows exactly as before (they carry a NULL
-- `subject_digest`, which is precisely the marker meaning "signed under the
-- old payload") and keeps serving across the apply. The trigger fires on one
-- INSERT nobody makes: the application's chain-head upsert can never name
-- '__epoch0' (its key is an organization id or 'platform'), and a bundle's
-- seed.sql inserts the anchor on a fresh database with no audit rows at all.
-- What the previous image CANNOT do is VERIFY a row written by the new one —
-- `scripts/verify-audit-chain.ts` and the evidence pack from an older image
-- read a new row's signature under the old payload and call it broken. That is
-- a property of the tool, not of the database, and image rollback is already
-- bounded at 0016/1.26.0 (ADR-0109 §rollback).
--
-- Each source migration of the journaled series under src/lib/db/migrations/pg/
-- gets its own block header below, in journal order. This delta carries exactly
-- one, and its statements are 0026's own, byte for byte.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0026_audit_subject_digest_and_anchor_insert.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0026 — the chain survives erasure; the anchor is created once, before there
-- is history (deep-test campaign round 2: findings DT-2-iv-1, DT-2-iv-6;
-- ADR-0037 LAW 5, ADR-0062, ADR-0109, ADR-0110).
--
-- 1. AN ORDINARY USER DELETION BROKE EVERY CHAIN THE USER HAD ACTED IN.
--    `actor_id`, `target_user_id` and `organization_id` were inside the signed
--    audit payload AND are declared ON DELETE SET NULL, which PostgreSQL runs
--    as the implicit UPDATE 1.28.0's append-only trigger deliberately admits.
--    So a supported, authorised, audited erasure left the row in place with a
--    signature that no longer recomputes, the verifier called the whole chain
--    'content tampered or signature mismatch', 1.28.0 refused both repairs
--    (the row can be neither re-signed nor removed), and the evidence pack
--    exits 1 for every organization from then on. Worst of all it made a REAL
--    row edit indistinguishable from housekeeping.
--
--    `subject_digest` is payload v2's answer: a row written from here on signs
--    the old payload MINUS those three ids PLUS one keyed, domain-separated
--    HMAC component PER id (chain secret, tagged by column), computed at INSERT
--    by the writer that signs and verified per column — so after an erasure the
--    verifier can name WHICH column stopped re-deriving and classify the row as
--    anonymised rather than tampered. The columns keep their
--    evidential value; the SIGNATURE stops depending on values the schema is
--    allowed to rewrite. Keyed rather than hashed, so an erased identifier is
--    not recoverable from the row. NULLABLE and not backfilled: NULL IS the
--    statement "this row was signed under the old payload", and such a row
--    keeps verifying exactly as before.
--
-- 2. THE ANCHOR'S OPEN INSERT WAS NOT CONTAINED. 1.28.0's boundary argued that
--    leaving INSERT uncovered was safe because a forged anchor would re-root
--    only chains cut after the forgery. Measured in round 2: the verifier reads
--    the anchor as the genesis at VERIFY time, so an anchor inserted after the
--    fact re-roots every existing chain — one plain INSERT, inside the app
--    role's own grant, no RLS on that table and no trigger to suspend, turning
--    every chain into 'chain broken: N row(s) unreachable from genesis',
--    irreversibly, because 1.28.0 then freezes the row it just created. The
--    containment that paragraph wanted is the trigger below: an anchor may be
--    created only on a database with NO signed audit history, which is exactly
--    the fresh-install case the boundary exists for (seed.sql runs before any
--    audit row).
SET lock_timeout = '5s';

ALTER TABLE "admin_audit_log" ADD COLUMN IF NOT EXISTS "subject_digest" text;

CREATE OR REPLACE FUNCTION audit_chain_head_anchor_insert_guard() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  signed_rows bigint;
BEGIN
  SELECT count(*) INTO signed_rows FROM admin_audit_log WHERE event_signature IS NOT NULL;
  IF signed_rows > 0 THEN
    RAISE EXCEPTION 'audit_chain_head: the % anchor may only be created on a database with no signed audit history (ADR-0062, migration 0026): % signed row(s) already exist. The verifier reads this row as the genesis at VERIFY time, so an anchor inserted now re-roots every chain that was verified without it.', NEW.chain_key, signed_rows;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS audit_chain_head_anchor_insert_trg ON "audit_chain_head";
CREATE TRIGGER audit_chain_head_anchor_insert_trg
  BEFORE INSERT ON "audit_chain_head"
  FOR EACH ROW WHEN (NEW.chain_key = '__epoch0')
  EXECUTE FUNCTION audit_chain_head_anchor_insert_guard();
