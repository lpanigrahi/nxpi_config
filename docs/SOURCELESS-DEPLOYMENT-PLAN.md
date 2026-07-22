# Sourceless Deployment Plan — NXPi on Azure VM via Static SQL

## Goal & chosen approach

Deploy the NXPi platform to an Azure Ubuntu VM such that the deploy target needs
**no application source code** and **no git access to the private `nxpi_dev`
repo**. Decided (2026-07-15):

- **Architecture B — Static SQL artifacts.** A `schema.sql` + `seed.sql` pair,
  generated once per release, applied on the target with plain `psql`. No
  drizzle-kit, no `pnpm install`, no source tree, no git clone.
- **Full reference seed** — org + 8 RBAC roles + 3 permission groups + platform
  settings + 48 nav-visibility rows + 7 built-in tools + super admin, matching
  today's `db:bootstrap` exactly.
- **App-repo CI additions are permitted** (build/packaging only — no
  application-logic changes) so artifacts are produced automatically per release
  and stay in lockstep with the code.
- **Per-deploy admin password preserved** (no shared known password) via a tiny
  public hash helper — see Part 3.

### Why the source dependency exists today (root cause)
The schema is realized **only** by `drizzle-kit push` reading the 144-table
`src/lib/db/pg/schema.pg.ts` at deploy time. The in-repo migration files are a
broken split-brain (tree A journaled to `0008` with dead files to `0022`; tree B
has no journal) — you **cannot replay migrations** to build a fresh DB. So the
current `bootstrap`/`migrate` one-shots clone the private repo + `pnpm install` +
run drizzle-kit. This plan replaces that with a faithful **capture** of what the
source produces.

---

## End-to-end architecture

```
┌─ nxpi_dev (PRIVATE app repo) ──────────────────────────────┐
│  CI on release published (vX.Y.Z):                         │
│   1. spin throwaway pgvector, `pnpm db:bootstrap`          │
│      (fixed admin UUID, placeholder email/hash)           │
│   2. pg_dump --schema-only        → schema.sql            │
│   3. pg_dump --data-only (seeds)  → seed.sql (parameterized│
│      admin email + password hash as psql :vars)           │
│   4. schema-diff vs previous tag  → migrate-<X.Y.Z>.sql   │
│   5. build tiny hash helper image → ghcr.io/.../nxpi-hash │
│   6. cross-repo publish 1–4 to PUBLIC nxpi_config         │
└────────────────────────────────────────────────────────────┘
                         │ (public; no source, DDL+data only)
                         ▼
┌─ nxpi_config (PUBLIC config repo) ─────────────────────────┐
│  azure-deployment/db/<X.Y.Z>/{schema.sql,seed.sql,         │
│                               migrate-<X.Y.Z>.sql}         │
└────────────────────────────────────────────────────────────┘
                         │ git clone (public) — no token
                         ▼
┌─ Azure VM (deploy target) ─────────────────────────────────┐
│  ./install.sh:                                             │
│   • docker pull app image (public GHCR) + nxpi-hash        │
│   • psql -f schema.sql                                     │
│   • HASH=$(docker run nxpi-hash "$ADMIN_PW")               │
│   • psql -v admin_email -v admin_password_hash -f seed.sql │
│   • start app (AUTO_DB_MIGRATE=false)                      │
│  NO source, NO drizzle-kit, NO git access to nxpi_dev.     │
└────────────────────────────────────────────────────────────┘
```

---

## Part 1 — Artifact generation (in the app repo, `nxpi_dev`)

New CI only; **no application code changes**.

### 1a. Schema export → `schema.sql`
- New script `scripts/export-schema.ts` (or a CI step): against a freshly
  `db:bootstrap`-ed throwaway pgvector DB, run
  `pg_dump --schema-only --no-owner --no-privileges --no-comments`.
- Captures automatically (per research): all 130–137 tables, `CREATE EXTENSION
  vector`, all 14 CHECK constraints, 5 HNSW + 1 GIN indexes with opclasses,
  `vector`/`halfvec`/`tsvector` columns, sequences/defaults, and the
  `drizzle.__drizzle_migrations` journal table.
- **App role**: append `scripts/setup-app-db-role.sql` (already static) — creates
  the least-privilege `neo_gen` role + grants. Its password is set per-deploy by
  the installer (`ALTER ROLE neo_gen PASSWORD …` from the target's
  `postgres_url` secret), so no secret is baked into the artifact.
- **RLS**: default **off** (matches every current deployment — the app runs fine
  RLS-off). Optionally emit `schema-rls.sql` from the reconciled set
  (`src/lib/db/rls/0002…0007`, NOT the stale `0001`) as an opt-in hardening.

### 1b. Seed generation → `seed.sql`
- Bootstrap the reference DB with a **fixed admin UUID** (deterministic, e.g. an
  all-zeros-suffixed sentinel) and a **placeholder** email/password.
- `pg_dump --data-only --column-inserts` for exactly the seed tables:
  `"user"`, `account`, `organization`, `organization_member`, `org_role`,
  `org_role_permission`, `org_permission_group`, `org_permission_group_item`,
  `app_settings`, `nav_visibility_override`, `tool`.
  (`--column-inserts` → portable `INSERT` statements; pg_dump orders by FK.)
- **Post-process** the admin `user.email` and `account.password` values into psql
  variables: `:'admin_email'` and `:'admin_password_hash'`. Everything else
  (org, RBAC, settings, nav, tools, and all FK references to the fixed admin
  UUID) stays literal — the UUID is just an internal id, safe to be constant.
- Result: `seed.sql` is a static file the installer feeds two per-deploy values.

### 1c. Day-2 additive migrations → `migrate-<X.Y.Z>.sql`
- In CI, stand up two DBs: one pushed at the **previous** release tag, one at the
  **current** tag. Diff with `migra` (or `apgdiff`) to produce **additive** DDL.
- Ship `migrate-<X.Y.Z>.sql` per release. Destructive statements (DROP COLUMN /
  type narrowing) are flagged in a header comment for manual review — mirroring
  today's "destructive drizzle-kit push fails loudly" safety.
- Target tracks its schema version in a marker (`app_settings` row
  `deploy_schema_version`, or a dedicated 1-row table). The updater applies the
  ordered chain of `migrate-*.sql` between the installed and target versions.

### 1d. Password hash helper → `ghcr.io/lpanigrahi/nxpi-hash` (public)
- ~10-line Dockerfile: `FROM node:24-alpine; RUN npm i better-auth@<pinned>;
  COPY hash.mjs .; ENTRYPOINT ["node","hash.mjs"]`.
- `hash.mjs`: `import {hashPassword} from "better-auth/crypto";
  process.stdout.write(await hashPassword(process.argv[2]))`.
- Contains **only the public `better-auth` npm package — no app source.** Using
  the real library guarantees the scrypt format/params match verification
  exactly (`salt:hex(key)`, N=16384 r=16 p=1 dkLen=64, NFKC). Built in the app
  repo CI so its `better-auth` version pins to the app's.

### 1e. CI workflow + cross-repo publish
- New `.github/workflows/db-artifacts.yml`, trigger `release: [published]` +
  `workflow_dispatch` (same PAT note as `container.yaml` so it fires on tag).
- Job: pgvector service → `pnpm install` → `pnpm db:bootstrap` → export schema +
  seed + diff → build/push `nxpi-hash` (reuse the `container.yaml` GHCR login and
  `metadata-action` version tags so it aligns with the app image).
- Publish `schema.sql`/`seed.sql`/`migrate-*.sql` to the **public** `nxpi_config`
  repo via a cross-repo commit (a deploy-key/PAT the CI holds), under
  `azure-deployment/db/<X.Y.Z>/`. The public audience gets them with a plain
  `git clone nxpi_config` — **no `nxpi_dev` access.**

---

## Part 2 — Deployment package (config repo, `nxpi_config/azure-deployment`)

Replace the source-dependent one-shots; everything else in the hardened package
(Caddy, secrets, rollback pin, backup/restore, locks) stays.

### 2a. Drop the clone-based one-shots
- Remove the `bootstrap` and `migrate` services that `git clone` + `pnpm install`
  (and the `git_token` secret + repo-access preflight become unnecessary for the
  DB path — keep only if the app image itself is private).

### 2b. `install.sh` — fresh install flow
1. Preflight, Docker, secrets (unchanged; **`git_token` no longer required**).
2. `.env`/`.env.app` (unchanged). New: `DB_ARTIFACT_VERSION` (defaults to the
   `db/` folder matching `APP_IMAGE`'s tag).
3. `docker compose pull` app image + `docker pull nxpi-hash:<ver>`.
4. `up -d postgres redis`; wait healthy.
5. Provision (idempotency fork on `table_count`):
   - Fresh: `psql "$PRIVILEGED_URL" -f db/<ver>/schema.sql`
     → `ALTER ROLE neo_gen PASSWORD` (from `postgres_url` secret)
     → compute `HASH=$(docker run --rm nxpi-hash "$ADMIN_PW")`
     → `psql -v admin_email="$ADMIN_EMAIL" -v admin_password_hash="$HASH" -f db/<ver>/seed.sql`
     → stamp `deploy_schema_version=<ver>`.
   - Existing: apply the ordered `migrate-*.sql` chain (see 2c).
   - `ADMIN_PW` = `SUPER_ADMIN_PASSWORD` from `.env` if set, else generated
     random **and printed once** (preserves today's UX). psql runs inside the
     `postgres` container via `exec -T`, so no psql client on the host.
6. `up -d` app + Caddy; health gate (unchanged).

### 2c. `update.sh` / `migrate.sh` — day-2, data-preserving
- Read installed `deploy_schema_version`; apply each `db/<v>/migrate-<v>.sql` for
  versions between installed and target, in order, via `psql` (privileged).
- Safety backup first, destructive-diff guard (header flag → refuse without an
  explicit override), then bump the marker, then roll the app. Same
  backup-first / rollback-pin machinery already in the package.

### 2d. Admin password
- No shared secret in any artifact. `seed.sql` carries only the fixed admin
  **UUID** (an internal id) + psql-var placeholders for email and hash. The hash
  is computed on the target per-deploy from the operator's chosen or a generated
  random password.

### 2e. Compose changes
- Add a `psql`/provisioning path (reuse the `postgres` container via `exec`, or a
  one-shot `postgres:17` client container) instead of the node one-shots. `app`
  stays on `AUTO_DB_MIGRATE=false`. `nxpi-hash` referenced by `install.sh`
  directly (no compose service needed).

---

## Part 3 — Coverage, gaps, and how each is handled

| Concern | Handling |
|---|---|
| Full schema (tables, CHECKs, HNSW/GIN, vector types, extension) | `pg_dump --schema-only` — captures 100% (superset of `drizzle-kit push`). |
| Deterministic seeds (org/RBAC/settings/nav/tools) | `pg_dump --data-only` of the seed tables; all IDs are `defaultRandom()`. |
| Admin password (the only runtime-bound value) | Public `nxpi-hash` helper computes the Better Auth scrypt hash per-deploy; portable (salt embedded, no server pepper). Per-deploy unique. |
| Journal stamp / boot migrator | `AUTO_DB_MIGRATE=false` (as today); journal table exists in the dump but is never read. |
| App role (`neo_gen`) + grants | `setup-app-db-role.sql` in `schema.sql`; password set per-deploy from the target's secret. |
| RLS | Off by default (matches current); optional `schema-rls.sql` from the reconciled set for opt-in hardening. |
| Day-2 migrations | Per-release CI-generated additive `migrate-<v>.sql`; version marker on target. |
| Per-release regeneration | Automated in app-repo CI on every release; artifacts land in the public config repo, version-foldered. |
| `EMBEDDING_DIMENSIONS`-driven vector width | Frozen at generation to the CI default (1536). If deployments vary the embedding model, generate a variant or parameterize — documented caveat. |

**Net exposure:** the deploy target sees only DDL (data model shape) + reference
data + a public crypto helper. **No React, no business logic, no `src/`.**

---

## Part 4 — Phasing

1. **Phase 1 (unblocks fresh installs — the immediate need):** app-repo CI for
   `schema.sql` + `seed.sql` + `nxpi-hash`; config-repo `install.sh` static-SQL
   fresh-install path. Deliverable: a public-only fresh deploy.
2. **Phase 2 (day-2):** `migrate-<v>.sql` diff generation + `update.sh`/version
   marker. Deliverable: sourceless upgrades.
3. **Phase 3 (optional):** RLS-on artifact variant; multi-embedding-dimension
   variants; artifact signing/attestation.

Until Phase 1 ships, the current token-based clone path remains the fallback.

---

## Part 5 — Verification

- **CI self-check:** after generating artifacts, apply them to a *second* clean
  pgvector and assert parity with a `db:bootstrap`-ed DB (table count, seed row
  counts: 8 roles / 3 groups / 48 nav / 7 tools, CHECK/index inventory via the
  existing `scripts/db-inventory.ts` + `verify-rls.sql`).
- **Round-trip login:** apply schema+seed with a known password, boot the app
  image, assert `/api/auth/sign-in/email` returns 200 and the admin can create an
  org (RBAC auto-seed intact).
- **Local fidelity:** run the whole flow under the existing `compose.verify.yml`
  pattern (remapped ports) before touching a VM.
- **Day-2:** apply `migrate-<v>.sql` to a populated DB, assert additive-only and
  data byte-identical, then app boots green.

---

## Implementation status — Phase 1 (BUILT + VERIFIED locally, 2026-07-15)

Proven end-to-end against throwaway pgvector containers on this machine.

**Built (in the app repo `nxpi_dev`):**
- `scripts/export-db-artifacts.sh` — bootstraps a reference DB, emits
  `schema.sql` (`pg_dump --schema-only`), `grants.sql` (copy of
  `setup-app-db-role.sql`, no password), and `seed.sql`
  (`pg_dump --data-only --column-inserts`, excluding `session` / `verification`
  / `admin_audit_log`, with the admin email + scrypt hash parameterized as
  `:'admin_email'` / `:'admin_password_hash'`; wrapped in
  `session_replication_role = replica` to defer FKs during load).
- `docker/nxpi-hash/{Dockerfile,hash.mjs}` — public helper (only the
  `better-auth` npm package, no app source) that prints the Better Auth scrypt
  hash for a chosen password. Built image ≈259 MB; pinned `better-auth@1.4.1`.
- `.github/workflows/db-artifacts.yml` — on release: bootstrap → export →
  self-verify parity on a 2nd DB → attach `db-artifacts-<ver>.tar.gz` to the
  release → (if `CONFIG_REPO_TOKEN` set) commit the SQL into the public
  `nxpi_config` under `azure-deployment/db/<ver>/`; plus a job that builds and
  publishes `ghcr.io/<owner>/nxpi-hash` (asserts its better-auth pin matches
  `package.json`).

**Verified facts (differ slightly from the pre-build estimates — these are the
measured truth):**
- Fresh DB has **144 tables** in `public` (+ the `drizzle` schema/journal).
- Seed parity with `db:bootstrap`: `user`=1, `account`=1, `organization`=**2**
  (default org **plus the admin's personal workspace** — the signup hook creates
  it even with `PERSONAL_WORKSPACE_ENABLED=false`), `org_role`=**16**,
  `org_permission_group`=6, `app_settings`=6, `nav_visibility_override`=48,
  `tool`=**6**, plus seeded workflow examples (2 workflows / 17 edges / 16
  nodes). `session`=0 (correctly excluded).
- Applied to a fresh pgvector with plain `psql` (schema → grants →
  `ALTER ROLE neo_gen PASSWORD` → seed with `-v`): **zero errors**.
- The **app image booted** against the sourceless DB as the least-privilege
  `neo_gen` role (readiness 200), and **admin login worked**: correct password
  → HTTP 200 + a session row written; wrong password → HTTP 401. The
  per-deploy hash from `nxpi-hash` verifies against the app's Better Auth.

**Resolved open items:**
- Circular FKs (`org_role`, `a2a_task`, …) → handled by
  `session_replication_role = replica` in `seed.sql` (superuser-applied).
- No fixed admin UUID needed — `pg_dump` captures the bootstrap's random UUID
  consistently across all FK references; only email + hash are parameterized.
- Better Auth hash is portable (salt embedded, no server pepper) — confirmed by
  applying a hash generated by `nxpi-hash` and logging in.

## Phase 1 config-repo side — DONE + VERIFIED (2026-07-15)

`azure-deployment` reworked to sourceless: the git-clone `bootstrap`/`migrate`
one-shots, the `git_token` secret and `postgres_privileged_url` are gone.
`install.sh` now provisions by applying `db/<version>/schema.sql` →
`grants.sql` → `ALTER ROLE neo_gen PASSWORD` (from the secret) → `seed.sql`
(with the admin email + `nxpi-hash`-computed hash via `psql -v`), all through
`compose exec postgres psql`. Live-verified end-to-end: 144 tables, app boots
as `neo_gen`, admin login 200 / wrong 401. **A public audience needs zero
tokens** (app image + `nxpi-hash` public, SQL in the public config repo).

## Phase 2 — day-2 migrations — DONE + VERIFIED (2026-07-15)

- `scripts/gen-migration-diff.sh` (app repo): diffs the previous release's
  `schema.sql` against the current one with **migra**, classifying by exit code
  (0 none / 2 additive → "additive-only" header / 3 destructive → captured with
  `--unsafe` under a `REQUIRES-REVIEW` header). Verified: additive diff applies
  and the post-apply diff is EXACTLY empty (round-trip proven); destructive
  direction is flagged.
- `apply_migrations` (deployment package): applies `db/<ver>/migrate-*.sql` in
  order, tracked in a `deploy_schema_migrations` marker table; **refuses
  `REQUIRES-REVIEW` files unless `ALLOW_DESTRUCTIVE_MIGRATION=1`**. Wired into
  `update.sh` / `migrate.sh` / `restore.sh`. Verified: additive applies,
  destructive refused then override-applies, idempotent no-op on re-run.
  (This testing also caught + fixed a real fd-0 stdin-drain bug that would have
  processed only the first migration.)
- `db-artifacts.yml` (app repo CI): generates `migrate-<ver>.sql` by anonymously
  cloning the **public** config repo for the previous schema (no token),
  semver-selecting the predecessor version, and includes it in the published
  artifact set.

## Remaining / optional

- **Decisions still open:** the cross-repo publish credential `CONFIG_REPO_TOKEN`
  (+ optional `CONFIG_REPO` var) so CI auto-commits SQL into `nxpi_config`;
  whether to ship an optional RLS-on schema variant.
- **Slim `nxpi-hash`** (259 MB) — deferred; the real library guarantees hash
  format parity.
- **Multi-version jumps:** `update.sh` applies the target version's
  `migrate-*.sql`; crossing several releases at once needs each intermediate
  `db/<v>/` present (or a squashed diff) — document as an operational note.
- All work is **UNCOMMITTED** in both repos.
