# Release upgrade runbook — db 1.42.0 → 1.54.0 with `ghcr.io/negentrophi/nxpi:sha-9bd2039`

An Azure VM at database release **1.42.0** (running
`ghcr.io/negentrophi/nxpi:sha-57efcce@sha256:0394839f…4aa34d3e`, or the
`sha-cb44bba` / `cd1397249` builds) moves to the newest app build,
**`ghcr.io/negentrophi/nxpi:sha-9bd2039@sha256:cbacdbe481d99c7b249ec81bf858420e27e546e36ab5e00940418c62f07969d2`**
(= `latest` on 2026-10-14), and to database release **1.54.0**.

This is **not** a rolling update. Twelve deltas are pending; four of them
(1.46.0, 1.50.0, 1.51.0, 1.54.0) rewrite or drop data that only the
pre-upgrade dump can bring back, and two (1.48.0, 1.53.0) hold write locks for
as long as their tables take. Upstream labels every one of them
`Route: ./update.sh`; this package gates the four as REQUIRES-REVIEW
(`PACKAGE_REVIEW_VERSIONS` in `lib.sh`), so `./update.sh` refuses the jump and
the move runs as one **maintenance window** driven by `./upgrade-release.sh`.

A host still **below** 1.42.0 (for example one that never completed the
1.15.0 → 1.41.0 window) takes the same window with the same target; its
pending set then also carries 1.26.0, 1.29.0 and 1.35.0, so do that runbook's
preparation as well (`git show 00bb498:docs/RELEASE-UPGRADE-RUNBOOK.md` §3–§4:
privileged pool, uploads inventory, `DROP-AGENT-MEMORY`).

Earlier runbooks are in git history:
`git show 7838a3f:docs/RELEASE-UPGRADE-RUNBOOK.md` (1.41.0 → 1.42.0 with
`latest` = `57efccedd`), `git show 4df2d18:…` (image-only roll) and
`git show 00bb498:…` (the 1.15.0 → 1.41.0 window).

## 1. Analysis: what changed

### 1.1 Deployment package (`nxpi_dev/azure-deployment` → this repo)

`tools/sync-from-app-copy.sh ../nxpi_dev/azure-deployment` (2026-10-19):

| Item | Finding | Done here |
|---|---|---|
| `db/1.43.0` … `db/1.54.0` | **new** (app migrations 0044–0055) | copied verbatim with `--apply`; `tests/db-bundle-lint.sh` 424/424 |
| `db/1.2.0` … `db/1.42.0` | 42 folders identical on both sides | none |
| Scripts, compose, Caddyfile, `.env*.example`, README | the 17 files that differ are this package's own later fixes; the app copy documents none of the new app variables | report only, as before |
| Destructive-delta gate | none of the 12 new files carries a `REQUIRES-REVIEW` marker, so `./update.sh` would have applied 1.54.0's `DROP TABLE`s unasked | `PACKAGE_REVIEW_VERSIONS` + `is_review_delta` in `lib.sh` gate 1.46.0, 1.50.0, 1.51.0, 1.54.0 without editing the shipped SQL |
| Pre-checks (`lib-checks.sh`) | nothing knew the new deltas | `p46_*`, `p48_*`, `p50_*`, `p51_*`, `p53_*`, `p54_*` checks; row-count allow-list for 1.46.0 / 1.51.0 / 1.54.0 |
| `upgrade-db.sh` | no review notes past 1.35.0 | review notes for the four gated deltas |
| `SCHEMA_PROBES` | stopped at 1.42.0 | rows for 1.43–1.45, 1.47–1.49, 1.52–1.54; 1.54.0 uses a new `no_table` kind (its only footprint is a drop); 1.46/1.50 (data only) and 1.51 (its objects die in 1.54) have none |
| Tests | — | `lib-harness` 212, `checks-harness` 49, rehearsal seed + assertions extended to 1.54.0 |

**Delta proof (local, pgvector:pg17).** `db/1.42.0/schema.sql` plus the twelve
deltas in order gives a catalog identical to `db/1.54.0/schema.sql` (the only
difference is the three `GRANT … TO neo_gen` the 1.47/1.52 deltas issue
themselves, which `grants.sql` asserts on every upgrade anyway). Every new
probe reads absent on 1.42.0 and present after; every pre-check query runs
against a 1.42.0 catalog.

### 1.2 The twelve deltas

| Release | Migration | What it does | Risk |
|---|---|---|---|
| 1.43.0 | 0044 | 8 nullable `knowledge_base` ingestion-setting columns, `marketplace_install.installed_resource_id`, two CHECKs | additive |
| 1.44.0 | 0045 | `marketplace_listing.metadata` jsonb | additive |
| 1.45.0 | 0046 | `knowledge_base_attachment` + owner backfill | additive |
| **1.46.0** | 0047 | knowledge bases shared only through the Marketplace (ADR-0120): an approved team/org/public share in an organization becomes a **published listing**; **every other direct share becomes private**, its previous audience not recorded | **gated** — ack `PRIVATIZE-KB-SHARES` when non-zero |
| 1.47.0 | 0048 | `knowledge_upload_batch` / `_item` (RLS forced), 3 `knowledge_base_document` + 4 `org_storage_governance` columns, one index | additive; short write block on `knowledge_base_document` |
| 1.48.0 | 0049 | three plain `CREATE INDEX` on `knowledge_base_document` / `ingestion_jobs`; `knowledge_base_folder` + backfill | **write lock for the build time** — sized by `p48_index_build_rows` |
| 1.49.0 | 0050 | `prompt_template_comment` | additive |
| **1.50.0** | 0051 | every `prompt_template.category` → `user` (ADR-0123) | **gated**; not undoable |
| **1.51.0** | 0052 | `org_label` (RLS forced) copied from the platform labels each org uses; `org_user_label.label_id` repointed; unresolvable assignments **deleted**; FK added | **gated**; an older image cannot save member labels (23503) |
| 1.52.0 | 0053 | `org_presentation_template` (RLS forced) | additive |
| 1.53.0 | 0054 | `cron_run_log.tool_calls`, `orchestration_run.user_id` + FK + index; the run→thread FK becomes **ON DELETE CASCADE** and is validated in the same transaction | **write lock on `orchestration_run` / `chat_thread` through validation**; **blocks** on orphan `thread_id`s (`p53_run_orphan_threads`) |
| **1.54.0** | 0055 | `DROP TABLE org_user_label, org_label` (ADR-0124 amendment: they were never enforced) | **gated**, roll-forward-only — ack `DROP-ORG-LABELS` when non-zero |

No new role, extension or `optional-*.sql`; `grants.sql` is byte-identical
across 1.42.0–1.54.0; nothing touches `thread_attachment`, the privileged
role or BYPASSRLS. Each delta starts `SET lock_timeout = '5s'` — that bounds
the wait for a lock, not how long it is held. With the app stopped (window
step 2) nothing competes for the locks.

### 1.3 Application (`57efccedd..9bd203913`, about 690 commits, 2026-10-05 → 2026-10-14)

Verified from the published image (config labels `revision=9bd2039136…`,
`version=1.2.0-main.9bd2039136`; Node 24.13.1; `CMD node server.js`; no
Dockerfile change). The app checkout is 10 commits ahead of `origin`
(bulk-import / ADR-0128) — **no published image carries them**; they are not
part of this move.

| Change | Operator consequence |
|---|---|
| **Code runner** (ADR-0125/0126): JS, Python, bash, `runTests` and `createPresentation` run only in a separate isolated service; the browser runtime is gone and bash no longer runs in the app | **this package does not ship the runner and no runner image is published**: those tools are withheld after the roll (the model is told so), org presentation-template uploads answer 503, `/api/health/deep` shows `codeRunner: not_configured` (not gating). `.env.app.example` "Code runner" |
| **Org-governed tool access** (ADR-0124): `org_user_tool_permission` allows/denies become enforced at deploy (they were display-only) | an org allow of `bash-execution` / `browser-automation` now grants the tool; the composer's toolkit toggles no longer narrow tools. Inventory in §3 |
| Knowledge folder uploads (ADR-0121): multipart into the uploads volume, own BullMQ queue `kbBatchIngestion` | runs inside `app` on the existing noeviction Redis; size the disk for large batches; `KB_*` knobs documented |
| KB OCR and multimodal extraction **on by default** | tesseract language data is downloaded from its CDN on first use into the `/tmp` tmpfs (refetched after restarts); `KNOWLEDGE_OCR_LANG_PATH` for offline VMs |
| Prompt library / sharing (ADR-0122/0123) | flags default OFF (`PROMPT_LIBRARY_V2`, `PROMPT_SHARING_V1`) |
| Built-in skill bodies | the boot seed now refreshes built-in skill bodies still byte-identical to a shipped version (log: `refreshed N unmodified built-in skill body(ies)`); edited, pinned and attested rows are left alone |
| `worker-main.js` | still a broken CJS bundle — irrelevant here (no worker service; `app` runs the background services) |

No new variable is needed to boot; `TRUSTED_PROXY_MODE` and `METRICS_TOKEN`
are unchanged. `/api/metrics` gains two KB-ingest gauges.

### 1.4 Calls made for this release (review them)

- **Ship without the code runner.** Packaging it means building and
  publishing a runner image (none exists) and merging the app repo's
  `compose.code-runner.yml` overlay; that is its own release. Tell users that
  JS/Python/bash/deck generation are unavailable on this VM until then.
- **Gate in the package, not in the SQL.** The shipped folders stay
  byte-identical to the app copy so the sync tool keeps reporting real drift.
- **1.48.0 and 1.53.0 are not gated** (nothing is lost and the old image runs
  on them); the window covers their locks, and `p53_run_orphan_threads` blocks
  the run before anything is written.

## 2. Scope and guarantees

| Data | Effect | Proof |
|---|---|---|
| Users, orgs, chats, messages, uploads, documents, chunks, grants | unchanged | window step 10: row counts against the printed allow-list; uploads bytes compared |
| Knowledge-base shares | approved ones become Marketplace listings; the rest become private | `p46_*` counts in the dry run; `PRIVATIZE-KB-SHARES` ack |
| Prompt categories | all `user` | `p50_prompt_category_rewrites` count |
| Org label assignments (not platform labels) | **dropped** | `p54_org_label_assignments` count; `DROP-ORG-LABELS` ack; allow-list `gone` |
| Secrets, sessions, credentials | unchanged | secrets never regenerated; sign-in probes |
| Downtime | stop → bundle → parity → scratch rehearsal → migrate → roll → verify | ≈ 8 min on seed data (§4 step 6); plan ≥ 2× plus the lock steps |

Rollback restores the **bundle** (dump + uploads + config) taken in the
window, never just the old image: after 1.54.0 the old image fails on the
labels routes, and 1.46.0/1.50.0 cannot be undone in place.

## 3. Prerequisites (T-7 days)

- [ ] **The image is pullable from the VM** and is the reviewed build:
  ```bash
  docker manifest inspect ghcr.io/negentrophi/nxpi:sha-9bd2039 >/dev/null && echo pullable
  docker pull ghcr.io/negentrophi/nxpi:sha-9bd2039@sha256:cbacdbe481d99c7b249ec81bf858420e27e546e36ab5e00940418c62f07969d2
  docker image inspect ghcr.io/negentrophi/nxpi:sha-9bd2039 --format '{{index .Config.Labels "org.opencontainers.image.revision"}}'
  # 9bd2039136ae23c57977c147ee836ac2b5ea59bf
  ```
  If `latest` has moved past `9bd203913` by the window, either stay on this
  pin or redo §1.3 for the new range (`git -C <nxpi_dev> diff --stat 9bd203913..<rev> -- azure-deployment src/lib/db/migrations .env.example docker`) — a new `db/<version>` means another sync first.
- [ ] **This package revision is on `origin`** (branch `feat/db-1.54-upgrade`
  merged to `main` and pushed; `neogen-nayara` gets a git bundle).
- [ ] **Tell the people affected, before the window** — the deltas change
  what they see, and the dry run (T-1) gives the exact numbers:
  - owners of directly shared knowledge bases that are not approved (they go private; re-share through the Marketplace after the window);
  - org admins using org-scoped user labels (the assignments are dropped; platform labels stay);
  - users of JS/Python/bash/deck generation (withheld until a code runner is packaged).
- [ ] **ADR-0124 inventory** — which org tool rules start enforcing (read-only,
  `./compose.sh exec -T postgres psql -U neogen_admin -d neogen`):
  ```sql
  SELECT organization_id, user_id, allowed_tools, denied_tools
    FROM org_user_tool_permission
   WHERE cardinality(allowed_tools) > 0 OR cardinality(denied_tools) > 0;
  SELECT organization_id, user_id FROM org_user_tool_permission
   WHERE allowed_tools && ARRAY['bash-execution','browser-automation'];
  ```
  Clear anything that should not start granting a tool **before** the window.
- [ ] **Record the VM's current image digest** (rollback image; rehearsal start):
  `./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'`.
- [ ] **Copy `secrets/` off the VM** (it is in no backup):
  `tar czf - secrets .env .env.app | gpg -c > nxpi-secrets-$(date +%F).tgz.gpg`, then move it off the machine.
- [ ] **Tooling rehearsal passed** on a workstation (done for this package
  revision, §4 step 6): `bash tests/rehearsal.sh --force-clean` — 1.15.0 →
  1.54.0 on the new image, including the rollback half, must end `0 failed`.
  The in-window rehearsal (step 5) repeats the migration on the VM's real dump.

## 4. VM preparation (T-1 day)

Read-only for the database.

1. **Get the package revision onto the VM** (`git status --porcelain` must be
   empty; `.env`, `.env.app`, `secrets/`, `backups/` are gitignored):
   ```bash
   cd ~/nxpi_config            # /nxpi/nxpi_config on neogen-nayara
   git fetch origin && git checkout main && git pull
   ls db | sort -V | tail -1                               # 1.54.0
   bash tests/lib-harness.sh && bash tests/db-bundle-lint.sh && bash tests/checks-harness.sh   # all "0 failed"
   ```
   `./install.sh` is **not** needed: no compose service, secret or required
   `.env.app` key changed since 1.42.0. (A host coming from below 1.41.0 runs
   it per the 00bb498 runbook.)
2. **The VM is at the release it claims.**
   ```bash
   grep -E '^(DB_VERSION|APP_IMAGE|POSTGRES_PRIVILEGED_URL_FILE)=' .env   # DB_VERSION=1.42.0
   ./schema-parity.sh 1.42.0
   ./provision-privileged-role.sh --check                                 # five ok lines
   ```
3. **Discovery**: `./discover.sh` must end `READY`, with
   `REQUIRES-REVIEW pending: migrate-1.46.0.sql migrate-1.50.0.sql migrate-1.51.0.sql migrate-1.54.0.sql`.
4. **Dry run** (pulls the image, runs every pre-check, prints the review notes
   and the row-count allow-list; changes nothing):
   ```bash
   ./upgrade-release.sh --dry-run --target 1.54.0 \
     --image ghcr.io/negentrophi/nxpi:sha-9bd2039@sha256:cbacdbe481d99c7b249ec81bf858420e27e546e36ab5e00940418c62f07969d2 \
     2>&1 | tee backups/dryrun-1.54.0-$(date +%Y%m%d-%H%M).log
   ```
   Read the pre-check block and resolve every line:

   | Line | Meaning | Do |
   |---|---|---|
   | `BLOCK p53_run_orphan_threads N` | runs pointing at deleted chat threads — 1.53.0's validation would abort | list them (the sample is printed); null their `thread_id` or delete the runs in the product **with the owner's agreement**; re-run the dry run |
   | `ACK p46_kb_shares_go_private N` | N shares will go private | confirm with the owners (§3), then pass `--ack PRIVATIZE-KB-SHARES` |
   | `ACK p54_org_label_assignments N` | N org label assignments are dropped | confirm with the org admins, then pass `--ack DROP-ORG-LABELS` |
   | `info p46_kb_shares_to_marketplace N` | N shares become published listings | none |
   | `info p50_prompt_category_rewrites N` | N prompt categories become `user` | none (the dump keeps the old values) |
   | `info p51_label_assignments_unresolvable N` | assignments whose platform label is gone | none (1.54.0 drops them anyway) |
   | `info p48_index_build_rows`, `p53_fk_validate_rows` | rows the lock-holding steps scan | budget the window (step 6) |

   Expected tail: `Dry run complete`, 12 pending files, disk verdict `ok`,
   `typed acks required` listing exactly the words you will pass.
5. **Record what will change** — paste into the ops log, run read-only:
   ```sql
   SELECT visibility, governance_status, organization_id IS NULL AS no_org, count(*)
     FROM knowledge_base WHERE visibility IN ('team','org','public') GROUP BY 1,2,3;
   SELECT category, count(*) FROM prompt_template GROUP BY 1;
   SELECT organization_id, count(*) FROM org_user_label GROUP BY 1;
   SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) FROM pg_class
    WHERE relname IN ('knowledge_base_document','ingestion_jobs','orchestration_run','chat_thread');
   ```
6. **Announce the window.** Budget = the measured rehearsal wall-clock × 2, two
   300 s health gates, your own checks, plus the 1.48.0 / 1.53.0 lock steps
   (seconds per million rows on Premium SSD). Measured locally on the seed
   database (amd64 emulated): see `RUN-TIMINGS` below.

   Measured 2026-10-19 (`tests/rehearsal.sh`, 1.15.0 → 1.54.0 on
   `sha-9bd2039`, seed-sized data, Apple Silicon emulating amd64):
   `upgrade-release.sh` 471 s end to end, rollback 17 s, whole rehearsal
   638 s, 77/77 assertions. A real VM is native amd64 but has more data:
   scale the migrate step by the row counts from step 4.

## 5. The window, step by step

```bash
cd ~/nxpi_config
./upgrade-release.sh --target 1.54.0 \
  --image ghcr.io/negentrophi/nxpi:sha-9bd2039@sha256:cbacdbe481d99c7b249ec81bf858420e27e546e36ab5e00940418c62f07969d2 \
  [--ack PRIVATIZE-KB-SHARES] [--ack DROP-ORG-LABELS] \
  2>&1 | tee backups/upgrade-1.54.0-$(date +%Y%m%d-%H%M).log
```

Pass only the acks the dry run asked for. Type `UPGRADE` at the single
prompt. Every step is recorded in `backups/release-<id>/state.env`;
`--resume <id>` continues after any interruption. **Nothing is written to the
live database before step 7.**

| Step | What happens | What to check |
|---|---|---|
| 1 Preflight | discovery, image pull + digest, disk need, dry run, review notes for 1.46/1.50/1.51/1.54, acks | `READY`; `new image (pinned)` = `sha256:cbacdbe4…`; `typed acks required` matches what you passed |
| 2 Stop app | Caddy answers 502 from here | downtime starts — note the time |
| 3 Bundle | dump, uploads tar, config tar (secrets, env, Caddyfile, compose, certs), caddy volumes, row counts, `manifest.sha256` | `config tar: … (secrets, …)`; a "WITHOUT secrets" warning means sudo expired — copy `secrets/` off by hand before continuing |
| 4 Parity vs 1.42.0 | scratch load of `db/1.42.0/schema.sql` diffed against the live catalog | `missing=0` |
| 5 Rehearsal | the fresh dump restored to a scratch postgres, every pre-check and all 12 deltas applied there, counts and catalog compared | `the pending set takes this data to db/1.54.0 cleanly` |
| 6 Privileged pool | `provision-privileged-role.sh` (idempotent) | `neogen_priv ready` |
| 7 Migrate | `upgrade-db.sh`: `DB_VERSION` → 1.54.0, deltas one transaction each, sentinels / grants / marker verified, row counts against the allow-list | `org_user_label gone`, `marketplace_listing grow`, `no unexpected row loss`, `Upgrade complete` |
| 8 Switch `.env` | `APP_IMAGE` := the digest-pinned new image | — |
| 9 Roll | `update.sh` recreates the app, 300 s health gate through Caddy | `app rolled and health-gated` |
| 10 Verify | counts vs allow-list, custom RBAC rows, uploads bytes, users, credentialed deep probe, schema parity vs `db/1.54.0`, privileged pool in the app process | every line ✔, `release-<id>/summary.txt` |

**Go / no-go before letting users in** (plus §6): sign in as a real admin;
open a chat and send a message; open a knowledge base and search it; upload a
file and open it; `./compose.sh logs --tail 300 app | grep -Ei 'error|42P01|42703|org_label|sentinel|POSTGRES_PRIVILEGED_URL|codeRunner'`
shows nothing unexplained. If any of that fails, roll back now (§7), before
users write.

## 6. Functional verification

Regression (what already worked still works):

- [ ] Sign in with an existing password as an admin and as a member
- [ ] An existing chat opens; a new message streams to completion
- [ ] Open an existing upload; upload a new file and open it; its status leaves `pending`
- [ ] Knowledge-base search returns chunks; a quota-limited upload still says the knowledge base is full
- [ ] Roles & Permissions renders; a custom role keeps its grants
- [ ] An agent, a workflow and an MCP server open; a short agent turn runs; a scheduled trigger fires
- [ ] A `.docx`, `.xlsx` and `.pdf` are generated, download and open

What the deltas changed (compare with the §4 step 5 record):

- [ ] A knowledge base that was org-shared and approved is visible to another member through its Marketplace listing; **Stop sharing** puts it back to private
- [ ] A knowledge base that was shared but not approved is now private to its owner
- [ ] Prompt templates insert text into the composer; their category reads `user`
- [ ] Organization → member labels: the tab loads with no org labels; platform labels and their tool policies still apply

New in this build:

- [ ] **Folder upload** into a knowledge base (a small folder of mixed files): the batch progresses, the folder tree shows, the files become searchable
- [ ] **OCR**: a scanned PDF or an image in a knowledge base yields searchable text (first use downloads the language data — if the VM has no egress, set `KNOWLEDGE_OCR_LANG_PATH` or `MEDIA_INGEST_ENABLED=false`)
- [ ] **Tool access**: a member's org-level tool allow/deny (ADR-0124 inventory, §3) is enforced in chat
- [ ] **Code tools withheld**: ask the model to run a short Python snippet — it says the tool is unavailable (no error page, no hang); `( . ./lib.sh; deep_probe_body ) | grep -o '"codeRunner"[^}]*}'` shows `not_configured` (the helper presents `METRICS_TOKEN` and handles domain mode)
- [ ] `./compose.sh logs app | grep 'refreshed .* built-in skill'` — record the count

## 7. Rollback and the failure matrix

```bash
./upgrade-release.sh --rollback                                  # type ROLLBACK; exit 5 = back and healthy
./upgrade-release.sh --rollback <id> --accept-data-loss-since    # after users were let in
```

It verifies the manifest, restores `.env`/`.env.app` from the bundle first
(`DB_VERSION=1.42.0`, the old `APP_IMAGE`), pins the old digest with
`.rollback-image.yml`, restores the dump and the uploads tar, starts the old
image and health-gates it, then compares counts against the bundle. Every
share, prompt category and label assignment comes back exactly as it was at
step 3 — and everything written since is lost.

| Exit | Meaning | State | Do |
|---|---|---|---|
| 0 | upgraded, every verification passed | new image on 1.54.0 | §6, close the window |
| 1 | preflight or usage failure | nothing changed, old app running | fix, re-run |
| 2 | refused at a gate before any write (parity, rehearsal, ack, a `BLOCK`) | old app restarted, database untouched | resolve; `--resume <id>` reuses the bundle |
| 3 | migrated but not rolled (a delta failed, or the health gate) | **app down**, database at an intermediate or final release | fix and `--resume <id>`, or `--rollback <id>` |
| 4 | serving on the new image, a verification differs | new image serving | investigate `backups/release-<id>/`; rollback valid until users write |
| 5 | rollback completed and healthy | old image on 1.42.0, pin installed | back; the pin clears on the next successful `./update.sh` |
| 6 | rollback failed | app stopped, `.env` reverted, old digest pinned | **do not start the app by hand**; read the restore log, fix the cause, re-run `--rollback <id>` |

A delta that fails (for example 1.53.0's validation on an orphan the
pre-check missed, or a `lock_timeout`) rolls its own transaction back; the
marker records only the deltas that completed, so `--resume <id>` continues
from the failed one after the cause is fixed.

**Never** point `.env` at the old image with the database past 1.51.0 and
start it by hand: member-label saves fail on 1.51–1.53 and the labels routes
fail on 1.54.

## 8. Aftercare

- [ ] Copy `backups/neogen-<id>.dump` and `backups/uploads-<id>.tar.gz` off the VM; keep `backups/release-<id>/` until the next backup cycle has proven itself — it is the only copy of the pre-1.46 shares, pre-1.50 categories and the dropped label assignments
- [ ] Record the rolled digest, `rev=`, the acks given, the §4 step 5 numbers and the measured window timings in the ops log
- [ ] Watch app memory and restarts for a day (`docker stats`, `./compose.sh ps`); exit 137 means OOM — raise `APP_MEM_LIMIT`
- [ ] Watch the uploads volume after the first folder uploads (`docker system df -v | grep uploads`)
- [ ] Delete `.env.bak-*` once confident
- [ ] Repeat on the next host: `neogen-nayara` → `neogen-vm`
- [ ] Open items for the next release: package the code runner (image publish + `compose.code-runner.yml` merged into this compose, `secrets/code_runner_token`, `CODE_RUNNER_URL`/`CODE_RUNNER_TOKEN_FILE` on `app`); the 10 unpushed app commits (ADR-0128 bulk import) once CI publishes them
- [ ] Next sync: `tools/sync-from-app-copy.sh <nxpi_dev>/azure-deployment`, then `--apply`; for every new delta decide **here** whether it belongs in `PACKAGE_REVIEW_VERSIONS` (upstream's `Route:` line is not the gate), add its pre-checks and its `SCHEMA_PROBES` row, bump `DB_VERSION` in `.env.example` and the README
