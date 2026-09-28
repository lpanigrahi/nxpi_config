-- migrate-1.20.0.sql — schema delta 1.19.0 → 1.20.0 (source migration 0098).
--
-- ADDITIVE-ONLY, every step existence-guarded; re-running is a no-op. W-S12
-- (G10-schema): (1) apikey.id gains a DB default — the ONLY Better-Auth
-- table without one, which made every key create 500 since the plugin
-- shipped; (2) apikey.organization_id — a key binds to ONE org at issuance
-- (the scope reader refuses unbound keys, so the nullable column is not a
-- hole). As with every table in this package, RLS is NOT part of the bundle
-- (the compliance register discloses that limit).


-- apikey scoping (overhaul W-S12, gap G10-schema): (1) a DB default for id —
-- Better Auth omits id on insert under generateId:false and this was the ONLY
-- BA table without a default, so every key create 500ed since the day the
-- plugin shipped; (2) organization_id — a key binds to ONE org at issuance;
-- the scope reader refuses null-bound keys as unscoped, so the nullable
-- column is not a hole. Both steps additive + idempotent.
ALTER TABLE "apikey" ALTER COLUMN "id" SET DEFAULT gen_random_uuid()::text;
DO $$ BEGIN
ALTER TABLE "apikey" ADD COLUMN "organization_id" uuid;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN
ALTER TABLE "apikey" ADD CONSTRAINT "apikey_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS "apikey_organization_id_idx" ON "apikey" ("organization_id");
