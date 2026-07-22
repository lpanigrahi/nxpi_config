# NXPi — Standalone Azure VM Deployment Package

A **self-contained production deployment package** for running the NXPi
chatbot platform on a single Azure Ubuntu VM. Copy it to the VM and run one
command.

The application itself is an **immutable release artifact**: a multi-arch
Docker image published by CI to GHCR. This package only *pulls* it — it never
builds, compiles, or modifies the application.

```
ghcr.io/lpanigrahi/nxpi_dev        latest | X.Y.Z | sha-<commit>
```

## Prerequisites

- An **Azure Ubuntu VM** (22.04+), ≥2 vCPU / 8 GB, with inbound **22
  (restricted), 80, 443** open and nothing else.
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
| `backup.sh` | `pg_dump` + uploads-volume archive + retention (cron-able) |
| `restore.sh` | Restore a backup (destructive, `--yes`-gated, health-gated) |
| `compose.sh` | Pin-honoring `docker compose` wrapper — use it for all manual compose operations |
| `lib.sh` | Shared helpers sourced by the scripts above |
| `docker-compose.yml` | The full production stack (app, Caddy, Postgres+pgvector, Redis, one-shots) |
| `Caddyfile` | Reverse proxy: auto-HTTPS (domain mode), security headers, SSE-safe compression |
| `secrets-entrypoint.sh` | Bridges Docker file-secrets → env for the app container |
| `init.sql` | Enables the pgvector extension on first Postgres boot |
| `db/<version>/` | Static provisioning SQL: `schema.sql` + `grants.sql` + `seed.sql` (+ `migrate-<version>.sql` for upgrades), published per release |
| `.env.example` | Compose interpolation values (image refs, URLs, admin seed, `DB_VERSION`) |
| `.env.app.example` | App runtime env (LLM provider keys, storage, cookies) |
| `secrets/` | Generated secret files live here (never commit/share them) |
| `backups/` | Local backup target |

## Fresh installation

1. **Provision a VM** — Ubuntu 22.04+, 16 GB ,
   NSG allowing inbound **22 (restricted), 80, 443** and nothing else.

2. **Get this package onto the VM** and enter the deployment folder:

   ```bash
   ssh azureuser@<vm-ip>
   git clone https://github.com/lpanigrahi/nxpi_config.git
   cd nxpi_config/azure-deployment
   cp .env.example .env
   ```
   Update  .env file with machine IP , userid and password

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

5. **Log in** at the URL the installer printed. The super admin email defaults
   to `admin@example.com` (set `SUPER_ADMIN_EMAIL` in `.env` to your own
   address before the first install). Leave `SUPER_ADMIN_PASSWORD` unset and
   the installer **generates a strong password and prints it once** in its
   summary — capture it, then change it after first login.

### IP-only mode vs domain mode

| | IP-only (default) | Domain |
|---|---|---|
| `SITE_ADDRESS` in `.env` | *(unset)* | `your.domain.com` |
| `BETTER_AUTH_URL` in `.env` | `http://<vm-ip>` (auto-filled) | `https://your.domain.com` |
| TLS | none (plain HTTP :80) | automatic Let's Encrypt on 80/443 |
| `.env.app` | `BETTER_AUTH_COOKIE_SECURE=false` (auto-set — without it sign-in loops) | leave unset |

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
# deterministic, recommended for production (artifacts at db/1.2.0/):
APP_IMAGE=ghcr.io/lpanigrahi/nxpi_dev:1.2.0    NXPI_HASH_IMAGE=ghcr.io/lpanigrahi/nxpi-hash:1.2.0
# newest build — pin the artifact version explicitly:
APP_IMAGE=ghcr.io/lpanigrahi/nxpi_dev:latest   DB_VERSION=1.2.0
```

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

**Updates never re-initialize the database.** The schema step is the `migrate`
one-shot: it refuses to create a database, never seeds or overwrites rows, and
applies additive-only diffs — your data survives every upgrade. Both
`update.sh` and `migrate.sh` additionally refuse to run against an *empty*
database (that's `install.sh`'s job), so a mis-targeted "update" can never
half-provision one.

### Schema-only migration (no app roll)

```bash
./migrate.sh                # safety backup → additive schema sync, data preserved
```

Use it when a release ships schema changes you want applied ahead of (or
independent of) rolling the app image — `update.sh` runs this same one-shot
as part of the full upgrade.

## Backup

```bash
./backup.sh
```

Produces `backups/neogen-<timestamp>.dump` (`pg_dump -Fc`, integrity-checked)
plus `backups/uploads-<timestamp>.tar.gz` when file storage is local. Local
retention is `BACKUP_RETENTION_DAYS` (default 7, set in `.env`).

Daily cron:

```bash
crontab -e
# 0 3 * * *  cd $HOME/azure-deployment && ./backup.sh >> "backups/cron-$(date +\%F).log" 2>&1
```

(Dated cron logs are pruned by the same retention window as the dumps. If a
backup fires while another operation holds the deployment lock, it skips that
run rather than snapshotting a mid-operation database.)

**A single VM's disk is not a durability story** — ship dumps off the VM
(`az storage blob upload …`; the exact command is printed after every backup),
and keep a copy of the `secrets/` directory somewhere safe: **losing the
secrets means losing access to the data** (a bootstrap re-run adopts, it never
resets passwords).

## Restore

```bash
./restore.sh --yes                                      # newest local dump
./restore.sh --yes backups/neogen-<ts>.dump             # specific dump
./restore.sh --yes <dump> --uploads backups/uploads-<ts>.tar.gz
```

Destructive: validates both archives up front, takes a **safety backup of the
current state first** (skip with `--no-backup`; the uploads safety archive is
mandatory when `--uploads` is used), stops the app, `pg_restore --clean`s the
database back to the dump, verifies the result, **re-runs the additive schema
sync** (so a dump older than the current release cannot leave the schema
behind the code), **flushes Redis** (queued jobs from the post-dump timeline
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
APP_IMAGE=ghcr.io/lpanigrahi/nxpi_dev@sha256:…
```

then `./compose.sh up -d app`. Schema syncs are additive-only, so an older
image keeps working against a newer schema.

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
  superuser is used only by the one-shot DDL jobs.
- Security headers + SSE-safe compression at the proxy (see `Caddyfile` for
  what is deliberately *not* set there, and why).
- Memory limits and log rotation (10 MB × 3) on every service.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `install.sh` dies at image pull with auth error | The GHCR package is private: `echo $PAT \| docker login ghcr.io -u <user> --password-stdin` (PAT scope `read:packages`), re-run. |
| `install.sh` dies: "no SQL artifacts found under ./db" | The `db/<version>/` folder for your image tag isn't present. Set `DB_VERSION` in `.env` to a version that exists under `db/`, or pull the matching release of this repo. |
| Seed step: "could not compute the admin hash" | The `nxpi-hash` helper image isn't pullable. `docker pull ghcr.io/lpanigrahi/nxpi-hash:<ver>` (or set `NXPI_HASH_IMAGE`), then re-run. |
| `install.sh` dies: "existing data volume found but no secrets" | You are adopting data from a previous deployment — copy its `secrets/` directory here (new random secrets can't open old data), or `docker compose down -v` to start fresh (destroys all data). |
| App logs: `FATAL: … not readable by uid 1001` | Secret file permissions drifted. `sudo chown 1001 secrets/{postgres_url,redis_url,better_auth_secret} && sudo chmod 400` same files, then `docker compose up -d app`. |
| Sign-in loops back to the login page (IP mode) | `BETTER_AUTH_COOKIE_SECURE=false` missing from `.env.app`, or `BETTER_AUTH_URL` doesn't exactly match what the browser uses (scheme + host, no trailing slash). |
| A `migrate-<ver>.sql` fails to apply | It stops before the app is rolled (data untouched). Inspect the file under `db/<ver>/`; a genuinely destructive change needs a maintenance window + backup. Confirm `DB_VERSION` matches the target image. |
| Port 80 already in use | Another web server on the VM. Stop it, or set `CADDY_HTTP_PORT`/`CADDY_HTTPS_PORT` in `.env` and front it yourself. |
| Health gate fails after update | `update.sh` already rolled back. Diagnose with `docker compose logs app`; the pre-update backup is in `./backups`. |
| Lost the super-admin password | No automatic reset. Restore a backup, or if the data is disposable: `docker compose down -v` and `./install.sh` fresh (a new password is generated). |

## Relationship to the application repository

This package deploys the NXPi application, whose source lives in a separate,
private repository (`nxpi_dev`). **Neither the source nor git access to it is
needed to deploy.** The application is consumed only as a pre-built container
image from GHCR, and the database is provisioned from static SQL
(`db/<version>/`) that the app repo's CI generates per release and publishes
into this repo — applied on the VM with plain `psql`. The admin password is
hashed locally by the public `nxpi-hash` helper image. See
[`docs/SOURCELESS-DEPLOYMENT-PLAN.md`](docs/SOURCELESS-DEPLOYMENT-PLAN.md) for
the full design.

Keep `APP_IMAGE` and the `db/<version>/` artifacts pointing at the **same
release** — the [Version pinning](#version-pinning) section explains the
mapping.

## License

Apache License 2.0 — see [`LICENSE`](../LICENSE) at the repository root.
