# NXPi — Standalone Azure VM Deployment Package

A **self-contained production deployment package** for running the NXPi
chatbot platform on a single Azure Ubuntu VM. Copy it to the VM and run one
command.

The application itself is an **immutable release artifact**: a Docker image
(linux/amd64) published by the app repo's CI to GHCR. This package only
*pulls* it — it never builds, compiles, or modifies the application.

```
ghcr.io/negentrophi/nxpi_dev   latest | main | sha-<short> | <pkgver>-main.<shortsha> | X.Y.Z
```

Only an exact `X.Y.Z` tag (published from a `v*` release tag) participates in
DB-version alignment/derivation — every other form is a moving or suffixed
build tag, and `DB_VERSION` in `.env` is authoritative alongside it.

## Prerequisites

- An **Azure Ubuntu VM** (22.04+), ≥2 vCPU / 8 GB, with inbound **22
  (restricted), 80, 443** open and nothing else. `Standard_D4ds_v6`
  (4 vCPU / 16 GB) is the recommended production size — B-series is burstable
  and credit exhaustion throttles CPU **and** disk under sustained vector search.
- **Dedicated data disks are optional here.** The stack ships with plain
  Docker-managed volumes on the OS disk. The hardened layout — PGDATA, WAL and
  the Redis AOF each bind-pinned to their own Premium SSD v2 at `/srv/pgdata`,
  `/srv/pgwal`, `/srv/redis` — is opt-in: run `./prepare-disks.sh`, uncomment the
  `driver_opts` blocks in `docker-compose.yml`, and read
  [`docs/CUTOVER-RUNBOOK.md`](docs/CUTOVER-RUNBOOK.md) first if the deployment is
  already live. Note the VM must be **zonal** for Premium SSD v2 and a zone
  cannot be added after creation, which is why the runbook is a rebuild.
- Ability to **pull two public GHCR images**: the application image and the
  `nxpi-hash` helper. (If either is a private package, `docker login ghcr.io`
  with a `read:packages` token first.)
- At least one **LLM provider API key** (OpenAI / Anthropic / …).

**No source code and no git access to the application repo are required.** The
database is provisioned from pre-generated static SQL shipped in this repo
(`db/<version>/`) and applied with plain `psql`; the admin password is hashed
on the VM by the public `nxpi-hash` helper. Nothing clones or builds the app.

## Contents

| File | Purpose |
|---|---|
| `install.sh` | Single-command idempotent installer / converger |
| `update.sh` | Pull latest image → schema sync → roll → health gate → auto-rollback |
| `migrate.sh` | Schema-ONLY migration of the existing database — never initializes, never touches data rows |
| `upgrade-db.sh` | Guided multi-release upgrade of an existing database to a shipped `db/<version>` (newest by default): data pre-checks, row-count snapshot, `migrate.sh`, then verifies every expected object and that nothing was lost |
| `backup.sh` | `pg_dump` + uploads-volume archive + retention with a keep-N floor + optional off-VM shipping to Blob (cron-able) |
| `restore.sh` | Restore a backup (destructive, `--yes`-gated, health-gated) |
| `pgbackrest.sh` | Point-in-time recovery: stanza, WAL archive, full/diff/incr backups, restore drill. **Adds to** `backup.sh`, does not replace it |
| `pgbackrest.conf` | pgBackRest repository/stanza config, mounted read-only into the postgres container (that is where `archive_command` runs) |
| `prepare-disks.sh` | Format / mount / persist the optional dedicated data disks; `--check` verifies without changing anything |
| `migrate-legacy-deployment.sh` | One-way, orchestrated move of a LEGACY checkout's data onto a fresh install of this one (destructive for the old stack) |
| `compose.sh` | Pin-honoring `docker compose` wrapper — use it for all manual compose operations |
| `lib.sh` | Shared helpers sourced by the scripts above |
| `docker-compose.yml` | The full production stack (app, Caddy, Postgres+pgvector, two Redis tiers) |
| `Caddyfile` | Reverse proxy: auto-HTTPS (domain mode), custom-cert import, security headers, SSE-safe compression |
| `generate-certs.sh` | Extract a `.pfx` bundle into `certs/` for custom-certificate mode (see `certs/README.md`) |
| `certs/` | Bring-your-own certificate material (bind-mounted read-only into Caddy) |
| `secrets-entrypoint.sh` | Bridges Docker file-secrets → env for the app container |
| `init.sql` | Enables the pgvector extension on first Postgres boot |
| `docs/CUTOVER-RUNBOOK.md` | Moving a LIVE deployment onto the dedicated data disks — read before touching disks |
| `db/<version>/` | Static provisioning SQL: `schema.sql` + `grants.sql` + `seed.sql` (+ `migrate-<version>.sql` for upgrades), published per release |
| `.env.example` | Compose interpolation values (image refs, URLs, admin seed, `DB_VERSION`) |
| `.env.app.example` | App runtime env (LLM provider keys, storage, cookies) |
| `secrets/` | Generated secret files live here (never commit/share them) |
| `backups/` | Local backup target |

## Fresh installation

1. **Provision a VM** — Ubuntu 22.04+, ≥2 vCPU / 8 GB (16 GB recommended —
   see [Prerequisites](#prerequisites)), NSG allowing inbound **22
   (restricted), 80, 443** and nothing else.

2. **Get this package onto the VM** and enter the deployment folder:

   ```bash
   ssh azureuser@<vm-ip>
   git clone https://github.com/lpanigrahi/nxpi_config.git
   cd nxpi_config
   cp .env.example .env
   ```
   Update the `.env` file with the machine IP, admin email, and (optionally)
   password. The per-release SQL bundle is also published as an OCI artifact —
   `oras pull ghcr.io/negentrophi/nxpi_dev/db:<version>` fetches
   `schema.sql`/`grants.sql`/`seed.sql` for a version this repo doesn't carry
   (the day-2 `migrate-*.sql` deltas ship only here).

3. **Run the installer:**

   ```bash
   ./install.sh
   ```

   It generates secrets, creates `.env`/`.env.app`, pulls the images, and
   provisions the database from the shipped SQL. It is **idempotent** —
   re-running is always safe and simply converges the deployment (existing
   secrets/env are never overwritten; a populated database is left as-is).

4. **Add an LLM key** (the only thing that cannot be generated for you):

   ```bash
   nano .env.app          # set e.g. ANTHROPIC_API_KEY=…
   ./compose.sh up -d app
   ```

5. **Log in** at the URL the installer printed. `.env.example` ships
   `SUPER_ADMIN_EMAIL=admin@negentrophi.com` — set it to your own address
   before the first install (if the key is absent entirely, `install.sh` falls
   back to `admin@example.com`). Leave `SUPER_ADMIN_PASSWORD` unset and
   the installer **generates a strong password and prints it once** in its
   summary — capture it, then change it after first login.

### Ingress modes: IP-only, domain (Let's Encrypt), custom certificate

| | IP-only (default) | Domain | Custom cert (bring your own) |
|---|---|---|---|
| `SITE_ADDRESS` in `.env` | *(unset)* | `your.domain.com` | `your.domain.com` (must match the cert) |
| `BETTER_AUTH_URL` in `.env` | `http://<vm-ip>` (auto-filled) | `https://your.domain.com` | `https://your.domain.com` |
| TLS | none (plain HTTP :80) | automatic Let's Encrypt on 80/443 | your certificate (corporate CA / wildcard / no ACME reachability) |
| Extra setup | — | DNS A-record → VM | put the `.pfx` at the project root; `install.sh` extracts it (see `certs/README.md`) |
| `.env.app` | `BETTER_AUTH_COOKIE_SECURE=false` (auto-set — without it sign-in loops) | leave unset | leave unset |

To switch to a domain later: point the DNS A-record at the VM, edit `.env`
(set `SITE_ADDRESS`, change `BETTER_AUTH_URL` to `https://…`), then re-run
`./install.sh` — it re-enables Secure cookies and restarts what changed
(a plain `./compose.sh up -d app caddy` works too if you also remove the
`BETTER_AUTH_COOKIE_SECURE=false` line from `.env.app` yourself).

### Version pinning

`APP_IMAGE` (the container) and the SQL artifact set in `db/<version>/` must
describe the **same release**. `install.sh` auto-derives the artifact version
from the image tag; set `DB_VERSION` explicitly when the tag is `:latest`.

```bash
# deterministic, recommended for production (immutable per-commit tag):
APP_IMAGE=ghcr.io/negentrophi/nxpi_dev:sha-9b5c610   DB_VERSION=1.15.0
# newest build — pin the artifact version explicitly:
APP_IMAGE=ghcr.io/negentrophi/nxpi_dev:latest        DB_VERSION=1.15.0
```

Moving/suffixed tags (`latest`, `main`, `sha-<short>`, `<pkgver>-main.<sha>`)
never auto-derive a DB version — `DB_VERSION` is required with them and the
scripts fail fast when it is missing.

## Updating

```bash
./update.sh
```

Order of operations — each stage aborts **before** the running app is touched:
safety backup → capture current image digest (rollback ref) → `pull app`
(only the app image; postgres/redis/caddy are never restarted by an update —
their image updates apply on `install.sh` re-runs) → additive-only schema
sync (a destructive schema diff *fails loudly* here by design) → `up -d app`
(single-container rolling restart; Caddy keeps serving) → health gate through
the public ingress (in domain mode this probes `https://<domain>` against the
real certificate, so a broken TLS/vhost fails the gate). If the gate fails,
the app is **automatically rolled back** to the captured digest and re-gated.

**Updates never re-initialize the database.** The schema step applies the
shipped `db/<version>/migrate-*.sql` via `psql` inside the postgres container:
it never seeds or overwrites rows and is additive-only on this path — your
data survives every upgrade. (A migration flagged `REQUIRES-REVIEW` is refused
here and routed through `./migrate.sh` for a deliberate maintenance window.)
Both
`update.sh` and `migrate.sh` additionally refuse to run against an *empty*
database (that's `install.sh`'s job), so a mis-targeted "update" can never
half-provision one.

### Schema-only migration (no app roll)

```bash
./migrate.sh                # safety backup → additive schema sync, data preserved
```

Use it when a release ships schema changes you want applied ahead of (or
independent of) rolling the app image — `update.sh` applies this same
migration set as part of the full upgrade. After a *destructive*
(`REQUIRES-REVIEW`) migration applied with `ALLOW_DESTRUCTIVE_MIGRATION=1`,
the still-running old image is *expected* to fail the post-migration health
check — `migrate.sh` says so and exits 0; roll the matching image with
`./update.sh` right after. For an adopted or freshly-restored database whose
migration marker is empty, set `ADOPT_SCHEMA_VERSION=<its release>` so
already-present migrations are stamped instead of re-applied.

Each migration file is applied in a **single transaction** (a mid-file
failure rolls the whole file back — the database is never left half-migrated),
and after a successful migration run the release's `grants.sql` is
**re-applied** (idempotent) so the app role picks up grants that only newer
releases carry.

### Upgrading THIS PACKAGE (one required step, once)

This revision adds a second Redis — a dedicated cache tier with the opposite
eviction policy to the queue tier — and the app service now consumes a
`redis_cache_url` **file secret**. That file is generated by `./install.sh`, not
by `./update.sh`, and Compose refuses to start a service whose declared secret
file is missing. So on an existing deployment adopting this version:

```bash
./install.sh          # idempotent converger; generates secrets/redis_cache_url
./update.sh           # only now
```

`install.sh` never re-seeds and never regenerates an existing secret
(`gen_secret` is create-only-if-missing), so this is safe to run on a live
deployment. Running `./update.sh` first fails on the missing secret file.

Nothing else here is required. The pgvector tuning, memory ceilings and PITR
switches all default to today's behaviour, and the dedicated-disk layout stays
opt-in (see [Prerequisites](#prerequisites)).

### Upgrading to db 1.15.0 (additive — rolling path)

`db/1.15.0/migrate-1.15.0.sql` bundles app migrations 0083–0089, which landed
between the cut of 1.13.0 (0081) and the cut of 1.14.0 (0090–0092) and were
packaged by **neither** — so a VM sitting at db 1.14.0 is already behind the
image built from the same tree. Six columns
(`model_pricing.cached_input_cost_per_1m` / `cache_write_cost_per_1m`,
`skill_install.enabled`, `plugin_bundle_install.enabled` / `reconciled_items`,
`plugin_bundle.deleted_at`) and five CHECK constraints (the plugin enums at the
database, and `nav_visibility_override` scope/organization agreement). Additive
only — every column is nullable or constant-defaulted, every constraint is keyed
on `pg_constraint` by name — so `./update.sh` applies it on the rolling path with
no maintenance window. Apply it twice and the second run is a no-op.

**Apply this BEFORE (or with) any image carrying app migration 0089.**
`plugin_bundle.deleted_at` is the soft-delete filter read on *every* Plugins
list/detail query, so an image ahead of this delta fails that tab with
`column "deleted_at" does not exist` (`42703`); the two `enabled` bits are read
on chat-toolkit resolution once an installer has toggled anything. The app's
boot-time schema sentinels now probe all of them, so a mismatched VM says so at
startup rather than at the first request.

The delta runs one `UPDATE` (`nav_visibility_override`), which reconciles rows
whose `scope` and `organization_id` disagree *before* adding the CHECK that
forbids the combination. It changes no row counts, so `./upgrade-db.sh`'s
snapshot comparison still holds.

**Optional, not automatic.** Source migration 0082 drops the redundant IVFFlat
index on `knowledge_embeddings.embedding` — an unused twin of the HNSW index:
write cost and storage, no read path. A `DROP` is not additive, and `migrate.sh`
is additive-only by contract, so it ships *outside* the `migrate-*.sql` glob as
`db/1.15.0/optional-0082-drop-ivfflat-index.sql`. Neither `./update.sh`,
`./migrate.sh` nor `./upgrade-db.sh` will ever apply it. Run it yourself whenever
convenient (metadata-only, milliseconds). Fresh installs from
`db/1.15.0/schema.sql` never have the index.

```bash
# 1. set DB_VERSION=1.15.0 in ./.env
# 2. rolling, additive-only path (auto-rollback intact):
./update.sh
# 3. (optional, any time) drop the redundant IVFFlat index:
./compose.sh exec -T postgres psql -U neogen_admin -d neogen \
  -v ON_ERROR_STOP=1 < db/1.15.0/optional-0082-drop-ivfflat-index.sql
```

Network note for the acquisition surfaces that arrived with 1.14.0: GitHub /
git-URL plugin import and marketplace-source sync fetch from `github.com` (and
the registered marketplace hosts) over outbound HTTPS from the `app` container,
which sits on the non-internal `frontend` network — allow that egress. Public
repositories only; no token is read.

### Upgrading to db 1.14.0 (additive — rolling path)

`db/1.14.0/migrate-1.14.0.sql` bundles app migrations 0090–0092 (plugin
acquisition, ADR-0105): two new tables (`plugin_source`, `plugin_source_entry` —
registered GitHub / git-URL / hosted-marketplace sources and their synced
entries), two nullable columns on `plugin_bundle` (`source_id`, `origin` — the
acquisition provenance a bundle records) and one nullable column on
`plugin_source` (`last_sync_notes`), with their indexes and FKs. Nothing is
dropped, narrowed or rewritten, so `./update.sh` applies it on the rolling path
with no maintenance window.

**Apply this BEFORE (or with) any image carrying app migration 0090** — this is
the *sixth* occurrence of this incident class (after 1.6.0's `qa_baseline_hash`,
1.8.0's `deployed`, 1.10.0's `session.mfa_verified_at` and 1.11.0's
`organization_entitlement`). Every render of the Plugins tab, list and detail,
selects `plugin_bundle.origin`, so an image ahead of this delta fails that
screen with `column "origin" does not exist` (`42703`). `./update.sh` migrates
before switching the image, which is the correct order; a manual image swap is
how to get it wrong.

Inert on arrival: the new tables start empty and the new columns are nullable
with no default, so nothing changes until an admin registers a plugin source or
imports a plugin. The acquisition surfaces ship **default ON** as platform
flags; each has an operator kill switch in `./.env.app` (`PLUGIN_IMPORT_V1`,
`PLUGIN_MARKETPLACES_V1`, `PLUGIN_GENERATOR_V1` — see `.env.app.example`).

Because these are new **tables**, they need new privileges rather than
inheriting an existing table's. The delta grants them and `grants.sql` re-asserts
them; `./upgrade-db.sh` verifies the role actually got them.

```bash
# 1. set DB_VERSION=1.14.0 in ./.env
# 2. rolling, additive-only path (auto-rollback intact):
./update.sh
```

### Upgrading to db 1.13.0 (additive — rolling path)

`db/1.13.0/migrate-1.13.0.sql` bundles app migration 0081: one boolean column
(`org_role_permission.denied`, `DEFAULT false`) plus a partial index. Additive
only, so `./update.sh` applies it on the rolling path with no maintenance window.

**Apply this BEFORE (or with) any image carrying ADR-0083.** The app queries
`denied` on every read of Organizations → Roles & Permissions, so an image ahead
of this delta fails that screen with `column "denied" does not exist`.

Inert on arrival: org RBAC was a pure union of a role's own rows, its ancestors'
and its groups', with no way to subtract — which is why the Permission Matrix
rendered inherited cells locked. This column represents the missing state (no
row = no statement, `denied = false` = granted, `denied = true` = refused,
outranking inheritance). The default preserves every existing row's meaning and
permission resolution stays byte-identical until an admin unticks an inherited
cell for the first time.

The index is **partial** (`WHERE denied`), so `information_schema` cannot see it
— `./upgrade-db.sh` probes `pg_indexes` for it, the same way it does for 1.11.0's
two partial UNIQUE indexes.

```bash
# 1. set DB_VERSION=1.13.0 in ./.env
# 2. rolling, additive-only path (auto-rollback intact):
./update.sh
```

### Upgrading to db 1.12.0 (additive — rolling path)

`db/1.12.0/migrate-1.12.0.sql` bundles app migration 0080: three columns on
`"user"` (`failed_login_attempts`, `last_failed_login_at`, `locked_until`)
backing account lockout after repeated failed sign-ins. Additive, no backfill,
metadata-only (the `DEFAULT 0` is a constant, so PostgreSQL 11+ records it in
the catalog and never rewrites the table) — deliberately **not**
REQUIRES-REVIEW, so `./update.sh` applies it with no maintenance window.

**Apply this BEFORE (or with) any image carrying app migration 0080.** Once an
admin enables lockout, the sign-in route reads `user.locked_until` on *every*
attempt, so an image ahead of this delta `42703`s there — a total login outage,
the same blast radius as 1.10.0's `session.mfa_verified_at`.

The columns are deliberately **not** part of the Better Auth user model, so an
*older* image is unaffected by them: this delta is safe to apply ahead of the
image roll with `./migrate.sh`. The feature stays inert until it is switched on
— the stored policy defaults to disabled, and `ACCOUNT_LOCKOUT_ENABLED=false`
in `./.env.app` is a hard kill switch that overrides the stored setting (and
the break-glass route back in if a lock on your only super admin is what is
keeping you out of the console).

```bash
# 1. set DB_VERSION=1.12.0 in ./.env
# 2. rolling, additive-only path (auto-rollback intact):
./update.sh
```

This delta creates no unique index, so unlike 1.11.0 it has no live-data
pre-check to fail on — an `ADD COLUMN` with a constant default cannot conflict
with existing rows. `./upgrade-db.sh` still verifies all three columns landed.

### Upgrading to db 1.11.0 (additive — rolling path)

`db/1.11.0/migrate-1.11.0.sql` bundles app migrations 0078 and 0079: the
`organization_entitlement` table (per-org entitlement override that can *raise*
a cap above the plan's, ADR-0073) and two partial UNIQUE indexes that make the
billing webhook and org invites idempotent. Additive, no backfill, arrives
empty — deliberately **not** REQUIRES-REVIEW, so `./update.sh` applies it with
no maintenance window.

**Apply this BEFORE (or with) any image carrying app migration 0078.**
`resolveOrgEntitlement` sits on the org-quota path that *every inference
request* walks, so an image ahead of this delta `42P01`s there.

```bash
# 1. set DB_VERSION=1.11.0 in ./.env
# 2. rolling, additive-only path (auto-rollback intact):
./update.sh
```

**If the migration stops on duplicate data** — `org_invite_pending_email_uq` or
`invoice_org_external_id_uq` "cannot be created" — that is this delta's own
pre-flight guard, not a failure. Nothing was applied: the whole file rolls back
in one transaction and is not stamped. The delta refuses to delete rows to make
an index fit, because `migrate.sh` is additive-only by contract, so the data is
yours to resolve deliberately. Duplicate *pending* invites are expected on a VM
with invite churn — re-inviting after an invite expired leaves both rows
pending. The error names the query that lists the offending groups.

`./upgrade-db.sh` checks both tables during **preflight** instead, so
`./upgrade-db.sh --dry-run` reports the problem before anything is backed up,
migrated, or written to `./.env`.

### Upgrading to db 1.10.0 (additive — rolling path)

`db/1.10.0/migrate-1.10.0.sql` bundles app migration 0077: one nullable column,
`session.mfa_verified_at`, recording that the IdP (Entra) asserted MFA for a
sign-in. Additive, no backfill, no default — deliberately **not**
REQUIRES-REVIEW, so the rolling `./update.sh` path applies it with no
maintenance window.

**Apply this BEFORE (or with) any image carrying app migration 0077.** Better
Auth's drizzle adapter names every column explicitly, so an image ahead of this
delta `42703`s inside `auth.api.getSession()` — that is a total login outage,
not a degraded page. It is the fourth incident of this class (after 1.5.0's
`lifecycle_status`, 1.6.0's `qa_baseline_hash` and 1.8.0's `deployed`) and the
first to take authentication down rather than one page.

```bash
# 1. set DB_VERSION=1.10.0 in ./.env
# 2. rolling, additive-only path (auto-rollback intact):
./update.sh
```

If you are still on 1.8.0 or earlier, `update.sh` will want to apply 1.9.0 first
and will refuse — that one is REQUIRES-REVIEW. Either take the guided path,
which handles both in one run:

```bash
./upgrade-db.sh            # walks 1.5.0 → newest, gating 1.9.0 for review
```

…or take 1.9.0 through the maintenance path below, then re-run `./update.sh`.

### Upgrading to db 1.9.0 (REQUIRES-REVIEW)

`db/1.9.0/migrate-1.9.0.sql` bundles app migrations 0071–0076 (governance
policy versioning, the append-only audit trigger, the cron single-claim
index, queue idempotency tables, the audit hash chain, agent-deployment
ownership). It is flagged REQUIRES-REVIEW because 0073 re-creates the
`document_chunk` organization FK as `ON DELETE CASCADE` — deleting an
organization then deletes its RAG corpus instead of re-homing it. Runbook:

**Recommended — the guided path.** `./upgrade-db.sh` drives the same
machinery with the pre- and post-checks a multi-release jump needs:

```bash
./upgrade-db.sh --dry-run         # report what would happen, change nothing
./upgrade-db.sh                   # backup → migrate → verify (newest shipped db/)
./upgrade-db.sh 1.9.0             # or stop at a specific release
./update.sh                       # then roll the matching image
```

It adds no migration logic of its own — it calls `./migrate.sh` — but it:

* **refuses to guess `ADOPT_SCHEMA_VERSION`** on a database whose migration
  marker is empty, and shows exactly which files would be *stamped* versus
  *executed* before you confirm. This matters: guessing too low re-runs
  `db/1.3.0/migrate-1.3.0.sql`, which `DELETE`s `org_role_permission` and
  `org_permission_group_item` rows. Use
  `./upgrade-db.sh --adopt-schema-version <X.Y.Z>` once you have confirmed
  the schema's actual release;
* **pre-checks `cron_run_log` for duplicate `running` rows.**
  `migrate-1.9.0.sql` downgrades that collision to a `NOTICE`, so psql still
  exits 0 and the file is stamped applied while its unique index is silently
  never created — the app then fails at runtime with *"no unique or exclusion
  constraint matching the ON CONFLICT specification"* and nothing in the marker
  table hints at it;
* **pre-checks `invoice` and `org_invite` for duplicates** when
  `migrate-1.11.0.sql` is pending. That delta fails *closed* on them rather
  than deleting rows to make its UNIQUE indexes fit, so without this check the
  stop arrives only after a full backup has been taken;
* **snapshots every table's row count** to
  `backups/pre-<version>-rowcounts.txt` before migrating and re-compares
  afterwards, so "no data was lost" is verified rather than assumed;
* **verifies the result** — every table, column, index, trigger and FK the
  deltas in scope should have produced, plus that `grants.sql` actually
  reached the new tables — and refuses to declare success if any check fails.

**Manual equivalent**, if you prefer to drive it yourself:

```bash
# 1. review the delta:  less db/1.9.0/migrate-1.9.0.sql
# 2. set DB_VERSION=1.9.0 in ./.env
# 3. backup-first, deliberate maintenance path (update.sh refuses this delta):
ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh
# 4. roll the matching image:
./update.sh
```

Either way, set `AUDIT_SIGNING_KEY` in `./.env.app` **before** the first
post-1.9.0 audit row is written — 1.9.0 installs the admin-audit hash chain, and
it starts from whatever key is active at the first write.

## Backup

```bash
./backup.sh
```

Produces `backups/neogen-<timestamp>.dump` (`pg_dump -Fc`, integrity-checked)
plus `backups/uploads-<timestamp>.tar.gz` when file storage is local. Local
retention is `BACKUP_RETENTION_DAYS` (default 7, set in `.env`) with a COUNT
floor, `BACKUP_MIN_KEEP` (default 3): age alone is not a retention policy, and
`find -mtime` would otherwise delete your last dump after a quiet month.

Set `BACKUP_BLOB_ACCOUNT` + `BACKUP_BLOB_CONTAINER` in `.env` to ship each dump
off the VM automatically. It uses `--auth-mode login` (the VM's managed
identity), so no account key sits on disk, and a shipping failure makes the run
exit non-zero so cron notices. Give the container versioning and a time-based
immutability policy — a backup a compromised VM can delete is not a backup.

Daily cron:

```bash
crontab -e
# 0 3 * * *  cd $HOME/azure-deployment && ./backup.sh >> "backups/cron-$(date +\%F).log" 2>&1
```

Exit codes for cron/automation: `backup.sh` exits **1** when the database
dump succeeded but the uploads archive failed (a silent 0 would let uploads
backups quietly stop accumulating); `update.sh` exits **0** on success, **2**
when the update failed but the automatic rollback left the OLD image serving
healthily, and **1** on hard failures; `restore.sh` exits **1** when the
restore completed degraded (e.g. uploads not restored).

(Dated cron logs are pruned by the same retention window as the dumps. If a
backup fires while another operation holds the deployment lock, it skips that
run rather than snapshotting a mid-operation database.)

**A single VM's disk is not a durability story** — ship dumps off the VM
(`az storage blob upload …`; the exact command is printed after every backup),
and keep a copy of the `secrets/` directory somewhere safe: **losing the
secrets means losing access to the data** (an `install.sh` re-run adopts, it
never resets passwords).

### Point-in-time recovery (pgBackRest — optional, OFF by default)

`backup.sh` gives you the state at each dump. `pgbackrest.sh` adds a continuous
WAL archive so you can recover to a moment *between* them, and protects against
losing the disk rather than only against logical damage. It is **added
alongside**, never instead: `update.sh`, `migrate.sh` and `restore.sh` all depend
on `backup.sh`'s exit-code contract and its `neogen-*.dump` filename.

The enabling ORDER is load-bearing. Turning on `archive_mode` while the
repository is unreachable makes Postgres **retain every WAL segment until the
disk fills and the database stops accepting writes** — worse than not archiving
at all:

```bash
# 1. POSTGRES_IMAGE=ghcr.io/<owner>/nxpi-postgres:<ver> in ./.env, then:
./compose.sh up -d postgres          # archive_command runs INSIDE this container,
                                     # so the binary has to be there, not on the host
# 2. fill repo1-azure-* in ./pgbackrest.conf
./pgbackrest.sh stanza-create
./pgbackrest.sh check                # MUST pass before the next step
# 3. POSTGRES_ARCHIVE_MODE=on in ./.env, then RESTART (archive_mode needs a
#    restart, not a reload):
./compose.sh up -d --force-recreate postgres
```

Then `./pgbackrest.sh backup full|diff|incr` and `./pgbackrest.sh info`. Restores
are deliberately not automated — `./pgbackrest.sh drill` prints the exact command
and what to verify. **PITR is not done when a backup succeeds; it is done when
you have restored to a target time on a scratch VM and passed a health gate.**
Record the wall-clock time that takes: it is your RTO.

Never put an account key in `pgbackrest.conf` — that file is committed. Prefer a
managed identity, or pass `PGBACKREST_REPO1_AZURE_KEY` through `./.env`
(pgbackrest reads `PGBACKREST_*` from the environment and they override the
file).

## Restore

```bash
./restore.sh --yes                                      # newest local dump
./restore.sh --yes backups/neogen-<ts>.dump             # specific dump
./restore.sh --yes <dump> --uploads backups/uploads-<ts>.tar.gz
```

Destructive: validates both archives up front, takes a **safety backup of the
current state first** (skip with `--no-backup`; the uploads safety archive is
mandatory when `--uploads` is used), stops the app, **drops the schema and
restores exactly the dump** (a plain `--clean` restore would leave objects the
dump doesn't know about, silently mixing releases), re-applies `grants.sql`,
verifies the result, **re-runs the additive schema sync** (so a dump older
than the current release cannot leave the schema behind the code), **flushes
both Redis tiers** (queued jobs from the post-dump timeline
would reference rows that no longer exist), restarts, and health-gates — so
even restoring the wrong dump is recoverable.

## Rollback (image only, no data restore)

`update.sh` rolls back automatically on a failed health gate (also when the
roll itself fails). It writes the digest pin to `.rollback-image.yml` and
applies it as a compose override — deliberately *not* an `APP_IMAGE=… docker
compose` env prefix, which is silently stripped when docker runs through
`sudo`. **Every script in this package honors the pin** (install/update/
restore all route compose through it), so a later `install.sh` converge or
`restore.sh` cannot accidentally redeploy the broken image; the next
*successful* `./update.sh` clears it. To roll back manually to any
previously-running image, pin the digest it prints in `.env`:

```bash
# .env
APP_IMAGE=ghcr.io/negentrophi/nxpi_dev@sha256:…
```

then `./compose.sh up -d app`. Schema syncs are additive-only, so an older
image keeps working against a newer schema.

## Migrating from a legacy checkout

`migrate-legacy-deployment.sh` moves an OLD, already-running deployment's data
onto a fresh install of *this* checkout — for a machine carrying an older copy of
this package in a different directory:

```bash
./migrate-legacy-deployment.sh --old-dir /path/to/old-checkout --yes
./migrate-legacy-deployment.sh --old-dir /path/to/old-checkout --yes \
    --adopt-schema-version 1.4.0        # if the old schema's marker is empty
```

It adds no `pg_dump`/`pg_restore`/secret-generation logic of its own — it drives
`backup.sh` → `install.sh` → `restore.sh` → `migrate.sh` → `update.sh` in order.
Two things to understand before running it:

- **It is DESTRUCTIVE and ONE-WAY for the old deployment.** Step 4 is
  `docker compose down -v` in `--old-dir` (both checkouts use the same compose
  project name, so they cannot run side by side). After that point, recovery
  means restoring the staged dump through this checkout, not undoing the
  teardown.
- **Only `better_auth_secret` is carried over.** Regenerating it would
  permanently break decryption of stored integration credentials and invalidate
  every session. Postgres/Redis secrets are deliberately regenerated fresh —
  safe, and it is what sidesteps stale credentials on the old side. The script
  refuses to start if this checkout already has any of them.

Zero data loss, **not** zero downtime: the app is offline from step 4 until the
step-8 health gate. Uploads on local disk storage are not handled — use
`backup.sh`/`restore.sh --uploads` for those yourself; the script only warns.

## Day-2 quick reference

Use `./compose.sh` (not raw `docker compose`) for anything that (re)creates
containers: after a failed update auto-rolls back, the wrapper keeps the app
pinned to the last-good image where raw compose would redeploy the broken one.

```bash
./compose.sh ps                          # stack status (healthy?)
./compose.sh logs -f app                 # app logs
./compose.sh logs -f caddy               # ingress logs
curl -s localhost/api/health/ready       # readiness through Caddy
./migrate.sh                             # schema-only migration (data preserved)
./upgrade-db.sh --dry-run                # what an upgrade would do (no changes)
./prepare-disks.sh --check               # dedicated-disk layout: verify, change nothing
./pgbackrest.sh info                     # what the PITR repository holds (if enabled)
./compose.sh exec postgres psql -U neogen_admin -d neogen   # SQL console
```

Reboots need nothing: every service has `restart: unless-stopped`.

## Security posture (what's already in place)

- Only Caddy publishes ports (80/443); the app port is not host-exposed and
  the data tier lives on an **internal network with no egress**.
- The app image runs **non-root (uid 1001)**; `no-new-privileges` everywhere;
  `cap_drop: ALL` on app and Caddy (Caddy keeps only `NET_BIND_SERVICE`).
- Credentials are **file-secrets** (never in `docker inspect` or process
  argv); the app's secrets are readable only by uid 1001, mode 400.
- Least-privilege DB split: the app connects as `neo_gen` (DML-only); the
  superuser is used only by the deployment scripts' DDL, via `psql` inside
  the postgres container.
- Security headers + SSE-safe compression at the proxy (see `Caddyfile` for
  what is deliberately *not* set there, and why).
- Memory limits and log rotation (10 MB × 3) on every service.

## Development: helper self-test

`tests/lib-harness.sh` asserts the pure helpers in `lib.sh` (dotenv parsing,
semver ordering, version/artifact resolution, migration-file selection,
percent-decoding, the rollback-pin compose wrapper, the data-placement deciders
`placement_verdict`/`compose_volume_device`/`mount_ok`/`fstab_has_mount`, the
backup retention floor `prune_keeping`, and the pgBackRest readiness guards) in a
throwaway sandbox — no docker or database needed. Run it after any `lib.sh`
change:

```bash
bash tests/lib-harness.sh                 # local
docker run --rm -v "$PWD":/pkg:ro ubuntu:24.04 \
  bash /pkg/tests/lib-harness.sh /pkg/lib.sh   # target-fidelity (Ubuntu)
```

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `install.sh` dies at image pull with auth error | The GHCR package is private: `echo $PAT \| docker login ghcr.io -u <user> --password-stdin` (PAT scope `read:packages`), re-run. |
| `install.sh` dies: "APP_IMAGE tag is X but DB_VERSION=Y" | `assert_version_alignment` refuses a mismatch on purpose — it only fires for an exact `X.Y.Z` image tag (moving tags like `latest`/`main`/`sha-…`/`<ver>-main.<sha>` skip it and rely on `DB_VERSION`). Note the app version and the DB artifact version advance INDEPENDENTLY — `package.json` is at 1.2.0 while `db/` reaches 1.15.0, because a release that ships no migration does not add a `db/<ver>/` folder. Set `DB_VERSION` explicitly rather than letting it derive from the tag. |
| `install.sh` dies: "no SQL artifacts found under ./db" | The `db/<version>/` folder for your image tag isn't present. Set `DB_VERSION` in `.env` to a version that exists under `db/`, or pull the matching release of this repo. |
| Seed step: "could not compute the admin hash" | The `nxpi-hash` helper image isn't pullable. `docker pull ghcr.io/negentrophi/nxpi-hash:latest` (published by the app repo's ci.yml; or set `NXPI_HASH_IMAGE`), then re-run. |
| `install.sh` dies: "existing data volume found but no secrets" | You are adopting data from a previous deployment — copy its `secrets/` directory here (new random secrets can't open old data), or `docker compose down -v` to start fresh (destroys all data). |
| App logs: `FATAL: … not readable by uid 1001` | Secret file permissions drifted. `sudo chown 1001 secrets/{postgres_url,redis_url,redis_cache_url,better_auth_secret} && sudo chmod 400` same files, then `docker compose up -d app`. |
| Sign-in loops back to the login page (IP mode) | `BETTER_AUTH_COOKIE_SECURE=false` missing from `.env.app`, or `BETTER_AUTH_URL` doesn't exactly match what the browser uses (scheme + host, no trailing slash). |
| A `migrate-<ver>.sql` fails to apply | It stops before the app is rolled (data untouched). Inspect the file under `db/<ver>/`; a genuinely destructive change needs a maintenance window + backup. Confirm `DB_VERSION` matches the target image. |
| Port 80 already in use | Another web server on the VM. Stop it, or set `CADDY_HTTP_PORT`/`CADDY_HTTPS_PORT` in `.env` and front it yourself. |
| Health gate fails after update | `update.sh` already rolled back. Diagnose with `docker compose logs app`; the pre-update backup is in `./backups`. |
| Lost the super-admin password | No automatic reset. Restore a backup, or if the data is disposable: `docker compose down -v` and `./install.sh` fresh (a new password is generated). |

## Relationship to the application repository

This package deploys the NXPi application, whose source lives in a separate
repository (`github.com/negentrophi/nxpi_dev`, folder `azure-deployment/`
there — that repo now carries its own copy of this same package).
**Neither the source nor git access to it is needed to deploy from here.**
The application is consumed only as a pre-built container image from GHCR
(`ghcr.io/negentrophi/nxpi_dev`), and the database is provisioned from static
SQL (`db/<version>/`) shipped in this repo — applied on the VM with plain
`psql`. The admin password is hashed locally by the public `nxpi-hash` helper
image.

The app repo's CI (`ci.yml`) publishes three artifacts per build: the app
image, the SQL bundle as an ORAS OCI artifact
(`ghcr.io/negentrophi/nxpi_dev/db`), and the `nxpi-hash` helper — but it does
not push into this repo automatically (the earlier cross-repo auto-publish
design is obsolete; see the note at the top of
[`docs/SOURCELESS-DEPLOYMENT-PLAN.md`](docs/SOURCELESS-DEPLOYMENT-PLAN.md)).
New `db/<version>/` folders and deployment-tooling fixes land in the app
repo's embedded copy first and are carried over here by hand — check that
copy periodically if a release you need isn't under `db/` yet.

Keep `APP_IMAGE` and the `db/<version>/` artifacts pointing at the **same
release** — the [Version pinning](#version-pinning) section explains the
mapping.

## License

Apache License 2.0 — see [`LICENSE`](../LICENSE) at the repository root.
