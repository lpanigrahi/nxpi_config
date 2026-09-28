-- migrate-1.22.0.sql — schema delta 1.21.0 → 1.22.0 (source migrations 0002,
-- 0004 and 0005, of the #158-unfrozen JOURNALED series:
-- src/lib/db/migrations/pg/0002_skill_submission_reviewed_by_set_null.sql,
-- src/lib/db/migrations/pg/0004_apikey_config_id.sql,
-- src/lib/db/migrations/pg/0005_audit_view_floor_carveout.sql). Additive-safe
-- (0002/0004) + data-only convergence (0005).
--
-- Additive-safe, deliberately unflagged (lib.sh scans the first six lines
-- for its destructive-review marker — that token must not appear up here):
-- no table, column, or row is dropped and no cascade is introduced. The
-- constraint is dropped and re-added in one transaction (migrate.sh applies
-- with psql -1) only to change its DELETE action NO ACTION → SET NULL;
-- re-validation cannot fail (every existing reviewed_by already satisfied
-- the same FK). Re-running is a no-op in effect: DROP IF EXISTS + ADD
-- converges on the same state.
--
-- WHY (r12 track RR): `skill_submission.reviewed_by` is attribution, not
-- ownership — every sibling actor column (skill.lifecycle_reviewed_by,
-- skill_attestation.signed_by/revoked_by, skill_qa_certification.
-- issued_by/revoked_by) declares ON DELETE SET NULL. With NO action,
-- deleting ANY user who ever reviewed ANY skill submission raised an
-- unconditional 23503. The app image shipping with this delta DELETED its
-- runtime pre-null compensation for this column (R11's workaround), so an
-- image at this release AGAINST a database without this delta regresses
-- reviewer deletion — this file must ship WITH that image, and
-- db/1.22.0/schema.sql carries the same action for fresh installs.

ALTER TABLE "skill_submission"
  DROP CONSTRAINT IF EXISTS "skill_submission_reviewed_by_user_id_fk";
ALTER TABLE "skill_submission"
  ADD CONSTRAINT "skill_submission_reviewed_by_user_id_fk"
  FOREIGN KEY ("reviewed_by") REFERENCES "public"."user"("id")
  ON DELETE SET NULL ON UPDATE NO ACTION;


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0004_apikey_config_id.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0004 — apikey.config_id (PH5: better-auth 1.4→1.6 apiKey plugin). The
-- extracted @better-auth/api-key 1.6 plugin added a REQUIRED, plugin-managed
-- `config_id` field (the rate-limit configuration a key resolves against,
-- "default" when unnamed), written on every mint. Without the column the
-- drizzle adapter throws "field configId does not exist" and org API-key
-- minting 500s. Additive-safe and idempotent (IF NOT EXISTS + a NOT NULL
-- DEFAULT so existing rows backfill); db/1.22.0/schema.sql carries the same
-- column + index for fresh installs.

ALTER TABLE apikey
  ADD COLUMN IF NOT EXISTS config_id text DEFAULT 'default' NOT NULL;
CREATE INDEX IF NOT EXISTS apikey_config_id_idx
  ON apikey USING btree (config_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- >>> 0005_audit_view_floor_carveout.sql
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 0005 — audit:view floor carve-out convergence (F-19, 2026-09-07 role-matrix
-- audit). The catalog moved `audit` into VIEW_FLOOR_EXCLUDED_RESOURCES and
-- granted audit:view to security-admin explicitly; ensureSystemRoles seeds
-- permissions for newly-created roles only, so deployed orgs' is_system
-- viewer/security-admin rows (and the system read-only pack) converge here.
-- Data-only and idempotent (the DELETEs converge; the INSERT is ON CONFLICT
-- DO NOTHING); custom roles, custom packs, per-instance grants and deny rows
-- untouched. No DDL, so db/1.22.0/schema.sql is unchanged; the catalog seed
-- in the app image writes the new shape for fresh orgs.

DELETE FROM "org_role_permission" orp
USING "org_role" r
WHERE orp.role_id = r.id
  AND r.is_system
  AND r.key = 'viewer'
  AND orp.permission = 'audit:view'
  AND orp.denied = false;
INSERT INTO "org_role_permission" (role_id, permission)
SELECT r.id, 'audit:view'
FROM "org_role" r
WHERE r.is_system
  AND r.key = 'security-admin'
ON CONFLICT (role_id, permission) DO NOTHING;
DELETE FROM "org_permission_group_item" gi
USING "org_permission_group" g
WHERE gi.group_id = g.id
  AND g.is_system
  AND g.key = 'read-only'
  AND gi.permission = 'audit:view';
