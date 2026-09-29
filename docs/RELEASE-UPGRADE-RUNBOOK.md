# Release upgrade runbook — db 1.15.0 → 1.41.0 and the current image, on neogen-vm

The VM `neogen-vm` (20.235.57.26) moves from database release 1.15.0 on the
frozen `ghcr.io/negentrophi/nxpi_dev` image to database release 1.41.0 on
`ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b98…868af9`, inside one
maintenance window driven by `./upgrade-release.sh`. Zero data loss is
verified at every step, not assumed; the way back at any point before users
are let in is `./upgrade-release.sh --rollback`, which restores the bundle
byte for byte (rehearsed locally: 71/71 assertions, upgrade 357 s, rollback
17 s). The README section *Upgrading to db 1.41.0* explains what each delta
does; this is the operator's timeline.

## 1. Scope and guarantees

| Data | Where it lives | Proof during the window |
|---|---|---|
| Every user-authored row (users, organizations, chats, attachments, knowledge bases, agents, grants, roles) | PostgreSQL 17 volume `neogen_postgres-data` (+ `neogen_postgres-wal`) | row counts snapshotted with the app stopped before and after the 27 deltas; only the printed allow-list of changes is tolerated; custom RBAC rows compared byte for byte |
| Uploaded files | Docker volume `neogen_uploads-data` | file count and bytes identical before and after; tar in the bundle |
| Sessions, passwords, integration credentials | `user`/`session`/`account` + `secrets/better_auth_secret` | secrets never regenerated; sign-in smoke test after the roll |
| TLS state, configuration | `neogen_caddy-data`, `.env`, `.env.app`, `secrets/` | archived in the bundle with a sha256 manifest |

**What changes by design** (functionality, not data): three deltas are
roll-forward-only, two delete materialised system-role defaults the catalog
now supplies, API keys without an organization lose org authority, and upload
files with no catalog row answer 404 on the new image. Each is in §2 with its
mitigation; §6 is the functional checklist that proves nothing else changed.

## 2. Analysis

The risk sits in five places: three roll-forward-only deltas, one 2,250-line
delta that fails closed on dirty data, the registry rename, a boot refusal
without `TRUSTED_PROXY_MODE`, and an upload-serving rule that changes.

**Current state** (`./discover.sh` confirms it on the VM)

| Item | Value |
|---|---|
| Deployment | installed from this package (compose project `neogen`, unpinned Docker volumes on the OS disk) |
| Database | PostgreSQL 17 + pgvector, marker `public.deploy_schema_migrations` at `migrate-1.15.0.sql` |
| App image | `ghcr.io/negentrophi/nxpi_dev` (frozen: the repo moved to `negentrophi/nxpi`, CI publishes `ghcr.io/negentrophi/nxpi`) |
| Target | db 1.41.0 = journaled migration 0042; image `nxpi:sha-cb44bba`, built from `cb44bbad6` on 2026-09-28 |
| Vector store | pgvector inside PostgreSQL (no LanceDB, nothing to re-index) |
| Not in any backup today | `secrets/` (`better_auth_secret` also encrypts stored integration credentials), redis queue, caddy TLS state |

**The 27 deltas by data impact**

| Releases | Path | Data impact | Handled by |
|---|---|---|---|
| 1.16.0–1.21.0, 1.23.0, 1.24.0, 1.27.0, 1.28.0, 1.30.0–1.34.0, 1.36.0–1.41.0 | rolling (additive) | none; 1.27.0/1.40.1 upsert reference rows; 1.39.0/1.41.0 backfill columns | allow-list of expected growth |
| 1.22.0 | rolling, data-moving | deletes the system viewer role's and read-only pack's `audit:view` rows, inserts it on security-admin | open shrink in the allow-list; custom rows byte-compared |
| 1.25.0 | rolling, 2,250 lines | `org_role.key` NOT NULL + backfill; `org_resource_grant` rebuilt partitioned (copied, checksummed, swapped); deletes materialised catalog defaults from SYSTEM roles/packs; **fails closed** on duplicate pending privilege requests, team members outside their org, malformed role keys, grants with a bad type / non-UUID / dangling resource, unknown permission slugs | 16 read-only pre-checks in discovery and dry run; the scratch rehearsal on the real dump |
| 1.26.0 | REQUIRES-REVIEW | `audit_chain_head.chain_key` NOT NULL: the old image cannot write audit rows afterwards | window; rollback = bundle |
| 1.29.0 | REQUIRES-REVIEW | row-level security ENABLED + FORCED on 26 tables; background cross-tenant sweeps need a BYPASSRLS role | `neogen_priv` provisioned |
| 1.35.0 | REQUIRES-REVIEW | 47 constraint renames; `document_chunk` org FK → ON DELETE CASCADE; drops the orphan `agent_memory` table and the IVFFlat index | `agent_memory` must have 0 rows (else a typed ack); parity check |

**Behaviour changes to expect after the roll**

| Change | Effect | What to do |
|---|---|---|
| `TRUSTED_PROXY_MODE` required (image) | app refuses to boot without it | `install.sh` appends `xff` before the window |
| Uploads without a `thread_attachment` row (1.36.0 + image) | 404 for old uncataloged files, except `uploads/shared/` | `discover.sh` lists them; decide before the window |
| API keys without an organization (1.20.0) | hold no org authority until re-bound | count reported; re-issue the keys that matter |
| Deleting an organization (1.35.0) | deletes its RAG chunks instead of re-homing them | operational awareness |
| Privileged pool (1.29.0) | expired-grant sweep and knowledge GC need `neogen_priv` | provisioned by the orchestrator |
| `METRICS_TOKEN` (image) | `/api/health/deep` answers 403 without it | generated by `install.sh` |

**Risks and mitigations**

| Risk | Mitigation |
|---|---|
| A delta aborts mid-window on live data | every fail-closed predicate is mirrored as a read-only check a week early; the pending set is rehearsed on a scratch copy of the fresh dump before the live DB is touched |
| The old image cannot be rolled back onto the new schema | rollback restores the bundle (dump + uploads + config), never the old image alone |
| Rows deleted by mistake | only the printed allow-list is tolerated; custom RBAC rows must be byte-identical |
| Wrong version claimed | `schema-parity.sh` proves the live catalog equals `db/1.15.0/schema.sql` before and `db/1.41.0/schema.sql` after |
| Out of disk / memory | preflight budgets 3×DB + 2×uploads + image + slack; the scratch postgres goes to disk when the DB exceeds a quarter of available memory |
| Operator error | one typed `UPGRADE`; typed acks cannot be skipped; every step recorded for `--resume` |
| Feature loss | the VM runs the CI build of `nxpi_dev`, not a local build, so no uncommitted feature exists on it to lose — discovery's digest confirms it |

## 3. Prerequisites (T-7 days)

- [ ] **The new image is pullable from the VM.** `ghcr.io/negentrophi/nxpi` is not anonymously pullable today. Make the package public, or `docker login ghcr.io` on the VM with a `read:packages` token. Check: `docker manifest inspect ghcr.io/negentrophi/nxpi:sha-cb44bba`.
- [ ] **The package revision is on `origin`.** Merge branch `worktree-db-1.41-upgrade` into `main` and push (or push the branch and check it out on the VM); the VM clones `github.com/lpanigrahi/nxpi_config`.
- [ ] **Record the VM's current image digest** (the rollback image and the rehearsal's starting point): `./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'`.
- [ ] **Copy `secrets/` off the VM** — it is in no backup: `tar czf - secrets .env .env.app | gpg -c > nxpi-secrets-$(date +%F).tgz.gpg`, then move it off the machine.
- [ ] **Rehearse with the VM's real digest** on a workstation with Docker (≈ 7 min; amd64 images run emulated on Apple Silicon):
  ```bash
  tests/rehearsal.sh --old-image ghcr.io/negentrophi/nxpi_dev@sha256:<vm-digest> \
                     --new-image ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b9827059b5dd8d3dc01780cb4385da6db9675590351708d3137dd868af9
  ```
  It must end `71 passed, 0 failed` including the rollback half; a schema-only pass does not authorise the window.
- [ ] If PITR (`pgbackrest.sh`) is enabled, take a full backup and note its time; confirm yesterday's cron dump and uploads tar exist under `backups/`.

## 4. VM preparation (T-1 day)

Read-only for the database; the order matters because `install.sh` must
converge the package **before** `DB_VERSION` moves.

1. **Get the package revision onto the VM** (`git status --porcelain` must be empty; `.env`, `.env.app`, `secrets/`, `backups/` are gitignored and survive a pull):
   ```bash
   ssh neogen-vm && cd ~/nxpi_config
   git fetch origin && git checkout main && git pull
   ls db | sort -V | tail -1                                  # 1.41.0
   bash tests/lib-harness.sh && bash tests/db-bundle-lint.sh  # both "0 failed"
   ```
2. **Converge secrets and `.env.app`** with `.env` still at the current `DB_VERSION`/`APP_IMAGE`:
   ```bash
   ./install.sh
   ```
   Generates `secrets/postgres_privileged_url` and `secrets/redis_cache_url` if missing, appends `TRUSTED_PROXY_MODE=xff` and a `METRICS_TOKEN` to `.env.app`, warns that `APP_IMAGE` names the frozen registry, re-gates the OLD image, leaves the database untouched.
3. **Opt in to the privileged pool** — add to `.env`:
   ```
   POSTGRES_PRIVILEGED_URL_FILE=/run/secrets/postgres_privileged_url
   ```
   `./provision-privileged-role.sh --check` must then print five ok lines (the orchestrator provisions the role in its step 6; running it now is idempotent).
4. **Discovery** (read-only; report under `backups/discover-<ts>.txt`): `./discover.sh` must end `READY`. Resolve every **DECISION**:

   | Decision | Recommended | How to record it |
   |---|---|---|
   | Uncataloged upload files (404 under the new image) | inventory, decide per file | list in `…-uploads-uncataloged.txt`; catalog them in the product, move under `uploads/shared/`, or accept → `--accept-uncataloged-uploads` |
   | `agent_memory` rows > 0 (1.35.0 drops the table) | expect 0 | investigate; `--ack DROP-AGENT-MEMORY` accepts the loss |
   | Any `BLOCK` line in the pre-checks | fix in the product | the 1.25.0 delta refuses them; nothing here deletes rows for you |
   | API keys without an organization | re-issue the ones integrations rely on | after the roll |

5. **Dry run** (read-only; pulls the image, runs every pre-check, shows every review header):
   ```bash
   ./upgrade-release.sh --image ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b9827059b5dd8d3dc01780cb4385da6db9675590351708d3137dd868af9 --dry-run
   ```
   Expected: `Dry run complete`, 27 pending files, `REQUIRES-REVIEW pending migrate-1.26.0.sql migrate-1.29.0.sql migrate-1.35.0.sql`, disk verdict `ok`, the allow-list of row changes, `typed acks required` empty or matching your `--ack` words.
6. **Announce the window.** Budget: the rehearsal wall-clock × 2, plus two 300 s health gates and your own checks. Measured locally: orchestrator 357 s, rollback 17 s on a seed-sized database; a real database migrates longer (1.25.0 rewrites `org_resource_grant`; 1.26.0/1.31.0 build indexes on `admin_audit_log`).

## 5. The window, step by step

```bash
ssh neogen-vm && cd ~/nxpi_config
./backup.sh && az storage blob upload ...     # one more dump, shipped off the VM
./upgrade-release.sh \
    --image ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b9827059b5dd8d3dc01780cb4385da6db9675590351708d3137dd868af9 \
    [--accept-uncataloged-uploads] [--ack DROP-AGENT-MEMORY]
```

Type `UPGRADE` at the single prompt. Every step is recorded in
`backups/release-<id>/state.env`; `--resume <id>` continues after any
interruption. **Nothing is written to the live database before step 7; steps
1–6 can only refuse and restart the old app.**

| Step | What happens | What to check |
|---|---|---|
| 1 Preflight | discovery, image pull + digest, disk need, dry run with every pre-check, allow-list, the three review headers, uploads gate | `READY`; `typed acks required` matches what you passed; `new image (pinned)` is the expected digest |
| 2 Stop app | Caddy answers 502 from here | note the time — downtime starts |
| 3 Bundle | `backups/neogen-<id>.dump`, `uploads-<id>.tar.gz`, `release-<id>/config-<id>.tar.gz` (secrets, env, Caddyfile, compose, certs), caddy volumes, row counts, `manifest.sha256` | `config tar: … (secrets, …)`; a "WITHOUT secrets" warning means sudo expired — copy `secrets/` off by hand before continuing |
| 4 Parity vs 1.15.0 | scratch load of `db/1.15.0/schema.sql` diffed against the live catalog | `missing=0` (else exit 2, old app restarted). `differs` lines (a legacy lineage: RLS already forced on `assistant`, the NOT VALID dims CHECK, `skill_*`/`tool_*` constraint names) and `only-live` lines are what the deltas reconcile; step 5 proves it |
| 5 Rehearsal | the fresh dump restored to a scratch postgres, every pre-check and all 27 deltas applied there, counts and catalog compared | `the pending set takes this data to db/1.41.0 cleanly` |
| 6 Privileged pool | `provision-privileged-role.sh` | `neogen_priv ready: BYPASSRLS, member of neo_gen, password matches` |
| 7 Migrate | `upgrade-db.sh`: `DB_VERSION` bumped (`.env.bak-<ts>`), deltas applied one transaction each, sentinels/grants/marker verified, row-count allow-list and custom RBAC rows compared | `no unexpected row loss`, `… byte-identical`, `Upgrade complete` |
| 8 Switch `.env` | `APP_IMAGE` := the digest-pinned new image; `TRUSTED_PROXY_MODE`, `METRICS_TOKEN` present | — |
| 9 Roll | `update.sh` recreates the app, 300 s health gate through Caddy | `app rolled and health-gated` |
| 10 Verify | app-stopped before/after counts vs the allow-list (hard gate), users/orgs/uploads unchanged, running digest = pin, credentialed deep probe, privileged pool in the app process, sign-in probes, parity vs `db/1.41.0` | every line ✔, `Upgrade complete`, `release-<id>/summary.txt` |

**Go / no-go before letting users in** (plus §6): sign in as a real admin;
open a chat and send a message; open **Plugins** and **Organizations → Roles &
Permissions**; upload a file and open it; run a knowledge-base search;
`./compose.sh logs --tail 100 app` shows no sentinel or
`POSTGRES_PRIVILEGED_URL` warnings. If any of that fails, roll back now,
before `OPENED_AT` matters.

## 6. Functional verification (no functionality lost)

Do it as a real admin and as an ordinary member. Each item names what would break it.

- [ ] Sign in as an admin and as a member with an existing password (auth tables, `TRUSTED_PROXY_MODE`, cookies)
- [ ] An existing chat opens with its history; a new message streams to completion (SSE keepalive through Caddy)
- [ ] Open an existing cataloged upload from a chat; upload a new file and open it (`thread_attachment`, uploads volume)
- [ ] Open a knowledge base and run a search that returns its chunks (`document_chunk`, pgvector)
- [ ] Organizations → Roles & Permissions renders with the catalog; a custom role keeps its grants and denials; toggle one permission and revert it (`permission_catalog` ≥ 78, custom rows preserved)
- [ ] A team's member list shows its members (1.25.0 `team_member` backfill)
- [ ] Plugins tab: list and detail render (`plugin_bundle.origin`, `deleted_at`, `source_id`)
- [ ] Open an agent, a workflow and an MCP server; run a short agent turn (visibility CHECKs, `agent.governance_disabled_by`)
- [ ] `cron_run_log` gains a `success` row after the next schedule; no job holds two `running` rows
- [ ] An integration relying on an API key still works; unscoped keys (count printed) re-issued or bound (1.20.0)
- [ ] An admin action appears as a new audit row; the app log shows no audit-chain errors (1.26.0)
- [ ] No `POSTGRES_PRIVILEGED_URL` fallback warning in the app log; `./provision-privileged-role.sh --check` prints five ok lines (1.29.0)
- [ ] `/api/health/ready` answers 200; `./schema-parity.sh 1.41.0` reports `live catalog matches`
- [ ] The storage console shows the same usage as before

Anything that fails here is a reason to roll back while the bundle is still
the truth; after users write new data, rollback costs those writes.

## 7. Rollback and the failure matrix

Rollback restores the bundle, never just the old image: 1.26.0, 1.29.0 and
1.35.0 make the schema unservable by the old image.

```bash
./upgrade-release.sh --rollback                                  # type ROLLBACK; exit 5 = back and healthy
./upgrade-release.sh --rollback <id> --accept-data-loss-since    # after users were let in
```

In order: verifies `manifest.sha256`; refuses after `OPENED_AT` without the
flag; stops the app; restores `.env` and `.env.app` from the bundle **first**
(`DB_VERSION` and `APP_IMAGE` back); installs `.rollback-image.yml` pinning
the old digest (every compose call honours it); runs `restore.sh --yes <dump>
--uploads <tar> --skip-resync` (drops the schema, restores exactly the dump,
1.15.0 grants, flushes both redis tiers, re-extracts the uploads, starts the
pinned old image, health-gates); compares row counts (no table may shrink),
uploads and the ingress against the bundle. `neogen_priv` and its secret may
remain; they are inert without the `.env` flag.

| Exit | Meaning | State of the VM | What to do |
|---|---|---|---|
| 0 | upgraded, every verification passed | new image serving 1.41.0 | run §6, close the window |
| 1 | preflight or usage failure | nothing changed, old app running | fix, re-run |
| 2 | refused at a gate before any write (parity, rehearsal, uploads, an ack, a pre-check) | old app restarted, database untouched | resolve the message; `--resume <id>` reuses the bundle |
| 3 | migrated but not rolled: a delta failed, or the roll's health gate failed | **app down**, database at an intermediate or final release | fix and `--resume <id>`, or `--rollback <id>` |
| 4 | serving on the new image, a verification differs | new image serving | investigate under `backups/release-<id>/`; rollback still valid until users write |
| 5 | rollback completed and healthy | old image serving 1.15.0, pin installed | back; the pin clears on the next successful `./update.sh` |
| 6 | rollback failed | app stopped, `.env` reverted, old digest pinned, database possibly still at 1.41.0 | **do not start the app by hand** (the old image would boot against a forced-RLS schema); read the restore log under `backups/`, fix the cause (disk full for the safety backup is the usual one), re-run `--rollback <id>` or `./restore.sh --yes <dump> --uploads <tar> --skip-resync --no-backup` |

**If the script itself dies** (SSH drop, Ctrl-C): `state.env` says which step
was reached. Before step 7 the trap restarts the old app and `--resume <id>`
continues. After step 7 started, the app stays down until `--resume` or
`--rollback`; never run `./compose.sh up` with `.env` pointing at the old image
and the database past 1.26.0.

## 8. Aftercare

- [ ] Copy `backups/neogen-<id>.dump` and `backups/uploads-<id>.tar.gz` off the VM (they sit under the cron retention window) and keep `backups/release-<id>/` until the next backup cycle has proven itself
- [ ] Re-issue or bind the API keys reported as unscoped
- [ ] Settle the uncataloged uploads you accepted: catalog them, move them under `uploads/shared/`, or record that they stay unreachable
- [ ] Set `DB_PRIVILEGED_PREFLIGHT_MODE=enforce` in `.env.app` once the privileged pool is confirmed working
- [ ] Delete `.env.bak-*` once confident; the daily `backup.sh` cron needs no change
- [ ] Record the decisions (privileged pool, uploads, acks) and the measured timings in `summary.txt` or your ops log
- [ ] Next release: `tools/sync-from-app-copy.sh <app-repo>/azure-deployment` shows what is new; a single additive release goes through `./update.sh`, a multi-release jump through this runbook again
