-- migrate-1.31.0.sql — schema delta 1.30.0 → 1.31.0: a TWO-MIGRATION bundle, journal order 0027 (DT-S, the chain refuses what it cannot verify) then 0028 (DT-T, a member's removal keeps the evidence it used to erase) — unioned by the controller at the DT-T merge; each half keeps its own header and rollback below. Apply with psql -1 (ON_ERROR_STOP) so both halves land or neither does.
-- ══ HALF 1 — migration 0027 (DT-S) ══════════════════════════════════════
-- migrate-1.31.0.sql — schema delta 1.30.0 → 1.31.0 (deep-test campaign round 3, DT-S): the chain refuses what it cannot verify — an UNSIGNED append, a HEAD that is not its chain's last row, a head row RENAMED into the epoch-0 anchor, a head REMOVED from a chain that still holds rows, and a head row whose id is REWRITTEN or CLAIMED out of the writer's reach.
-- rollback: every object here is reversible. DROP TRIGGER IF EXISTS
-- admin_audit_log_signed_append_trg ON "admin_audit_log"; DROP FUNCTION IF
-- EXISTS admin_audit_log_signed_append(); DROP TRIGGER IF EXISTS
-- audit_chain_head_vouched_trg ON "audit_chain_head"; DROP FUNCTION IF EXISTS
-- audit_chain_head_vouched(); DROP TRIGGER IF EXISTS
-- audit_chain_head_retained_trg ON "audit_chain_head"; DROP FUNCTION IF EXISTS
-- audit_chain_head_retained(); DROP TRIGGER IF EXISTS
-- audit_chain_head_id_assigned_trg ON "audit_chain_head"; DROP FUNCTION IF
-- EXISTS audit_chain_head_id_assigned(); DROP INDEX IF EXISTS
-- admin_audit_log_chain_signature; DROP INDEX IF EXISTS
-- admin_audit_log_chain_prev_signature; — and reversing them restores exactly the
-- posture this delta finds: a governance trail anyone holding the
-- application's own database credential may APPEND a fabricated row to, and a
-- head pointer any such session may set to a value no row ever published,
-- after which the next honest write signs that value into history and the
-- tenant's chain never verifies again. WHAT A REVERSE COSTS IS STATED RATHER
-- THAN DISCOVERED: nothing written while this delta was applied depends on it
-- (it adds no column and signs nothing), so a reverse loses the refusals and
-- no data.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly:
-- every object here refuses a statement no image makes. The application's only
-- audit INSERT computes the signature before it writes (both images do), its
-- head upsert advances each chain to a signature it has just published inside
-- the same transaction (both images do) with the id both images compute as
-- MAX(id) + 1, and neither image can name '__epoch0' as a chain key at all. So a pod running the previous image keeps
-- serving across the apply, and a pod running the new one sees no change in
-- behaviour beyond the refusals.
--
-- THE TWO INDEXES ARE NOT COSMETIC: the head guard asks "does a row of THIS
-- chain carry THIS signature" and "does a row of THIS chain link FROM it" on
-- every audit write, and without them each question walks a whole chain's heap
-- tuples. They are created before the trigger that needs them, and each
-- `CREATE INDEX` here takes a SHARE lock on `admin_audit_log` for the build —
-- see the `lock_timeout` below and, on a large deployment, the runbook's
-- guidance for the upgrade window.
--
-- Each source migration of the journaled series under src/lib/db/migrations/pg/
-- gets its own block header below, in journal order, and its statements are
-- that migration's own, byte for byte.
--
-- 1.31.0 IS A TWO-MIGRATION BUNDLE. Two lanes of the deep-test campaign cut
-- into this version: DT-S's 0027 (below) and DT-T's 0028, and the controller
-- unions them here at the second merge — so the file an operator reads after
-- that merge carries ONE BLOCK PER SOURCE MIGRATION in journal order, 0027
-- first. Until that merge lands only this block is present, and a bundle
-- carrying one block is not evidence that the other was dropped: the journal
-- under src/lib/db/migrations/pg/ is what says how many there are.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0027_audit_signed_append_and_vouched_head.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0027 — the chain refuses what it cannot verify (deep-test campaign round 3:
-- findings SR-b-1, SR-b-2, DT-3-iv-3 and the task review's rounds 1 and 2;
-- ADR-0037 LAW 5, ADR-0062, ADR-0109, ADR-0110).
--
-- 1. AN UNSIGNED ROW IS AN APPEND NO SIGNATURE COVERS. The chain verifier
--    opens by dropping every row whose `event_signature` is NULL, and the
--    repository's own read narrowed the same way — a filter written for rows
--    that predate the chain, which also made an ARRIVING unsigned row
--    invisible to every check. One INSERT with the application's own database
--    credential put a fabricated ORG_ROLE_ASSIGNED into the organization's
--    trail, the streamed export and the evidence pack's
--    cc6.2/identity-audit.jsonl, beside a chain-verification.json that said
--    {ok:true} and a process that exited 0 — and 1.28.0's append-only control
--    then refused both repairs, so the forgery was permanent. Refused
--    unconditionally from here on: the only INSERT path in the application
--    signs, this bundle's seed.sql writes no audit row, and a row already on
--    the database keeps its NULL and is read exactly as before.
--
-- 2. A HEAD IS A POINTER INTO ITS OWN CHAIN, NOT A FREE VALUE. 1.28.0 freezes
--    the '__epoch0' anchor and nothing else, so every NAMED chain's head row
--    was ordinary DML for anyone with the app grant — and the head is the
--    value the NEXT honest audit write links from and signs into history. One
--    UPDATE, and from the next write on that tenant's chain reads 'chain
--    broken: N row(s) unreachable from genesis' for ever, growing with every
--    further honest write, with both repairs refused and the reason string
--    blaming a deletion that never happened. The head may now move only to the
--    signature of the LAST row of that same chain — a row it holds that no row
--    of it links from, because an OLDER row of the chain forks it exactly as a
--    value nobody published does — and the genesis '' is admitted while, and
--    only while, the chain holds no rows, which is the state this bundle's
--    seed.sql ships it in.
--
-- 3. `chain_key` IS AN IDENTITY, SO IT IS NEVER RENAMED. 1.30.0 closed the
--    anchor's creation on the INSERT verb only, and 1.28.0's freeze reads the
--    row's OLD key — so an INSERT under a scratch key followed by an UPDATE of
--    that row's chain_key manufactured the anchor on a database that already
--    had signed history, re-rooting every chain irreversibly. ANY change of
--    chain_key is refused, which closes the rename in both directions.
--
-- 4. A HEAD THAT IS REMOVED IS A HEAD THAT WAS REWRITTEN. The third verb had
--    no arm at all — 1.28.0's freeze covers DELETE for the epoch-0 row alone —
--    so removing a named chain's head row bought the same permanent break as
--    rewriting it: the next audit write finds no head, re-seeds the chain from
--    the anchor and forks it at its first row. Refused while that chain still
--    holds rows. A head row whose chain holds NOTHING may still be removed,
--    which is what the reference-database export does per organization.
--
-- 5. AN `id` IS ASSIGNED, NOT CHOSEN — AND IT GUARDS THE WHOLE DEPLOYMENT.
--    `audit_chain_head.id` is an integer primary key, and the application
--    takes the next head id as MAX(id) + 1 inside its own upsert's VALUES
--    list, which PostgreSQL evaluates BEFORE it detects the conflict — so that
--    expression runs on every audit write, not only when a head row is new.
--    Two statements inside the app grant therefore stopped the trail
--    everywhere: an id-only UPDATE (which never entered the head guard at all,
--    because its WHEN clause named chain_key and head_signature and nothing
--    else) and an INSERT under a never-audited key carrying an id near the
--    integer ceiling. After either, every subsequent audit write — every
--    organization's, the platform chain's — fails with 22003, SILENTLY,
--    because each caller swallows an audit failure by design and the chain
--    still verifies green over the rows that remain. ANY change of id is now
--    refused, and an INSERT may claim the next id or one at or below the
--    current maximum but never leap past it — which is what this bundle's
--    seed.sql (1, then 0) and the application itself already write.
SET lock_timeout = '5s';

CREATE INDEX IF NOT EXISTS "admin_audit_log_chain_signature"
  ON "admin_audit_log" ("chain_key", "event_signature");

CREATE INDEX IF NOT EXISTS "admin_audit_log_chain_prev_signature"
  ON "admin_audit_log" ("chain_key", "prev_signature");

CREATE OR REPLACE FUNCTION admin_audit_log_signed_append() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'admin_audit_log is append-only AND signed (ADR-0037, ADR-0062, migration 0027): an INSERT with event_signature NULL is refused. Every row this application appends is signed by insertAuditLog under the chain head; a row with no signature is covered by no chain check, renders in the trail and the evidence pack as though it were evidence, and 0025 Part A then refuses to remove it. Rows written before the chain existed keep their NULL and are read exactly as before.';
END;
$$;

DROP TRIGGER IF EXISTS admin_audit_log_signed_append_trg ON "admin_audit_log";
CREATE TRIGGER admin_audit_log_signed_append_trg
  BEFORE INSERT ON "admin_audit_log"
  FOR EACH ROW WHEN (NEW.event_signature IS NULL)
  EXECUTE FUNCTION admin_audit_log_signed_append();

CREATE OR REPLACE FUNCTION audit_chain_head_vouched() RETURNS trigger
LANGUAGE plpgsql AS $$
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
        SELECT 1 FROM admin_audit_log WHERE chain_key = NEW.chain_key
      ) THEN
        RAISE EXCEPTION 'audit_chain_head: the head of chain % may be put back to the genesis only while that chain holds NO rows (ADR-0062, migration 0027). With rows in it the genesis is not a chain with nothing in it: the next audit row written here would link from the genesis, which the first row of this chain already links from, and two rows sharing a predecessor is a fork verifyAuditChain refuses for ever. The one producer that resets a head to the genesis is scripts/export-db-artifacts.sh, which runs under session_replication_role = replica.', NEW.chain_key;
      END IF;
    ELSIF NOT EXISTS (
      SELECT 1 FROM admin_audit_log
       WHERE chain_key = NEW.chain_key
         AND event_signature = NEW.head_signature
    ) THEN
      RAISE EXCEPTION 'audit_chain_head: the head of chain % may only be moved to a signature a row of that chain published (ADR-0062, migration 0027). The next audit row written to this chain links from this value and signs it into history, so a head no row vouches for breaks the chain permanently — and 0025 Part A refuses both repairs.', NEW.chain_key;
    ELSIF EXISTS (
      SELECT 1 FROM admin_audit_log
       WHERE chain_key = NEW.chain_key
         AND prev_signature = NEW.head_signature
    ) THEN
      RAISE EXCEPTION 'audit_chain_head: the head of chain % may only name the LAST row of that chain (ADR-0062, migration 0027): a row of this chain already links from this signature. A head rewound to an older row makes the next honest write share a predecessor with the row that already follows it — a fork, the same permanent break a head no row vouches for causes, and 0025 Part A refuses both repairs.', NEW.chain_key;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS audit_chain_head_vouched_trg ON "audit_chain_head";
CREATE TRIGGER audit_chain_head_vouched_trg
  BEFORE UPDATE ON "audit_chain_head"
  FOR EACH ROW WHEN (NEW.id IS DISTINCT FROM OLD.id
                     OR NEW.chain_key IS DISTINCT FROM OLD.chain_key
                     OR NEW.head_signature IS DISTINCT FROM OLD.head_signature)
  EXECUTE FUNCTION audit_chain_head_vouched();

CREATE OR REPLACE FUNCTION audit_chain_head_retained() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM admin_audit_log WHERE chain_key = OLD.chain_key
  ) THEN
    RAISE EXCEPTION 'audit_chain_head: the head of chain % may not be DELETED while that chain still holds rows (ADR-0062, migration 0027). Without its head the next audit row written to this chain re-seeds from the anchor, so the chain forks at its first row — the same permanent break a rewritten head causes, and 0025 Part A refuses both repairs. A head row whose chain holds no rows may still be removed.', OLD.chain_key;
  END IF;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS audit_chain_head_retained_trg ON "audit_chain_head";
CREATE TRIGGER audit_chain_head_retained_trg
  BEFORE DELETE ON "audit_chain_head"
  FOR EACH ROW
  EXECUTE FUNCTION audit_chain_head_retained();

CREATE OR REPLACE FUNCTION audit_chain_head_id_assigned() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE max_id bigint;
BEGIN
  SELECT MAX(id)::bigint INTO max_id FROM audit_chain_head;

  IF NEW.id::bigint > COALESCE(max_id, 0) + 1 THEN
    RAISE EXCEPTION 'audit_chain_head: a head row''s id is ASSIGNED, not chosen (ADR-0062, migration 0027): id % is beyond the next one (%). The audit writer takes the next head id as MAX(id) + 1 inside its own upsert, and PostgreSQL evaluates that before it detects the conflict — so a head row claiming an id near the integer ceiling stops EVERY audit write in this deployment with 22003, for every organization, while each caller swallows the failure and verifyAuditChain still answers ok over the rows that remain. Inserting a head row under a new chain_key is admitted; leaping the id is not.', NEW.id, COALESCE(max_id, 0) + 1;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS audit_chain_head_id_assigned_trg ON "audit_chain_head";
CREATE TRIGGER audit_chain_head_id_assigned_trg
  BEFORE INSERT ON "audit_chain_head"
  FOR EACH ROW
  EXECUTE FUNCTION audit_chain_head_id_assigned();

-- ══ HALF 2 — migration 0028 (DT-T) ══════════════════════════════════════
-- migrate-1.31.0.sql — schema delta 1.30.0 → 1.31.0 (deep-test campaign round 3, DT-T): 0028 (numbered 0027 in its lane, renumbered at the merge), a member's removal keeps the evidence it used to erase.
-- rollback: every statement here is reversible as DDL — the three membership
-- foreign keys back to ON DELETE CASCADE (and `access_review_item`'s
-- re-created), DROP TRIGGER org_role_eligibility_release_trg, DROP FUNCTION
-- org_role_eligibility_release_guard(), the scope UNIQUE back to its five
-- columns, DROP COLUMN released_membership_id. WHAT A REVERSE COSTS IS STATED
-- RATHER THAN DISCOVERED: the released rows this delta preserves become
-- unreachable by the restored cascade (they reference no membership, so
-- nothing deletes them either), and `org_privilege_activation.membership_id`
-- cannot be restored to NOT NULL while any released activation exists — that
-- half is FORWARD-ONLY once it has fired, exactly as 1.28.0's
-- `requested_by` is.
--
-- THE THIRD COST, ADDED AFTER THIS BUNDLE SHIPPED (deep-test round 4,
-- SR2-b-3; the journaled 0028 is frozen and cannot acquire the sentence, so it
-- lives here, in docs/security/authz-program/deep-test/
-- step6-rollback-rehearsal.md, and in migration 0029's header). The
-- five-column `scope_unique` above CANNOT BE RESTORED once TWO members holding
-- the same (organization, role, team) eligibility have been offboarded: their
-- two rows then differ only in `released_membership_id` — which is exactly why
-- that column joined the key — and the ADD CONSTRAINT raises 23505. The ALTER
-- rolls back whole, so nothing is left half-reversed, and the failure is loud;
-- but that half of this delta is FORWARD-ONLY from the second release onward,
-- exactly as `membership_id`'s NOT NULL is. Drop the released rows or keep the
-- six-column key. Measured on two seeded members removed by an ordinary
-- DELETE FROM "user".
-- Route: ./update.sh   (the ordinary rolling path)
--
-- ROLLING-SAFE, and the previous image is the reason to say so explicitly: the
-- new column is ADDITIVE and NULLABLE, the dropped NOT NULL only widens what
-- the table accepts, and a foreign key's ON DELETE action is invisible to a
-- pod that never deletes a membership mid-upgrade. A pod running the previous
-- image keeps serving across the apply and writes these tables exactly as
-- before. What it CANNOT do is know that a released rule is inert — it reads
-- `membership_id IS NULL` as "any governor may activate this" — so an image
-- older than 1.31.0 must not be left running against this schema while a
-- member removal happens. Image rollback is already bounded at 0016/1.26.0
-- (ADR-0109 §rollback); this delta does not move that bound, it adds a reason
-- to it.
--
-- AT THE MERGE OF THE TWO ROUND-3 LANES this file is UNIONED with lane B's
-- chain delta into one 1.31.0 (schema.sql = 1.30.0 + both, this file = both in
-- journal order); it is written here as though this migration were the only
-- one.
--
-- Each source migration of the journaled series under src/lib/db/migrations/pg/
-- gets its own block header below, in journal order. This delta carries exactly
-- one, and its statements are 0027's own, byte for byte. The round-3 register
-- calls that file 0028; this lane numbers it 0027 so the journaled series
-- stays contiguous, and the merge renumbers both the file and this header.

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0027_membership_removal_evidence.sql
-- ═══════════════════════════════════════════════════════════════════════════
SET lock_timeout = '5s';

-- ── WHY ────────────────────────────────────────────────────────────────────
-- ONE `DELETE FROM organization_member` — by a holder of `members:remove`, an
-- ordinary delegable catalog slug, or unattended by a SCIM de-provisioning run
-- (`scim-service.server.ts` deprovision: "remove the org membership, account
-- preserved") — erased three kinds of EVIDENCE, silently, with nothing in the
-- audit metadata saying what went. Measured on a journal-built database before
-- this file: `items=1 → 0`, `activations=1 → 0`, `eligibilities=1 → 0`.
--
-- 1. THE REVIEWER'S DECIDED WORK. `access_review_item.membership_id` was
--    ON DELETE CASCADE, so the removal deleted every access-review item about
--    that member — including DECIDED items of CLOSED campaigns — while the
--    campaign kept its `evidence_sha` and its `audit_head_signature`. The
--    campaign then certified fewer people than it did, and a re-hash of the
--    export no longer equalled the stored column. The export route's own
--    docblock says what a reader is meant to conclude from that: "on this
--    surface, where an auditor re-hashes the export and compares, a
--    disagreement reads as tampered evidence on a campaign nothing is wrong
--    with".
--
-- 2. THE ELEVATION RECORD. `org_privilege_activation.membership_id` was
--    ON DELETE CASCADE, so the row saying this member held `org-admin` for an
--    hour during incident 42 — its `reason`, its approver, its window — went
--    with the membership. The evidence pack reads `activations.jsonl` LIVE
--    from this table, so every pack generated afterwards was silently short.
--
-- 3. THE RULE THE ELEVATION SPENT. `org_role_eligibility.membership_id` was
--    ON DELETE CASCADE too, and 0022's ON DELETE RESTRICT on
--    `org_privilege_activation.eligibility_id` — the edge 0022's header calls
--    "the one edge that must not cascade" — does NOT fire on this path:
--    PostgreSQL cascades both children of `organization_member`, so by the
--    time the rule is deleted the activation that referenced it is already
--    gone and the referential check is satisfied. `eligibilityService.remove`'s
--    409 `eligibility_in_use` is the control a member removal walked around,
--    and re-inviting the member restores their access and not their history,
--    because the re-invite mints a NEW membership id.
--
-- ── WHY SET NULL AND NOT RESTRICT (measured, not assumed) ──────────────────
-- ON DELETE RESTRICT would make a stray `DELETE FROM organization_member`
-- fail loudly instead of erasing, which is the shape this campaign's register
-- proposed. It was tried on a journal-built database first, and it breaks a
-- SUPPORTED path: `organization_member` itself cascades from `"user"`, so a
-- USER DELETION — a GDPR erasure, `removeUser`, the acceptance teardown that
-- deletes every test user — walks into the RESTRICT two tables away and fails
-- 23503 for any person who ever elevated. RESTRICT is also checked
-- IMMEDIATELY rather than at end of statement, so it is order-dependent
-- against the other cascades of the same parent — which is precisely the
-- interaction that stopped 0022's RESTRICT firing in the first place. SET NULL
-- keeps every evidentiary column, needs no ordering argument, and leaves user
-- deletion and organization deletion exactly as they were.
--
-- The COMPOSITE tenancy keys use the COLUMN-LIST form `ON DELETE SET NULL
-- (membership_id)` — the form 0024 introduced for the reviewer keys — because
-- the plain form would try to null `organization_id` too, which is NOT NULL.
-- That form is Postgres 15+ and is expressible in SQL but NOT in drizzle, so
-- those two constraints live in this migration alone and their columns carry
-- the note in `schema.pg.ts`.

-- ── Part A — the review item keeps its subject, id and all ─────────────────
-- The item's membership reference is DROPPED rather than nulled, and that is
-- the one place this file departs from the shape the others take. The reason
-- is the HASH: `access-review-export.ts` states that its legacy payload is
-- "frozen by what is already stamped" — a rename or an addition invalidates
-- every `evidence_sha` a deployment holds — and `membershipId` is one of its
-- nine fields. A nulled reference would keep the row and still move the sha,
-- which reads to an auditor exactly like the tampering this file exists to
-- prevent; a dropped FK keeps the VALUE, so both export shapes re-derive
-- byte-identically after a removal. `organization_id` still carries the
-- tenancy (the item has no composite membership key, and never had one), and
-- `user_id` remains the subject key. It is the posture `org_role_eligibility
-- .created_by` already takes, for the reason 0022 wrote there: "provenance
-- that survives the deletion is worth more here than referential tidiness".
ALTER TABLE "access_review_item"
  DROP CONSTRAINT IF EXISTS access_review_item_membership_id_organization_member_id_fk;

-- ── Part B — the elevation record outlives the membership ─────────────────
ALTER TABLE "org_privilege_activation"
  ALTER COLUMN membership_id DROP NOT NULL;

ALTER TABLE "org_privilege_activation"
  DROP CONSTRAINT IF EXISTS org_privilege_activation_member_fk,
  ADD CONSTRAINT org_privilege_activation_member_fk
    FOREIGN KEY (membership_id) REFERENCES organization_member (id)
    ON DELETE SET NULL;

ALTER TABLE "org_privilege_activation"
  DROP CONSTRAINT IF EXISTS org_privilege_activation_member_org_fk,
  ADD CONSTRAINT org_privilege_activation_member_org_fk
    FOREIGN KEY (organization_id, membership_id)
    REFERENCES organization_member (organization_id, id)
    ON DELETE SET NULL (membership_id);

-- ── Part C — the RULE outlives it too, and says whose it was ──────────────
-- A rule whose `membership_id` is NULL means something already: "any governor
-- of this org may activate it" (`activationService.request`, the `isGovernor`
-- branch). Nulling a member-scoped rule would therefore turn a departed
-- member's rule into an ORG-WIDE one — an escalation, not an erasure — and two
-- such rules for the same (org, role, team) would collide on
-- `org_role_eligibility_scope_unique`, which would make the second offboarding
-- fail 23505. So the release is RECORDED rather than merely applied:
--
--   · `released_membership_id` says whose membership it was about. It is a
--     bare uuid with NO reference, for the reason `created_by` beside it is:
--     the membership it names is gone by construction;
--   · it joins the scope UNIQUE, so two released rules for the same role are
--     distinct rows and neither offboarding fails;
--   · the trigger stamps it, and lapses the rule, on the FK's own implicit
--     UPDATE — so a HAND-RUN deletion that never touches the service produces
--     a released rule too, rather than an org-wide one. That is the half a
--     service-side release could not have.
ALTER TABLE "org_role_eligibility"
  ADD COLUMN IF NOT EXISTS released_membership_id uuid;

ALTER TABLE "org_role_eligibility"
  DROP CONSTRAINT IF EXISTS org_role_eligibility_membership_id_organization_member_id_fk,
  ADD CONSTRAINT org_role_eligibility_membership_id_organization_member_id_fk
    FOREIGN KEY (membership_id) REFERENCES organization_member (id)
    ON DELETE SET NULL;

ALTER TABLE "org_role_eligibility"
  DROP CONSTRAINT IF EXISTS org_role_eligibility_member_org_fk,
  ADD CONSTRAINT org_role_eligibility_member_org_fk
    FOREIGN KEY (organization_id, membership_id)
    REFERENCES organization_member (organization_id, id)
    ON DELETE SET NULL (membership_id);

ALTER TABLE "org_role_eligibility"
  DROP CONSTRAINT IF EXISTS org_role_eligibility_scope_unique,
  ADD CONSTRAINT org_role_eligibility_scope_unique
    UNIQUE NULLS NOT DISTINCT
    (organization_id, membership_id, role_id, team_id, is_break_glass, released_membership_id);

CREATE OR REPLACE FUNCTION org_role_eligibility_release_guard() RETURNS trigger
LANGUAGE plpgsql AS $$
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

DROP TRIGGER IF EXISTS org_role_eligibility_release_trg ON "org_role_eligibility";
CREATE TRIGGER org_role_eligibility_release_trg
  BEFORE UPDATE ON "org_role_eligibility"
  FOR EACH ROW WHEN (OLD.membership_id IS NOT NULL AND NEW.membership_id IS NULL)
  EXECUTE FUNCTION org_role_eligibility_release_guard();
