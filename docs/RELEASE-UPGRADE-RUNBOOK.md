# Release upgrade runbook — db 1.41.0 → 1.42.0 with `ghcr.io/negentrophi/nxpi:latest`

An Azure VM at database release **1.41.0** (running
`ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b98…868af9`, or the
`2a22ae7c9` document-tools build if the previous roll was done) moves to the
newest app build, **`ghcr.io/negentrophi/nxpi:latest`**, and to database
release **1.42.0**. The one pending delta is additive (one nullable column),
so this is still a rolling update driven by `./update.sh`, with seconds of
downtime. You do not need a maintenance window or `upgrade-release.sh`.

What is different from the last roll: **the package must be updated on the VM
first** (it now ships `db/1.42.0/`), and **`DB_VERSION` moves to `1.42.0` in
the same edit as `APP_IMAGE`**.

Earlier runbooks are in git history:
`git show 4df2d18:docs/RELEASE-UPGRADE-RUNBOOK.md` (1.41.0 → `latest`, image
only) and `git show 00bb498:docs/RELEASE-UPGRADE-RUNBOOK.md` (the 1.15.0 →
1.41.0 window).

## 1. Analysis: what changed

### 1.1 Deployment package (`nxpi_dev/azure-deployment` → this repo)

`tools/sync-from-app-copy.sh` against the app copy at `aa7534c7b` (`cd1397249`
changes nothing in `azure-deployment/`):

| Item | Finding | Done here |
|---|---|---|
| `db/1.42.0/` | **new** (app commit `630753ae1`, 2026-10-02): `migrate-1.42.0.sql` (migration 0043), `schema.sql` = 1.41.0 + one column line, `seed.sql` with a 44-row journal stamp, `grants.sql` identical to 1.41.0 | copied verbatim; `tests/db-bundle-lint.sh` 327/327 |
| `db/1.2.0` … `db/1.41.0` | 41 folders identical on both sides | none |
| Scripts, compose, Caddyfile, `.env*.example`, README | **no change** in the app copy since `cb44bba`; the 17 files that differ are this package's own later fixes (report only, as before) | none |
| `lib.sh` `SCHEMA_PROBES` | had no 1.42.0 sentinel | added `1.42.0 column thread_attachment.rag_skip_reason`; `tests/lib-harness.sh` 204/204 |
| `.env.example`, README | still said `DB_VERSION=1.41.0` for `latest` | now `1.42.0`; README release table has the 1.42.0 row |

**Delta proof (local, pgvector:pg17).** Loading `db/1.41.0/schema.sql` and
applying `migrate-1.42.0.sql` gives a schema byte-identical to
`db/1.42.0/schema.sql` (`pg_dump -s` diff empty apart from pg_dump's random
`\restrict` token). Running the delta a second time is a no-op
(`ADD COLUMN IF NOT EXISTS`).

### 1.2 The 1.42.0 delta

```sql
SET lock_timeout = '5s';
ALTER TABLE thread_attachment ADD COLUMN IF NOT EXISTS rag_skip_reason text;
```

- Nullable, no default, no backfill: a catalog-only change. The `ACCESS
  EXCLUSIVE` lock on `thread_attachment` is held for milliseconds, and
  `lock_timeout` bounds the wait for it.
- It is not `REQUIRES-REVIEW`, so `update.sh` applies it before rolling the
  app.
- The new image names the column in **every** attachment status write. An
  image from `630753ae1` or later on a 1.41.0 database fails those writes
  (`42703`), and uploads stay `pending`. The boot sentinel names the missing
  column. This is why `DB_VERSION` must move in the same edit as `APP_IMAGE`.
- The **old** image ignores the column, so rollback to the old digest needs
  no schema change (§6).
- Like 1.40.0–1.41.0, the delta does not stamp the app's drizzle journal
  (`AUTO_DB_MIGRATE=false`; the package marker `deploy_schema_migrations` is
  the record).

### 1.3 Application (`2a22ae7c9..cd1397249`, about 60 commits)

| Area | Change | Consequence for the VM |
|---|---|---|
| Attachments: PDF | every model now takes PDFs. Native models get them inline. Images-only models get server-rendered page images (`pdfjs-dist` + `@napi-rs/canvas` on worker threads, hard timeout). Text models get extracted text. Fail-soft. | CPU and memory per PDF go up on the app container. Watch it (§4.3) |
| Attachments: spreadsheets | large workbooks are parsed on a worker thread. `readDocument` lists sheets with row counts, reads one sheet, gives whole-file overviews and row windows | new optional knobs `XLSX_WORKER_*`, `XLSX_SCAN_TIMEOUT_MS`, `RAG_XLSX_MAX_SHEET_ROWS`, `PDF_RENDER_WORKER_FILE`. **All have defaults; `.env.app` needs no change** |
| RAG quota | an over-quota upload is refused **before** parsing and embedding. A file skipped for quota is labelled "document limit full", not "re-upload" (this is the 1.42.0 column) | users at `knowledge_max_docs_per_user` (default 100) get an honest message |
| Documents | `readDocument` reads past 50k characters, pages losslessly, and extracts once across slices. Generated PDFs embed Unicode fonts (`Ø`, `≤`, `≥`) | none |
| Agents and workflows | documents, retrieval, generated files and step budget on every agent path. Generated files carry through every workflow node, log, webhook and `workflow.failed`. No-tools scheduled agents get Documents only | none; regression-test agents and workflows (§5) |
| Chat | lists the files a reply generated; thread titles come from what the user typed; dedupes repeated attachments | none |
| Models | when an admin enables image input on a model, a **vision probe** sends one small image through the AI gateway to check it | one tiny billed model call per enable |
| Dependencies and image | `@napi-rs/canvas`, `pdfjs-dist`, `@pdf-lib/fontkit`, `sharp` added. `next.config.ts` traces the worker modules, fonts and the native `.node` binary into the standalone output. From `18816f6a2` the image build also runs `scripts/verify-standalone-pdf-worker.mjs` in the runner stage. Runtime is `node:24-alpine` | re-run that script on the pulled image before rolling (§3 step 2) |
| Compose, Caddy, secrets, env schema | no change | none |
| Seeded skills | no change since `2a22ae7c9` | the seed gap from the previous roll remains (§5) |

**PDF worker: fixed in `18816f6a2`, published as `latest` = `cd1397249`.**
`aa7534c7b` built an image whose PDF worker could not load `pdfjs-dist` or
`@napi-rs/canvas`. Every PDF job failed with `PdfRenderUnavailableError`.
- **Why nothing caught it.** The worker reported ready, health checks passed
  and CI was green, but a PDF sent to a model without native PDF input reached
  it as "could not be converted for this model".
- **The fix.**
  - The worker resolves both packages from pnpm's store.
  - pdfjs's entry file is now shipped.
  - Canvas is loaded first, together with its globals.
  - `docker/Dockerfile` runs `scripts/verify-standalone-pdf-worker.mjs` in
    the runner stage, so a broken worker now fails the image build. The
    script stays in the image for ops (§3 step 2).
- **Checked on the published image** (`sha256:53241602…`):
  `OK verify-standalone-pdf-worker: /app — extract 1 page, render 4427 B PNG`.
  Driving the worker directly gives `extract OK text=["Hello nxpi"]` and
  `render OK` (PNG).
- **One harmless line.** pdfjs still prints `Warning: Cannot load
  "@napi-rs/canvas" package` from its own directory. The worker supplies
  canvas itself, as the render shows. The line is expected.
- **Never roll `aa7534c7b` (`sha256:98abcdd2…`).**

`cd1397249` also carries one agents-list UI fix. Neither commit touches
`azure-deployment/`, migrations, `.env.example` or compose.

### 1.4 Application since the last analysis (`cd1397249..57efccedd`, 354 commits, 2026-10-03 → 2026-10-05)

`latest` moved again on 2026-10-05 (16:19 UTC). It is built from `57efccedd`,
the head of app `main`, and is also published as `sha-57efcce` and
`1.2.0-main.57efccedd`; index digest
`sha256:0394839f61f99ba05da234a54683e7885a7cd5d3b8c861a95a84bbbb4aa34d3e`.
`630753ae1` and `18816f6a2` are ancestors, so everything in §1.2 and §1.3
still holds: the image needs **db 1.42.0** and its PDF worker is the fixed one.

**What did not change.** No migration: the app journal still ends at 0043 =
`db/1.42.0`. `schema.pg.ts` gains two optional keys inside existing `json`
columns (`cron_job.config.calendar`, `cron_run_log.token_usage.totalTokens`),
which is no DDL and nothing for the package. The permission catalog,
`azure-deployment/`, `docker/Dockerfile`, compose, Caddy, secrets and the
runtime dependency list are unchanged (`tools/sync-from-app-copy.sh`: 42
bundles identical, scripts differ only by this package's own fixes). The
354 commits are the workflow canvas, the scheduler and the execution center,
plus their tests.

| Area | Change | Consequence for the VM |
|---|---|---|
| Workflow **Files node** | new node that reads files from SharePoint (as the run user, through Graph), from an organization's Azure Blob connector, or (ADR-0118) from an **allow-listed folder on the app server**. Every fetched file takes the upload path (MIME allow-list, magic bytes, storage governance, quota) and lands in `uploads` with a `thread_attachment` row | Off by default twice: the organization's **Workflow file inputs** switch (Organizations → Settings), and for the local-folder source `WORKFLOW_LOCAL_FILE_ROOTS` in `.env.app` **plus** a read-only bind mount of that folder into `app` (commented block in `docker-compose.yml`). Every org with the switch on can read everything under the roots. Fetched files consume storage quota and the uploads volume |
| Delegated Graph scope | `GRAPH_DELEGATED_FILES_SCOPE` (default `https://graph.microsoft.com/Sites.Read.All`) is the scope the Files node redeems for SharePoint. Needs admin consent on the Microsoft registration; the run user must have signed in with Microsoft | none unless the SharePoint source is used; documented in `.env.app.example` |
| Generate / Edit with AI | `POST /api/workflow/ai` drafts a workflow, `/api/workflow/<id>/ai-edit` proposes a validated change set, `/api/agent/ai` refines an agent. Blocked prompt injection and a declining model are shown as notices | billed model calls for the editor, through the normal gateway; nothing to configure |
| Scheduler | calendar schedules compiled to cron (the choice is stored beside the cron in the job config); targets picked by name; a new trigger does not fire for a tick before it existed; event triggers only see their own org's events; a trigger whose owner left the org stops; a deleted workflow retires its synced triggers; scheduled runs bypass the response cache | none; existing cron rows are read as before |
| Execution center | real token counts (summed in SQL); per-run Output tab and report downloads; cancel a queued or waiting run; **delete finished runs** (single and bulk); edit-and-rerun; AI diagnosis of a failed run | run deletion is user-driven data removal, with the backup as the only recourse. Raw-query timestamps are now read as UTC (the container already runs UTC, so no visible change here) |
| Tool node | Multiple-tools mode runs a metered LLM tool loop over a toolset; `createPdfDocument` is available to Tool nodes | more tokens per run on such workflows |
| Validators and engine | cyclic graphs refused before compile; the graph is validated on the server before publishing (ADR-0117) through one publish gate; long waits chunked so `setTimeout` never overflows; file references re-gated at every scheduled run; an over-window LLM prompt is refused instead of trimmed | a workflow that was published while invalid may fail to re-publish until it is fixed. Regression-test (§5) |
| MCP | files a stdio server writes into a workdir subfolder are captured; tool-name matches rank above description matches in discovery | none |
| Node guide, i18n | a guide for all 52 node kinds (en, hi); translated node labels | none |

**Image tag.** The runbook uses the label `latest`. Before anything is rolled,
§3 checks that `latest` was built from `630753ae1` or later (and, for working PDF conversion, `18816f6a2`
or later: `cd1397249` on 2026-10-03, `57efccedd` from 2026-10-05, see §1.4).
`update.sh` records the running **digest** as its rollback reference, so the
moving tag does not weaken rollback.

## 2. Scope and guarantees

| Data | Effect of this update | Proof |
|---|---|---|
| Database rows | none changed. One nullable column added (NULL on every existing row) | `update.sh` safety dump; marker ends at `migrate-1.42.0.sql`; `schema-parity.sh 1.42.0` |
| Uploaded files | none | untouched volume |
| Sessions, secrets, credentials | none | secrets never regenerated; sign-in check |
| Downtime | one container recreate plus the health gate | `update.sh` 300 s gate through the ingress |

Rollback does **not** restore a bundle. The old image runs on the 1.42.0
schema, so rolling back means running the previous image digest again (§6).

## 3. Before you start (T-1 hour)

Run on the VM from the package directory (`~/nxpi_config`, or
`/nxpi/nxpi_config` on `neogen-nayara`). Do the whole runbook on
**`neogen-nayara` first**, and only then on `neogen-vm`.

1. **`latest` is the new build.**
   ```bash
   docker pull ghcr.io/negentrophi/nxpi:latest       # pull only; the running container is untouched
   docker image inspect ghcr.io/negentrophi/nxpi:latest --format \
     '{{index .RepoDigests 0}}  rev={{index .Config.Labels "org.opencontainers.image.revision"}}'
   ```
   On a machine with the app checkout, confirm the revision contains the
   column change:
   ```bash
   git -C <nxpi_dev> merge-base --is-ancestor 18816f6a2 <rev> && echo OK   # implies 630753ae1
   ```
   - If it is not `OK`, CI has not published the new build yet. Stop and try
     again later.
   - Expected from 2026-10-05: `rev=57efccedd…`, index digest
     `sha256:0394839f61f99ba05da234a54683e7885a7cd5d3b8c861a95a84bbbb4aa34d3e`
     (same build as the `sha-57efcce` tag; analysed in §1.4). The previous
     build, `rev=cd1397249…` / `sha256:53241602…ace12f1e`, is also fine to
     roll; it lacks only §1.4's features.
   - If `<rev>` is later than `57efccedd`, run
     `git -C <nxpi_dev> diff --stat 57efccedd..<rev> -- azure-deployment src/lib/db/migrations src/lib/db/pg/schema.pg.ts .env.example docker next.config.ts`
     and repeat §1's checks. In particular, a newer `db/<version>` means you
     sync the package again first.
   - **Write the digest down.**

2. **The PDF worker works in the image as shipped** (read-only, a throwaway
   container). The image carries its own check:
   ```bash
   docker run --rm --entrypoint node ghcr.io/negentrophi/nxpi:latest \
     scripts/verify-standalone-pdf-worker.mjs
   # OK verify-standalone-pdf-worker: /app — extract 1 page, render <n> B PNG
   ```
   The pdfjs `Warning: Cannot load "@napi-rs/canvas"` line above the `OK` is
   expected (§1.3).
   - `Cannot find module …/verify-standalone-pdf-worker.mjs`: the build
     predates `18816f6a2`. Do not roll it.
   - Any other failure: do not roll it; report it against the app build.

3. **Record the running digest** (the rollback reference):
   ```bash
   ./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'
   ```

4. **The database is at 1.41.0 and matches it.**
   ```bash
   grep -E '^(DB_VERSION|APP_IMAGE|APP_MEM_LIMIT)=' .env    # DB_VERSION=1.41.0
   ./schema-parity.sh 1.41.0                               # live catalog matches
   ```
   If parity differs, stop. That is a different runbook
   (`docs/DEPLOYMENT-GUIDE.md` §4.2).

5. **Bring the package to this commit** (it carries `db/1.42.0/`). Off-VM
   copies first, as always.
   - `neogen-vm`: run `git status --porcelain` (it must be empty), then
     `git pull`.
   - `neogen-nayara` (no GitHub access): ship it as a git bundle, as for the
     1.41.0 upgrade, and `git pull` from the bundle.
   ```bash
   git log -1 --oneline                          # this runbook's commit
   ls db/1.42.0                                  # grants.sql migrate-1.42.0.sql schema.sql seed.sql
   ./discover.sh                                 # pending: migrate-1.42.0.sql only, no REQUIRES-REVIEW
   ```
   **Do not run `./install.sh`** for this roll. Nothing it converges changed.
   It also pulls and starts whatever `APP_IMAGE` names, without `update.sh`'s
   backup, delta ordering and rollback.

6. **Memory headroom for PDF rendering.** In `docker stats --no-stream`, note
   the app's current usage against its limit. If the VM runs the 1 GB default
   on a 16 GB machine, decide now whether to set `APP_MEM_LIMIT=4g` (the
   16 GB profile in `.env.example`) in step 4.1. `update.sh`'s `up -d app`
   applies it in the same recreate.

7. **Disk.** `df -h .` must show ≥ 3 GB free (backup plus the new image
   layers). Only remove the frozen `ghcr.io/negentrophi/nxpi_dev` images,
   never the digest from step 3.

8. **Off-VM copies.** The last nightly dump and an encrypted copy of
   `secrets/` exist off the VM (`docs/DEPLOYMENT-GUIDE.md` §3.7).

## 4. The update

Announce a short blip (≈ 1–5 min, dominated by the backup and the health gate).

### 4.1 Point `.env` at `latest` **and** 1.42.0, in one edit

```bash
cp .env .env.bak-$(date +%Y%m%d-%H%M%S)
sed -i -e 's|^APP_IMAGE=.*|APP_IMAGE=ghcr.io/negentrophi/nxpi:latest|' \
       -e 's|^DB_VERSION=.*|DB_VERSION=1.42.0|' .env
# optional, decided in §3 step 6:
#   grep -q '^APP_MEM_LIMIT=' .env && sed -i 's|^APP_MEM_LIMIT=.*|APP_MEM_LIMIT=4g|' .env || echo 'APP_MEM_LIMIT=4g' >> .env
grep -E '^(DB_VERSION|APP_IMAGE|APP_MEM_LIMIT)=' .env
# APP_IMAGE=ghcr.io/negentrophi/nxpi:latest
# DB_VERSION=1.42.0
```

`DB_VERSION` is mandatory with a moving tag: `latest` never derives a release.
If you leave it at `1.41.0`, `update.sh` finds nothing pending and rolls an
image whose attachment writes fail.

### 4.2 Roll

```bash
./update.sh 2>&1 | tee backups/update-$(date +%Y%m%d-%H%M%S).log
```

| Stage | Expect on screen |
|---|---|
| Preflight | `target image: ghcr.io/negentrophi/nxpi:latest (SQL artifacts: 1.42.0)` |
| Safety backup | a new `backups/neogen-<ts>.dump` |
| Rollback reference | `rollback image digest: …` = §3 step 3 |
| Pull | the digest from §3 step 1 |
| Schema sync | `applying migration: migrate-1.42.0.sql`, then `grants.sql` re-applied, then `schema migrated to ./db/1.42.0` |
| Roll + gate | app recreated, health gate passes through the ingress |

| Exit | Meaning | Do |
|---|---|---|
| 0 | updated and healthy | §4.3, then §5 |
| 2 | gate failed, **automatically rolled back** to the old digest, `.rollback-image.yml` installed. The column stays, which is harmless | read the log and `./compose.sh logs --tail 200 app`; see §6 |
| 1 before "Rolling update" | the pull or the delta failed. The running app and database are as they were (the delta runs in one transaction) | read the error. A `lock_timeout` failure means a long transaction held `thread_attachment`; retry `./update.sh` |
| 1 after "Rolling update" | rollback not healthy | §6 |

A `REQUIRES-REVIEW` refusal cannot happen on this path. If you see one,
`DB_VERSION` or the package is not what §3 established. Stop.

### 4.3 Confirm what is running

```bash
./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'   # the §3 step 1 digest
curl -s -o /dev/null -w '%{http_code}\n' localhost/api/health/ready                # 200
./schema-parity.sh 1.42.0                                                           # live catalog matches
./discover.sh                                                                       # nothing pending; probe reports 1.42.0
./provision-privileged-role.sh --check                                              # five ok lines
./compose.sh logs --tail 300 app | grep -Ei 'error|42703|rag_skip_reason|POSTGRES_PRIVILEGED_URL|TRUSTED_PROXY|contentNotRefreshed'
docker stats --no-stream                                                            # app well under its limit
```

`contentNotRefreshed` naming the four Builder skills is expected, unless the
gap was closed earlier. `42703` or a sentinel line naming `rag_skip_reason`
means the delta did not land. Check `DB_VERSION` and run `./discover.sh`.
Any other error line needs a reason before users are let in.

## 5. Functional verification

Regression (what already worked still works):

- [ ] Sign in with an existing password as an admin and as a member
- [ ] An existing chat opens; a new message streams to completion
- [ ] Open an existing upload; upload a new file and open it. Its status leaves `pending`
- [ ] Knowledge-base search returns chunks
- [ ] Roles & Permissions renders; a custom role keeps its grants
- [ ] An agent, a workflow and an MCP server open; a short agent turn runs
- [ ] Document tools from the last roll: a `.docx`, `.xlsx`, `.pdf` and `.pptx` are generated, download and open

New in this build:

- [ ] **PDF to a native model** (e.g. Claude/GPT-4o class): attach a PDF and ask about page 2. The answer uses the content
- [ ] **PDF to a model without native PDF input** (e.g. Kimi, DeepSeek, Mistral): same question. The PDF is converted (page images, or text), not reported as "could not be converted". Then check `docker stats --no-stream`
- [ ] **Large spreadsheet** (several sheets, thousands of rows): `readDocument` lists the sheets with row counts, reads one sheet on request, and the chat stays responsive while it parses
- [ ] **Quota message**: as a user at the document limit (or with `knowledge_max_docs_per_user` lowered on a test org), upload a file. The model says the knowledge base is full, **not** "re-upload". In the database the new row has `rag_status='skipped', rag_skip_reason='quota'`
- [ ] A generated PDF with `Ø`, `≤`, `≥` and non-Latin text renders the characters
- [ ] A reply that generated files lists them at its end; a new thread's title comes from the typed message, not the file name
- [ ] A workflow node that generates a file passes it to the next node, and the file appears in the run history
- [ ] Admin enables image input on a model: the vision probe passes (one small model call)

New since `cd1397249` (only on `57efccedd` or later, §1.4):

- [ ] **Generate with AI** on the Workflows page produces a draft that opens on the canvas; **Edit with AI** on an existing workflow previews a change, applies it as one undo step, and the run still passes
- [ ] **Scheduler calendar**: create a trigger with the calendar editor; its next run is in the future, and it does not fire for the tick that preceded its creation
- [ ] **Execution center**: a finished run shows real token counts and an Output tab; cancel a waiting scheduled run; delete one finished run (the row is gone, nothing else is)
- [ ] **Files node** (only if an org has Workflow file inputs on): a SharePoint link resolves as the run user; with `WORKFLOW_LOCAL_FILE_ROOTS` unset the local-folder source fails naming the variable, and with it set plus the bind mount a folder's files are listed. A path outside the roots is refused
- [ ] A workflow published before this build still re-publishes after an edit; if the server-side validation refuses it, the message names the node

**Close the seed gap** if this host has not done it yet (product UI, Skills →
the skill → edit). Add the matching tool to `allowed-tools`:

| Skill | Add to `allowed-tools` |
|---|---|
| Word Document Builder | `createWordDocument` |
| Spreadsheet Builder | `createSpreadsheet` |
| PDF Builder | `createPdfDocument` |
| Presentation Builder | `createPresentation` |

Do **not** delete the rows to force a re-seed. That discards admin edits and
anything that references the skill.

## 6. Rollback

The old image does not read `rag_skip_reason`, so rollback swaps the image and
leaves the schema at 1.42.0:

```bash
cp .env .env.bak-$(date +%Y%m%d-%H%M%S)
sed -i 's|^APP_IMAGE=.*|APP_IMAGE=<repo>:<old tag>@sha256:<full digest from §3 step 3>|' .env
# DB_VERSION stays 1.42.0 — do NOT set it back to 1.41.0
./update.sh
```

- Use the **digest pin**, not `latest`. `latest` would pull the new build
  again.
- Leave `DB_VERSION=1.42.0`. The alignment check only compares exact-semver
  tags, so a `sha-…@sha256:` pin runs against it. With it set back,
  `schema-parity.sh` would report the extra column.
- **Never drop the column by hand.** The marker records `migrate-1.42.0.sql`
  as applied, so a later `./update.sh` would not re-add it, and the next new
  image would fail every attachment write. If the column really must go, drop
  it **and** delete that marker row in one transaction, and record it.
- If `update.sh` exited 1 after the roll and the app is down,
  `./compose.sh up -d app` is safe: the schema is compatible with both images.
- Restore from the safety dump (`./restore.sh --yes backups/neogen-<ts>.dump`)
  only if a data problem is proven. It discards everything written since that
  dump.

## 7. Aftercare

- [ ] Record the rolled digest, its `rev=` label, the time, and the `update.sh` log in your ops log
- [ ] **Pin what you rolled** (recommended). Change `APP_IMAGE` to `ghcr.io/negentrophi/nxpi:latest@sha256:<digest>`. `latest` keeps moving, and the next `./install.sh` or `./compose.sh pull` would otherwise roll an unreviewed build outside `update.sh`
- [ ] Watch app memory and restarts for a day (`docker stats`, `./compose.sh ps`): exit 137 means OOM, so raise `APP_MEM_LIMIT`
- [ ] Seed gap closed on each host (§5), or recorded as deferred
- [ ] Delete `.env.bak-*` once confident
- [ ] Repeat on the next host: `neogen-nayara` → `neogen-vm` (NX-PI once it is at 1.41.0)
- [ ] Next build: sync first. Run `tools/sync-from-app-copy.sh <nxpi_dev>/azure-deployment` (report), then `--apply` for any new `db/<version>`, `bash tests/db-bundle-lint.sh`, add a `SCHEMA_PROBES` row in `lib.sh`, and bump `DB_VERSION` in `.env.example` and the README. A single additive release goes through `./update.sh` with `DB_VERSION` bumped in the same edit as `APP_IMAGE`. A `REQUIRES-REVIEW` or multi-release jump goes through `docs/DEPLOYMENT-GUIDE.md` §4.2
