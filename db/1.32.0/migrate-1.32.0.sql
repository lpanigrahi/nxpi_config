-- migrate-1.32.0.sql — schema delta 1.31.0 → 1.32.0: a TWO-MIGRATION bundle, journal order 0029 (DT-X, the chain admits only what it can verify under the app role's own search_path) then 0030 (DT-Y, a closed campaign's evidence survives every deletion) — unioned by the controller at the DT-Y merge; each half keeps its own header and rollback below. Apply with psql -1 (ON_ERROR_STOP) so both halves land or neither does.
-- ══ HALF 1 — migration 0029 (DT-X) ══════════════════════════════════════
-- migrate-1.32.0.sql — schema delta 1.31.0 → 1.32.0 (deep-test campaign round 4, DT-X): a guard resolves its own names, and the chain admits only what it can verify.
-- THIS FILE IS ONE HALF OF A TWO-MIGRATION BUNDLE. Lane B (DT-X) writes journaled migration 0029, below; lane C (DT-Y) writes 0030, and the controller UNIONS its delta into this same file at the second merge, in journal order (0029 then 0030), exactly as 1.31.0 carries 0027 then 0028. Apply with psql -1 (ON_ERROR_STOP) so every half lands or none does.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH. PostgreSQL searches the session's own
-- temporary schema for RELATIONS before the search path — before pg_catalog,
-- unless pg_temp is explicitly listed — so a trigger function whose body names
-- `admin_audit_log` unqualified asks its question of whatever table the
-- CALLING session has created. Two `CREATE TEMP TABLE` statements, a privilege
-- PostgreSQL grants to PUBLIC, needing no ownership, no DDL on any real object
-- and no `session_replication_role`, were measured admitting four of the five
-- doors migrations 0026 and 0027 exist for — a head moved to a value no row
-- published, the DELETE of a live chain's head, an `__epoch0` anchor
-- manufactured on a database with signed history, and a head row claiming
-- id 2147483647 (after which every audit write in the deployment dies 22003) —
-- with the schema sentinels, the behavioural self-test and `db:drift-report`
-- all reporting the floor intact. Every trigger function the journaled series
-- defines is re-issued here with `SET search_path = pg_catalog, public` and
-- `public.`-qualified relation names; the qualification is the half that
-- closes the relation lookup.
--
-- AND TWO COLUMNS BESIDE THE SIGNATURE. 0027 bound the audit append on
-- `event_signature IS NULL` alone. A row that omits `subject_digest` chooses
-- which payload version the verifier checks it against, and a row whose
-- `chain_key` names no chain any reader verifies renders in a tenant's trail,
-- its export and its evidence pack while every chain the pack verifies reads
-- ok. Both are refused here, and a head may now only ADVANCE BY ONE LINK.
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- every refusal added here refuses a statement no image makes. The
-- application's only audit INSERT has computed `subject_digest` since 0026 and
-- has written `chainKeyFor(organization_id)` since 0020 (both images do), and
-- its head upsert advances each chain to the row it has just written inside
-- the same transaction (both images do), which is one link. A pod running the
-- previous image keeps working across the apply.
--
-- IT SUPERSEDES ONE SENTENCE OF `migrate-1.31.0.sql`'s own header (SR2-b-3).
-- 1.31.0's half 2 says "EVERY STATEMENT HERE IS REVERSIBLE AS DDL" of
-- migration 0028 and names two costs. There is a THIRD: after two offboardings
-- of members holding the same (organization, role, team) eligibility, two rows
-- differ only in `released_membership_id`, and 0028's own five-column
-- `scope_unique` reversal then raises 23505. The ALTER rolls back whole, so
-- nothing is half-reversed — but that half of 0028 is FORWARD-ONLY once a
-- second release has fired, exactly as its `membership_id` NOT NULL is. Drop
-- the released rows or keep the six-column key.
--
-- ══ HALF 1 — migration 0029 (DT-X) ══════════════════════════════════════
SET lock_timeout = '5s';

-- ── WHAT THIS FILE SUPERSEDES, SAID HERE ──────────────────────────────────
-- A LANDED MIGRATION IS NEVER EDITED (lib/guardian/migration-ledger.ts), so
-- everything below that corrects an object of 0007, 0025, 0026, 0027 or 0028
-- is a CREATE OR REPLACE from THIS file. Three sentences those files state as
-- fact are superseded here rather than in them:
--
--  * 0027 Part C's "a signature a row of that chain published" is not a
--    statement about CONTENT. The database cannot check a row's HMAC, so that
--    guard bounds a denial; it was measured admitting a head move to a row the
--    attacker had just forged (DT-4-iv-1). Part C below adds the clause that
--    makes the bound structural: the head may only ADVANCE BY ONE LINK.
--  * 0026's "IT COUNTS SIGNED ROWS" and 0027's whole enumeration reason about
--    verbs, columns and ownership. They do not reason about WHERE THE NAMES
--    INSIDE THE FUNCTION RESOLVE, which is what DT-4-iv-2 measured.
--  * 0028's `-- rollback:` header says "EVERY STATEMENT HERE IS REVERSIBLE AS
--    DDL" and names two costs. THE THIRD COST is not named there (SR2-b-3),
--    and it fires on the most ordinary state that file creates: after two
--    offboardings of members holding the same (org, role, team) eligibility,
--    two rows differ only in `released_membership_id`, and the header's own
--    five-column `scope_unique` reversal then raises 23505 — the ALTER rolls
--    back whole, so nothing is half-reversed, and that half of 0028 is
--    FORWARD-ONLY once a second release has fired, exactly as its
--    `membership_id` NOT NULL is. 0028 is frozen; this is where the sentence
--    lives, beside the packaged `migrate-1.31.0.sql` header and
--    docs/security/authz-program/deep-test/.
--
-- ── PART A — pg_temp IS SEARCHED BEFORE public, FOR RELATIONS (DT-4-iv-2) ──
-- Measured as the application role on the ROLE-SPLIT lineage (`rolsuper = f`,
-- `rolbypassrls = f`, owner of nothing, TRUNCATE denied on both audit tables,
-- CREATE on the database denied): with no shadow all four doors 0026/0027
-- declare REFUSED; after
--
--   create temp table admin_audit_log  (id uuid, chain_key text, …);
--   create temp table audit_chain_head (id integer, chain_key text, …);
--
-- — two statements needing no ownership, no DDL on any real object and no
-- `session_replication_role` — a head moved to an unpublished value was
-- ACCEPTED, the DELETE of a live chain's head was ACCEPTED, an `__epoch0`
-- anchor was manufactured on a database with signed history (which 0026 exists
-- to make impossible, and which 0025 Part B then freezes against repair), and
-- a head row claiming id 2147483647 was ACCEPTED — after which EVERY audit
-- write in the deployment dies 22003. `findMissingSchemaSentinels` reported
-- 0 missing of 131, the behavioural self-test 0 failures and `db:drift-report`
-- "✔ no drift" throughout, because every one of them describes an OBJECT and
-- this attack changes no object.
--
-- TWO HALVES, AND THE SECOND IS THE LOAD-BEARING ONE FOR RELATIONS.
-- `SET search_path` is stored in `proconfig` and applied for the duration of
-- the call, so it makes FUNCTION, OPERATOR and TYPE lookups
-- attacker-independent. It does NOT by itself close the relation lookup:
-- PostgreSQL searches the session's temporary schema FIRST, before
-- `pg_catalog`, unless `pg_temp` is explicitly listed in the path — so
-- `SET search_path = public` (which 0007's two functions already carried) is
-- no defence at all. What closes the relation lookup is the `public.`
-- qualification on every relation name in every body. Both are applied here,
-- and `audit-guard-functions.test.ts` refuses either omission on the LAST
-- definition of every trigger function the journaled series defines.
--
-- THE DIGEST CONSEQUENCE IS FAVOURABLE AND DELIBERATE: `SET` lives in
-- `proconfig`, so schema-qualifying the BODY is what re-derives the pinned
-- digests — the two land in one migration so no database carries one half.
--
-- WHY EVERY TRIGGER FUNCTION AND NOT ONLY THE AUDIT FAMILY (SR2-b-2): the
-- pinned list was two tables wide by its own assertion, so 0028's
-- `org_role_eligibility_release_guard` had a presence probe and no body digest
-- — and replacing that body turns every ordinary offboarding into an org-wide,
-- never-expiring elevation rule. 0007's two generation bumpers are the same
-- kind of object one plane over: shadow `organization` in `pg_temp` and the
-- bump lands in the attacker's table, so every authorization cache in the
-- deployment keeps serving the permissions a revoke has already taken away.

CREATE OR REPLACE FUNCTION admin_audit_log_immutable() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
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

CREATE OR REPLACE FUNCTION audit_chain_head_anchor_immutable() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  RAISE EXCEPTION 'audit_chain_head: the % anchor is frozen (ADR-0062): % is not permitted. It is the signature every per-organization chain is rooted in, so moving it re-roots chains that were verified against it.', OLD.chain_key, TG_OP;
END;
$$;

CREATE OR REPLACE FUNCTION audit_chain_head_anchor_insert_guard() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
  signed_rows bigint;
BEGIN
  SELECT count(*) INTO signed_rows FROM public.admin_audit_log WHERE event_signature IS NOT NULL;
  IF signed_rows > 0 THEN
    RAISE EXCEPTION 'audit_chain_head: the % anchor may only be created on a database with no signed audit history (ADR-0062, migration 0026): % signed row(s) already exist. The verifier reads this row as the genesis at VERIFY time, so an anchor inserted now re-roots every chain that was verified without it.', NEW.chain_key, signed_rows;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION audit_chain_head_retained() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.admin_audit_log WHERE chain_key = OLD.chain_key
  ) THEN
    RAISE EXCEPTION 'audit_chain_head: the head of chain % may not be DELETED while that chain still holds rows (ADR-0062, migration 0027). Without its head the next audit row written to this chain re-seeds from the anchor, so the chain forks at its first row — the same permanent break a rewritten head causes, and 0025 Part A refuses both repairs. A head row whose chain holds no rows may still be removed.', OLD.chain_key;
  END IF;

  RETURN OLD;
END;
$$;

CREATE OR REPLACE FUNCTION audit_chain_head_id_assigned() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE max_id bigint;
BEGIN
  SELECT MAX(id)::bigint INTO max_id FROM public.audit_chain_head;

  IF NEW.id::bigint > COALESCE(max_id, 0) + 1 THEN
    RAISE EXCEPTION 'audit_chain_head: a head row''s id is ASSIGNED, not chosen (ADR-0062, migration 0027): id % is beyond the next one (%). The audit writer takes the next head id as MAX(id) + 1 inside its own upsert, and PostgreSQL evaluates that before it detects the conflict — so a head row claiming an id near the integer ceiling stops EVERY audit write in this deployment with 22003, for every organization, while each caller swallows the failure and verifyAuditChain still answers ok over the rows that remain. Inserting a head row under a new chain_key is admitted; leaping the id is not.', NEW.id, COALESCE(max_id, 0) + 1;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION org_role_eligibility_release_guard() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  NEW.released_membership_id := OLD.membership_id;
  -- A released rule can mint nothing: `request` refuses a lapsed rule before
  -- it ever asks who the subject is, so this is the floor under the service's
  -- own refusal rather than a duplicate of it. An END already in the past is
  -- left alone — moving it would rewrite a lapse somebody else owns.
  IF NEW.expires_at IS NULL OR NEW.expires_at > now() THEN
    NEW.expires_at := now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION authz_bump_generation() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE org uuid;
BEGIN
  org := COALESCE(NEW.organization_id, OLD.organization_id);
  UPDATE public."organization" SET authz_generation = authz_generation + 1 WHERE id = org;
  RETURN NULL;
END
$$;

CREATE OR REPLACE FUNCTION authz_bump_generation_via_role() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE org uuid;
BEGIN
  IF TG_TABLE_NAME = 'org_permission_group_item' THEN
    SELECT organization_id INTO org FROM public.org_permission_group
      WHERE id = COALESCE(NEW.group_id, OLD.group_id);
  ELSE
    SELECT organization_id INTO org FROM public.org_role
      WHERE id = COALESCE(NEW.role_id, OLD.role_id);
  END IF;
  UPDATE public."organization" SET authz_generation = authz_generation + 1 WHERE id = org;
  RETURN NULL;
END
$$;

-- ── PART B — AN APPENDED ROW IS SIGNED, DIGESTED AND FILED (DT-4-iv-1, SR2-b-1)
-- 0027 Part B bound the append on ONE predicate, `event_signature IS NULL`,
-- and its own comment said so: "only a row arriving with no signature reaches
-- the function". Two columns beside it were left free, and each is a complete
-- forgery on its own — measured as the application role, one INSERT each:
--
--  * `subject_digest` NULL. The verifier tells payload v1 from payload v2 BY
--    THE COLUMN, "because the column IS the difference and a row cannot lie
--    about carrying one" — a row CAN lie about carrying one, by not carrying
--    it. A v1-shaped row with `actor_id` NULL then fails its v1 recompute,
--    `erasureCouldExplain` classifies the failure as ANONYMISED, and the chain
--    answers `{"ok":true,"verified":4,"anonymised":1}` with the CLI exiting 0
--    and the evidence pack calling the chain intact.
--  * `chain_key` free text. Evidence is selected by `organization_id`;
--    integrity is asserted per `chain_key`; nothing said the two must agree.
--    A row carrying the victim's `organization_id` and a chain key nobody
--    names renders in the tenant's trail, in the streamed export and in the
--    pack's cc6.2/identity-audit.jsonl while every chain the pack verifies
--    reads ok. 0025 Part A then refuses both repairs, so it is permanent.
--
-- The rule for `chain_key` is `chainKeyFor` expressed in SQL — it is what the
-- ONE producer already writes (`audit-log-repository.pg.ts`), so it needs no
-- carve-out for anything the application does. It needs none for legacy rows
-- either: this trigger fires on INSERT alone, and pre-split rows are HISTORY.
-- A fixture that must create a legacy-shaped row writes it the way
-- `scripts/export-db-artifacts.sh` does, under
-- `session_replication_role = replica`, which suspends this trigger as it
-- suspends 0025's.
--
-- THE COMPARISON IS EXACT, not case-folded: `organization_id::text` is
-- PostgreSQL's canonical lowercase uuid rendering and `chainKeyFor` passes
-- through the id the row itself carries, so the two agree by construction —
-- and a reader that folded case would admit two spellings of one chain.
CREATE OR REPLACE FUNCTION admin_audit_log_signed_append() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.event_signature IS NULL THEN
    RAISE EXCEPTION 'admin_audit_log is append-only AND signed (ADR-0037, ADR-0062, migration 0027): an INSERT with event_signature NULL is refused. Every row this application appends is signed by insertAuditLog under the chain head; a row with no signature is covered by no chain check, renders in the trail and the evidence pack as though it were evidence, and 0025 Part A then refuses to remove it. Rows written before the chain existed keep their NULL and are read exactly as before.';
  END IF;

  IF NEW.subject_digest IS NULL THEN
    RAISE EXCEPTION 'admin_audit_log is append-only AND signed (ADR-0062, migration 0029): an INSERT with subject_digest NULL is refused. The verifier reads a row with no digest as a payload-v1 row and recomputes it under v1, so a row that simply omits this column chooses which payload the verifier checks it against — and a v1 mismatch whose actor_id or target_user_id is NULL is classified anonymised rather than tampered. insertAuditLog has computed this value for every row since migration 0026. Rows written before 0026 keep their NULL and are read exactly as before.';
  END IF;

  IF NEW.chain_key IS DISTINCT FROM COALESCE(NEW.organization_id::text, 'platform') THEN
    RAISE EXCEPTION 'admin_audit_log is append-only AND signed (ADR-0062, migration 0029): chain_key % does not name this row''s own chain (%). Evidence is selected by organization_id and integrity is asserted per chain_key, so a row of an organization filed under a chain no reader verifies renders in that tenant''s trail, its export and its evidence pack while every chain the pack verifies reads ok. The one producer writes chainKeyFor(organization_id); a legacy-shaped row is written under session_replication_role = replica, as scripts/export-db-artifacts.sh does.', COALESCE(NEW.chain_key, 'NULL'), COALESCE(NEW.organization_id::text, 'platform');
  END IF;

  RETURN NEW;
END;
$$;

-- The WHEN clause widens with the function: an ordinary audit INSERT still
-- never calls it at all, and every row that is unsigned, undigested or misfiled
-- now does. DROP-then-CREATE because a WHEN clause is part of the trigger's
-- DEFINITION and CREATE OR REPLACE TRIGGER is not available on this floor.
DROP TRIGGER IF EXISTS admin_audit_log_signed_append_trg ON "admin_audit_log";
CREATE TRIGGER admin_audit_log_signed_append_trg
  BEFORE INSERT ON "admin_audit_log"
  FOR EACH ROW WHEN (NEW.event_signature IS NULL
                     OR NEW.subject_digest IS NULL
                     OR NEW.chain_key IS DISTINCT FROM COALESCE(NEW.organization_id::text, 'platform'))
  EXECUTE FUNCTION admin_audit_log_signed_append();

-- ── PART C — A HEAD ADVANCES BY ONE LINK (DT-4-iv-1) ──────────────────────
-- 0027 Part C asks whether a row of this chain PUBLISHED the value and whether
-- any row LINKS FROM it. Both were satisfied by the forged row, because the
-- forgery published the value and the forgery was the tail. The clause added
-- here is the one an attacker cannot satisfy without the chain's own history:
-- the row the head names must link FROM the head it is replacing. That is
-- exactly what the writer does — it inserts a row whose `prev_signature` is
-- the head it read, then advances the head to that row — so the honest write
-- is admitted unchanged, and a head can no longer jump to any other published
-- signature of its chain.
--
-- WHY NOT "the row with the greatest created_at / id", which is how the
-- register phrased the same requirement: `created_at` is set by the
-- APPLICATION (the writer signs the value it chose), so two replicas with
-- skewed clocks would make an honest write non-maximal and this guard would
-- refuse it — an audit outage for every organization, which is the harm door 5
-- describes. And `admin_audit_log.id` is a random uuid, so it orders nothing.
-- The chain's own linkage is the order the chain defines, and "the row that
-- links from the current head and that nothing links from" IS its newest row.
CREATE OR REPLACE FUNCTION audit_chain_head_vouched() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'audit_chain_head: id is the other half of a head row''s identity and is never changed (ADR-0062, migration 0027): the head of chain % may not move from id % to id %. The audit writer assigns the next head id as MAX(id) + 1 inside its own upsert and PostgreSQL evaluates that BEFORE it detects the conflict, so an id moved out of reach stops EVERY audit write in this deployment with 22003 — for every organization — while each caller swallows the failure and verifyAuditChain still answers ok over the rows that remain.', OLD.chain_key, OLD.id, NEW.id;
  END IF;

  IF NEW.chain_key IS DISTINCT FROM OLD.chain_key THEN
    RAISE EXCEPTION 'audit_chain_head: chain_key is an identity and is never renamed (ADR-0062, migration 0027): % may not become %. Renaming a head row into the __epoch0 anchor creates, on a database that already has signed history, the genesis every chain is verified from — which re-roots all of them irreversibly, because 0025 Part B then freezes the row.', OLD.chain_key, NEW.chain_key;
  END IF;

  IF NEW.head_signature IS DISTINCT FROM OLD.head_signature THEN
    IF NEW.head_signature = '' THEN
      IF EXISTS (
        SELECT 1 FROM public.admin_audit_log WHERE chain_key = NEW.chain_key
      ) THEN
        RAISE EXCEPTION 'audit_chain_head: the head of chain % may be put back to the genesis only while that chain holds NO rows (ADR-0062, migration 0027). With rows in it the genesis is not a chain with nothing in it: the next audit row written here would link from the genesis, which the first row of this chain already links from, and two rows sharing a predecessor is a fork verifyAuditChain refuses for ever. The one producer that resets a head to the genesis is scripts/export-db-artifacts.sh, which runs under session_replication_role = replica.', NEW.chain_key;
      END IF;
    ELSIF NOT EXISTS (
      SELECT 1 FROM public.admin_audit_log
       WHERE chain_key = NEW.chain_key
         AND event_signature = NEW.head_signature
    ) THEN
      RAISE EXCEPTION 'audit_chain_head: the head of chain % may only be moved to a signature a row of that chain published (ADR-0062, migration 0027). The next audit row written to this chain links from this value and signs it into history, so a head no row vouches for breaks the chain permanently — and 0025 Part A refuses both repairs.', NEW.chain_key;
    ELSIF EXISTS (
      SELECT 1 FROM public.admin_audit_log
       WHERE chain_key = NEW.chain_key
         AND prev_signature = NEW.head_signature
    ) THEN
      RAISE EXCEPTION 'audit_chain_head: the head of chain % may only name the LAST row of that chain (ADR-0062, migration 0027): a row of this chain already links from this signature. A head rewound to an older row makes the next honest write share a predecessor with the row that already follows it — a fork, the same permanent break a head no row vouches for causes, and 0025 Part A refuses both repairs.', NEW.chain_key;
    ELSIF NOT EXISTS (
      SELECT 1 FROM public.admin_audit_log
       WHERE chain_key = NEW.chain_key
         AND event_signature = NEW.head_signature
         AND prev_signature IS NOT DISTINCT FROM OLD.head_signature
    ) THEN
      RAISE EXCEPTION 'audit_chain_head: the head of chain % ADVANCES BY ONE LINK (ADR-0062, migration 0029): the row it names must link FROM the head it replaces. The writer inserts a row whose prev_signature is the head it read and then advances the head to that row, so an honest write always satisfies this; a head moved to any OTHER signature its chain published is a jump across history, and a row appended with a signature nobody computed publishes such a value at the tail — which is how a forged append completed itself while both earlier clauses were satisfied.', NEW.chain_key;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ══ HALF 2 — migration 0030 (DT-Y) ══════════════════════════════════════
-- migrate-1.32.0.sql — schema delta 1.31.0 → 1.32.0: lane C's HALF, migration 0030 (DT-Y, round 4) — an account deletion keeps the evidence a closed campaign and a two-person approval stand on. THE CONTROLLER UNIONS LANE B's 0029 DELTA (DT-X) INTO THIS SAME BUNDLE at the second merge, in journal order 0029 then 0030, each half keeping its own header and rollback; this file is the second half as it stands in lane C. Apply with psql -1 (ON_ERROR_STOP) so the halves land or none does.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- this delta drops two foreign keys, weakens three to ON DELETE SET NULL,
-- drops two NOT NULLs, adds one nullable column and adds one trigger that
-- fires only on the implicit UPDATE those keys perform. The previous image
-- writes `org_privilege_request` with both columns populated and reads
-- `access_review_item` unchanged, so a pod running it keeps serving across the
-- apply; a pod running the new image sees no behaviour change beyond the
-- refusal a released request now earns. The one thing that MOVES is what a
-- deletion destroys, which is the finding.
--
-- LOCK COST: every statement is a catalogue change on two small governance
-- tables. `ALTER TABLE … ADD CONSTRAINT … FOREIGN KEY` validates existing rows
-- and takes a SHARE ROW EXCLUSIVE lock on the child and a ROW SHARE on the
-- parent (`organization_member`, `"user"`); with `lock_timeout = 5s` below a
-- busy deployment gets a clean 55P03 rather than a queue. Re-run it.
--
-- ══ HALF (lane C) — migration 0030 (DT-Y) ══════════════════════════════════
-- 0030 — an account deletion keeps the evidence a closed campaign and a two-person approval stand on (deep-test campaign round 4, findings DT-4-iii-2 and DT-4-iii-3; ADR-0110).
-- rollback: ALTER TABLE "access_review_item" ADD CONSTRAINT access_review_item_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE, ADD CONSTRAINT access_review_item_decided_by_user_id_fk FOREIGN KEY (decided_by) REFERENCES "user" (id) ON DELETE SET NULL; the three "org_privilege_request" keys back to ON DELETE CASCADE with their NOT NULLs; DROP TRIGGER IF EXISTS org_privilege_request_release_trg ON "org_privilege_request"; DROP FUNCTION IF EXISTS org_privilege_request_release_guard(); ALTER TABLE "org_privilege_request" DROP COLUMN IF EXISTS released_membership_id. EVERY STATEMENT HERE IS REVERSIBLE AS DDL AND REVERSING IT COSTS MORE THAN IT RESTORES, stated rather than discovered (the SR2-b-3 lesson): re-adding the two "user" keys FAILS 23503 on any review item whose subject or decider has already been erased, so the reverse must first delete those items — which is the erasure this file exists to prevent, performed by hand; the three org_privilege_request keys cannot go back to NOT NULL while any released or requester-less row exists, so that half is FORWARD-ONLY once it has fired, exactly as 0025's `requested_by` and 0028's `membership_id` are; and a re-added CASCADE on `access_review_item.user_id` means the next account deletion takes the items again. Reverse the trigger and the column if you must; leave the keys.
SET lock_timeout = '5s';

-- ── THE NUMBER ────────────────────────────────────────────────────────────
-- 0030 is this lane's number by the round-4 register's ruling: lane B holds
-- 0029 (the chain work) and this file is lane C's. The journal `idx` is what
-- `expect(e.idx).toBe(i)` requires in a branch whose series ends at 0028 — the
-- 0012/idx-11 shape the permission-catalog migration recorded — and the `when`
-- sits 70,000 above 0028's, which is above lane B's declared ~20,000, so
-- neither entry re-orders at the merge. Until lane B merges, this branch's
-- migration TAGS have a gap at 0029 and `migration-ledger.guard.test.ts`'s
-- contiguity case reds on it, by construction and on this branch alone.
--
-- ── WHAT THIS FILE IS ABOUT ──────────────────────────────────────────────
-- Migration 0028 closed the MEMBERSHIP edge: one `DELETE FROM
-- organization_member` no longer erases a closed campaign's decided items, a
-- member's elevation record or the rules it stood on. `organization_member`
-- itself cascades from `"user"`, so the whole class was reachable ONE TABLE
-- UPSTREAM through an edge 0028's own contract could not see:
--
-- 1. THE CLOSED CAMPAIGN'S SUBJECT. `access_review_item.user_id` was ON DELETE
--    CASCADE from `"user"`, so the review's own SUBJECT — acting on their own
--    account, through `POST /api/auth/delete-user`, which is a PUBLIC prefix
--    in `proxy.ts` and needs no permission at all — deleted every item about
--    themselves, in every tenant, in every campaign, open or closed, pending
--    or decided, while the campaign kept its `evidence_sha` and its
--    `audit_head_signature`. Measured: items 1 -> 0, campaign still `closed`
--    with its sha. That is the most adversarial actor this control has and the
--    one with the clearest motive to make the record of their own
--    certification unverifiable.
--
-- 2. THE CLOSED CAMPAIGN'S DECIDER. `access_review_item.decided_by` was ON
--    DELETE SET NULL and `decidedBy` is inside BOTH export payloads — the
--    programme shape in `campaign-service.ts` and the frozen legacy shape in
--    `access-review-export.ts`. So deleting a departed reviewer's account,
--    which is ordinary offboarding hygiene and needs no adversary, moved the
--    `evidence_sha` of every campaign they ever decided in. The export route's
--    own docblock says what a reader concludes from that: "a disagreement
--    reads as tampered evidence on a campaign nothing is wrong with".
--
-- 3. THE ORG TIER'S DUAL-CONTROL RECORD. `org_privilege_request` is the
--    standing answer to "who asked for org-admin during incident 42, and who
--    signed it off", and BOTH of its identity edges were ON DELETE CASCADE:
--    `membership_id` (single AND composite) — the cascade DT-T's own report
--    named and declined, "the one evidence-bearing cascade I did NOT take" —
--    and `requested_by`, the exact twin of
--    `org_privilege_activation.requested_by`, which migration 0025 moved to ON
--    DELETE SET NULL for this reason and which nobody carried across.
--    Measured: an APPROVED request carrying `decided_by`, `decided_at` and
--    `decision_note` goes 1 -> 0 on one `DELETE FROM "user"`.
--
-- ── Part A — the review item keeps its subject AND its decider, BY VALUE ──
-- DROPPED rather than nulled, and rather than left to cascade, for the reason
-- 0028 Part A gives one column over: the HASH. Both payloads quote `userId`
-- and `decidedBy` RAW, and the legacy payload is "frozen by what deployments
-- have already stamped" (`access-review-export.ts`), so a nulled reference
-- would keep the row and STILL move the sha — which reads to an auditor
-- exactly like the tampering this file exists to prevent. Keeping the VALUE is
-- what makes both export shapes re-derive byte-identically after any deletion,
-- and an item whose subject has been erased is precisely what an auditor
-- asking "who was certified" must still see. The export renders such a person
-- BY ID and says so; `organization_id` still carries the tenancy, and
-- `campaign_id` still carries the campaign.
--
-- The alternative the round-4 report offered — a keyed digest of the two
-- columns stored beside the sha, the shape migration 0026 took for the audit
-- chain — is NOT taken here: it is a second payload version for every campaign
-- closed after it, and the register ratified the DT-T posture instead, which
-- is the one that leaves every stamped sha exactly where it is.
ALTER TABLE "access_review_item"
  DROP CONSTRAINT IF EXISTS access_review_item_user_id_user_id_fk;

ALTER TABLE "access_review_item"
  DROP CONSTRAINT IF EXISTS access_review_item_decided_by_user_id_fk;

-- ── Part B — the dual-control record outlives the membership and the user ─
-- SET NULL here, and DROP FK in Part A, and the difference is the HASH again:
-- nothing stamps one over this table, so the value is not load-bearing for a
-- re-derivation, while a nulled reference is the honest marker that the
-- membership is gone — which is what makes the pending-lifecycle refusal below
-- free, structural, and true on a HAND-RUN delete that no service ever sees.
-- The row keeps everything the two people did: `requested_by` (while that
-- account exists), `decided_by`, `decided_at`, `decision_note`, `reason`, the
-- role and the team.
--
-- The COMPOSITE tenancy key uses the COLUMN-LIST form `ON DELETE SET NULL
-- (membership_id)` — 0024's form, as 0028 used for the two elevation keys —
-- because the plain form would try to null `organization_id` too, which is NOT
-- NULL. That form is Postgres 15+ and is expressible in SQL but NOT in
-- drizzle, so this constraint lives in migrations 0010 and 0030 alone and its
-- column carries the note in `schema.pg.ts`.
ALTER TABLE "org_privilege_request"
  ALTER COLUMN membership_id DROP NOT NULL;

ALTER TABLE "org_privilege_request"
  ALTER COLUMN requested_by DROP NOT NULL;

ALTER TABLE "org_privilege_request"
  ADD COLUMN IF NOT EXISTS released_membership_id uuid;

ALTER TABLE "org_privilege_request"
  DROP CONSTRAINT IF EXISTS org_privilege_request_membership_id_organization_member_id_fk,
  ADD CONSTRAINT org_privilege_request_membership_id_organization_member_id_fk
    FOREIGN KEY (membership_id) REFERENCES organization_member (id)
    ON DELETE SET NULL;

ALTER TABLE "org_privilege_request"
  DROP CONSTRAINT IF EXISTS org_privilege_request_member_org_fk,
  ADD CONSTRAINT org_privilege_request_member_org_fk
    FOREIGN KEY (organization_id, membership_id)
    REFERENCES organization_member (organization_id, id)
    ON DELETE SET NULL (membership_id);

ALTER TABLE "org_privilege_request"
  DROP CONSTRAINT IF EXISTS org_privilege_request_requested_by_user_id_fk,
  ADD CONSTRAINT org_privilege_request_requested_by_user_id_fk
    FOREIGN KEY (requested_by) REFERENCES "user" (id)
    ON DELETE SET NULL;

-- ── Part C — the release is RECORDED, and a released request is not open ──
-- 0028 Part C's shape, on the table that needed it next:
--
--   * `released_membership_id` says WHOSE request it was after the reference
--     goes. It is a bare uuid with NO reference, for the reason `created_by`
--     beside it on `org_role_eligibility` is: the membership it names is gone
--     by construction. Without it a nulled `membership_id` would leave the org
--     tier's evidence saying that SOMEBODY was approved;
--   * a PENDING request whose subject membership has gone is EXPIRED by the
--     same trigger, because it can never be approved: `decideRequest` would
--     assign a role to a membership that does not exist. The service refuses
--     it by name as well (`request_membership_released`, the shape
--     `activationService.approve` already takes) — this is the floor under
--     that refusal rather than a duplicate of it, and it is the half a
--     service-side release cannot have, because the FK's implicit UPDATE fires
--     on a hand-run `DELETE FROM organization_member` too;
--   * and it frees `org_privilege_request_pending_unique`: the partial index
--     is on (membership_id, role_id, coalesce(team_id, …)) WHERE status =
--     'pending', so a released row leaves the pending population entirely and
--     a re-invited member can file the same request again. A row left pending
--     with a NULL membership would sit in that index forever — NULLs are
--     distinct there, so it would collide with nothing and block nothing, and
--     it would still be a door the inbox offers a checker.
--
-- `SET search_path = pg_catalog, public` and no unqualified relation name in
-- the body: the rule DT-X's 0029 states for every guard function from 0029 on.
-- This body reads no relation at all, which is the strongest form of it.
CREATE OR REPLACE FUNCTION org_privilege_request_release_guard() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  NEW.released_membership_id := OLD.membership_id;
  IF NEW.status = 'pending' THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS org_privilege_request_release_trg ON "org_privilege_request";
CREATE TRIGGER org_privilege_request_release_trg
  BEFORE UPDATE ON "org_privilege_request"
  FOR EACH ROW WHEN (OLD.membership_id IS NOT NULL AND NEW.membership_id IS NULL)
  EXECUTE FUNCTION org_privilege_request_release_guard();
