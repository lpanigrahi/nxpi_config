# NXPi deployment and upgrade guide

Two jobs, one package: stand up a **new** NXPi deployment on an Azure Ubuntu
VM (Part A), or move an **existing** deployment to a newer database release and
app image (Part B). In both, zero data loss is verified by the scripts, never
assumed. Written for the operator with SSH and sudo on the VM; every command
runs from the package directory and every script prints `--help`.

The companion `docs/RELEASE-UPGRADE-RUNBOOK.md` is Part B §4.1 written for
the current move: a VM at db 1.41.0 on `sha-cb44bba` rolled to
`nxpi:latest` (no database change). The 1.15.0 → 1.41.0 window runbook is
at `git show 00bb498:docs/RELEASE-UPGRADE-RUNBOOK.md`.

## 1. Which path am I on?

| Starting point | Path | Driver | Downtime |
|---|---|---|---|
| No VM yet, or an empty database | Part A | `./install.sh` | none |
| Already at the newest shipped `db/<version>`, only a newer image build to roll | Part B §4.1 | `./update.sh` | seconds |
| One additive release behind (no `REQUIRES-REVIEW` delta pending) | Part B §4.1 | `./update.sh` | seconds |
| Several releases behind, or any pending delta is `REQUIRES-REVIEW` (1.26.0, 1.29.0, 1.35.0 today) | Part B §4.2 | `./upgrade-release.sh` | minutes, announced |
| Old package checkout in another directory | README, *Migrating from a legacy checkout* | `./migrate-legacy-deployment.sh` | minutes |

`./discover.sh` tells you which row you are in: it prints the pending delta
list and flags the `REQUIRES-REVIEW` ones.

**What "no data loss" means here**

- Every user-authored row is counted with the app stopped before and after a
  change; only a printed allow-list of changes is tolerated.
- Uploaded files are compared by count and bytes; a tar sits in the bundle.
- Sessions, passwords and stored integration credentials survive because the
  secrets under `secrets/` are never regenerated once they exist.
- The way back is a restore of the safety bundle (dump + uploads + config),
  never a hope that the old image tolerates the new schema.
- Nothing is cataloged, deleted or backfilled on your behalf outside the
  shipped SQL deltas; decisions are surfaced as typed acknowledgements.

## 2. Analysis: how the package works

The package is **sourceless**: it pulls an immutable app image from GHCR and
provisions PostgreSQL from static SQL under `db/<version>/` with `psql` inside
the postgres container. The app never migrates its own schema
(`AUTO_DB_MIGRATE=false`), so the database changes only when an operator runs a
script from this package. That is what makes every guarantee checkable.

```
 Caddy (:80/:443) ──▶ App (ghcr.io/negentrophi/nxpi, uid 1001)
                          │
        ┌─────────────────┼──────────────────┬──────────────────┐
        ▼                 ▼                  ▼                  ▼
  Postgres 17        Redis (queue)      Redis (cache)        Uploads
  * USER DATA *      BullMQ, AOF        no persistence      * USER DATA *
  postgres-data      redis-data         rebuilt on start    uploads-data
  postgres-wal       flushed on restore

 Host directory (the package clone, mounted into the containers)
  secrets/ * USER DATA *   .env, .env.app   certs/, Caddyfile   backups/
  better_auth_secret also  image pin,       bring-your-own TLS  dumps, uploads
  encrypts credentials     DB_VERSION,      (ACME state lives   tars: ship
                           LLM keys         in caddy-data)      off the VM
```

**Components (package `main` 00bb498; app `main` 2a22ae7c9, 2026-10-01)**

| Piece | Value | Why it matters |
|---|---|---|
| App image | `ghcr.io/negentrophi/nxpi` (`latest`, `sha-<short>`, `X.Y.Z`); `nxpi_dev` is frozen | pin `tag@sha256:…`; an `.env` naming `nxpi_dev` never updates again |
| Deployed build | `nxpi:sha-cb44bba@sha256:1a615b98…868af9`, linux/amd64 | needs `TRUSTED_PROXY_MODE=xff` in `.env.app` to boot; `/api/health/deep` wants `METRICS_TOKEN` |
| Next build | `nxpi:latest` from app `2a22ae7c9` (server-side document tools); still db 1.41.0 | image-only roll via `update.sh`; `DB_VERSION=1.41.0` must stay set with a moving tag |
| Database | PostgreSQL 17 + pgvector; newest shipped `db/1.41.0` (= app migration 0042) | `DB_VERSION` is authoritative for every non-`X.Y.Z` tag |
| Bookkeeping | marker `public.deploy_schema_migrations`, one row per applied delta | pending set = shipped deltas minus marker rows; never guess it |
| Roll-forward-only | 1.3.0, 1.9.0, 1.26.0, 1.29.0, 1.35.0 (`REQUIRES-REVIEW` in the first lines) | old image cannot serve the schema afterwards; rollback = restore the bundle |
| Row-level security | forced on 26+ tables since 1.29.0 | sweeps need the BYPASSRLS role `neogen_priv` |
| Uploads rule | since 1.36.0 + this image, a file with no `thread_attachment` row answers 404 (except `uploads/shared/`) | `discover.sh` inventories them; nothing catalogs for you |
| Compose project | `neogen`; volumes `neogen_postgres-data`, `neogen_postgres-wal`, `neogen_redis-data`, `neogen_uploads-data`, `neogen_caddy-data` | Docker-managed on the OS disk by default; dedicated disks opt-in |

**What counts as user data, and what protects it**

| Data | Lives in | Protected by |
|---|---|---|
| Rows (users, orgs, chats, attachments, knowledge, agents, RBAC, audit) | `neogen_postgres-data` (+ WAL) | `backup.sh` dump; row-count and custom-RBAC compares in every upgrade |
| Uploaded files | `neogen_uploads-data` | `backup.sh` tar; count + bytes compared after an upgrade |
| Passwords, sessions | `user`, `account`, `session` | never touched by deltas; sign-in smoke test after a roll |
| Integration credentials | encrypted under `secrets/better_auth_secret` | `install.sh` never regenerates an existing secret; **not in any backup** |
| TLS certificates, ACME account | `neogen_caddy-data`, `certs/` | archived in the release bundle |
| Queue state | `neogen_redis-data` | deliberately flushed on restore |

## 3. Part A: a new deployment

A fresh install provisions the database straight from
`db/<DB_VERSION>/schema.sql` (no deltas replayed). You supply the VM, a DNS
name if you want TLS, an admin email and an LLM key.

### 3.1 Provision the VM

1. Ubuntu 22.04/24.04, ≥ 2 vCPU / 8 GB; `Standard_D4ds_v6` (4 vCPU / 16 GB)
   recommended for production. Avoid B-series (credit exhaustion throttles CPU
   and disk under vector search).
2. NSG: inbound **22** (restricted), **80**, **443**, nothing else. Static
   public IP.
3. Optional hardened storage (three Premium SSD v2 disks at LUN 10/11/12,
   zonal VM required): skip for a first deployment; `docs/CUTOVER-RUNBOOK.md`
   moves a live deployment later.
4. Domain mode: create the DNS A record before the install so Let's Encrypt
   validates on the first start.

### 3.2 Get the package onto the VM

```bash
ssh azureuser@<vm-ip>
git clone https://github.com/lpanigrahi/nxpi_config.git
cd nxpi_config
ls db | sort -V | tail -1        # newest shipped release
bash tests/lib-harness.sh        # "0 failed"
```

Clone as the login user, never with `sudo` (a root-owned directory fails every
later write; the installer says how to fix it).

### 3.3 Write `.env`

```bash
cp .env.example .env && nano .env
```

| Key | Set to | Notes |
|---|---|---|
| `APP_IMAGE` | `ghcr.io/negentrophi/nxpi:sha-<short>@sha256:<digest>` | tag + digest: readable and immutable |
| `DB_VERSION` | the release matching the image (`1.41.0` today) | must be a folder under `db/` |
| `BETTER_AUTH_URL` | IP mode: leave the placeholder (auto-filled). Domain mode: `https://your.domain` | exact match with what browsers use |
| `SITE_ADDRESS` | domain mode only | turns on auto-HTTPS; mismatch with `BETTER_AUTH_URL` is refused |
| `SUPER_ADMIN_EMAIL` | your address | change before the first run |
| `SUPER_ADMIN_PASSWORD` | leave unset | generated and printed **once** |
| `POSTGRES_PRIVILEGED_URL_FILE` | `/run/secrets/postgres_privileged_url` | opt-in BYPASSRLS pool; `install.sh` then provisions `neogen_priv` |
| `BACKUP_BLOB_ACCOUNT`, `BACKUP_BLOB_CONTAINER` | your storage account | dumps shipped off the VM via managed identity |
| memory profile keys | the 16 GB profile from the comments if sized so | defaults fit 8 GB |

Custom certificate: put the `.pfx` at the project root, set `SITE_ADDRESS`,
`BETTER_AUTH_URL=https://…`, optionally `PFX_PASSWORD`.

### 3.4 Run the installer

```bash
./install.sh
```

Idempotent, in order: Ubuntu/sudo check → Docker Engine + Compose v2 if
missing → secret files (app secrets uid 1001, mode 400) → `.env.app` from the
example, `BETTER_AUTH_COOKIE_SECURE=false` in IP mode, `TRUSTED_PROXY_MODE=xff`
and a `METRICS_TOKEN` appended → pull the app image and the `nxpi-hash` helper
→ start Postgres and both Redis tiers → `schema.sql`, marker stamped through
`DB_VERSION`, `grants.sql`, atomic `seed.sql` → `neogen_priv` when opted in →
app + Caddy, health gate **through the public ingress**.

- [ ] Copy the generated super-admin password from the summary (printed only there).
- [ ] If the docker group was just added, the next login picks it up.

On failure, fix the cause and re-run. It never regenerates an existing secret,
never re-seeds a populated database, and resumes an interrupted seed.

### 3.5 Add the LLM key

```bash
nano .env.app          # ANTHROPIC_API_KEY=… or OPENAI_API_KEY=…
./compose.sh up -d app
```

Day-one settings in `.env.app`: `DISABLE_SIGN_UP=true` if only invited users
may register; `FILE_STORAGE_TYPE=azure` if uploads should live in Blob (decide
before any upload, there is no mover); OAuth client IDs. Always use
`./compose.sh`, never raw `docker compose` (it honours the rollback pin).

### 3.6 First login and functional check

- [ ] Sign in as the super admin; change the password.
- [ ] A chat message streams to completion.
- [ ] Upload a file in a chat and open it again.
- [ ] Create a knowledge base, add a document, search it.
- [ ] Organizations → Roles & Permissions renders the catalog.
- [ ] `./compose.sh logs --tail 100 app`: no `TRUSTED_PROXY_MODE`, sentinel or `POSTGRES_PRIVILEGED_URL` warnings.
- [ ] `./provision-privileged-role.sh --check` prints five ok lines (if opted in).
- [ ] `./schema-parity.sh <DB_VERSION>` ends with *live catalog matches*.

### 3.7 Protect the data before anyone uses it

1. **Copy `secrets/` off the VM now** (in no backup; `better_auth_secret`
   also encrypts stored integration credentials):
   ```bash
   tar czf - secrets .env .env.app | gpg -c > nxpi-secrets-$(date +%F).tgz.gpg
   ```
2. Daily backups:
   ```
   0 3 * * *  cd $HOME/nxpi_config && ./backup.sh >> "backups/cron-$(date +\%F).log" 2>&1
   ```
3. Prove a restore once while the data is disposable: `./backup.sh`, then
   `./restore.sh --yes`, sign in again, record the time.
4. Optional PITR (`pgbackrest.sh`) only after `stanza-create` and `check`
   pass; enabling `archive_mode` first fills the disk.
5. Record: image digest, `DB_VERSION`, admin email, where the secrets copy
   lives, the backup container.

## 4. Part B: upgrade an existing deployment

Every upgrade starts the same way: bring the package to the current revision,
converge it with `./install.sh` while `.env` still names the **old** version,
then let `./discover.sh` say whether §4.1 or §4.2 applies.

### 4.0 Common preparation (read-only for the database)

1. Clean clone, current revision:
   ```bash
   cd ~/nxpi_config && git status --porcelain     # empty
   git fetch origin && git checkout main && git pull
   ls db | sort -V | tail -1
   bash tests/lib-harness.sh && bash tests/db-bundle-lint.sh
   ```
   If `git push` from the workstation is blocked: `git bundle create
   /tmp/pkg.bundle main`, copy it, `git pull --ff-only /tmp/pkg.bundle main`.
2. Converge **before** touching `DB_VERSION` or `APP_IMAGE`: `./install.sh`.
   It generates missing secrets (`redis_cache_url`,
   `postgres_privileged_url`), appends `TRUSTED_PROXY_MODE`/`METRICS_TOKEN`,
   warns about the frozen registry, re-gates the running image, leaves the
   database alone. Skipping it is the one failure that surfaces only at
   container create.
3. Opt in to the privileged pool if the target is ≥ 1.29.0:
   `POSTGRES_PRIVILEGED_URL_FILE=/run/secrets/postgres_privileged_url` in
   `.env`; `./provision-privileged-role.sh --check`.
4. `./discover.sh` → read the last block. `READY`, empty pending list, same
   digest: nothing to do. Pending without `REQUIRES-REVIEW` and one release
   step: §4.1. Anything else: §4.2. Fix every `BLOCKER` in the product first.
5. `secrets/` copied off the VM (§3.7 step 1).

### 4.1 Rolling update

1. Pin in `.env`: `APP_IMAGE=ghcr.io/negentrophi/nxpi:sha-<short>@sha256:<digest>`
   and, if a new `db/<version>` ships, `DB_VERSION=<version>`.
2. `./update.sh` — preflight → safety backup → capture the running digest →
   `pull app` → pending `migrate-*.sql` one transaction each, `grants.sql`
   re-applied → `up -d app` → 300 s gate through the ingress; a failed gate
   rolls back automatically.
3. Exit codes: **0** updated; **2** failed but the old image is serving
   again with `.rollback-image.yml` installed (the next successful update
   clears it); **1** hard failure (pre-update dump under `backups/`).
4. A *REQUIRES-REVIEW* refusal means §4.2; never set
   `ALLOW_DESTRUCTIVE_MIGRATION=1` by hand outside a window.

### 4.2 The maintenance window

```
 Steps 1–6 refuse or continue; a refusal restarts the old app (exit 2)
   1 Preflight → 2 Stop app → 3 Bundle → 4 Parity → 5 Rehearse → 6 Priv role
                                  │  one typed UPGRADE, then forward only
 Steps 7–10 go forward; the way back is the bundle
   7 Migrate → 8 Switch .env → 9 Roll → 10 Verify → exit 0
      │ exit 3 (app down)        │ exit 3      │ exit 4 (differs)
      └────────────▶ --rollback: restore the bundle, old digest pinned, exit 5
```

**T-7 days**

- [ ] `docker manifest inspect ghcr.io/negentrophi/nxpi:sha-<short>` works from the VM.
- [ ] The package revision carrying the target `db/<version>` is on `origin` (or in a bundle).
- [ ] Record the running digest: `./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'`.
- [ ] `secrets/` copied off the VM.
- [ ] Rehearse with the VM's real old digest (≈ 7 min; on Apple Silicon export
      `DOCKER_DEFAULT_PLATFORM=linux/amd64` and `NXPI_NO_SUDO=1`):
      ```bash
      tests/rehearsal.sh --old-image ghcr.io/negentrophi/nxpi_dev@sha256:<vm-digest> \
                         --new-image ghcr.io/negentrophi/nxpi:sha-<short>@sha256:<digest>
      ```
      Must end `71 passed, 0 failed`; a schema-only pass does not authorise a window.
- [ ] If PITR is enabled: `pgbackrest.sh backup full`, note the time.

**T-1 day** (§4.0 done)

1. Resolve every `DECISION` from discovery:

   | Decision | Recommended | Record it |
   |---|---|---|
   | Uncataloged uploads (404 under the new image) | per file, from `backups/discover-<ts>-uploads-uncataloged.txt` | catalog, move under `uploads/shared/`, or `--accept-uncataloged-uploads` |
   | `agent_memory` rows > 0 | expect 0 | investigate; `--ack DROP-AGENT-MEMORY` |
   | API keys without an organization | re-issue after the roll | count printed |
   | Privileged pool | opt in | `--check` prints five ok lines |

2. Dry run (changes nothing):
   ```bash
   ./upgrade-release.sh --image ghcr.io/negentrophi/nxpi:sha-<short>@sha256:<digest> --dry-run
   ```
   Expected: `Dry run complete`, the pending file count, flagged releases,
   disk verdict `ok`, `typed acks required` matching your `--ack` words.
3. Announce the window: rehearsal wall-clock × 2 plus two 300 s gates.

**The window**

```bash
./backup.sh
./upgrade-release.sh \
    --image ghcr.io/negentrophi/nxpi:sha-<short>@sha256:<digest> \
    [--target <version>] [--accept-uncataloged-uploads] [--ack DROP-AGENT-MEMORY]
```

Type `UPGRADE` once. Run under `nohup` or `tmux`; `backups/release-<id>/state.env`
records every step and `--resume <id>` continues with the same flags.

| Step | What happens | Check on screen |
|---|---|---|
| 1 Preflight | `discover.sh`, image pull + digest assert, disk need, `upgrade-db.sh --dry-run`, uploads gate | `READY`; `new image (pinned)` is the expected digest |
| 2 Stop app | Caddy answers 502; dump exact, no `lock_timeout` trips | downtime starts |
| 3 Bundle | dump, uploads tar, config tar (secrets, env, Caddyfile, compose, certs), caddy volumes, row counts, `manifest.sha256` | `config tar: … (secrets, …)`; *WITHOUT secrets* = sudo expired, copy by hand |
| 4 Parity | live catalog vs `db/<current>/schema.sql` in a scratch postgres | `only-scratch=0` |
| 5 Rehearsal | fresh dump restored to the scratch, every pending delta applied there | `takes this data to db/<target> cleanly` |
| 6 Privileged pool | `provision-privileged-role.sh` | `neogen_priv ready` |
| 7 Migrate | `upgrade-db.sh`: `DB_VERSION` bumped (`.env.bak-<ts>`), deltas one txn each, sentinels/grants/marker, allow-list and custom RBAC compared | `no unexpected row loss`, `byte-identical` |
| 8 Switch `.env` | `APP_IMAGE` := pinned new image; proxy mode, metrics token | last moment `.env` changes |
| 9 Roll | `update.sh --no-backup`, 300 s gate | `app rolled and health-gated` |
| 10 Verify | app-stopped counts vs allow-list, users/orgs, uploads bytes, digest, deep probe, privileged pool, sign-in probes, parity vs target | `Upgrade complete`, `release-<id>/summary.txt` |

### 4.3 Functional verification before users are let in

- [ ] Sign in with an existing password as admin and as member
- [ ] An existing chat opens; a new message streams
- [ ] Open an existing upload; upload a new file and open it
- [ ] Knowledge-base search returns chunks
- [ ] Roles & Permissions renders; a custom role keeps its grants and denials
- [ ] A team's member list is complete
- [ ] Plugins, an agent, a workflow, an MCP server open; a short agent turn runs
- [ ] A new audit row appears; no audit-chain error in the log
- [ ] No `POSTGRES_PRIVILEGED_URL` fallback warning in `./compose.sh logs --tail 100 app`
- [ ] `curl -s localhost/api/health/ready` = 200; `./schema-parity.sh <target>` matches
- [ ] Storage console shows the same usage as before

### 4.4 Rollback and the failure matrix

```bash
./upgrade-release.sh --rollback                                  # type ROLLBACK; exit 5
./upgrade-release.sh --rollback <id> --accept-data-loss-since    # after users were let in
```

Order: verify `manifest.sha256`; refuse after `OPENED_AT` without the flag;
stop the app; restore `.env`/`.env.app` **first**; pin the old digest in
`.rollback-image.yml`; `restore.sh --yes <dump> --uploads <tar> --skip-resync`;
re-verify counts, uploads, ingress.

| Exit | Meaning | State | Do |
|---|---|---|---|
| 0 | upgraded and verified | new image serving | §4.3, close the window |
| 1 | preflight/usage | nothing changed | fix, re-run |
| 2 | refused before any write | old app restarted | resolve; `--resume <id>` |
| 3 | migrated, roll failed | **app down** | `--resume <id>` or `--rollback <id>` |
| 4 | serving, verification differs | new image serving | investigate `backups/release-<id>/`; rollback valid until users write |
| 5 | rollback healthy | old image, pin installed | done; pin clears on the next successful `update.sh` |
| 6 | rollback failed | app stopped, `.env` reverted, old digest pinned | **do not start the app by hand**; fix the cause (usually disk), re-run `--rollback` or `restore.sh … --skip-resync --no-backup` |

If the script dies: before step 7 the trap restarts the old app and
`--resume` continues; after step 7 the app stays down until `--resume` or
`--rollback`. Never `./compose.sh up` with `.env` on the old image and the
database past a `REQUIRES-REVIEW` release.

### 4.5 Aftercare

- [ ] Copy the bundle's dump and uploads tar off the VM; keep `backups/release-<id>/`
- [ ] Re-issue or bind unscoped API keys
- [ ] Settle the accepted uncataloged uploads
- [ ] `DB_PRIVILEGED_PREFLIGHT_MODE=enforce` in `.env.app` once the pool is confirmed
- [ ] Delete `.env.bak-*` once confident
- [ ] Record decisions and timings
- [ ] Next release: `tools/sync-from-app-copy.sh <app-repo>/azure-deployment`

## 5. Data-safety guarantees: what each check proves

| Guarantee | Mechanism | Runs in | Failure looks like |
|---|---|---|---|
| The DB is really at the release it claims | `schema-parity.sh <current>`; `SCHEMA_PROBES` sentinels | discovery, step 4 | `only-scratch`, exit 2 |
| A delta will not abort on this data | 16 read-only pre-checks (`lib-checks.sh`) | discovery, dry run, step 1 | `BLOCK` lines |
| The pending set works on the real data first | `schema-parity.sh --rehearse <dump>` | step 5 | exit 2 |
| No row lost beyond the allow-list | `rowcount_snapshot`/`rowcount_compare`, app stopped | `upgrade-db.sh`, step 10 | `shrank`/`disappeared`, exit 4 |
| Custom RBAC survives | custom rows dumped and byte-compared | `upgrade-db.sh` | `differs` |
| Uploads intact | count + bytes; sha256 in rehearsal; tar in bundle | steps 3, 10 | exit 4 |
| Users/orgs unchanged | counts equal | step 10 | exit 4 |
| Credentials keep working | secrets never regenerated; incomplete-set refusal; sign-in probes | install, step 10 | refusal / 401 |
| The image is the one approved | `tag@sha256`, asserted after pull and on the container | steps 1, 10 | exit 1 / 4 |
| No half-applied delta | one transaction per file; marker row on success only | `migrate.sh` | exit 3, marker exact |
| Rollback restores the exact state | manifest; `.env` first; `--skip-resync`; re-verified | `--rollback` | exit 6 + recovery command |
| Nothing runs concurrently | one deployment lock; cron backup skips | all scripts | *lock held* |

**Never done automatically:** cataloging or deleting uploads; dropping
`agent_memory` without `--ack`; applying a `REQUIRES-REVIEW` delta outside a
window; regenerating a secret, re-seeding, or re-stamping the drizzle journal;
rolling back after users wrote data without `--accept-data-loss-since`.

**Keep off the VM:** an encrypted copy of `secrets/`, `.env`, `.env.app`; the
nightly dump and uploads tar in a versioned, immutable container; the release
bundles until the next backup cycle has proven itself.

## 6. Appendix

**Exit codes**

| Script | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| `update.sh` | updated | hard failure | rolled back healthy | | | | |
| `upgrade-release.sh` | verified | nothing changed | refused, app restarted | app down | verification differs | rollback healthy | rollback failed |
| `backup.sh` | done | uploads archive failed | | | | | |
| `restore.sh` | done | degraded | | | | | |
| `schema-parity.sh` | parity | error | | differences | | | |
| `discover.sh` | READY | BLOCKERS | | | | | |

**File map**

| Path | Holds | Committed |
|---|---|---|
| `.env`, `.env.app` | pins, URLs, keys, flags | no |
| `secrets/` | seven secret files | no, and in no backup |
| `backups/` | dumps, tars, reports, `release-<id>/`, logs | no |
| `certs/`, `*.pfx` | custom TLS | no |
| `.rollback-image.yml`, `.env.bak-<ts>` | pin after a failed update; `.env` before each bump | no |
| `db/<version>/`, scripts, `docker-compose.yml`, `Caddyfile`, `docs/`, `tests/` | the package | yes |

**Go / no-go, new deployment:** installer ended *Deployment complete* and the
password is saved; LLM key set and a chat streams; §3.6 green; `secrets/`
copied off, cron installed, one restore proven.

**Go / no-go, window:** rehearsal `71 passed, 0 failed` with the real old
digest; `./install.sh` run after the pull with `.env` on the old version;
`./discover.sh` `READY` with every `DECISION` answered; `--dry-run` shows the
expected set; fresh backup shipped; window announced with a rollback deadline.
