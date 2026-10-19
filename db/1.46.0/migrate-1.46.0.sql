-- migrate-1.46.0.sql — data delta 1.45.0 → 1.46.0: a knowledge base is shared only through the Marketplace, so every DIRECT share (visibility team / org / public with no Marketplace share listing) is converted once (ADR-0120). Source migration 0047 (journaled migration 0047_knowledge_base_direct_shares.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see NOT DESTRUCTIVE below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- A knowledge base's settings used to set its audience (team, organization,
-- public) directly. From this release that audience exists ONLY as a
-- Marketplace share: the share listing remembers the audience it replaced and
-- Stop sharing puts it back. This delta converts what the old settings left
-- behind. An APPROVED direct share gets the share listing the application
-- writes when someone shares it (scope team with its own team, or
-- organization; published; submitted by its owner; memo "previous visibility:
-- private"), and its audience does not change — a team knowledge base stays
-- its team's, never wider; `public` (the legacy synonym of `org`) is written
-- `org`. Every OTHER direct share — not approved, without an organization,
-- whose team is gone, or whose listing is under moderation — becomes private,
-- keeping only its owner's attachment. No attachment is added.
--
-- SHIP IT WITH THE IMAGE THAT REFUSES DIRECT SHARES (or after it). An image
-- that still offers team / organization in the settings would recreate
-- direct shares after this delta ran; re-running the delta converts them.
--
-- NOT DESTRUCTIVE TO SCHEMA. No DDL: rows of knowledge_base,
-- marketplace_listing and knowledge_base_attachment only, limited to direct
-- shares. Re-runnable: every statement matches only direct shares that remain
-- direct shares, so a second apply changes nothing. `SET lock_timeout` bounds
-- every row-lock wait.
--
-- No RLS and no schema change in this bundle: schema.sql and grants.sql are
-- 1.45.0's, unchanged; seed.sql re-renders the journal stamp through 0047.
--
-- ROLLBACK.
--
--     Forward-only. A knowledge base this delta made PRIVATE does not record
--     the audience it had (its owner shares it again from the Marketplace).
--     A listing this delta wrote is undone per knowledge base with Stop
--     sharing, which restores it to private.

SET lock_timeout = '5s';

-- 1. Approved, shareable direct shares get the listing `shareKb` writes.
INSERT INTO "marketplace_listing" (
  "resource_type", "resource_id", "organization_id", "scope", "team_id",
  "name", "description", "status", "submitted_by", "submitted_at", "metadata"
)
SELECT
  'knowledge_pack', kb."id", kb."organization_id",
  CASE WHEN kb."visibility" = 'team' THEN 'team' ELSE 'organization' END,
  CASE WHEN kb."visibility" = 'team' THEN kb."team_id" ELSE NULL END,
  kb."name", kb."description", 'published', kb."user_id", CURRENT_TIMESTAMP,
  jsonb_build_object('previousVisibility', 'private', 'previousTeamId', NULL)
FROM "knowledge_base" kb
LEFT JOIN "marketplace_listing" ml
  ON ml."resource_type" = 'knowledge_pack' AND ml."resource_id" = kb."id"
WHERE kb."visibility" IN ('team', 'org', 'public')
  AND kb."organization_id" IS NOT NULL
  AND kb."governance_status" = 'approved'
  AND (
    kb."visibility" <> 'team'
    OR EXISTS (
      SELECT 1 FROM "team" t
      WHERE t."id" = kb."team_id" AND t."organization_id" = kb."organization_id"
    )
  )
  AND (
    ml."id" IS NULL
    OR (
      ml."status" = 'published'
      AND jsonb_typeof(ml."metadata" -> 'previousVisibility') IS DISTINCT FROM 'string'
    )
  )
ON CONFLICT ("resource_type", "resource_id") DO UPDATE SET
  "organization_id" = EXCLUDED."organization_id",
  "name" = EXCLUDED."name",
  "description" = EXCLUDED."description",
  "scope" = EXCLUDED."scope",
  "team_id" = EXCLUDED."team_id",
  "status" = EXCLUDED."status",
  "submitted_by" = EXCLUDED."submitted_by",
  "submitted_at" = EXCLUDED."submitted_at",
  "metadata" = (
    CASE WHEN jsonb_typeof("marketplace_listing"."metadata") = 'object'
      THEN "marketplace_listing"."metadata" ELSE '{}'::jsonb END
  ) || EXCLUDED."metadata",
  "updated_at" = CURRENT_TIMESTAMP
WHERE "marketplace_listing"."status" = 'published'
  AND jsonb_typeof("marketplace_listing"."metadata" -> 'previousVisibility') IS DISTINCT FROM 'string';

-- 2. An organization share is stored as `org` with no team, as `shareKb`
--    writes it (`public` is the legacy synonym of `org`).
UPDATE "knowledge_base" kb
SET "visibility" = 'org', "team_id" = NULL, "updated_at" = CURRENT_TIMESTAMP
WHERE kb."visibility" IN ('org', 'public')
  AND (kb."visibility" = 'public' OR kb."team_id" IS NOT NULL)
  AND EXISTS (
    SELECT 1 FROM "marketplace_listing" ml
    WHERE ml."resource_type" = 'knowledge_pack'
      AND ml."resource_id" = kb."id"
      AND ml."scope" = 'organization'
      AND jsonb_typeof(ml."metadata" -> 'previousVisibility') = 'string'
  );

-- 3. Every direct share still left goes private below: first remove the
--    attachments outside that audience (everyone but the owner).
DELETE FROM "knowledge_base_attachment" a
USING "knowledge_base" kb
WHERE a."knowledge_base_id" = kb."id"
  AND a."user_id" IS DISTINCT FROM kb."user_id"
  AND kb."visibility" IN ('team', 'org', 'public')
  AND NOT EXISTS (
    SELECT 1 FROM "marketplace_listing" ml
    WHERE ml."resource_type" = 'knowledge_pack'
      AND ml."resource_id" = kb."id"
      AND jsonb_typeof(ml."metadata" -> 'previousVisibility') = 'string'
  );

-- 4. ...and make them private.
UPDATE "knowledge_base" kb
SET "visibility" = 'private', "team_id" = NULL, "updated_at" = CURRENT_TIMESTAMP
WHERE kb."visibility" IN ('team', 'org', 'public')
  AND NOT EXISTS (
    SELECT 1 FROM "marketplace_listing" ml
    WHERE ml."resource_type" = 'knowledge_pack'
      AND ml."resource_id" = kb."id"
      AND jsonb_typeof(ml."metadata" -> 'previousVisibility') = 'string'
  );
