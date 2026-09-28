-- migrate-1.35.0.sql — schema delta 1.34.0 → 1.35.0 (lineage convergence, spec docs/superpowers/specs/2026-09-21-migration-lineage-convergence-design.md): legacy constraint names reconciled, RLS parity for assistant/organization_entitlement/knowledge_embedding_migration_state, the five legacy deltas converged. Source migrations 0034 (journaled migration 0034_legacy_name_reconciliation.sql), 0035 (0035_rls_parity_retrofit.sql) and 0036 (0036_legacy_delta_convergence.sql), carried whole below.
-- REQUIRES-REVIEW: 0036 re-applies legacy 0073 — the document_chunk organization
-- FK becomes ON DELETE CASCADE (was SET NULL) on any database that never
-- received it, so deleting an organization now DELETES its RAG corpus instead of
-- re-homing it. Review + take a backup, then apply via
-- ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh (update.sh's rolling path refuses
-- REQUIRES-REVIEW deltas by design). db/1.9.0 ledgered exactly this change for
-- the databases that DID receive 0073; this is the same door for the ones the
-- watermark law stamped complete without it.
-- Route: ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh   then   ./update.sh
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- This bundle's lineage and the journaled one had drifted in three ways that
-- nothing could see. (1) NAMES: legacy 0059/0060 renamed tables and indexes
-- but not CONSTRAINTS, and other legacy files created constraints inline, so a
-- database born on this packaged lineage carries 47 constraint names a fresh
-- one does not — `skill_pkey` among them, which on this lineage belongs to the
-- `assistant` table. Journaled 0002 drops one of them BY ITS FRESH NAME and
-- fails 42704 here, so a packaged database that ever meets `pnpm db:migrate`
-- stops at 0002. 0034 renames every pair, guarded on (conname, conrelid), and
-- heals `skill_submission(reviewed_by)` by COLUMN — one FK, ON DELETE SET
-- NULL, which is the 0002 contract finally true on this lineage too. (2) ROW
-- SECURITY: this lineage FORCES `tenant_isolation` on `assistant`,
-- `organization_entitlement` and `knowledge_embedding_migration_state` and the
-- fresh lineage never did (29 policies vs 26) — so 0035 is a no-op HERE and
-- the reason it exists is the other direction. It is carried anyway because a
-- delta that skipped it would let the two lineages diverge again the moment
-- either one is rebuilt. (3) THE FIVE LEGACY DELTAS a watermark-stamped
-- database may never have received (legacy 0072, 0073, 0082, 0084, 0094):
-- 0036 re-applies each legacy body under its own guard, so a database that
-- already has the object executes nothing, and adds `knowledge_embeddings`'s
-- dims CHECK (legacy 0055) which the fresh lineage never had.
--
-- WHAT MOVES. The one statement that changes BEHAVIOUR rather than shape is
-- 0073's, named in the REQUIRES-REVIEW block above: on a database that missed
-- legacy 0073, `document_chunk`'s organization FK is dropped and re-created as
-- ON DELETE CASCADE, so an organization delete takes its chunk rows with it
-- instead of leaving them with a NULL `organization_id`. Everything else is
-- name-only or additive: the renames move no data, the three policies are the
-- ones this lineage already enforces, and the four objects 0036 adds are new
-- ones. Two DROPs REMOVE something, and both are empty by construction —
-- `agent_memory` has zero readers in the image and zero rows (legacy 0094
-- dropped it on the databases that received it), and
-- `knowledge_embeddings_embedding_ivfflat_idx` is the redundant ANN index
-- legacy 0082 removed, with the HNSW index beside it serving every query. The
-- file's other DROP statements remove NOTHING on net: each
-- `DROP CONSTRAINT`/`DROP POLICY` here is immediately followed by the CREATE
-- that replaces it, in the same transaction — that is the idempotency pattern
-- (drop-then-create so a re-run lands the same shape), not a removal.
--
-- ROLLBACK: each source migration states its own posture in its own header
-- below — 0034 needs none (a rename is reversible by running the same DO block
-- with each pair swapped; the reviewed_by FK is the 0002 contract and is not
-- reverted), 0035 is three statements per table, 0036 is four statements plus
-- two forward-only DROPs. Read them there rather than trusting a summary here.
-- The 0073 cascade reverses with `ALTER TABLE document_chunk DROP CONSTRAINT
-- document_chunk_organization_id_organization_id_fk;` followed by the same
-- constraint re-added `ON DELETE SET NULL` — what it cannot reverse is a
-- delete that already cascaded, which is what the backup above is for.
--
-- Apply with psql -1 (ON_ERROR_STOP) so the file lands or does not.

-- ── 0034_legacy_name_reconciliation ──
-- 0034 — legacy constraint names → the fresh (0000_baseline) names, on every lineage (spec docs/superpowers/specs/2026-09-21-migration-lineage-convergence-design.md §A).
-- rollback: none needed — renames are name-only and a fresh database is a no-op; to restore legacy names run the same DO block with each (legacy, fresh) pair swapped. The reviewed_by block is the 0002 contract (one SET NULL FK) and is not reverted.
--
-- WHY. Legacy 0059/0060 renamed tables and indexes but not constraints, other
-- legacy files created constraints inline (Postgres auto-names) or with short
-- names, so a legacy-lineage database carries 47 constraint names a fresh one
-- does not. Journaled 0002 dropped one by its FRESH name and failed 42704 on
-- every legacy database, blocking 0002..0033 in one transaction. The
-- `runMigrate` preflight now reconciles a database stamped AT the watermark
-- before drizzle runs (it cannot reach this file otherwise); this migration is
-- the same render for databases already PAST 0002 — the dev database, and any
-- deployment whose 0002 was hand-fixed. Both are pinned to
-- src/lib/db/legacy-name-map.ts by legacy-name-reconciliation.parity.test.ts.
--
-- ORDER: `assistant` rows first — its PK is literally `skill_pkey` on a legacy
-- database, and index names are schema-unique, so `skill`'s `tool_pkey`
-- cannot take the name until it is freed. Every rename is guarded on
-- (conname, conrelid): a fresh database executes nothing. reviewed_by is
-- healed by COLUMN: every FK on skill_submission(reviewed_by) is dropped (the
-- legacy NO ACTION key, the fresh key, or the 1.22.0 duplicate pair) and
-- exactly one SET NULL key is added — the 0002 contract, finally true on the
-- packaged lineage too.
SET lock_timeout = '5s';
-- >>> legacy-name-reconciliation (generated from src/lib/db/legacy-name-map.ts — do not edit by hand)
DO $$
DECLARE
  renamed int := 0;
  c text;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_pkey' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_pkey' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_pkey TO assistant_pkey;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_agent_id_agent_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_agent_id_agent_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_agent_id_agent_id_fk TO assistant_agent_id_agent_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_created_by_user_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_created_by_user_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_created_by_user_id_fk TO assistant_created_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_knowledge_base_id_knowledge_base_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_knowledge_base_id_knowledge_base_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_knowledge_base_id_knowledge_base_id_fk TO assistant_knowledge_base_id_knowledge_base_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_organization_id_organization_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_organization_id_organization_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_organization_id_organization_id_fk TO assistant_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_prompt_version_id_prompt_version_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_prompt_version_id_prompt_version_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_prompt_version_id_prompt_version_id_fk TO assistant_prompt_version_id_prompt_version_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_reviewed_by_user_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_reviewed_by_user_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_reviewed_by_user_id_fk TO assistant_reviewed_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_team_id_team_id_fk' AND conrelid = to_regclass('assistant'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_team_id_team_id_fk' AND conrelid = to_regclass('assistant')) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_team_id_team_id_fk TO assistant_team_id_team_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_team_skill_id_team_id_pk' AND conrelid = to_regclass('assistant_team'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_team_assistant_id_team_id_pk' AND conrelid = to_regclass('assistant_team')) THEN
    ALTER TABLE assistant_team RENAME CONSTRAINT skill_team_skill_id_team_id_pk TO assistant_team_assistant_id_team_id_pk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_team_skill_id_skill_id_fk' AND conrelid = to_regclass('assistant_team'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_team_assistant_id_assistant_id_fk' AND conrelid = to_regclass('assistant_team')) THEN
    ALTER TABLE assistant_team RENAME CONSTRAINT skill_team_skill_id_skill_id_fk TO assistant_team_assistant_id_assistant_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_team_team_id_team_id_fk' AND conrelid = to_regclass('assistant_team'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assistant_team_team_id_team_id_fk' AND conrelid = to_regclass('assistant_team')) THEN
    ALTER TABLE assistant_team RENAME CONSTRAINT skill_team_team_id_team_id_fk TO assistant_team_team_id_team_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inference_request_log_skill_id_skill_id_fk' AND conrelid = to_regclass('inference_request_log'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inference_request_log_assistant_id_assistant_id_fk' AND conrelid = to_regclass('inference_request_log')) THEN
    ALTER TABLE inference_request_log RENAME CONSTRAINT inference_request_log_skill_id_skill_id_fk TO inference_request_log_assistant_id_assistant_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_pkey' AND conrelid = to_regclass('skill'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_pkey' AND conrelid = to_regclass('skill')) THEN
    ALTER TABLE skill RENAME CONSTRAINT tool_pkey TO skill_pkey;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_user_id_user_id_fk' AND conrelid = to_regclass('skill'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_user_id_user_id_fk' AND conrelid = to_regclass('skill')) THEN
    ALTER TABLE skill RENAME CONSTRAINT tool_user_id_user_id_fk TO skill_user_id_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_organization_id_organization_id_fk' AND conrelid = to_regclass('skill'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_organization_id_organization_id_fk' AND conrelid = to_regclass('skill')) THEN
    ALTER TABLE skill RENAME CONSTRAINT tool_organization_id_organization_id_fk TO skill_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_install_pkey' AND conrelid = to_regclass('skill_install'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_install_pkey' AND conrelid = to_regclass('skill_install')) THEN
    ALTER TABLE skill_install RENAME CONSTRAINT tool_install_pkey TO skill_install_pkey;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_install_tool_id_tool_id_fk' AND conrelid = to_regclass('skill_install'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_install_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_install')) THEN
    ALTER TABLE skill_install RENAME CONSTRAINT tool_install_tool_id_tool_id_fk TO skill_install_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_install_user_id_user_id_fk' AND conrelid = to_regclass('skill_install'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_install_user_id_user_id_fk' AND conrelid = to_regclass('skill_install')) THEN
    ALTER TABLE skill_install RENAME CONSTRAINT tool_install_user_id_user_id_fk TO skill_install_user_id_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_install_tool_id_user_id_unique' AND conrelid = to_regclass('skill_install'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_install_skill_id_user_id_unique' AND conrelid = to_regclass('skill_install')) THEN
    ALTER TABLE skill_install RENAME CONSTRAINT tool_install_tool_id_user_id_unique TO skill_install_skill_id_user_id_unique;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_rating_pkey' AND conrelid = to_regclass('skill_rating'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_rating_pkey' AND conrelid = to_regclass('skill_rating')) THEN
    ALTER TABLE skill_rating RENAME CONSTRAINT tool_rating_pkey TO skill_rating_pkey;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_rating_tool_id_tool_id_fk' AND conrelid = to_regclass('skill_rating'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_rating_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_rating')) THEN
    ALTER TABLE skill_rating RENAME CONSTRAINT tool_rating_tool_id_tool_id_fk TO skill_rating_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_rating_user_id_user_id_fk' AND conrelid = to_regclass('skill_rating'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_rating_user_id_user_id_fk' AND conrelid = to_regclass('skill_rating')) THEN
    ALTER TABLE skill_rating RENAME CONSTRAINT tool_rating_user_id_user_id_fk TO skill_rating_user_id_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_rating_tool_id_user_id_unique' AND conrelid = to_regclass('skill_rating'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_rating_skill_id_user_id_unique' AND conrelid = to_regclass('skill_rating')) THEN
    ALTER TABLE skill_rating RENAME CONSTRAINT tool_rating_tool_id_user_id_unique TO skill_rating_skill_id_user_id_unique;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_submission_pkey' AND conrelid = to_regclass('skill_submission'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_submission_pkey' AND conrelid = to_regclass('skill_submission')) THEN
    ALTER TABLE skill_submission RENAME CONSTRAINT tool_submission_pkey TO skill_submission_pkey;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_submission_tool_id_tool_id_fk' AND conrelid = to_regclass('skill_submission'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_submission_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_submission')) THEN
    ALTER TABLE skill_submission RENAME CONSTRAINT tool_submission_tool_id_tool_id_fk TO skill_submission_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tool_submission_user_id_user_id_fk' AND conrelid = to_regclass('skill_submission'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_submission_user_id_user_id_fk' AND conrelid = to_regclass('skill_submission')) THEN
    ALTER TABLE skill_submission RENAME CONSTRAINT tool_submission_user_id_user_id_fk TO skill_submission_user_id_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_embedding_migration_state_organization_id_fkey' AND conrelid = to_regclass('knowledge_embedding_migration_state'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_embedding_migration_state_organization_id_organizatio' AND conrelid = to_regclass('knowledge_embedding_migration_state')) THEN
    ALTER TABLE knowledge_embedding_migration_state RENAME CONSTRAINT knowledge_embedding_migration_state_organization_id_fkey TO knowledge_embedding_migration_state_organization_id_organizatio;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_embedding_migration_state_user_id_fkey' AND conrelid = to_regclass('knowledge_embedding_migration_state'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_embedding_migration_state_user_id_user_id_fk' AND conrelid = to_regclass('knowledge_embedding_migration_state')) THEN
    ALTER TABLE knowledge_embedding_migration_state RENAME CONSTRAINT knowledge_embedding_migration_state_user_id_fkey TO knowledge_embedding_migration_state_user_id_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'semantic_response_cache_organization_id_fkey' AND conrelid = to_regclass('semantic_response_cache'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'semantic_response_cache_organization_id_organization_id_fk' AND conrelid = to_regclass('semantic_response_cache')) THEN
    ALTER TABLE semantic_response_cache RENAME CONSTRAINT semantic_response_cache_organization_id_fkey TO semantic_response_cache_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_policy_version_organization_id_fkey' AND conrelid = to_regclass('org_policy_version'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_policy_version_organization_id_organization_id_fk' AND conrelid = to_regclass('org_policy_version')) THEN
    ALTER TABLE org_policy_version RENAME CONSTRAINT org_policy_version_organization_id_fkey TO org_policy_version_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_policy_version_changed_by_fkey' AND conrelid = to_regclass('org_policy_version'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'org_policy_version_changed_by_user_id_fk' AND conrelid = to_regclass('org_policy_version')) THEN
    ALTER TABLE org_policy_version RENAME CONSTRAINT org_policy_version_changed_by_fkey TO org_policy_version_changed_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'job_execution_organization_id_fkey' AND conrelid = to_regclass('job_execution'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'job_execution_organization_id_organization_id_fk' AND conrelid = to_regclass('job_execution')) THEN
    ALTER TABLE job_execution RENAME CONSTRAINT job_execution_organization_id_fkey TO job_execution_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'event_outbox_organization_id_fkey' AND conrelid = to_regclass('event_outbox'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'event_outbox_organization_id_organization_id_fk' AND conrelid = to_regclass('event_outbox')) THEN
    ALTER TABLE event_outbox RENAME CONSTRAINT event_outbox_organization_id_fkey TO event_outbox_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'agent_deployment_owner_user_id_fkey' AND conrelid = to_regclass('agent_deployment'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'agent_deployment_owner_user_id_user_id_fk' AND conrelid = to_regclass('agent_deployment')) THEN
    ALTER TABLE agent_deployment RENAME CONSTRAINT agent_deployment_owner_user_id_fkey TO agent_deployment_owner_user_id_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'organization_entitlement_organization_id_fkey' AND conrelid = to_regclass('organization_entitlement'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'organization_entitlement_organization_id_organization_id_fk' AND conrelid = to_regclass('organization_entitlement')) THEN
    ALTER TABLE organization_entitlement RENAME CONSTRAINT organization_entitlement_organization_id_fkey TO organization_entitlement_organization_id_organization_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'organization_entitlement_updated_by_fkey' AND conrelid = to_regclass('organization_entitlement'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'organization_entitlement_updated_by_user_id_fk' AND conrelid = to_regclass('organization_entitlement')) THEN
    ALTER TABLE organization_entitlement RENAME CONSTRAINT organization_entitlement_updated_by_fkey TO organization_entitlement_updated_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_run_skill_id_fk' AND conrelid = to_regclass('skill_qa_run'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_run_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_qa_run')) THEN
    ALTER TABLE skill_qa_run RENAME CONSTRAINT skill_qa_run_skill_id_fk TO skill_qa_run_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_run_requested_by_fk' AND conrelid = to_regclass('skill_qa_run'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_run_requested_by_user_id_fk' AND conrelid = to_regclass('skill_qa_run')) THEN
    ALTER TABLE skill_qa_run RENAME CONSTRAINT skill_qa_run_requested_by_fk TO skill_qa_run_requested_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_check_result_run_id_fk' AND conrelid = to_regclass('skill_qa_check_result'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_check_result_run_id_skill_qa_run_id_fk' AND conrelid = to_regclass('skill_qa_check_result')) THEN
    ALTER TABLE skill_qa_check_result RENAME CONSTRAINT skill_qa_check_result_run_id_fk TO skill_qa_check_result_run_id_skill_qa_run_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_check_result_skill_id_fk' AND conrelid = to_regclass('skill_qa_check_result'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_check_result_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_qa_check_result')) THEN
    ALTER TABLE skill_qa_check_result RENAME CONSTRAINT skill_qa_check_result_skill_id_fk TO skill_qa_check_result_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_skill_id_fk' AND conrelid = to_regclass('skill_qa_certification'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_qa_certification')) THEN
    ALTER TABLE skill_qa_certification RENAME CONSTRAINT skill_qa_certification_skill_id_fk TO skill_qa_certification_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_run_id_fk' AND conrelid = to_regclass('skill_qa_certification'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_run_id_skill_qa_run_id_fk' AND conrelid = to_regclass('skill_qa_certification')) THEN
    ALTER TABLE skill_qa_certification RENAME CONSTRAINT skill_qa_certification_run_id_fk TO skill_qa_certification_run_id_skill_qa_run_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_issued_by_fk' AND conrelid = to_regclass('skill_qa_certification'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_issued_by_user_id_fk' AND conrelid = to_regclass('skill_qa_certification')) THEN
    ALTER TABLE skill_qa_certification RENAME CONSTRAINT skill_qa_certification_issued_by_fk TO skill_qa_certification_issued_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_revoked_by_fk' AND conrelid = to_regclass('skill_qa_certification'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_certification_revoked_by_user_id_fk' AND conrelid = to_regclass('skill_qa_certification')) THEN
    ALTER TABLE skill_qa_certification RENAME CONSTRAINT skill_qa_certification_revoked_by_fk TO skill_qa_certification_revoked_by_user_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_recording_run_id_fk' AND conrelid = to_regclass('skill_qa_recording'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_recording_run_id_skill_qa_run_id_fk' AND conrelid = to_regclass('skill_qa_recording')) THEN
    ALTER TABLE skill_qa_recording RENAME CONSTRAINT skill_qa_recording_run_id_fk TO skill_qa_recording_run_id_skill_qa_run_id_fk;
    renamed := renamed + 1;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_recording_skill_id_fk' AND conrelid = to_regclass('skill_qa_recording'))
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'skill_qa_recording_skill_id_skill_id_fk' AND conrelid = to_regclass('skill_qa_recording')) THEN
    ALTER TABLE skill_qa_recording RENAME CONSTRAINT skill_qa_recording_skill_id_fk TO skill_qa_recording_skill_id_skill_id_fk;
    renamed := renamed + 1;
  END IF;

  -- reviewed_by: drop EVERY foreign key on skill_submission(reviewed_by) (legacy name,
  -- fresh name, or the 1.22.0 duplicate pair), then add exactly one with ON DELETE SET NULL.
  IF to_regclass('skill_submission') IS NOT NULL THEN
    FOR c IN
      SELECT con.conname FROM pg_constraint con
      JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
      WHERE con.conrelid = to_regclass('skill_submission') AND con.contype = 'f' AND a.attname = 'reviewed_by'
    LOOP
      EXECUTE format('ALTER TABLE skill_submission DROP CONSTRAINT %I', c);
    END LOOP;
    ALTER TABLE skill_submission ADD CONSTRAINT skill_submission_reviewed_by_user_id_fk FOREIGN KEY (reviewed_by) REFERENCES "user"(id) ON DELETE SET NULL;
  END IF;
  RAISE NOTICE 'legacy-name-reconciliation: % constraint(s) renamed', renamed;
END $$;
-- <<< legacy-name-reconciliation

-- ── 0035_rls_parity_retrofit ──
-- 0035 — row security the LEGACY lineage has and the fresh lineage lacked: assistant, organization_entitlement, knowledge_embedding_migration_state (spec §B1).
-- rollback: per-table `ALTER TABLE <t> NO FORCE ROW LEVEL SECURITY; ALTER TABLE <t> DISABLE ROW LEVEL SECURITY; DROP POLICY IF EXISTS tenant_isolation ON <t>;` restores the fresh lineage's pre-0035 posture; grants are additive and harmless to leave.
--
-- WHY. Legacy 0059 (assistant), legacy 0055 (knowledge_embedding_migration_state)
-- and rls/0018 (organization_entitlement, the follow-up legacy 0078 REQUIRED)
-- ENABLE+FORCE row security with a tenant_isolation policy. 0000_baseline
-- carries no policies; 0001/0003 carry the seven knowledge tables; 0017+ the
-- authorization substrate. Nothing carried these three, so a FRESH install was
-- LESS isolated than an upgraded legacy database (29 policies vs 26), and the
-- RLS coverage ledger could not see it because it counted the stale rls/*.sql
-- files as coverage. Every reader of the three tables runs under withTenant
-- (assistant-repository.pg.ts, assistant-registry.ts, the entitlement and
-- embedding-migration services), so forcing the policy blanks nothing.
-- Predicates are the ones the legacy lineage already enforces, so this is a
-- no-op there. Idempotent: DROP POLICY IF EXISTS before CREATE.
SET lock_timeout = '5s';
DO $$
DECLARE
  t text;
  strict_org text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid';
BEGIN
  FOREACH t IN ARRAY ARRAY['assistant', 'organization_entitlement'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t, strict_org, strict_org);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO neo_gen', t);
  END LOOP;
END $$;
DO $$
DECLARE
  t text;
  pred text := 'organization_id = NULLIF(current_setting(''app.current_org_id'', true), '''')::uuid'
    || ' OR (organization_id IS NULL AND user_id = NULLIF(current_setting(''app.current_user_id'', true), '''')::uuid)';
BEGIN
  FOREACH t IN ARRAY ARRAY['knowledge_embedding_migration_state'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t, pred, pred);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO neo_gen', t);
  END LOOP;
END $$;

-- ── 0036_legacy_delta_convergence ──
-- 0036 — the legacy deltas a watermark-stamped legacy database may never have received (0072, 0073, 0082, 0084, 0094), plus the dims CHECK the fresh lineage never had (spec §C1).
-- rollback: `ALTER TABLE document_chunk DROP CONSTRAINT IF EXISTS document_chunk_organization_id_organization_id_fk; ALTER TABLE document_chunk ADD CONSTRAINT document_chunk_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES organization(id) ON DELETE SET NULL; ALTER TABLE nav_visibility_override DROP CONSTRAINT IF EXISTS nav_visibility_override_scope_org_check; DROP INDEX IF EXISTS cron_run_log_one_running_per_job; ALTER TABLE knowledge_embeddings DROP CONSTRAINT IF EXISTS knowledge_embeddings_dims_col_ck;` — the two DROPs (agent_memory, the ivfflat index) are forward-only: agent_memory had zero readers and zero rows (legacy 0094), the index was redundant (legacy 0082).
--
-- WHY. The watermark law stamps every pre-#158 database as "complete through
-- legacy 0099". The dev database proved otherwise: it never received 0072
-- (cron_run_log one-running index), 0073 (document_chunk org FK → CASCADE),
-- 0082 (drop the redundant ivfflat index), 0084 (nav_visibility_override
-- scope CHECK) or 0094 (drop agent_memory). None had a sentinel; db:drift-report
-- compares tables/columns only. Each block below re-applies the legacy file's
-- own guarded body, so a fresh database (already in this shape) executes
-- nothing. The dims CHECK (legacy 0055) went the other way: legacy has it,
-- fresh never did, and schema.pg.ts cites it — it now exists on both.
--
-- ONE BLOCK REFUSES rather than degrades (0072). Its unique index cannot be
-- created while some cron job already holds two rows at status = 'running',
-- and a NOTICE there left the 0036 index sentinel refusing EVERY later boot
-- (MigrationIncompleteError) with the remedy stranded in a log line: so that
-- block RAISEs, carrying its own triage query and fix, and the whole batch
-- rolls back unchanged. `pnpm db:preflight` answers it BEFORE the run — gate
-- `0036-cron-duplicate-running`, the same count, read-only.
SET lock_timeout = '5s';
-- 0073: document_chunk.organization_id must CASCADE (ADR-0045 F50). Found by
-- COLUMN, not name — and by EVERY key on that column, not one of them. The
-- first cut used `SELECT … INTO c, act`, which takes an ARBITRARY single row:
-- a database carrying the 1.22.0-shaped DUPLICATE pair on this column (two
-- keys, different names, different delete actions — exactly what 0034 heals
-- for skill_submission(reviewed_by)) could have its CASCADE key picked, leave
-- the non-CASCADE one in place, and satisfy the sentinel while an organization
-- delete still fails on the second key. This mirrors 0034's reviewed_by heal:
-- drop every non-CASCADE key on the column, then add the CASCADE one only if
-- none with CASCADE remains — so a fresh database (one CASCADE key already)
-- executes nothing.
DO $$
DECLARE c text; cascading int;
BEGIN
  FOR c IN
    SELECT con.conname FROM pg_constraint con
    JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
    WHERE con.conrelid = 'document_chunk'::regclass AND con.contype = 'f'
      AND a.attname = 'organization_id' AND con.confdeltype <> 'c'
  LOOP
    EXECUTE format('ALTER TABLE document_chunk DROP CONSTRAINT %I', c);
  END LOOP;
  SELECT count(*)::int INTO cascading
    FROM pg_constraint con
    JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
   WHERE con.conrelid = 'document_chunk'::regclass AND con.contype = 'f'
     AND a.attname = 'organization_id' AND con.confdeltype = 'c';
  IF cascading = 0 THEN
    ALTER TABLE document_chunk
      ADD CONSTRAINT document_chunk_organization_id_organization_id_fk
      FOREIGN KEY (organization_id) REFERENCES organization(id) ON DELETE CASCADE;
  END IF;
END $$;
-- 0084: scope and organization_id agree, and the CHECK says so.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'nav_visibility_override_scope_org_check' AND conrelid = 'nav_visibility_override'::regclass) THEN
    UPDATE nav_visibility_override
       SET scope = CASE WHEN organization_id IS NULL THEN 'global' ELSE 'org' END
     WHERE (scope = 'global') <> (organization_id IS NULL);
    ALTER TABLE nav_visibility_override
      ADD CONSTRAINT nav_visibility_override_scope_org_check
      CHECK ((scope = 'global') = (organization_id IS NULL));
  END IF;
END $$;
-- 0072: one running row per cron job. FAIL CLOSED, not degrade. The first cut
-- RAISEd a NOTICE and carried on — and the 0036 index sentinel then refused
-- EVERY later boot with MigrationIncompleteError naming an index whose remedy
-- existed only in a NOTICE line already scrolled away. A refusal HERE is the
-- same fact stated where it can be acted on: the batch rolls back, nothing is
-- changed, and the message carries the triage query and the fix (0011's
-- DETAIL/HINT shape).
DO $$
DECLARE dupes int;
BEGIN
  BEGIN
    CREATE UNIQUE INDEX IF NOT EXISTS cron_run_log_one_running_per_job
      ON cron_run_log (cron_job_id) WHERE status = 'running';
  EXCEPTION WHEN unique_violation THEN
    SELECT count(*)::int INTO dupes FROM (
      SELECT cron_job_id FROM cron_run_log WHERE status = 'running' GROUP BY cron_job_id HAVING count(*) > 1
    ) d;
    RAISE EXCEPTION
      'migration 0036 STOPPED: % cron job(s) already hold more than one cron_run_log row at status = ''running'', so cron_run_log_one_running_per_job cannot be created',
      dupes
      USING
        DETAIL = 'Triage (read-only): SELECT cron_job_id, count(*) FROM cron_run_log WHERE status = ''running'' GROUP BY 1 HAVING count(*) > 1;',
        HINT = 'Finalize the duplicate ''running'' rows — cleanupStaleLogs sweeps them, or UPDATE them to ''failed'' — then re-run pnpm db:migrate. The whole batch rolled back, nothing was changed. pnpm db:preflight reports this in advance as gate 0036-cron-duplicate-running.';
  END;
END $$;
-- 0055: dims must name exactly the populated vector column. NOT VALID — no scan; new rows bind.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_embeddings_dims_col_ck' AND conrelid = 'knowledge_embeddings'::regclass) THEN
    ALTER TABLE knowledge_embeddings ADD CONSTRAINT knowledge_embeddings_dims_col_ck CHECK (
      (dims = 1536 AND embedding      IS NOT NULL AND embedding_768 IS NULL AND embedding_1024 IS NULL AND embedding_3072 IS NULL) OR
      (dims = 768  AND embedding_768  IS NOT NULL AND embedding     IS NULL AND embedding_1024 IS NULL AND embedding_3072 IS NULL) OR
      (dims = 1024 AND embedding_1024 IS NOT NULL AND embedding     IS NULL AND embedding_768  IS NULL AND embedding_3072 IS NULL) OR
      (dims = 3072 AND embedding_3072 IS NOT NULL AND embedding     IS NULL AND embedding_768  IS NULL AND embedding_1024 IS NULL)
    ) NOT VALID;
  END IF;
END $$;
-- 0082 / 0094 (approved 2026-09-21): the redundant ANN index and the orphan table.
-- The index drop is table-scoped inside a DO block (shape rail, ≥0034: a DROP by
-- name outside one is a defect); a table name is schema-unique, so the table drop is bare.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'knowledge_embeddings' AND indexname = 'knowledge_embeddings_embedding_ivfflat_idx') THEN
    DROP INDEX knowledge_embeddings_embedding_ivfflat_idx;
  END IF;
END $$;
-- What the drop takes with it, on the record (the table is forward-only, so
-- the NOTICE is the only trace a legacy database's row count leaves).
DO $$
DECLARE n bigint;
BEGIN
  IF to_regclass('public.agent_memory') IS NOT NULL THEN
    EXECUTE 'SELECT count(*) FROM agent_memory' INTO n;
    RAISE NOTICE 'migration 0036: dropping agent_memory (% row(s))', n;
  END IF;
END $$;
DROP TABLE IF EXISTS agent_memory;
