-- migrate-1.33.0.sql — schema delta 1.32.0 → 1.33.0: a TWO-MIGRATION bundle, journal order 0031 (DT-AB, the chain's head vouched on every verb; a forged row can be quarantined by the owner) then 0032 (DT-AC, a closed campaign's evidence survives every deletion) — unioned by the controller at the DT-AC merge; each half keeps its own header and rollback below. Apply with psql -1 (ON_ERROR_STOP) so both halves land or neither does; grants.sql carries the quarantine function's revocation.
-- ══ HALF 1 — migration 0031 (DT-AB) ═════════════════════════════════════
-- migrate-1.33.0.sql — schema delta 1.32.0 → 1.33.0 (deep-test campaign round 5, DT-AB): the chain's head is vouched on its THIRD verb, and a row nobody can verify can be quarantined by the OWNER.
-- THIS FILE IS ONE HALF OF A TWO-MIGRATION BUNDLE. Lane B (DT-AB) writes journaled migration 0031, below; lane C (DT-AC) writes 0032, and the controller UNIONS its delta into this same file at the second merge, in journal order (0031 then 0032), exactly as 1.32.0 carries 0029 then 0030. Apply with psql -1 (ON_ERROR_STOP) so every half lands or none does.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- WHAT IT IS FOR, IN TWO PARAGRAPHS.
--
-- (1) A HEAD ROW WAS CHECKED FOR NOTHING BUT A LEAPING ID. 1.31.0 bound every
-- UPDATE of `audit_chain_head` and every DELETE; its own message said the
-- third verb was open ("Inserting a head row under a new chain_key is
-- admitted"). Measured as the application role on a role-split database: ONE
-- INSERT of a head row for a chain that has none — every organization's chain
-- until its first audit write, and 'platform' too on a from-zero install —
-- makes that tenant's next HONEST write link from a value nobody published.
-- The chain then reads "chain broken: N row(s) unreachable from genesis" from
-- its FIRST row onward, for ever, growing with every further honest write,
-- and all four repairs are refused. A head row is now BORN VOUCHED.
--
-- (2) A ROW THE CHAIN CANNOT VERIFY HAD NO REPAIR AT ALL. The database cannot
-- verify an HMAC it does not hold, so a forger holding the application's
-- credential can append a row that fails verification — and after it the
-- tenant's chain read ok:false and the evidence pack exited 1 for that
-- organization on every future run, because DELETE, UPDATE, a re-key and
-- TRUNCATE are all refused. This delta adds the OWNER's repair:
-- `admin_audit_log_quarantine` and the SECURITY DEFINER
-- `audit_quarantine_row(id, reason, verdict)`, which copies the row with the
-- operator, the reason and the verdict and then removes it under the ONE
-- exception the append-only trigger admits — for a row the quarantine table
-- already holds BYTE FOR BYTE. The application role cannot call the function
-- and cannot write the table (grants.sql of this bundle says so), so it can
-- neither perform the repair nor manufacture its precondition.
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- the head refusal refuses a statement no image makes (the writer inserts the
-- audit row and only then seeds the head with that row's own signature, which
-- both images do), and the quarantine is additive — nothing reads the new
-- table but the chain verifier and the evidence pack, both of which treat an
-- empty quarantine exactly as they did before it existed.
--
-- GRANTS ARE NOT SCHEMA: re-run this bundle's `grants.sql` after applying
-- this delta on a role-split deployment. The migration narrows the new
-- table's grants by name-discovery as it creates it, and `grants.sql` is what
-- keeps a later re-run of the blanket GRANT from re-opening it.
--
-- rollback: DROP TRIGGER IF EXISTS audit_chain_head_insert_vouched_trg ON "audit_chain_head"; DROP FUNCTION IF EXISTS audit_chain_head_insert_vouched(); DROP FUNCTION IF EXISTS audit_quarantine_row(uuid, text, text); re-apply 0029's own text for admin_audit_log_immutable(); DROP TABLE IF EXISTS "admin_audit_log_quarantine". WHAT A REVERSE COSTS IS STATED RATHER THAN DISCOVERED. The head half is fully reversible and loses only the refusal: it restores the posture this file found, where ONE INSERT into audit_chain_head by the application's own database credential — for any chain that has no head row, which every organization's chain is until its first audit write, and which 'platform' also is on the from-zero lineage — makes that tenant's next HONEST write link from a value nobody published, after which the chain reads "chain broken: N row(s) unreachable from genesis" from its first row onward for ever and 0025 Part A refuses both repairs. The quarantine half is FORWARD-ONLY once it has fired: dropping the table destroys the only copy of every row an operator has quarantined (the original was deleted under the trigger's one exception, and 0025 Part A refuses re-inserting it), and a chain whose gap those rows explain goes back to reading BROKEN. Reverse the head trigger if you must; leave the quarantine table and re-apply 0029's admin_audit_log_immutable() text only on a database where the quarantine is empty.
SET lock_timeout = '5s';

-- ── WHAT THIS FILE SUPERSEDES, SAID HERE ──────────────────────────────────
-- A LANDED MIGRATION IS NEVER EDITED (lib/guardian/migration-ledger.ts), so
-- the correction to 0025's `admin_audit_log_immutable()` below is a
-- CREATE OR REPLACE from THIS file, and two sentences earlier files state as
-- fact are superseded here rather than in them:
--
--  * 0027 Part E's "Inserting a head row under a new chain_key is admitted;
--    leaping the id is not" — and the door row in
--    `audit-log-chain.integration.test.ts` that declared that door open with
--    0027's header as its reason. Part A below closes it. The seed keeps its
--    door (a head row is still BORN at the genesis while its chain holds
--    nothing, which is what a bundle's `seed.sql` writes) and 0026 keeps the
--    anchor's.
--  * 0025 Part A's "DELETE is not permitted", unconditionally. Part B below
--    adds the ONE exception the repair needs, bounded by a record the
--    application role cannot write.
--
-- ── PART A — A HEAD ROW IS BORN VOUCHED (SR2-b-5) ─────────────────────────
-- SR-b-2's THIRD VERB. 0027 and 0029 bound every head UPDATE (Part C: the id,
-- the key, the genesis, "a signature a row of that chain published", and
-- ADVANCE BY ONE LINK) and every head DELETE (Part D), and an INSERT was
-- checked for NOTHING BUT A LEAPING ID — because the enumeration was written
-- about the verbs an attacker needs on a chain that EXISTS. A chain that does
-- not exist yet needs no UPDATE: the product does the linking.
--
-- MEASURED as the application role (`rolsuper = f`, `rolbypassrls = f`, owner
-- of nothing), two DML statements and nothing else:
--
--   insert into audit_chain_head (id, chain_key, head_signature, updated_at)
--   select coalesce(max(id),0)+1, '<an org with no audit history>',
--          repeat('de',32), now() from audit_chain_head;          -- ADMITTED
--
-- …then the deployment carries on doing its job. The next audit row the
-- PRODUCT writes for that tenant reads the poisoned head, signs it in as its
-- `prev_signature` and advances the head to its own signature — which Part C
-- admits, because the new head IS the chain's newest row and it DOES link
-- from the head it replaces. The honest write completes the attack:
-- `{"ok":false,"reason":"chain broken: 1 row(s) unreachable from genesis"}`
-- from the chain's FIRST row, growing with every further honest write, with
-- all four repairs refused (DELETE the poisoned row, UPDATE its
-- prev_signature, head := '' and DELETE the head row — each measured). On the
-- from-zero lineage `pnpm db:init` leaves `audit_chain_head` EMPTY, so the
-- same statement takes the PLATFORM chain, which every campaign anchor and
-- every pack verdict stands on.
--
-- THE RULE IS PART C'S, ON THE OTHER VERB, and it admits the ONE producer
-- exactly: `insertAuditLog` INSERTS the audit row and only THEN upserts the
-- head, inside one transaction under its own per-chain advisory lock — so the
-- signature a head is born with is always a signature that chain has already
-- published. (The order was verified rather than assumed:
-- `audit-log-repository.pg.ts`'s `insertAuditLog` writes the row, then the
-- `ON CONFLICT` upsert; nothing was reordered here.)
--
-- TWO BIRTHS IT MAY NOT REFUSE, and both are why 0027 declared the door open:
--  * THE GENESIS. A bundle's `seed.sql` ships 'platform' and '__epoch0' at ''
--    before any audit row exists, and `scripts/export-db-artifacts.sh` resets
--    a head to the genesis. Admitted here — while that chain holds NO rows,
--    which is exactly Part C's own genesis clause on the other verb. With
--    rows in it the genesis is not a chain with nothing in it: the next write
--    would link from a value the chain's first row already links from, and
--    two rows sharing a predecessor is a fork the verifier refuses for ever.
--  * THE '__epoch0' ANCHOR, whose head_signature is a copy of the single
--    global head taken at the split — a signature of the LEGACY epoch, not of
--    the '__epoch0' chain, so no clause about "a row of that chain" can be
--    true of it. 0026's `audit_chain_head_anchor_insert_guard` is its rule
--    (it may only be created on a database with no signed history) and stays
--    the whole of it; this trigger's WHEN clause hands the anchor to it
--    untouched.
--
-- A NULL `chain_key` is not this guard's question either: the column is NOT
-- NULL, so such a row is refused by the constraint with 23502 — which is what
-- the PREVIOUS app image's head upsert (pre-0020, no `chain_key` in its
-- VALUES list) receives, and this trigger stands aside so it keeps receiving
-- exactly that rather than a message about vouching.
--
-- NO WHEN CLAUSE FOR THE GENESIS, because the question needs a subquery and a
-- trigger WHEN clause may not contain one; the anchor exemption is a plain
-- column comparison and lives there. The lookup is
-- `admin_audit_log_chain_signature`'s own index (0027 created it for Part C's
-- identical EXISTS), read once per head INSERT — which, because ON CONFLICT
-- fires BEFORE INSERT triggers for the proposed row, means once per audit
-- write, beside the two reads 0027 Part E and Part C already make there.

CREATE OR REPLACE FUNCTION audit_chain_head_insert_vouched() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.head_signature = '' THEN
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

DROP TRIGGER IF EXISTS audit_chain_head_insert_vouched_trg ON "audit_chain_head";--> statement-breakpoint
CREATE TRIGGER audit_chain_head_insert_vouched_trg
  BEFORE INSERT ON "audit_chain_head"
  FOR EACH ROW WHEN (NEW.chain_key IS NOT NULL
                     AND NEW.chain_key IS DISTINCT FROM '__epoch0')
  EXECUTE FUNCTION audit_chain_head_insert_vouched();

-- ── PART B — A ROW NOBODY CAN VERIFY CAN BE QUARANTINED (DT-5-iv-2) ───────
-- THE LIMIT FIRST, because the whole design turns on it: THE DATABASE CANNOT
-- VERIFY AN HMAC IT DOES NOT HOLD. Any row the application role can write, a
-- forger holding that credential can write — measured, one INSERT carrying a
-- 64-hex `event_signature` nobody computed, a `subject_digest` of the
-- attacker's choosing and the tenant's OWN `chain_key`, which satisfies all
-- three of 0029 Part B's predicates and is ACCEPTED. No fourth predicate can
-- close it: the forger reads the head like the writer does, so even
-- "prev_signature must be the current head" is satisfied for free (it was, in
-- the measured statement).
--
-- So the floor guarantees three things instead, and this file owns the third:
--  1. DETECTION — the verifier already refuses the row (its HMAC does not
--     recompute) and reports the chain broken from it. Unchanged.
--  2. NO LAUNDERING — no reader renders a row that fails verification as an
--     event. That half is in the repository and the pack, not here.
--  3. REPAIR BY THE OWNER, NEVER BY THE APPLICATION ROLE — this part.
--
-- Before it there was NO repair: DELETE, UPDATE, a re-key and TRUNCATE are
-- all refused for the application role (measured), so ONE INSERT left the
-- tenant's chain `ok:false` and `packExitCode` 1 FOR EVER, every future
-- quarterly pack naming a break — and "broken" then becomes that tenant's
-- expected state, in which a genuine row edit is indistinguishable from the
-- forgery, which is verbatim the argument 0026's header makes for payload v2.
-- A control any holder of the connection string can destroy beyond recovery
-- is a control the ADRs promise and the deployment does not have.
--
-- WHAT MAKES THE EXCEPTION SAFE, stated rather than assumed. The append-only
-- trigger admits a DELETE only when BOTH hold:
--  * the session names this row in `audit.quarantine` — a custom GUC, which
--    any session may set, so this half signals INTENT and nothing more; and
--  * `admin_audit_log_quarantine` already holds a row with this id whose
--    payload is `to_jsonb(OLD)` EXACTLY — the whole row, byte for byte.
-- The second half is the unforgeable one: the quarantine table is written by
-- this SECURITY DEFINER function alone (owned by the database owner, EXECUTE
-- revoked from PUBLIC, the write half of the table revoked from every
-- non-owner grantee below and in the bundle's `grants.sql`), so a session
-- holding only the application's credential cannot manufacture the
-- precondition — and cannot record a DIFFERENT copy of the row it removes.
-- The OPERATOR PRECONDITION is the standing one this family has had since
-- 0025: a deployment whose application role OWNS these tables has no split to
-- enforce, and the RLS runbook says so.

CREATE TABLE IF NOT EXISTS "admin_audit_log_quarantine" (
  "id" uuid PRIMARY KEY,
  "chain_key" text,
  "prev_signature" text,
  "event_signature" text,
  "created_at" timestamp NOT NULL,
  "row_payload" jsonb NOT NULL,
  "reason" text NOT NULL,
  "verdict" text NOT NULL,
  "quarantined_by" text NOT NULL,
  "quarantined_at" timestamp NOT NULL DEFAULT now()
);--> statement-breakpoint

-- The verifier's read: every quarantined row of ONE chain, so the gap in the
-- linkage can be explained without a scan.
CREATE INDEX IF NOT EXISTS "admin_audit_log_quarantine_chain" ON "admin_audit_log_quarantine" ("chain_key", "created_at");--> statement-breakpoint

-- The row copy is READABLE by the application (the verifier bridges the gap
-- with it and the pack reports it) and WRITABLE by nobody but the owner. The
-- REVOKE is dynamic because a migration does not know the application role's
-- name: `db:init`'s ensureAppRole and the bundle's `grants.sql` both GRANT
-- DML on ALL TABLES and set ALTER DEFAULT PRIVILEGES, so this table is born
-- writable on a role-split deployment and must be narrowed by name. Both of
-- those files carry the same REVOKE now, so a later re-run cannot re-open it.
REVOKE ALL ON TABLE "admin_audit_log_quarantine" FROM PUBLIC;--> statement-breakpoint
DO $$
DECLARE grantee_name text;
BEGIN
  FOR grantee_name IN
    SELECT DISTINCT g.grantee
      FROM information_schema.role_table_grants g
     WHERE g.table_schema = 'public'
       AND g.table_name = 'admin_audit_log_quarantine'
       AND g.grantee <> current_user
       AND g.grantee <> 'PUBLIC'
       AND g.privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE',
                                'REFERENCES', 'TRIGGER')
  LOOP
    EXECUTE format(
      'REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ' ||
      'ON TABLE public.admin_audit_log_quarantine FROM %I', grantee_name);
  END LOOP;
END
$$;--> statement-breakpoint

-- THE OPERATOR'S ONE STATEMENT. SECURITY DEFINER, so it runs as the owner of
-- this function — the database owner on a role-split deployment — and EXECUTE
-- is revoked from PUBLIC below, so holding the application's credential is
-- not enough to call it. `search_path` is pinned and every relation is
-- schema-qualified for the reason 0029 Part A states, and it matters more
-- here than anywhere else in the schema: a SECURITY DEFINER body resolving a
-- relation through the CALLER's temporary schema would run the caller's table
-- as the owner.
--
-- `p_verdict` carries the VERIFIER's own words (the runbook tells the
-- operator to paste them) and defaults to the class, because the database
-- cannot recompute the HMAC and will not pretend it did. `p_reason` is
-- required and non-empty: a quarantine with no reason is an unexplained
-- deletion, which is the act this whole family refuses.
CREATE OR REPLACE FUNCTION audit_quarantine_row(
  p_id uuid,
  p_reason text,
  p_verdict text DEFAULT 'unverified: the chain verifier refused this row'
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  row_payload jsonb;
  row_chain_key text;
  row_prev text;
  row_event text;
  row_created timestamp;
BEGIN
  IF p_reason IS NULL OR btrim(p_reason) = '' THEN
    RAISE EXCEPTION 'audit_quarantine_row: a REASON is required (migration 0031). A row removed from an append-only trail with no reason recorded is an unexplained deletion, which is the act ADR-0037 LAW 5 exists to refuse; the quarantine exists to make the removal itself evidence.';
  END IF;

  SELECT to_jsonb(a), a.chain_key, a.prev_signature, a.event_signature,
         a.created_at
    INTO row_payload, row_chain_key, row_prev, row_event, row_created
    FROM public.admin_audit_log a
   WHERE a.id = p_id;

  IF row_payload IS NULL THEN
    RAISE EXCEPTION 'audit_quarantine_row: no audit row % (migration 0031). Nothing was quarantined and nothing was removed.', p_id;
  END IF;

  INSERT INTO public.admin_audit_log_quarantine
    (id, chain_key, prev_signature, event_signature, created_at, row_payload,
     reason, verdict, quarantined_by)
  VALUES (p_id, row_chain_key, row_prev, row_event, row_created, row_payload,
          p_reason, p_verdict, session_user);

  -- The flag names THIS row and lives for the statement only. It is the
  -- INTENT half; the row above is the half a caller cannot forge.
  PERFORM set_config('audit.quarantine', p_id::text, true);
  DELETE FROM public.admin_audit_log WHERE id = p_id;
  PERFORM set_config('audit.quarantine', '', true);

  RETURN p_id;
END;
$$;--> statement-breakpoint

REVOKE ALL ON FUNCTION audit_quarantine_row(uuid, text, text) FROM PUBLIC;--> statement-breakpoint

-- 0025 Part A, with the ONE exception and nothing else. The UPDATE arm is
-- 0029's text unchanged (the FK-anonymisation carve-out); the DELETE arm now
-- asks whether this exact row has already been copied into the quarantine by
-- the function above, under a session that named it.
CREATE OR REPLACE FUNCTION admin_audit_log_immutable() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF current_setting('audit.quarantine', true) = OLD.id::text
       AND EXISTS (
         SELECT 1 FROM public.admin_audit_log_quarantine q
          WHERE q.id = OLD.id
            AND q.row_payload IS NOT DISTINCT FROM to_jsonb(OLD)
       )
    THEN
      RETURN OLD;
    END IF;
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted. The one exception is audit_quarantine_row(), which copies the row into admin_audit_log_quarantine — operator, reason and verdict — before removing it, and which the application role may not call (migration 0031).';
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

-- ══ HALF 2 — migration 0032 (DT-AC) ═════════════════════════════════════
-- migrate-1.33.0.sql — schema delta 1.32.0 → 1.33.0: lane C's HALF, migration 0032 (DT-AC, round 5) — a closed campaign's evidence survives its REVIEWER's own erasure, no campaign row makes a user undeletable, and the maker's deletion releases the request they filed. THE CONTROLLER UNIONS LANE B's 0031 DELTA (DT-AB) INTO THIS SAME BUNDLE at the second merge, in journal order 0031 then 0032, each half keeping its own header and rollback; this file is lane C's half as it stands in lane C. Apply with psql -1 (ON_ERROR_STOP) so every half lands or none does.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- this delta DROPS six foreign keys, re-issues one trigger function with a
-- widened trigger, and expires the rows already stranded by the half of 0030
-- that this file completes. It adds and drops no column and changes no type,
-- so the PREVIOUS image writes and reads both tables unchanged: it never
-- wrote a reviewer, opener or closer that did not exist, and the keys it
-- relied on were only ever a way for somebody's deletion to move a stamped
-- hash or to be refused outright. What MOVES is what a deletion destroys and
-- what it is refused — which is the finding.
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH. Migration 0030 closed the review item's
-- SUBJECT and DECIDER columns against an account deletion and left the
-- REVIEWER's. `exportPayload` quotes `reviewer_membership_id` on BOTH the
-- campaign and the item, and all four of those keys were ON DELETE SET NULL
-- from `organization_member`, which CASCADEs from `"user"` — so the one
-- person whose DECISIONS a campaign attests made their own certifications
-- unverifiable through `POST /api/auth/delete-user`, a public prefix needing
-- no permission (DT-5-iii-1; measured: `reviewer_membership_id -> NULL`,
-- `evidence_sha` unchanged, so the stamped hash no longer re-derives). The
-- same keys also made an account UNDELETABLE (DT-5-iii-2): `created_by` and
-- `closed_by` are SET NULL from `"user"` and the ordinary lifecycle puts one
-- person in both, so the first SET NULL made the row's `xmin` current and the
-- second forced a re-check of the reviewer key whose parent the same
-- statement had cascaded away — `23503 ... access_review_campaign_reviewer_
-- member_fk`, and the whole `DELETE FROM "user"` rolled back. All six keys
-- are dropped and every value is kept, which is the posture 0030 Part A and
-- 0028 Part A already ratified: the VALUE is what the hash quotes, so the
-- value is what survives, and the export renders a person who no longer has
-- an account BY ID. And the release trigger 0030 added now fires for the
-- MAKER's deletion too (DT-5-iii-3): `requested_by -> NULL` left a dual-
-- control request `pending` that `decideRequest` refuses by name, holding
-- `org_privilege_request_pending_unique` against its subject for ever.
--
-- ROLLBACK: the `-- rollback:` line of the journaled migration is the
-- statement of record and it is honest about the cost — re-adding any of the
-- six keys FAILS 23503 on any campaign whose reviewer, opener or closer has
-- already been erased, so the reverse must first NULL those columns by hand,
-- which moves the `evidence_sha` of every campaign it touches and restores
-- the undeletable account. The trigger half is freely reversible; the rows
-- the sweep clause below has already expired stay expired, exactly as 0028's
-- and 0030's releases are FORWARD-ONLY once they have fired.
-- ══ migration 0032 (DT-AC), as journaled ═══════════════════════════════
-- 0032 — a closed campaign's evidence survives its REVIEWER's own erasure, no campaign row makes a user undeletable, and the maker's deletion releases the request they filed (deep-test campaign round 5, findings DT-5-iii-1, DT-5-iii-2 and DT-5-iii-3; ADR-0110).
-- rollback: ALTER TABLE "access_review_campaign" ADD CONSTRAINT access_review_campaign_reviewer_member_fk FOREIGN KEY (reviewer_membership_id) REFERENCES organization_member (id) ON DELETE SET NULL, ADD CONSTRAINT access_review_campaign_reviewer_org_fk FOREIGN KEY (organization_id, reviewer_membership_id) REFERENCES organization_member (organization_id, id) ON DELETE SET NULL (reviewer_membership_id), ADD CONSTRAINT access_review_campaign_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES "user" (id) ON DELETE SET NULL, ADD CONSTRAINT access_review_campaign_closed_by_user_id_fk FOREIGN KEY (closed_by) REFERENCES "user" (id) ON DELETE SET NULL; the item's two reviewer keys the same way; and the previous release guard + trigger from 0030 re-issued verbatim. EVERY STATEMENT HERE IS REVERSIBLE AS DDL AND REVERSING THE KEYS COSTS MORE THAN IT RESTORES, stated rather than discovered (the SR2-b-3 lesson): re-adding any of the six keys FAILS 23503 on any campaign whose reviewer, opener or closer has already been erased, so the reverse must first NULL those columns by hand — which moves the `evidence_sha` of every campaign it touches and is the tampering this file exists to prevent, performed by an operator to get past an error message. Re-adding the reviewer keys also restores the UNDELETABLE ACCOUNT (23503 on `DELETE FROM "user"`) DT-5-iii-2 measured. The TRIGGER half is freely reversible and reversing it re-opens the pending slot leak; the rows this migration's sweep clause already expired stay expired, which is FORWARD-ONLY exactly as 0028's and 0030's releases are.
SET lock_timeout = '5s';

-- ── THE NUMBER ────────────────────────────────────────────────────────────
-- 0032 is this lane's number by the round-5 register's ruling: lane B (DT-AB)
-- holds 0031 and this file is lane C's. The journal `idx` is what
-- `expect(e.idx).toBe(i)` requires in a branch whose series ends at 0030 —
-- the 0012/idx-11 shape the permission-catalog migration recorded and 0030
-- repeated. The `when` sits 30,000,000 above 0030's — the register asks for
-- at least 30,000 and this is the step the series itself uses (0029 -> 0030),
-- so it is above lane B's declared 20,000 WHICHEVER scale lane B reads it at,
-- and neither entry re-orders at the merge. Until lane B merges, this
-- branch's migration TAGS have a gap at 0031 and
-- `migration-ledger.guard.test.ts`'s contiguity case reds on it, by
-- construction and on this branch alone.
--
-- ── WHAT THIS FILE IS ABOUT ──────────────────────────────────────────────
-- 0030 closed the review item's SUBJECT and DECIDER columns against an
-- account deletion and left the REVIEWER's. Three findings, one class:
--
-- 1. THE REVIEWER'S OWN ERASURE MOVED THE HASH (DT-5-iii-1). `exportPayload`
--    quotes `reviewerMembershipId` at BOTH levels — the campaign's and the
--    item's — and all four of those keys were ON DELETE SET NULL from
--    `organization_member`, which CASCADEs from `"user"`. So the one person
--    whose DECISIONS the campaign attests made their own certifications
--    unverifiable through `POST /api/auth/delete-user`: a PUBLIC prefix in
--    `proxy.ts` that needs no permission at all. Measured on a committed
--    fixture: `reviewer_membership_id -> NULL`, `evidence_sha` unchanged, so
--    the stamped sha no longer re-derives from the export — which the export
--    route's own docblock says "reads as tampered evidence on a campaign
--    nothing is wrong with". 0030's merge headline was "a closed campaign's
--    evidence survives every deletion"; this is the half that made it false.
--
-- 2. AND THE SAME KEYS MADE AN ACCOUNT UNDELETABLE (DT-5-iii-2). The ordinary
--    lifecycle — the `recertification:manage` holder opens a campaign naming
--    their own membership as its reviewer and closes it themselves — wrote a
--    row carrying THREE referential actions onto one tuple: `created_by` SET
--    NULL and `closed_by` SET NULL from `"user"`, `reviewer_membership_id`
--    SET NULL from the membership the same statement cascades away.
--    PostgreSQL skips an FK re-check on an UPDATE whose key columns did not
--    change UNLESS the row's `xmin` is the current transaction
--    (`RI_FKey_fk_upd_check_required`): the first `"user"`-side SET NULL makes
--    it current, the second forces the re-check, and the reviewer key's parent
--    is already gone. Measured: `23503 ... violates foreign key constraint
--    "access_review_campaign_reviewer_member_fk"`, and the WHOLE
--    `DELETE FROM "user"` rolls back — self-service erasure and the admin
--    plugin's `removeUser` alike. An ordinary administrator could not be
--    deleted, with a raw Postgres error and no guidance, and the operator's
--    workarounds are to remove the membership (which moves the sha, finding 1)
--    or to hand-edit the evidence.
--
-- 3. THE REQUEST THE MAKER'S DELETION LEFT UNDECIDABLE (DT-5-iii-3). 0030
--    made `org_privilege_request.requested_by` ON DELETE SET NULL — correctly
--    — and widened neither the release trigger nor anything else to match: its
--    `WHEN` clause read the MEMBERSHIP column alone, so deleting the MAKER (a
--    `roles:assign` holder filing for somebody else, which is the route's own
--    shape) left the row `pending` with a live membership and a NULL maker.
--    `decideRequest` refuses that row by name (`request_requester_unknown`)
--    AHEAD of the expiry branch, no sweep touched the table, and it held
--    `org_privilege_request_pending_unique` for that (membership, role, team)
--    for ever: the subject could never be put up for that role again. Before
--    0030 the row CASCADEd and the slot was freed, so it is a regression of
--    0030's own making, and it is deliberately inducible by anyone who can
--    file a request and then delete their own account.
--
-- ── Part A — the campaign and the item keep their REVIEWER, BY VALUE ──────
-- The posture 0030 Part A took for `user_id`/`decided_by` and 0028 took for
-- `membership_id`, on the last two columns of both payloads that still carried
-- a key: the foreign keys are DROPPED and the uuids are KEPT. SET NULL is
-- wrong for the reason it was wrong there — it keeps the row and STILL moves
-- the hash — and the alternative the round-5 report offered (a
-- `reviewerSnapshot` frozen at close) is a second payload version for every
-- campaign closed after it, which is exactly what 0030 refused when it
-- declined the keyed-digest shape.
--
-- The COMPOSITE tenancy key goes with the single one on each table. It is
-- what stopped one tenant's campaign naming another tenant's member, and the
-- row still carries `organization_id`; the service keeps that premise where
-- it can be answered with a message rather than a 23503 the caller cannot
-- read (`campaignService.create` refuses a reviewer membership that is not
-- this org's with a 404, and `decide` fails closed through
-- `ReviewerMismatchError` when the membership cannot be resolved at all).
ALTER TABLE "access_review_campaign"
  DROP CONSTRAINT IF EXISTS access_review_campaign_reviewer_member_fk;

ALTER TABLE "access_review_campaign"
  DROP CONSTRAINT IF EXISTS access_review_campaign_reviewer_org_fk;

ALTER TABLE "access_review_item"
  DROP CONSTRAINT IF EXISTS access_review_item_reviewer_member_fk;

ALTER TABLE "access_review_item"
  DROP CONSTRAINT IF EXISTS access_review_item_reviewer_org_fk;

-- ── Part B — and the campaign's OPENER and CLOSER, by value too ──────────
-- `created_by` and `closed_by` are OUTSIDE both export payloads, so nothing
-- about a hash requires this. What requires it is DT-5-iii-2: they were the
-- pair whose two SET NULLs made the row's `xmin` current and forced the
-- re-check that refused the author's own deletion. Dropping the reviewer keys
-- alone would close the measured 23503, and it would leave the mechanism
-- standing for the next key anyone adds to this table — an evidence row must
-- not be able to decide who can be erased. The values are kept for the reason
-- `org_role_eligibility.created_by` is a bare uuid: provenance that survives
-- the author's deletion is worth more here than referential tidiness, and the
-- console renders an opener who no longer has an account BY ID.
ALTER TABLE "access_review_campaign"
  DROP CONSTRAINT IF EXISTS access_review_campaign_created_by_user_id_fk;

ALTER TABLE "access_review_campaign"
  DROP CONSTRAINT IF EXISTS access_review_campaign_closed_by_user_id_fk;

-- ── Part C — the release fires for the MAKER's deletion too ──────────────
-- 0030's own Part C states this harm verbatim for the other column: a row
-- left pending "would still be a door the inbox offers a checker". The WHEN
-- clause gains the second cause and the body distinguishes them:
--
--   * `released_membership_id` is stamped for the MEMBERSHIP cause ALONE. It
--     names WHOSE request this was once the subject reference is gone, and a
--     row whose subject is still standing must not claim a membership was
--     released;
--   * a PENDING row is EXPIRED for EITHER cause, because neither can ever be
--     decided: `decideRequest` refuses a released membership
--     (`request_membership_released`) and an unknown maker
--     (`request_requester_unknown`) by name, both ahead of the pending test.
--     This is the floor under those refusals rather than a duplicate of them,
--     and it is the half a service cannot have: the foreign key's implicit
--     UPDATE fires on a hand-run `DELETE FROM "user"` no service ever sees;
--   * and it frees `org_privilege_request_pending_unique`, whose partial
--     predicate is `WHERE status = 'pending'`, so the subject can be put up
--     for that role again.
--
-- A DECIDED row is untouched by either cause, which is the whole point of
-- 0030: the record of who asked and who signed it off outlives both accounts.
--
-- `SET search_path = pg_catalog, public` and no unqualified relation name in
-- the body: the rule 0029 states for every guard function from 0029 on. This
-- body reads no relation at all, which is the strongest form of it.
CREATE OR REPLACE FUNCTION org_privilege_request_release_guard() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF OLD.membership_id IS NOT NULL AND NEW.membership_id IS NULL THEN
    NEW.released_membership_id := OLD.membership_id;
  END IF;
  IF NEW.status = 'pending' THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS org_privilege_request_release_trg ON "org_privilege_request";
CREATE TRIGGER org_privilege_request_release_trg
  BEFORE UPDATE ON "org_privilege_request"
  FOR EACH ROW WHEN ((OLD.membership_id IS NOT NULL AND NEW.membership_id IS NULL)
                  OR (OLD.requested_by IS NOT NULL AND NEW.requested_by IS NULL))
  EXECUTE FUNCTION org_privilege_request_release_guard();

-- ── Part D — the rows that are ALREADY orphaned ──────────────────────────
-- The trigger is the floor from here on and it is retroactive about nothing.
-- A deployment that ran 0030 and lost a maker before this file holds a
-- `pending` row with a NULL requester, holding the pending unique index
-- against its subject for ever. One UPDATE collects them, and it is written
-- as the trigger would have written it: the status moves and
-- `released_membership_id` is not touched, because these rows still have
-- their subject. The daily sweep does the same thing from the other side for
-- anything this statement raced (`sweepExpiredPrivileges`), which is the
-- writer that can see a row no service ever touches again.
UPDATE "org_privilege_request"
   SET status = 'expired'
 WHERE status = 'pending'
   AND requested_by IS NULL;
