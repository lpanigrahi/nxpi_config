-- migrate-1.3.0.sql — schema delta 1.2.0 → 1.3.0 (source migrations 0055–0062).
--
-- REQUIRES-REVIEW: contains TABLE RENAMES (skill→assistant, tool→skill et al).
-- Renames are DATA-PRESERVING (no rows are dropped or modified destructively)
-- but they are NOT additive: the 1.2.x app image cannot run against the renamed
-- schema, so the rolling-update path (additive rollback contract) must not
-- apply this file. Apply via:  ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh
-- (migrate.sh takes its own safety backup first).
--
-- Composed verbatim from the application tree's hand-authored IDEMPOTENT
-- deltas, in order — every step is existence-guarded, so re-running is a no-op:
--   0055_knowledge_embeddings_multidim.sql   (multi-width embedding store)
--   0056_chat_memory_core.sql                (memory_entry.last_accessed_at, chat_thread.metadata)
--   0057_inference_cache_attribution.sql     (cache columns on inference_request_log)
--   0058_semantic_response_cache.sql         (new table + HNSW indexes)
--   0059_rename_skill_to_assistant.sql       (org persona skill→assistant + stored-data migration)
--   0060_rename_tool_to_skill.sql            (workspace tool→skill + stored-data migration)
--   0061_assistant_published_slug_unique.sql (partial unique index, degrade-to-NOTICE)
--   0062_notification_deleted_at.sql         (notification soft-delete)
--
-- ORDER IS LOAD-BEARING: 0059 must vacate the `skill` name (persona→assistant)
-- BEFORE 0060 reuses `skill` for the ex-`tool` workspace entity. Applying 0060
-- first would rename `tool` onto a still-occupied name and fail.


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0055_knowledge_embeddings_multidim.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Phase A (multi-model embedding store) — dimension-aware `knowledge_embeddings`.
-- Idempotent + additive (safe to re-run). Apply with the PRIVILEGED role:
--   pnpm dotenv -- bash -c 'psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 -f src/lib/db/pg/migrations/pg/0055_knowledge_embeddings_multidim.sql'
--
-- pgvector `vector(N)` columns are fixed-width and one HNSW index is built per
-- width, so mixed dimensions need one column per width. `knowledge_embeddings`
-- becomes the primary vector store: 1536 reuses the legacy `embedding` column
-- (now the "1536 slot"), 768/1024 add `vector` columns, 3072 uses `halfvec`
-- (pgvector's HNSW `vector` opclass caps at 2000 dims). Exactly one vector column
-- is populated per row, keyed by `dims`. Existing 1536 rows are unaffected.

-- ── 1. Native-width vector columns (nullable; exactly one populated per row) ──
ALTER TABLE knowledge_embeddings
  ADD COLUMN IF NOT EXISTS embedding_768  vector(768),
  ADD COLUMN IF NOT EXISTS embedding_1024 vector(1024),
  ADD COLUMN IF NOT EXISTS embedding_3072 halfvec(3072);

-- ── 2. Relax the legacy 1536 column so non-1536 rows can exist (the 1536 slot) ─
--    Metadata-only, instant. Existing rows keep their values; new 1536 rows fill it.
ALTER TABLE knowledge_embeddings ALTER COLUMN embedding DROP NOT NULL;

-- `document_chunk.embedding` must also tolerate non-1536 scopes: for those the
-- vector lives ONLY in knowledge_embeddings; for 1536 scopes it is still filled
-- (legacy read path). Safe — existing rows keep values, HNSW skips NULLs.
ALTER TABLE document_chunk ALTER COLUMN embedding DROP NOT NULL;

-- ── 3. Integrity: `dims` must match exactly the one populated vector column ───
--    NOT VALID = no full-table scan now; VALIDATE after the backfill lands.
ALTER TABLE knowledge_embeddings
  DROP CONSTRAINT IF EXISTS knowledge_embeddings_dims_col_ck;
ALTER TABLE knowledge_embeddings
  ADD CONSTRAINT knowledge_embeddings_dims_col_ck CHECK (
    (dims = 1536 AND embedding      IS NOT NULL AND embedding_768 IS NULL AND embedding_1024 IS NULL AND embedding_3072 IS NULL) OR
    (dims = 768  AND embedding_768  IS NOT NULL AND embedding     IS NULL AND embedding_1024 IS NULL AND embedding_3072 IS NULL) OR
    (dims = 1024 AND embedding_1024 IS NOT NULL AND embedding     IS NULL AND embedding_768  IS NULL AND embedding_3072 IS NULL) OR
    (dims = 3072 AND embedding_3072 IS NOT NULL AND embedding     IS NULL AND embedding_768  IS NULL AND embedding_1024 IS NULL)
  ) NOT VALID;

-- ── 4. Per-width partial ANN indexes ────────────────────────────────────────
-- The new width columns start EMPTY everywhere, so a plain CREATE INDEX is
-- instant (nothing to scan/lock) and is used here for fresh-provision parity
-- with 0026. On an already-populated deployment, build these CONCURRENTLY by
-- hand instead (outside any transaction):
--   CREATE INDEX CONCURRENTLY IF NOT EXISTS ... WHERE <col> IS NOT NULL;
-- The existing knowledge_embeddings_embedding_hnsw_idx already covers the 1536 slot.
CREATE INDEX IF NOT EXISTS knowledge_embeddings_e768_hnsw_idx
  ON knowledge_embeddings USING hnsw (embedding_768 vector_cosine_ops)
  WITH (m = 16, ef_construction = 64) WHERE embedding_768 IS NOT NULL;
CREATE INDEX IF NOT EXISTS knowledge_embeddings_e1024_hnsw_idx
  ON knowledge_embeddings USING hnsw (embedding_1024 vector_cosine_ops)
  WITH (m = 16, ef_construction = 64) WHERE embedding_1024 IS NOT NULL;
CREATE INDEX IF NOT EXISTS knowledge_embeddings_e3072_hnsw_idx
  ON knowledge_embeddings USING hnsw (embedding_3072 halfvec_cosine_ops)
  WITH (m = 16, ef_construction = 64) WHERE embedding_3072 IS NOT NULL;

-- ── 5. Per-scope read-flip control table ────────────────────────────────────
-- Records which (org | user) scopes have been backfilled + verified and may read
-- from the new multi-model store. Same (org, user) scope shape + tenant_isolation
-- RLS as embedding_config, so the request-path read runs safely under withTenant.
-- Backfill writes run on the privileged pool (owner bypasses FORCE RLS). Global
-- rollout is gated by the RAG_MULTI_MODEL_STORE_READ env master flag, not a row.
CREATE TABLE IF NOT EXISTS knowledge_embedding_migration_state (
  id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organization(id) ON DELETE CASCADE,
  user_id uuid REFERENCES "user"(id) ON DELETE CASCADE,
  backfilled_at timestamp,
  verified_at timestamp,
  read_from_new boolean NOT NULL DEFAULT false,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Per-scope uniqueness. A composite (organization_id, user_id) unique index is
-- USELESS here: every scope row has one NULL key column and PG unique indexes
-- are NULLS-DISTINCT by default, so it would never dedupe (and an ON CONFLICT
-- on it never fires). Two PARTIAL unique indexes give real uniqueness per scope
-- shape AND serve as ON CONFLICT arbiters for the flip upsert.
DROP INDEX IF EXISTS knowledge_embedding_migration_state_scope_idx;
-- Dedupe first: the dropped composite index never deduped per-scope rows
-- (NULLS DISTINCT), so an earlier iteration may have left duplicates that would
-- abort the partial unique index creation below. Keep the newest row per scope.
DELETE FROM knowledge_embedding_migration_state a
  USING knowledge_embedding_migration_state b
  WHERE a.id <> b.id
    AND a.organization_id IS NOT DISTINCT FROM b.organization_id
    AND a.user_id IS NOT DISTINCT FROM b.user_id
    AND (a.updated_at, a.id) < (b.updated_at, b.id);
CREATE UNIQUE INDEX IF NOT EXISTS knowledge_embedding_migration_state_org_scope_idx
  ON knowledge_embedding_migration_state (organization_id) WHERE user_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS knowledge_embedding_migration_state_user_scope_idx
  ON knowledge_embedding_migration_state (user_id) WHERE organization_id IS NULL;
CREATE INDEX IF NOT EXISTS knowledge_embedding_migration_state_org_idx
  ON knowledge_embedding_migration_state (organization_id);
CREATE INDEX IF NOT EXISTS knowledge_embedding_migration_state_user_idx
  ON knowledge_embedding_migration_state (user_id);

-- ── 6. Tenant isolation (RLS) + app-role grant (same pattern as 0026/0028) ───
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

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0056_chat_memory_core.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Chat Memory Core — schema delta. Idempotent + additive (safe to re-run).
--
-- Apply with the PRIVILEGED (superuser) role:
--   pnpm dotenv -- bash -c 'psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 -f src/lib/db/pg/migrations/pg/0056_chat_memory_core.sql'
--
-- 1) memory_entry.last_accessed_at — touch-on-read timestamp behind the
--    composite retrieval score (relevance x recency x importance). NULL for
--    pre-existing rows; ranking falls back to created_at. Re-ranking happens
--    in TypeScript over a small over-fetched candidate set, so no index.
-- 2) chat_thread.metadata — general-purpose jsonb for thread-level flags;
--    first consumer is { memoryDisabled?: boolean } (per-thread incognito).
--
-- ADD COLUMN IF NOT EXISTS is additive + non-destructive. PostgreSQL
-- table-level privileges automatically cover new columns, so no extra GRANT
-- is needed; neither table is FORCE-RLS-affected by the addition.

ALTER TABLE memory_entry ADD COLUMN IF NOT EXISTS last_accessed_at timestamp;
ALTER TABLE chat_thread ADD COLUMN IF NOT EXISTS metadata jsonb;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0057_inference_cache_attribution.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- LLM Caching Program (Phase 1) — cache attribution on inference_request_log.
-- Idempotent + additive (safe to re-run).
--
-- Apply with the PRIVILEGED (superuser) role:
--   pnpm dotenv -- bash -c 'psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 -f src/lib/db/pg/migrations/pg/0057_inference_cache_attribution.sql'
--
-- cached_input_tokens / cache_write_tokens mirror the AI SDK's
-- usage.inputTokenDetails (cacheReadTokens / cacheWriteTokens) — provider-native
-- prompt-cache traffic that was previously dropped on the floor. Anthropic bills
-- cache writes at a premium and reads at a discount, so both sides are needed
-- for real cost accounting (consumed by later caching phases).
--
-- cache_hit / cache_layer mark responses served from the app-level response
-- cache ("exact" | "semantic" | "provider" — validated in the app layer).
-- prompt_fingerprint is the SHA-256 of the static prompt sections (Phase 3).
--
-- All columns are defaulted/nullable + forward-only: historical rows stay at
-- defaults and analytics attribute cache savings "since deploy". ADD COLUMN
-- with a constant DEFAULT is metadata-only in PostgreSQL 11+ (no table rewrite).

ALTER TABLE inference_request_log ADD COLUMN IF NOT EXISTS cached_input_tokens integer NOT NULL DEFAULT 0;
ALTER TABLE inference_request_log ADD COLUMN IF NOT EXISTS cache_write_tokens integer NOT NULL DEFAULT 0;
ALTER TABLE inference_request_log ADD COLUMN IF NOT EXISTS cache_hit boolean NOT NULL DEFAULT false;
ALTER TABLE inference_request_log ADD COLUMN IF NOT EXISTS cache_layer text;
ALTER TABLE inference_request_log ADD COLUMN IF NOT EXISTS prompt_fingerprint text;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0058_semantic_response_cache.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- LLM Caching Program (Phase 5) — semantic response cache.
-- Idempotent + additive (safe to re-run).
--
-- Apply with the PRIVILEGED (superuser) role:
--   pnpm dotenv -- bash -c 'psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 -f src/lib/db/pg/migrations/pg/0058_semantic_response_cache.sql'
--
-- One row per cached LLM response, addressable by query-embedding cosine
-- similarity within a STRICT scope (organization + user + model + static
-- prompt fingerprint). Multi-width embedding columns follow the
-- knowledge_embeddings pattern (exactly one populated per row; 3072 uses
-- halfvec — beyond pgvector's 2000-dim HNSW cap for plain vectors).
--
-- No RLS: reached only via SemanticCacheService whose every query carries all
-- scope columns (service-enforced scoping — the organization_member
-- precedent). Feature is default-OFF (platform flag / env kill-switch).

CREATE TABLE IF NOT EXISTS semantic_response_cache (
  id uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organization(id) ON DELETE CASCADE,
  user_scope text NOT NULL,
  model_id text NOT NULL,
  static_fingerprint text,
  query_text text NOT NULL,
  embedding vector(1536),
  embedding_768 vector(768),
  embedding_1024 vector(1024),
  embedding_3072 halfvec(3072),
  embedding_model text NOT NULL,
  dims integer NOT NULL DEFAULT 1536,
  envelope json NOT NULL,
  hit_count integer NOT NULL DEFAULT 0,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at timestamp NOT NULL
);

CREATE INDEX IF NOT EXISTS semantic_response_cache_org_idx
  ON semantic_response_cache (organization_id);
CREATE INDEX IF NOT EXISTS semantic_response_cache_scope_idx
  ON semantic_response_cache (user_scope, model_id, static_fingerprint);
CREATE INDEX IF NOT EXISTS semantic_response_cache_expires_idx
  ON semantic_response_cache (expires_at);

CREATE INDEX IF NOT EXISTS semantic_response_cache_embedding_hnsw_idx
  ON semantic_response_cache USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS semantic_response_cache_e768_hnsw_idx
  ON semantic_response_cache USING hnsw (embedding_768 vector_cosine_ops);
CREATE INDEX IF NOT EXISTS semantic_response_cache_e1024_hnsw_idx
  ON semantic_response_cache USING hnsw (embedding_1024 vector_cosine_ops);
CREATE INDEX IF NOT EXISTS semantic_response_cache_e3072_hnsw_idx
  ON semantic_response_cache USING hnsw (embedding_3072 halfvec_cosine_ops);

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0059_rename_skill_to_assistant.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 0059: Rename org persona entity `skill` → `assistant` (Tools/Skills/Assistants rename program, Phase 1).
--
-- Hand-authored IDEMPOTENT delta (dir2 canonical tree). The dev DB is
-- push-provisioned from schema.pg.ts (which now declares `assistant`), so fresh
-- resets never exercise this file; it exists to migrate EXISTING databases that
-- still carry the ex-copilot `skill` table. Apply directly, NOT via drizzle migrate:
--   psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 \
--     -f src/lib/db/pg/migrations/pg/0059_rename_skill_to_assistant.sql
--
-- Supersedes 0016_rename_copilot_to_skill for the persona entity and frees the
-- `skill` / `skill_team` / 'skill' namespace for the workspace agent-skill entity
-- (Phase 2 → 0060). Every step is existence-guarded so re-running is a no-op AND it
-- will not fight a fresh drizzle-pushed schema that already carries the new names.

BEGIN;

-- ── 1. Rename tables ─────────────────────────────────────────────────────────
DO $$ BEGIN
  IF to_regclass('public.skill') IS NOT NULL AND to_regclass('public.assistant') IS NULL THEN
    ALTER TABLE skill RENAME TO assistant;
  END IF;
  IF to_regclass('public.skill_team') IS NOT NULL AND to_regclass('public.assistant_team') IS NULL THEN
    ALTER TABLE skill_team RENAME TO assistant_team;
  END IF;
END $$;

-- ── 2. Rename FK columns ─────────────────────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='assistant_team' AND column_name='skill_id') THEN
    ALTER TABLE assistant_team RENAME COLUMN skill_id TO assistant_id;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='inference_request_log' AND column_name='skill_id') THEN
    ALTER TABLE inference_request_log RENAME COLUMN skill_id TO assistant_id;
  END IF;
END $$;

-- ── 3. Rename indexes / constraints (cosmetic; functionality is name-independent) ─
ALTER INDEX IF EXISTS skill_org_id_idx           RENAME TO assistant_org_id_idx;
ALTER INDEX IF EXISTS skill_agent_id_idx         RENAME TO assistant_agent_id_idx;
ALTER INDEX IF EXISTS skill_org_governance_idx   RENAME TO assistant_org_governance_idx;
ALTER INDEX IF EXISTS skill_team_id_idx          RENAME TO assistant_team_id_idx;
ALTER INDEX IF EXISTS inference_request_log_skill_id_created_at_idx
                      RENAME TO inference_request_log_assistant_id_created_at_idx;
-- Guards are conrelid-scoped, not name-only: after 0060 recycles the `skill`
-- name for the ex-`tool` table, a constraint named skill_visibility_check
-- exists again ON THAT table — a bare conname check would wrongly re-fire here.
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint
             WHERE conname='skill_org_slug_unique'
               AND conrelid='public.assistant'::regclass) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_org_slug_unique TO assistant_org_slug_unique;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint
             WHERE conname='skill_visibility_check'
               AND conrelid='public.assistant'::regclass) THEN
    ALTER TABLE assistant RENAME CONSTRAINT skill_visibility_check TO assistant_visibility_check;
  END IF;
END $$;

-- ── 4. Re-establish RLS on the renamed table (mirrors rls/0001 + rls/0002) ────
DO $$ BEGIN
  IF to_regclass('public.assistant') IS NOT NULL THEN
    ALTER TABLE assistant ENABLE ROW LEVEL SECURITY;
    ALTER TABLE assistant FORCE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS tenant_isolation ON assistant;
    CREATE POLICY tenant_isolation ON assistant
      USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid)
      WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::uuid);
  END IF;
END $$;

-- ── 5. Migrate stored DATA that names the entity ─────────────────────────────
-- 5a. Marketplace resource_type 'skill' → 'assistant' (drop CHECK, migrate, re-add).
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='marketplace_listing_resource_type_check') THEN
    ALTER TABLE marketplace_listing DROP CONSTRAINT marketplace_listing_resource_type_check;
  END IF;
END $$;
UPDATE marketplace_listing SET resource_type='assistant' WHERE resource_type='skill';
DO $$ BEGIN
  IF to_regclass('public.marketplace_version') IS NOT NULL THEN
    UPDATE marketplace_version SET resource_type='assistant' WHERE resource_type='skill';
  END IF;
  IF to_regclass('public.marketplace_install') IS NOT NULL THEN
    UPDATE marketplace_install SET resource_type='assistant' WHERE resource_type='skill';
  END IF;
  IF to_regclass('public.marketplace_fork') IS NOT NULL THEN
    UPDATE marketplace_fork SET fork_resource_type='assistant'   WHERE fork_resource_type='skill';
    UPDATE marketplace_fork SET source_resource_type='assistant' WHERE source_resource_type='skill';
  END IF;
END $$;
-- 'skill' is accepted alongside 'tool' so a re-run AFTER 0060 (which migrates
-- 'tool' rows to 'skill') can still re-add this check; 0060 re-tightens it.
ALTER TABLE marketplace_listing ADD CONSTRAINT marketplace_listing_resource_type_check
  CHECK (resource_type IN ('agent','tool','skill','workflow','assistant','prompt','knowledge_pack'));

-- 5b. RBAC resource grants 'skills' → 'assistants' (reverses 0016:26).
UPDATE org_resource_grant SET resource_type='assistants' WHERE resource_type='skills';

-- 5b-2. Role permission slugs skills:<action> → assistants:<action> (mirrors the
-- copilots→skills reconciliation in 0023). `ensureSystemRoles` only seeds NEW
-- roles, so without this every existing role's stored `skills:*` rows become
-- dead slugs and the role silently loses all assistant governance access.
-- Insert the assistants equivalent (guarded to valid catalog slugs), then drop
-- the migrated skills rows. ON CONFLICT keeps it re-runnable.
INSERT INTO "org_role_permission" ("role_id", "permission")
SELECT "role_id", 'assistants:' || split_part("permission", ':', 2)
FROM "org_role_permission"
WHERE "permission" LIKE 'skills:%'
  AND ('assistants:' || split_part("permission", ':', 2)) = ANY (ARRAY[
    'assistants:view', 'assistants:create', 'assistants:edit',
    'assistants:delete', 'assistants:deploy', 'assistants:approve',
    'assistants:disable', 'assistants:transfer', 'assistants:publish'
  ])
ON CONFLICT ("role_id", "permission") DO NOTHING;
DELETE FROM "org_role_permission"
WHERE "permission" LIKE 'skills:%'
  AND ('assistants:' || split_part("permission", ':', 2)) = ANY (ARRAY[
    'assistants:view', 'assistants:create', 'assistants:edit',
    'assistants:delete', 'assistants:deploy', 'assistants:approve',
    'assistants:disable', 'assistants:transfer', 'assistants:publish'
  ]);

-- 5b-3. Permission-group items — system packs (e.g. ai-builder) ship
-- resourceSlugs("assistants"); ensureSystemGroups skips already-seeded packs, so
-- pre-rename skills:* items are never reconciled. Same INSERT+DELETE as 5b-2.
INSERT INTO "org_permission_group_item" ("group_id", "permission")
SELECT "group_id", 'assistants:' || split_part("permission", ':', 2)
FROM "org_permission_group_item"
WHERE "permission" LIKE 'skills:%'
  AND ('assistants:' || split_part("permission", ':', 2)) = ANY (ARRAY[
    'assistants:view', 'assistants:create', 'assistants:edit',
    'assistants:delete', 'assistants:deploy', 'assistants:approve',
    'assistants:disable', 'assistants:transfer', 'assistants:publish'
  ])
ON CONFLICT ("group_id", "permission") DO NOTHING;
DELETE FROM "org_permission_group_item"
WHERE "permission" LIKE 'skills:%'
  AND ('assistants:' || split_part("permission", ':', 2)) = ANY (ARRAY[
    'assistants:view', 'assistants:create', 'assistants:edit',
    'assistants:delete', 'assistants:deploy', 'assistants:approve',
    'assistants:disable', 'assistants:transfer', 'assistants:publish'
  ]);

-- 5b-4. Per-instance resource grants store the full slug in `permission`
-- alongside resource_type (5b migrated resource_type only). `assistants:*` did
-- not exist pre-rename, so a plain guarded UPDATE cannot collide with the
-- (org, resource, permission, membership) unique.
UPDATE "org_resource_grant"
SET "permission" = 'assistants:' || split_part("permission", ':', 2)
WHERE "permission" LIKE 'skills:%'
  AND ('assistants:' || split_part("permission", ':', 2)) = ANY (ARRAY[
    'assistants:view', 'assistants:create', 'assistants:edit',
    'assistants:delete', 'assistants:deploy', 'assistants:approve',
    'assistants:disable', 'assistants:transfer', 'assistants:publish'
  ]);

-- 5b-5. Policy-engine rules store the governed slug in definition->>'action'
-- (and may carry a bare resourceType 'skills'). Rewrite both inside the jsonb
-- text so DENY/allow rules keep matching after the catalog rename.
UPDATE "org_policy"
SET "definition" =
  replace(replace("definition"::text, 'skills:', 'assistants:'), '"skills"', '"assistants"')::jsonb
WHERE "definition"::text LIKE '%skills:%' OR "definition"::text LIKE '%"skills"%';

-- 5c. Nav visibility overrides keyed on the registry ids.
UPDATE nav_visibility_override SET nav_item_id='org.assistants' WHERE nav_item_id='org.skills';
UPDATE nav_visibility_override SET nav_item_id='ops.assistants' WHERE nav_item_id='ops.skills';

-- 5d. Governance activity codes SKILL_* → ASSISTANT_* (admin_audit_log.action).
UPDATE admin_audit_log
   SET action = 'ASSISTANT_' || substring(action from 7)
 WHERE action LIKE 'SKILL_%';

-- 5e. Webhook subscriptions that explicitly listed the persona deploy events.
-- The emitter now sends assistant.deployed/assistant.undeployed; without this an
-- existing subscription keyed on the old event name silently stops firing.
UPDATE webhook
SET events = array_replace(
               array_replace(events, 'skill.deployed', 'assistant.deployed'),
               'skill.undeployed', 'assistant.undeployed')
WHERE 'skill.deployed' = ANY(events) OR 'skill.undeployed' = ANY(events);

COMMIT;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0060_rename_tool_to_skill.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 0060: Rename workspace agent-skill entity `tool` → `skill` (Tools/Skills/Assistants rename, Phase 2).
--
-- Hand-authored IDEMPOTENT delta (dir2 canonical tree). Runs AFTER 0059 (which
-- vacated the `skill` name from the ex-copilot persona → `assistant`). Reverses
-- migration 0015_rename_skill_to_tool for the workspace TOOL.md entity. Apply directly:
--   psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 \
--     -f src/lib/db/pg/migrations/pg/0060_rename_tool_to_skill.sql
--
-- SCOPE: ONLY the authored-skill entity (tool / tool_install / tool_rating /
-- tool_submission). NOT renamed (a different "tool"): tool_usage (function-call
-- analytics), mcp_tool_policy, mcp_server_tool_custom_instructions,
-- user_tool_permission, org_user_tool_permission, assistant.tool_config. This
-- entity is user-scoped (no RLS to migrate). Every step is existence-guarded.

BEGIN;

-- ── 1. Rename tables ─────────────────────────────────────────────────────────
DO $$ BEGIN
  IF to_regclass('public.tool') IS NOT NULL AND to_regclass('public.skill') IS NULL THEN
    ALTER TABLE tool RENAME TO skill;
  END IF;
  IF to_regclass('public.tool_install') IS NOT NULL AND to_regclass('public.skill_install') IS NULL THEN
    ALTER TABLE tool_install RENAME TO skill_install;
  END IF;
  IF to_regclass('public.tool_rating') IS NOT NULL AND to_regclass('public.skill_rating') IS NULL THEN
    ALTER TABLE tool_rating RENAME TO skill_rating;
  END IF;
  IF to_regclass('public.tool_submission') IS NOT NULL AND to_regclass('public.skill_submission') IS NULL THEN
    ALTER TABLE tool_submission RENAME TO skill_submission;
  END IF;
END $$;

-- ── 2. Rename FK columns tool_id → skill_id ──────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE column_name='tool_id'
             AND table_name IN ('skill_install','skill_rating','skill_submission')
  LOOP
    EXECUTE format('ALTER TABLE %I RENAME COLUMN tool_id TO skill_id', r.table_name);
  END LOOP;
END $$;

-- ── 3. Rename indexes / constraints (cosmetic; name-independent) ──────────────
ALTER INDEX IF EXISTS tool_user_id_idx            RENAME TO skill_user_id_idx;
ALTER INDEX IF EXISTS tool_category_idx           RENAME TO skill_category_idx;
ALTER INDEX IF EXISTS tool_is_published_idx       RENAME TO skill_is_published_idx;
ALTER INDEX IF EXISTS tool_user_id_visibility_idx RENAME TO skill_user_id_visibility_idx;
ALTER INDEX IF EXISTS tool_org_idx                RENAME TO skill_org_idx;
ALTER INDEX IF EXISTS tool_install_user_id_idx    RENAME TO skill_install_user_id_idx;
ALTER INDEX IF EXISTS tool_rating_tool_id_idx     RENAME TO skill_rating_skill_id_idx;
ALTER INDEX IF EXISTS tool_submission_tool_id_idx RENAME TO skill_submission_skill_id_idx;
ALTER INDEX IF EXISTS tool_submission_user_id_idx RENAME TO skill_submission_user_id_idx;
ALTER INDEX IF EXISTS tool_submission_status_idx  RENAME TO skill_submission_status_idx;
-- conrelid-scoped for symmetry with 0059's guards (name-only pg_constraint
-- checks are unsafe in this rename chain — names get recycled across tables).
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint
             WHERE conname='tool_visibility_check'
               AND conrelid='public.skill'::regclass) THEN
    ALTER TABLE skill RENAME CONSTRAINT tool_visibility_check TO skill_visibility_check;
  END IF;
END $$;

-- ── 4. Migrate stored DATA that names the entity ─────────────────────────────
-- 4a. Marketplace resource_type 'tool' → 'skill' (drop CHECK, migrate, re-add).
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='marketplace_listing_resource_type_check') THEN
    ALTER TABLE marketplace_listing DROP CONSTRAINT marketplace_listing_resource_type_check;
  END IF;
END $$;
UPDATE marketplace_listing SET resource_type='skill' WHERE resource_type='tool';
DO $$ BEGIN
  IF to_regclass('public.marketplace_version') IS NOT NULL THEN
    UPDATE marketplace_version SET resource_type='skill' WHERE resource_type='tool';
  END IF;
  IF to_regclass('public.marketplace_install') IS NOT NULL THEN
    UPDATE marketplace_install SET resource_type='skill' WHERE resource_type='tool';
  END IF;
  IF to_regclass('public.marketplace_fork') IS NOT NULL THEN
    UPDATE marketplace_fork SET fork_resource_type='skill'   WHERE fork_resource_type='tool';
    UPDATE marketplace_fork SET source_resource_type='skill' WHERE source_resource_type='tool';
  END IF;
END $$;
ALTER TABLE marketplace_listing ADD CONSTRAINT marketplace_listing_resource_type_check
  CHECK (resource_type IN ('agent','skill','workflow','assistant','prompt','knowledge_pack'));

-- 4b. Bookmarks item_type 'tool' → 'skill' (workspace entity is bookmarkable).
UPDATE bookmark SET item_type='skill' WHERE item_type='tool';

-- 4c. Nav visibility overrides keyed on the registry id (mirrors 0059's persona
-- nav-id migration). Without this an admin's hidden-tab override for the
-- workspace screen is orphaned and the tab silently reappears.
UPDATE nav_visibility_override SET nav_item_id='workspace.skills' WHERE nav_item_id='workspace.tools';

COMMIT;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0061_assistant_published_slug_unique.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 0061: Globally-unique public slug for LIVE (published + active) assistants (F3).
--
-- Hand-authored IDEMPOTENT delta (dir2 canonical tree). The public embed
-- (`GET /api/assistant/{slug}` → findPublicBySlug) is addressed by slug ALONE,
-- but `assistant_org_slug_unique` makes slug unique only PER-ORG. Two orgs
-- publishing the same slug therefore made the public lookup non-deterministic and
-- cross-tenant shadowable. This partial unique index makes the live public slug
-- space globally unambiguous. Apply directly:
--   psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 \
--     -f src/lib/db/pg/migrations/pg/0061_assistant_published_slug_unique.sql
--
-- The application-level guard (org-assistant-governance-service.setPublished →
-- hasPublishedSlugConflict) is the PRIMARY fix and blocks NEW collisions on its
-- own. This index is defense-in-depth: if the DB already holds a pre-existing
-- cross-org published-slug collision the index cannot be built, so creation is
-- wrapped to degrade to a NOTICE instead of hard-failing the migration — the app
-- guard keeps the invariant while the existing collision is resolved by hand.

BEGIN;

DO $$ BEGIN
  BEGIN
    CREATE UNIQUE INDEX IF NOT EXISTS assistant_published_slug_unique
      ON assistant (slug)
      WHERE is_published AND is_active AND deleted_at IS NULL;
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'assistant_published_slug_unique NOT created: a pre-existing cross-org published-slug collision exists. The application guard (setPublished) still blocks new collisions; de-duplicate the published slug, then re-run this migration.';
  END;
END $$;

COMMIT;

-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0062_notification_deleted_at.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 0062: Soft-delete for in-app notifications ("Clear").
--
-- Hand-authored IDEMPOTENT delta (mirrors 0061; there is no _journal.json for
-- this canonical tree — applied directly). The notification center gains a
-- user-facing "Clear" action; rather than hard-DELETE the rows, we soft-clear
-- them so the action is reversible and consistent with the codebase's
-- deleted_at soft-delete convention. `list` / `countUnread` gain an
-- `AND deleted_at IS NULL` guard so cleared rows drop out of the list + badge.
-- Apply directly:
--   psql "$POSTGRES_PRIVILEGED_URL" -v ON_ERROR_STOP=1 \
--     -f src/lib/db/pg/migrations/pg/0062_notification_deleted_at.sql
--
-- The column is nullable with no default, so every existing row reads as active
-- (deleted_at IS NULL) — no behavior change for pre-existing notifications.

BEGIN;

ALTER TABLE notification ADD COLUMN IF NOT EXISTS deleted_at timestamp;

-- Keep the hot newest-first active-list query fast without scanning cleared rows.
CREATE INDEX IF NOT EXISTS notification_user_active_idx
  ON notification (user_id, created_at)
  WHERE deleted_at IS NULL;

COMMIT;
