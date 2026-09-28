-- migrate-1.34.0.sql — schema delta 1.33.0 → 1.34.0 (deep-test campaign round 6, DT-AG; finding DT-6-iv-1): an ORGANIZATION chain is born vouched or not at all. Source migration 0033 (journaled migration 0033_org_chain_born_vouched.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- 1.33.0 made a head row of `audit_chain_head` BORN VOUCHED on its INSERT: at
-- the genesis ('') while its chain held nothing, or naming a signature a row
-- of that chain published. Measured as the application role on a from-zero
-- database (round 6, probe P1): the genesis half admitted '' for ANY row-less
-- chain, and every organization's chain is row-less until its first audit
-- write — so ONE INSERT of a genesis head for a fresh tenant is accepted, that
-- tenant's first honest audit row then links from '' rather than from the
-- '__epoch0' anchor, `verify-audit-chain --chain <org>` reports BROKEN at that
-- row, and nothing repairs it (the append-only floor refuses both edits; the
-- quarantine removes rows, it does not re-link). 1.34.0 replaces the ONE
-- function body: a genesis head is admitted for `chain_key = 'platform'` only
-- — the shape this bundle's own seed.sql writes — and there still only while
-- that chain holds no rows (1.33.0's own clause, unchanged); every other chain
-- is born naming a row's signature or not at all. The trigger, its WHEN
-- clause and the search_path pin are 1.33.0's, untouched. No table, column,
-- policy or grant moves; seed.sql, grants.sql and the app's own head writes
-- are unchanged paths.
--
-- ROLLBACK: re-apply 1.33.0's own text for audit_chain_head_insert_vouched()
-- (the CREATE OR REPLACE FUNCTION statement in migrate-1.33.0.sql). What that
-- costs is stated above rather than discovered: it restores the one-statement
-- door this file closes.
--
-- Apply with psql -1 (ON_ERROR_STOP) so the statement lands or does not.

SET lock_timeout = '5s';

CREATE OR REPLACE FUNCTION audit_chain_head_insert_vouched() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.head_signature = '' THEN
    IF NEW.chain_key <> 'platform' THEN
      RAISE EXCEPTION 'audit_chain_head: the chain % is BORN VOUCHED or not at all (ADR-0062, migration 0033): only the ''platform'' chain may be born at the genesis, and only while it holds no rows — the packaged seed''s one shape. An organization''s chain begins with its FIRST audit row, whose writer seeds the head with that row''s own signature (migration 0031); a genesis head planted before it would make that first honest row link from a value the ''__epoch0'' anchor never published, and the chain would read "unreachable from genesis" from its first row onward for ever (round 6, DT-6-iv-1).', NEW.chain_key;
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.admin_audit_log WHERE chain_key = NEW.chain_key
    ) THEN
      RAISE EXCEPTION 'audit_chain_head: a head row for chain % may be BORN at the genesis only while that chain holds NO rows (ADR-0062, migration 0031). With rows in it the genesis is not a chain with nothing in it: the next audit row written here would link from the genesis, which the first row of this chain already links from, and two rows sharing a predecessor is a fork verifyAuditChain refuses for ever. A bundle''s seed.sql writes this row before any audit row exists; export-db-artifacts.sh resets it under session_replication_role = replica.', NEW.chain_key;
    END IF;
  ELSIF NOT EXISTS (
    SELECT 1 FROM public.admin_audit_log
     WHERE chain_key = NEW.chain_key
       AND event_signature = NEW.head_signature
  ) THEN
    RAISE EXCEPTION 'audit_chain_head: a head row for chain % is BORN VOUCHED (ADR-0062, migration 0031): its head_signature must be the genesis or a signature a row of that chain published, and no row of that chain published this one. The next audit row written to this chain links from this value and signs it into history, so a head nobody vouches for breaks the chain from its FIRST row onward — permanently, because 0025 Part A refuses both repairs. The one producer inserts the audit row and only then seeds the head with that row''s own signature. This is 0027 Part C''s rule on the INSERT verb, which 0027''s header declared open (SR2-b-5).', NEW.chain_key;
  END IF;

  RETURN NEW;
END;
$$;
