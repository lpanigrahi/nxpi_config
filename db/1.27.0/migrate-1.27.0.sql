-- migrate-1.27.0.sql — schema delta 1.26.0 → 1.27.0 (Phase 6, authz programme): 0022 org_privilege_activation, the ELEVATION substrate.
-- rollback: yes. This delta is ADDITIVE-ONLY and reversible, and update.sh's
-- ordinary rolling path is safe for it. Three NEW tables that start empty and
-- ONE new nullable column with no default: the PREVIOUS app image names none of
-- these objects, so it keeps serving unchanged across the forward apply. (The
-- review posture 1.26.0's delta carries on its own line 2 is NOT inherited
-- here — this file deliberately raises no such marker, and the reverse
--   ALTER TABLE org_role_assignment DROP COLUMN IF EXISTS activation_id;
--   DROP TABLE IF EXISTS platform_privilege_activation;
--   DROP TABLE IF EXISTS org_privilege_activation;
--   DROP TABLE IF EXISTS org_role_eligibility;
-- loses only the eligibility rules an org entered and the activation history
-- recorded since the apply. It cannot strand a privilege: an activation's
-- GRANT is an org_role_assignment row, which this delta does not otherwise
-- touch. Drop the column FIRST (it is the only reference into
-- org_privilege_activation) and the tables in reverse dependency order.)
-- Route: ./update.sh   (the ordinary rolling path)
--
-- Each source migration of the journaled series under src/lib/db/migrations/pg/
-- gets its own block header below, in journal order. This delta carries exactly
-- one.
-- Also in this delta, source migration 0023 (after 0022 below): sod_rule — the separation-of-duties rules as tenant-editable rows, four TOXIC_SETS seeded as platform defaults, its own row-level policy; additive-only and reversible (DROP TABLE IF EXISTS sod_rule CASCADE).
-- Also in this delta, source migration 0024 (after 0023 below): access_review_program — eleven columns on access_review_campaign, three on access_review_item, and the NOT VALID access_review_item_reviewer_not_subject CHECK; additive, and reversible by dropping those columns and constraints (see the 0024 block for the one non-additive consequence: a self-decided review item stops being writable).

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0022_org_privilege_activation.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0022 — the ELEVATION substrate (plan §Phase 6 / P6-T2; ADR-0110 *privilege
-- is an activation, not a standing row*).
--
-- WHAT IT IS FOR. Today a privilege is a STANDING ROW: org_role_assignment
-- says "this member holds this role", optionally until an expiry nobody is
-- required to set, and the answer to "why does this person have org-admin?" is
-- an audit line written months ago. These tables split that into the RULE and
-- the EVENT. `org_role_eligibility` is the rule, written while nobody is
-- elevated — this membership, or (membership_id NULL) any governor of the org,
-- MAY activate this role for at most N minutes, with or without a checker and
-- a step-up. `org_privilege_activation` is the event: one row per elevation
-- actually taken, with its reason, its approver, its window and the grant it
-- minted. `platform_privilege_activation` is the same at the deployment tier,
-- where there is no organization to scope by.
--
-- FOUR CONSTRAINTS ARE THE FLOOR, and each exists because the corresponding
-- service check can be forgotten by the next writer, skipped by a hand-run
-- statement, or absent from a seed script: the 5..1440 window CHECK (the
-- window IS the control); the UNIQUE **NULLS NOT DISTINCT** that makes the
-- break-glass rule one row per org (Postgres treats NULLs as DISTINCT by
-- default, and two of that constraint's columns are nullable, so the default
-- would make it vacuous for exactly the rows that need it — Postgres 15 or
-- newer is therefore required, as it already is for 1.26.0's authz_settings);
-- the partial unique that allows ONE pending activation per (member, rule);
-- and the two requester-is-not-approver CHECKs, maker/checker stated at the
-- database.
--
-- ON DELETE RESTRICT on the eligibility→activation edge is the one that is not
-- a default: an activation is EVIDENCE that somebody held a privilege, and
-- deleting the rule must never delete the record of what it authorised.
--
-- THIS DELTA CARRIES NO POLICY, deliberately: no packaged artifact in this
-- lineage delivers row-level security (schema.sql is a pg_dump, which dumps no
-- policies), and the compliance register's CC6.1 control DISCLOSES exactly
-- that to the operator. Apply
-- src/lib/db/rls/0027_org_privilege_activation.sql through the runbook's RLS
-- step (docs/runbooks/production-rls-enablement.md) to get the two org tables'
-- policies. `platform_privilege_activation` has none anywhere: it carries no
-- organization_id, so there is no tenant predicate to write.
--
-- ZERO BEHAVIOUR CHANGE at the app: nothing reads any of these tables on a
-- decision path in the 1.27.0 image (the resolver feed is untouched, so a
-- member with an eligibility row has exactly the permissions they had before).
--
-- Re-runnable as written (CREATE TABLE / CREATE INDEX IF NOT EXISTS, ADD
-- COLUMN IF NOT EXISTS, and a DO block guarding the one ADD CONSTRAINT), so a
-- re-applied file is a no-op rather than an error mid-series. lib.sh applies
-- this file with psql -1: one transaction.
--
-- LOCK POSTURE for the operator: three CREATE TABLEs take ACCESS EXCLUSIVE on
-- relations no other session can be reading. The one statement that touches a
-- live table is the org_role_assignment ADD COLUMN — nullable, no default, so
-- a catalog update with no rewrite and no backfill, but it takes ACCESS
-- EXCLUSIVE on that table for as long as it waits, which on a busy tenant is
-- the only thing here that can queue behind a long-running reader. SET
-- lock_timeout bounds that acquisition, not the hold.

SET lock_timeout = '5s';

-- ── WHY ────────────────────────────────────────────────────────────────────
-- THE HOLE. Today a privilege is a STANDING ROW. `org_role_assignment` says
-- "this member holds this role", optionally until an expiry nobody is
-- required to set, and the answer to "why does this person have org-admin?"
-- is at best an audit line written months ago by someone who has left. W-S9
-- softened the edges — a dual-control REQUEST for a high-tier assignment, a
-- break-glass grant with a mandatory short expiry — but both of those end in
-- the same standing row, and neither can answer the question an auditor
-- actually asks: WHO MAY become an admin, FOR HOW LONG, and UNDER WHAT
-- CONDITIONS, stated in advance and reviewable while nobody is elevated.
--
-- THE FIX, and the shape of it (ADR-0110: privilege is an activation, not a
-- standing row). Two tables, and the split between them is the whole idea:
--
--   `org_role_eligibility` is the RULE, written while calm. One row says a
--   membership — or, with `membership_id` NULL, ANY governor of the org — may
--   activate one role, for at most N minutes, with or without a checker, with
--   or without a step-up. It grants NOTHING on its own: no resolver reads it,
--   and a member with an eligibility and no activation has exactly the
--   permissions they had before.
--
--   `org_privilege_activation` is the EVENT. One row per elevation actually
--   taken: the reason (at least 20 characters, because "test" is not a
--   reason), who asked, who approved, when it became live, when it lapses,
--   and — through `assignment_id` — the grant row it minted. The assignment
--   points back through `org_role_assignment.activation_id`, so the standing
--   row an auditor finds can always name the activation that created it.
--
-- `platform_privilege_activation` is the same event for the DEPLOYMENT tier,
-- where there is no organization at all: a lateral platform role
-- (platform-security-admin / platform-operations-admin) is held over every
-- tenant, so the row carries a user and no `organization_id`.
--
-- ── WHAT THIS FILE ENFORCES THAT NO SERVICE CAN ────────────────────────────
-- Four constraints below are the FLOOR, and each one exists because the
-- corresponding service check can be forgotten by the next writer, skipped by
-- a hand-run statement, or absent from a seed script:
--
--   * `org_role_eligibility_max_duration_check` — BETWEEN 5 AND 1440. The
--     window IS the control; a row saying "24 hours and one minute" is a
--     standing grant wearing an activation's clothes. The service refuses the
--     same value with a message (`eligibility-service.ts`), which is the
--     doctrine this phase repeats everywhere: the CHECK is the floor, the flag
--     (or the typed refusal) is the message.
--   * the UNIQUE, `NULLS NOT DISTINCT`, on
--     (organization_id, membership_id, role_id, team_id, is_break_glass).
--     Postgres treats NULLs as DISTINCT in a unique index BY DEFAULT, and
--     under that default the two nullable columns here — `membership_id` (a
--     SYSTEM eligibility) and `team_id` (an org-wide one) — would make the
--     constraint vacuous for exactly the rows that most need it: every call of
--     `ensureBreakGlassEligibility` would insert ANOTHER break-glass row with
--     its own ceiling, and the reader would answer from whichever it saw
--     first. `NULLS NOT DISTINCT` (Postgres 15+) is also what makes that
--     function's upsert an upsert at all.
--   * `org_privilege_activation_one_pending` — a PARTIAL unique index on
--     (membership_id, eligibility_id) WHERE status = 'pending'. A queue with
--     no uniqueness lets the same elevation sit in it N times, and each copy
--     is separately approvable (the hole migration 0010 closed for
--     org_privilege_request). Decided rows are deliberately unconstrained:
--     the history is the evidence.
--   * the two requester-is-not-approver CHECKs. Maker/checker is not a UI
--     rule. On the org table `approved_by <> requested_by`; on the platform
--     table `approved_by <> user_id` (the subject IS the requester there).
--     Stated at the database so that a service which loses the check, a
--     migration-time backfill and an operator's psql session are all bound by
--     it.
--
-- ── ON DELETE, stated per edge because the defaults are all wrong here ─────
-- `organization` CASCADEs on both org tables (a deleted tenant's rules and
-- history go with it). `org_role_eligibility → org_privilege_activation` is
-- ON DELETE **RESTRICT**, and it is the one edge that must not cascade: an
-- activation is EVIDENCE that somebody held a privilege, and deleting the
-- rule must never delete the record of what it authorised. An org that wants
-- the rule gone revokes it (`expires_at`) or deletes it only once no
-- activation references it. `assignment_id` and `review_item_id` SET NULL —
-- the grant or the review item can legitimately go while the activation
-- record stays — and `org_role_assignment.activation_id` SET NULLs for the
-- mirror-image reason: the activation's own history outlives the grant it
-- minted, and a cascade there would delete a live privilege row because its
-- provenance was tidied up.
--
-- ── THE COMPOSITE TENANCY FOREIGN KEYS ─────────────────────────────────────
-- Every single-column reference to `organization_member`, `org_role`, `team`
-- and `org_role_eligibility` below is ALSO carried as a composite
-- (organization_id, x) key, because the single-column form is satisfied by ANY
-- row in the cluster — a writer that lost its org predicate wrote a
-- cross-tenant row and the database took it happily (the class migrations 0010
-- and 0011 closed for org_role_assignment and org_privilege_request). On THIS
-- table the consequence is not a cosmetic mis-tag: an activation pointing at
-- another tenant's eligibility would be one org's ceiling authorising another
-- org's elevation. `org_role_eligibility` therefore carries its own
-- UNIQUE (organization_id, id) so the activation's composite key has something
-- to reference — the same shape `organization_member`, `org_role` and `team`
-- already carry for org_role_assignment's three legs.
--
-- ── ZERO BEHAVIOUR CHANGE ──────────────────────────────────────────────────
-- Three NEW tables that start EMPTY and one NEW nullable column with no
-- default. Nothing reads any of them on a decision path in this commit: the
-- resolver's feed is untouched, so a member with an eligibility row has
-- exactly the permissions they had before, and `activation_id` is written by
-- P6-T3's activation flow, which does not exist yet. The previous app image
-- names none of these objects, so the apply is rolling-safe in both
-- directions. Decision table unchanged; shadow parity 0.
--
-- ── LOCK POSTURE ───────────────────────────────────────────────────────────
-- This file carries no drizzle breakpoint marker, so the journaled path sends
-- it as ONE transaction, and the sourceless path is no different
-- (azure-deployment/lib.sh applies the packaged delta with psql -1). Three
-- CREATE TABLEs take ACCESS EXCLUSIVE on relations no other session can be
-- reading. The ONE statement that touches a live table is the
-- `org_role_assignment` ADD COLUMN: nullable, no default, so it is a catalog
-- update with no rewrite and no backfill — but it takes ACCESS EXCLUSIVE on
-- org_role_assignment for the duration it waits, which on a busy tenant is
-- the one thing here that can queue behind a long-running reader.
-- SET lock_timeout bounds that ACQUISITION, not the hold. The FK targets
-- (organization, "user", organization_member, org_role, team,
-- access_review_item) each take a brief SHARE ROW EXCLUSIVE.

-- ── org_role_eligibility — the RULE ───────────────────────────────────────
-- The single-column foreign keys carry the names drizzle-kit derives from
-- schema.pg.ts (table_column_reftable_refcolumn_fk), so db:push against a dev
-- database diffs to nothing. `created_by` is a bare uuid with NO reference,
-- deliberately and in line with the plan: the tree has closed a user-deletion
-- FK crash class twice, and provenance that survives the author's deletion is
-- worth more here than referential tidiness.
CREATE TABLE IF NOT EXISTS org_role_eligibility (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid NOT NULL CONSTRAINT org_role_eligibility_organization_id_organization_id_fk REFERENCES organization (id) ON DELETE CASCADE,
  membership_id uuid CONSTRAINT org_role_eligibility_membership_id_organization_member_id_fk REFERENCES organization_member (id) ON DELETE CASCADE,
  role_id uuid NOT NULL CONSTRAINT org_role_eligibility_role_id_org_role_id_fk REFERENCES org_role (id) ON DELETE CASCADE,
  team_id uuid CONSTRAINT org_role_eligibility_team_id_team_id_fk REFERENCES team (id) ON DELETE CASCADE,
  max_duration_min integer NOT NULL,
  requires_approval boolean DEFAULT false NOT NULL,
  requires_step_up boolean DEFAULT true NOT NULL,
  is_break_glass boolean DEFAULT false NOT NULL,
  created_by uuid,
  expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT org_role_eligibility_max_duration_check CHECK (max_duration_min BETWEEN 5 AND 1440),
  CONSTRAINT org_role_eligibility_scope_unique UNIQUE NULLS NOT DISTINCT (organization_id, membership_id, role_id, team_id, is_break_glass),
  CONSTRAINT org_role_eligibility_org_id_unique UNIQUE (organization_id, id),
  CONSTRAINT org_role_eligibility_member_org_fk FOREIGN KEY (organization_id, membership_id) REFERENCES organization_member (organization_id, id) ON DELETE CASCADE,
  CONSTRAINT org_role_eligibility_role_org_fk FOREIGN KEY (organization_id, role_id) REFERENCES org_role (organization_id, id) ON DELETE CASCADE,
  CONSTRAINT org_role_eligibility_team_org_fk FOREIGN KEY (organization_id, team_id) REFERENCES team (organization_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS org_role_eligibility_org_idx ON org_role_eligibility (organization_id);
CREATE INDEX IF NOT EXISTS org_role_eligibility_membership_idx ON org_role_eligibility (membership_id);

-- ── org_privilege_activation — the EVENT ──────────────────────────────────
-- FOUR of this table's foreign keys carry a HAND-SHORTENED name
-- (…_eligibility_fk, …_member_fk, …_assignment_fk, …_review_item_fk) rather
-- than drizzle-kit's derived table_column_reftable_refcolumn_fk: that form is
-- 64-66 bytes here, and Postgres truncates an identifier at 63, so the derived
-- name and the name the server actually stores would differ by a character and
-- every drift report would show a constraint being dropped and re-added
-- forever. schema.pg.ts declares the same four through `foreignKey({ name })`,
-- so the two spellings agree by construction.
CREATE TABLE IF NOT EXISTS org_privilege_activation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid NOT NULL CONSTRAINT org_privilege_activation_organization_id_organization_id_fk REFERENCES organization (id) ON DELETE CASCADE,
  eligibility_id uuid NOT NULL CONSTRAINT org_privilege_activation_eligibility_fk REFERENCES org_role_eligibility (id) ON DELETE RESTRICT,
  membership_id uuid NOT NULL CONSTRAINT org_privilege_activation_member_fk REFERENCES organization_member (id) ON DELETE CASCADE,
  reason text NOT NULL,
  status text NOT NULL,
  requested_at timestamp with time zone DEFAULT now() NOT NULL,
  requested_by uuid NOT NULL CONSTRAINT org_privilege_activation_requested_by_user_id_fk REFERENCES "user" (id) ON DELETE CASCADE,
  approved_by uuid CONSTRAINT org_privilege_activation_approved_by_user_id_fk REFERENCES "user" (id) ON DELETE SET NULL,
  activated_at timestamp with time zone,
  expires_at timestamp with time zone NOT NULL,
  revoked_by uuid,
  assignment_id uuid CONSTRAINT org_privilege_activation_assignment_fk REFERENCES org_role_assignment (id) ON DELETE SET NULL,
  review_item_id uuid CONSTRAINT org_privilege_activation_review_item_fk REFERENCES access_review_item (id) ON DELETE SET NULL,
  CONSTRAINT org_privilege_activation_reason_check CHECK (length(reason) >= 20),
  CONSTRAINT org_privilege_activation_status_check CHECK (status IN ('pending','active','expired','revoked','denied')),
  CONSTRAINT org_privilege_activation_approver_check CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT org_privilege_activation_eligibility_org_fk FOREIGN KEY (organization_id, eligibility_id) REFERENCES org_role_eligibility (organization_id, id) ON DELETE RESTRICT,
  CONSTRAINT org_privilege_activation_member_org_fk FOREIGN KEY (organization_id, membership_id) REFERENCES organization_member (organization_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS org_privilege_activation_org_idx ON org_privilege_activation (organization_id);
CREATE INDEX IF NOT EXISTS org_privilege_activation_status_idx ON org_privilege_activation (status);
-- The partial unique that makes "one pending elevation per (member, rule)" a
-- fact rather than a hope. Decided rows stay unconstrained on purpose.
CREATE UNIQUE INDEX IF NOT EXISTS org_privilege_activation_one_pending
  ON org_privilege_activation (membership_id, eligibility_id)
  WHERE status = 'pending';

-- ── platform_privilege_activation — the DEPLOYMENT tier ───────────────────
-- No organization_id, and therefore no tenant predicate and no RLS: the
-- subject is a user and the scope is every tenant. Ledgered `platform` in
-- rls-coverage-ledger.ts with that reason; its second net is the platform
-- frame (lib/authz/pep/platform-frame.ts), not a row policy.
CREATE TABLE IF NOT EXISTS platform_privilege_activation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL CONSTRAINT platform_privilege_activation_user_id_user_id_fk REFERENCES "user" (id) ON DELETE CASCADE,
  lateral_role text NOT NULL,
  reason text NOT NULL,
  status text NOT NULL,
  requested_at timestamp with time zone DEFAULT now() NOT NULL,
  approved_by uuid,
  activated_at timestamp with time zone,
  expires_at timestamp with time zone NOT NULL,
  revoked_by uuid,
  CONSTRAINT platform_privilege_activation_lateral_role_check CHECK (lateral_role IN ('platform-security-admin','platform-operations-admin')),
  CONSTRAINT platform_privilege_activation_reason_check CHECK (length(reason) >= 20),
  CONSTRAINT platform_privilege_activation_approver_check CHECK (approved_by IS NULL OR approved_by <> user_id)
);

CREATE INDEX IF NOT EXISTS platform_privilege_activation_user_idx ON platform_privilege_activation (user_id);

-- ── org_role_assignment.activation_id — the back-reference ────────────────
-- Nullable with no default: every existing row means "granted before P6-T2,
-- or granted by a path that is not an activation", which is exactly what NULL
-- says. SET NULL rather than CASCADE — see ON DELETE above.
ALTER TABLE org_role_assignment
  ADD COLUMN IF NOT EXISTS activation_id uuid;

DO $do$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'org_role_assignment_activation_fk'
  ) THEN
    ALTER TABLE org_role_assignment
      ADD CONSTRAINT org_role_assignment_activation_fk
      FOREIGN KEY (activation_id) REFERENCES org_privilege_activation (id) ON DELETE SET NULL;
  END IF;
END
$do$;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0023_sod_rule.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- sod_rule + the four seeded platform defaults (plan §Phase 6 / P6-T6).
-- Statement-identical to the journaled file; its operator header (WHY / lock
-- posture / the zero-behaviour-change argument) lives there. Applies on the
-- rolling path: a NEW table, no constraint tightened on existing data, no
-- backfill, and the previous app image names the table nowhere — so an old pod
-- serving beside it is unaffected in both directions.

SET lock_timeout = '5s';

-- ── The table ─────────────────────────────────────────────────────────────
-- organization_id NULL = a PLATFORM DEFAULT (the seeded rows below); a row
-- carrying an organization is that tenant's own statement, and
-- `loadSodRules` overlays the two BY NAME. CASCADE on the tenant, because an
-- org's SoD policy has no meaning once the org is gone.
--
-- created_by carries NO foreign key, which the plan's DDL states and this
-- mirrors: provenance is not authority here. A cascade would let deleting an
-- operator delete a control, and SET NULL would be a second column nobody
-- reads — the row is the policy, the author is a note on it.
CREATE TABLE IF NOT EXISTS sod_rule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid CONSTRAINT sod_rule_organization_id_organization_id_fk REFERENCES organization (id) ON DELETE CASCADE,
  name text NOT NULL,
  toxic_set text[] NOT NULL,
  mode text DEFAULT 'inherit' NOT NULL,
  reason text NOT NULL,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT sod_rule_mode_check CHECK (mode IN ('inherit','enforce','warn','off')),
  CONSTRAINT sod_rule_toxic_set_check CHECK (cardinality(toxic_set) >= 2),
  CONSTRAINT sod_rule_org_name_unique UNIQUE NULLS NOT DISTINCT (organization_id, name)
);

-- ── The index the policy and the per-org listing need ─────────────────────
-- The unique constraint leads on organization_id too, so this is not the only
-- way to seek it — it is kept because that constraint is free to change shape
-- (a third column, a different order) while this read is not.
CREATE INDEX IF NOT EXISTS sod_rule_org_idx ON sod_rule (organization_id);

-- ── The platform defaults, projected from TOXIC_SETS (GENERATED) ──────────
-- 4 rows = the four pairs `lib/organizations/rbac/sod-policy.ts`
-- has declared since W-S7, as data. mode 'inherit' on every one, so the org's
-- own `authz.sodMode` still decides what completing a pair MEANS and this
-- migration changes no decision.
INSERT INTO sod_rule (organization_id, name, toxic_set, mode, reason)
VALUES
  (NULL, 'agents-maker-checker', ARRAY['agents:create','agents:approve']::text[], 'inherit', 'An agent author who can approve agents reviews their own work — the approval gate stops gating.'),
  (NULL, 'assistants-maker-checker', ARRAY['assistants:create','assistants:approve']::text[], 'inherit', 'An assistant author who can approve assistants reviews their own work.'),
  (NULL, 'skills-maker-checker', ARRAY['skills:create','skills:approve']::text[], 'inherit', 'A skill author who can approve skills reviews their own work.'),
  (NULL, 'provisioning-spend', ARRAY['members:invite','billing:manage']::text[], 'inherit', 'Provisioning users AND controlling billing concentrates spend authority in one member (the HR/finance separation).')
ON CONFLICT (organization_id, name) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0024_access_review_program.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The access-review PROGRAM columns + the reviewer-is-not-the-subject CHECK
-- (plan §Phase 6 / P6-T8). Statement-identical to the journaled file; its
-- operator header (WHY / NOT VALID / lock posture / the zero-behaviour-change
-- argument) lives there.
--
-- APPLIES ON THE ROLLING PATH, with ONE thing to know before you run it.
-- Fourteen new columns, every one nullable or carrying the default that
-- reproduces today's row, so the PREVIOUS app image — which names none of them
-- — keeps serving unchanged across the forward apply. The exception is
-- `access_review_item_reviewer_not_subject`: from this apply onward the
-- database refuses a review item decided by its own subject. It is added
-- NOT VALID, so rows a deployment already self-decided stay READABLE and the
-- apply cannot fail on them; only writes from here on are bound. Do NOT add a
-- VALIDATE CONSTRAINT to this delta — validating would fail on exactly the
-- history the constraint exists to end, on the databases that need it most.
-- An app image that predates 1.27.0 and still allows a self-certification will
-- now meet a 23514 on that write; the 1.27.0 image maps it to a refusal.

SET lock_timeout = '5s';

-- ── access_review_campaign: the PROGRAM columns ────────────────────────────
ALTER TABLE access_review_campaign
  ADD COLUMN IF NOT EXISTS kind text DEFAULT 'legacy' NOT NULL,
  ADD COLUMN IF NOT EXISTS scope jsonb DEFAULT '{}'::jsonb NOT NULL,
  ADD COLUMN IF NOT EXISTS reviewer_membership_id uuid,
  ADD COLUMN IF NOT EXISTS recurrence text,
  ADD COLUMN IF NOT EXISTS due_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS include_manager_tier boolean DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS include_team_roles boolean DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS include_platform_roles boolean DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS generated_by_job_id text,
  ADD COLUMN IF NOT EXISTS generation_status text DEFAULT 'complete' NOT NULL,
  ADD COLUMN IF NOT EXISTS catalog_version integer;

-- ── access_review_campaign: the three vocabularies, at the database ────────
-- A `text` column is plain text at the DB level, so each of the three words
-- this table now speaks gets a CHECK. The cost of leaving one off is not a
-- crash: `kind` decides which SERVICE owns a row, `generation_status` decides
-- whether a reader waits or reports emptiness, and a value outside the
-- vocabulary would be read by a `switch` with no branch for it and silently
-- treated as the default — which is the failure mode that hides.
ALTER TABLE access_review_campaign
  DROP CONSTRAINT IF EXISTS access_review_campaign_kind_check,
  ADD CONSTRAINT access_review_campaign_kind_check
    CHECK (kind IN ('legacy','program','break_glass')),
  DROP CONSTRAINT IF EXISTS access_review_campaign_recurrence_check,
  ADD CONSTRAINT access_review_campaign_recurrence_check
    CHECK (recurrence IN ('none','monthly','quarterly','semiannual','annual')),
  DROP CONSTRAINT IF EXISTS access_review_campaign_generation_status_check,
  ADD CONSTRAINT access_review_campaign_generation_status_check
    CHECK (generation_status IN ('generating','complete','failed'));

-- ── access_review_item: the routing and recommendation columns ─────────────
ALTER TABLE access_review_item
  ADD COLUMN IF NOT EXISTS reviewer_membership_id uuid,
  ADD COLUMN IF NOT EXISTS recommendation text,
  ADD COLUMN IF NOT EXISTS recommendation_evidence jsonb;

ALTER TABLE access_review_item
  DROP CONSTRAINT IF EXISTS access_review_item_recommendation_check,
  ADD CONSTRAINT access_review_item_recommendation_check
    CHECK (recommendation IN ('certify','revoke','review'));

-- ── THE FLOOR: a reviewer is never the subject ─────────────────────────────
-- NOT VALID, so the rows a deployment already self-decided stay readable while
-- every write from here on is bound. See the header for why no VALIDATE
-- follows and why a re-apply must not add one.
ALTER TABLE access_review_item
  DROP CONSTRAINT IF EXISTS access_review_item_reviewer_not_subject,
  ADD CONSTRAINT access_review_item_reviewer_not_subject
    CHECK (decided_by IS NULL OR decided_by <> user_id) NOT VALID;

-- ── The reviewer references, single-column and COMPOSITE ───────────────────
-- The single-column foreign key is named by hand: drizzle would derive
-- `access_review_campaign_reviewer_membership_id_organization_member_id_fk`
-- (71 bytes), which Postgres truncates at 63, so the declared name and the
-- stored name would differ and every drift report would show the constraint
-- being dropped and re-added forever.
--
-- The COMPOSITE tenancy key is the 0010/0011 class: a single-column reference
-- to `organization_member` is satisfied by ANY membership row in the cluster,
-- so a writer that lost its org predicate could route one tenant's campaign to
-- another tenant's member and the database would accept it. It uses the
-- column-list form of SET NULL — `ON DELETE SET NULL (reviewer_membership_id)`
-- — because the plain form would try to null `organization_id` too, which is
-- NOT NULL. That form is Postgres 15+ and is expressible in SQL but NOT in
-- drizzle, so this constraint lives in the migration alone and the column
-- carries the note (the shape `org_role_assignment.activation_id` already
-- uses).
ALTER TABLE access_review_campaign
  DROP CONSTRAINT IF EXISTS access_review_campaign_reviewer_member_fk,
  ADD CONSTRAINT access_review_campaign_reviewer_member_fk
    FOREIGN KEY (reviewer_membership_id) REFERENCES organization_member (id)
    ON DELETE SET NULL,
  DROP CONSTRAINT IF EXISTS access_review_campaign_reviewer_org_fk,
  ADD CONSTRAINT access_review_campaign_reviewer_org_fk
    FOREIGN KEY (organization_id, reviewer_membership_id)
    REFERENCES organization_member (organization_id, id)
    ON DELETE SET NULL (reviewer_membership_id);

ALTER TABLE access_review_item
  DROP CONSTRAINT IF EXISTS access_review_item_reviewer_member_fk,
  ADD CONSTRAINT access_review_item_reviewer_member_fk
    FOREIGN KEY (reviewer_membership_id) REFERENCES organization_member (id)
    ON DELETE SET NULL,
  DROP CONSTRAINT IF EXISTS access_review_item_reviewer_org_fk,
  ADD CONSTRAINT access_review_item_reviewer_org_fk
    FOREIGN KEY (organization_id, reviewer_membership_id)
    REFERENCES organization_member (organization_id, id)
    ON DELETE SET NULL (reviewer_membership_id);

-- ── The reviewer's queue ───────────────────────────────────────────────────
-- "What is on MY desk" is the one read a program campaign adds, and it is a
-- per-reviewer filter over a table that is otherwise only ever read by
-- campaign. Partial, because every legacy item carries NULL here and there is
-- no reviewer to look them up by.
CREATE INDEX IF NOT EXISTS access_review_item_reviewer_idx
  ON access_review_item (reviewer_membership_id)
  WHERE reviewer_membership_id IS NOT NULL;

-- ── The program campaign's due list ────────────────────────────────────────
-- `spawnRecurring` asks one question of every tenant at once: which program
-- campaigns recur and are past due. Partial on `recurrence IS NOT NULL`, so
-- the index holds only program rows and the daily sweep never scans a legacy
-- campaign.
CREATE INDEX IF NOT EXISTS access_review_campaign_recurrence_due_idx
  ON access_review_campaign (recurrence, due_at)
  WHERE recurrence IS NOT NULL;
