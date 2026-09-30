# Release upgrade runbook — db 1.41.0 on `sha-cb44bba` → `ghcr.io/negentrophi/nxpi:latest`

An Azure VM already upgraded to database release **1.41.0** (running
`ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b98…868af9`) moves to the
newest app build, published as **`ghcr.io/negentrophi/nxpi:latest`**. The
database release does **not** change, so this is a rolling image update driven
by `./update.sh`, with seconds of downtime. You do not need a maintenance
window or `upgrade-release.sh`.

The previous runbook (the db 1.15.0 → 1.41.0 window, with its measured timings
and failure matrix) is in git history: `git show 00bb498:docs/RELEASE-UPGRADE-RUNBOOK.md`.

## 1. Analysis: what the new code contains

The app repo (`github.com/negentrophi/nxpi`, local checkout `nxpi_dev`) is at
`2a22ae7c9`, seven commits past the deployed `cb44bba`:

| Commit | Change |
|---|---|
| `e48fa2e50` | `createWordDocument`, a server-executed Word (.docx) tool |
| `c7df2ce06` | `createPdfDocument`, `createSpreadsheet` (.xlsx), with each format's limits stated |
| `ccaf9d79b` | `createPresentation` (.pptx); browser-only tools withheld from browserless paths (agents, scheduled jobs, workflows); ADR-0112 |
| `7dd00bca8` | `readDocument`: an agent reads an attachment back, gated to the owner |
| `d712bd88f` | two rendering defects fixed |
| `8020c2ef0` | charts embedded in generated documents; the document tools bound to the calling user (ADR-0113) |
| `2a22ae7c9` | docs only |

**Impact on the deployment** (checked file by file over `cb44bba..2a22ae7c9`, 73 files)

| Area | Changed? | Consequence for the VM |
|---|---|---|
| Database schema / `db/<version>/` | **no**: no migration, no drizzle journal entry, newest shipped is still `db/1.41.0` | `DB_VERSION` stays `1.41.0`; `update.sh` finds nothing pending and only re-applies `grants.sql` |
| Environment (`process.env`) | no new variables | `.env.app` unchanged |
| Compose, Caddy, `azure-deployment/`, secrets | no | package files unchanged; nothing to sync with `tools/sync-from-app-copy.sh` |
| Dependencies | `marked` added (bundled in the image) | none |
| Permissions | the five document tools added to `ROLE_DEFAULT_TOOLS` for **every** role (code, not DB rows); permission profile = no shell, no network category, no filesystem | users see the new tools without any grant |
| Storage | generated files go through the same governed path as uploads: storage policy, quota, a `thread_attachment` row | files are cataloged, so they are served under the 1.36.0 uploads rule; they count toward storage quota |
| Outbound network | `fetch-image.ts` fetches chart images named in the model's Markdown through `safeFetch` (private ranges blocked, 5 MB per image, 20 MB per document, 10 s timeout) | needs outbound HTTPS; a failed fetch degrades to alt text, not an error |
| Seeded skills | the four document skills gained "prefer the server tool" guidance and the new tool in `allowed-tools` | **does not reach the VM on its own**: see below |
| Browser state | `src/app/store/migrate.ts` migrates persisted client tool selection | no operator action |

**The seed gap (the one thing that needs a decision).**
`ensureSeedSkills` runs on every boot but is insert-only by skill name
(`src/lib/db/seeds/ensure-seed-skills.ts`). On the VM the rows already exist,
so **Presentation Builder**, **Word Document Builder**, **Spreadsheet Builder**
and **PDF Builder** keep their old bodies and `allowed-tools:
["mini-javascript-execution"]`. The new tools still work in ordinary chats
(role defaults). When a user invokes one of those four skills explicitly,
though, the turn is fenced to the browser sandbox tool, and the server tool
is not offered. §5 covers the fix. The app logs the skipped names as
`contentNotRefreshed`.

**Image tag.** CI run `36756010719` (push of `2a22ae7c9`) was still in flight
when this was written. `latest` then resolved to the same index as
`sha-cb44bba`, which is what the VM already runs. The runbook uses the label
`latest`. The check in §3 confirms that `latest` has moved before anything is
rolled. `update.sh` records the running **digest** as its rollback reference,
so the moving tag does not weaken rollback.

## 2. Scope and guarantees

| Data | Effect of this update | Proof |
|---|---|---|
| Database rows | none; no delta is pending | `update.sh` safety dump; marker still ends at `migrate-1.41.0.sql`; `schema-parity.sh 1.41.0` |
| Uploaded files | none | untouched volume; the old image can serve every file the new one writes (same catalog) |
| Sessions, secrets, credentials | none | secrets never regenerated; sign-in check |
| Downtime | one container recreate plus the health gate | `update.sh` 300 s gate through the ingress |

Rollback does **not** restore a bundle. The schema is identical, so rolling
back means running the previous image digest again (§6).

## 3. Before you start (T-1 hour, read-only)

Run on the VM from the package directory (`~/nxpi_config`, or `/nxpi/nxpi_config`
on `neogen-nayara`). Do the whole runbook on **`neogen-nayara` first**
(staging, same state) and only then on `neogen-vm`.

1. **CI is green and `latest` has moved.**
   ```bash
   docker buildx imagetools inspect ghcr.io/negentrophi/nxpi:latest | sed -n 1,4p
   ```
   The `Digest:` line must **not** be `sha256:1a615b98…868af9` (that is
   `cb44bba`, already running). If it still is, CI has not published yet:
   stop here and try again later.

2. **The new image is the code you analysed.** Pull it without rolling it
   (a plain pull does not touch the running container):
   ```bash
   docker pull ghcr.io/negentrophi/nxpi:latest
   docker image inspect ghcr.io/negentrophi/nxpi:latest --format \
     '{{index .RepoDigests 0}}  rev={{index .Config.Labels "org.opencontainers.image.revision"}}'
   ```
   Expect `rev=2a22ae7c9…` (or a later `main` commit; if it is later, run
   `git -C <nxpi_dev> diff --stat 2a22ae7c9..<rev>` and repeat §1's checks for
   migrations, env vars and compose). **Write the digest down.**

3. **Record the running digest** (the rollback reference):
   ```bash
   ./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'
   # expect ghcr.io/negentrophi/nxpi@sha256:1a615b98…868af9
   ```

4. **The database is at 1.41.0 and matches it.**
   ```bash
   grep -E '^(DB_VERSION|APP_IMAGE)=' .env      # DB_VERSION=1.41.0
   ./discover.sh                                  # READY, empty pending list
   ./schema-parity.sh 1.41.0                      # live catalog matches
   ```
   If anything is pending or parity differs, stop. That is a different
   runbook (`docs/DEPLOYMENT-GUIDE.md` §4.2).

5. **Package clean and current.** `git status --porcelain` is empty, and
   `git log -1` is at `00bb498` or later. No package pull is needed for this
   update. If you do pull, run `./install.sh` **now**, while `.env` still names
   the cb44bba pin. Never run it after step 4.1 below: `install.sh` pulls and
   starts whatever `APP_IMAGE` names, without `update.sh`'s backup and
   rollback.

6. **Disk.** `df -h .` must show ≥ 3 GB free (backup plus the new image
   layers). `update.sh` warns under 2 GB. If you need space, remove only the
   frozen `ghcr.io/negentrophi/nxpi_dev` images, never the `1a615b98…` digest.

7. **Off-VM copies.** The last nightly dump and an encrypted copy of `secrets/`
   exist off the VM (`docs/DEPLOYMENT-GUIDE.md` §3.7).

## 4. The update

Announce a short blip (≈ 1–5 min, dominated by the backup and health gate).

### 4.1 Point `.env` at `latest`

```bash
cp .env .env.bak-$(date +%Y%m%d-%H%M%S)
sed -i 's|^APP_IMAGE=.*|APP_IMAGE=ghcr.io/negentrophi/nxpi:latest|' .env
grep -E '^(DB_VERSION|APP_IMAGE)=' .env
# APP_IMAGE=ghcr.io/negentrophi/nxpi:latest
# DB_VERSION=1.41.0          <- must stay; `latest` never derives a release
```

`DB_VERSION` is mandatory with a moving tag. Without it, `update.sh` cannot
find `db/<version>/` and refuses.

### 4.2 Roll

```bash
./update.sh 2>&1 | tee backups/update-$(date +%Y%m%d-%H%M%S).log
```

| Stage | Expect on screen |
|---|---|
| Preflight | `target image: ghcr.io/negentrophi/nxpi:latest (SQL artifacts: 1.41.0)` |
| Safety backup | a new `backups/neogen-<ts>.dump` |
| Rollback reference | `rollback image digest: ghcr.io/negentrophi/nxpi@sha256:1a615b98…` |
| Pull | the digest from §3 step 2 |
| Schema sync | no pending migration; `grants.sql` re-applied |
| Roll + gate | app recreated, health gate passes through the ingress |

| Exit | Meaning | Do |
|---|---|---|
| 0 | updated and healthy | §5 |
| 2 | gate failed, **automatically rolled back** to `1a615b98…`, `.rollback-image.yml` installed | read the log and `./compose.sh logs --tail 200 app`; restore `.env` from `.env.bak-*`; fix, then retry |
| 1 | hard failure before the roll, or rollback not healthy | old app normally still serving; the safety dump is under `backups/`; see §6 |

A `REQUIRES-REVIEW` refusal cannot happen on this path. If you see one,
`DB_VERSION` or the package is not what §3 established. Stop.

### 4.3 Confirm what is running

```bash
./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'   # the §3 step 2 digest
curl -s -o /dev/null -w '%{http_code}\n' localhost/api/health/ready                # 200
./schema-parity.sh 1.41.0                                                           # live catalog matches
./provision-privileged-role.sh --check                                              # five ok lines
./compose.sh logs --tail 200 app | grep -Ei 'error|POSTGRES_PRIVILEGED_URL|TRUSTED_PROXY|contentNotRefreshed'
```

`contentNotRefreshed` naming the four Builder skills is expected (§1). Any
other error line needs a reason before users are let in.

## 5. Functional verification

Regression (what already worked still works):

- [ ] Sign in with an existing password as an admin and as a member
- [ ] An existing chat opens; a new message streams to completion
- [ ] Open an existing upload; upload a new file and open it
- [ ] Knowledge-base search returns chunks
- [ ] Roles & Permissions renders; a custom role keeps its grants
- [ ] An agent, a workflow and an MCP server open; a short agent turn runs
- [ ] The browser-sandbox skills still work in a chat (e.g. a chart via `mini-javascript-execution`)

New in this build:

- [ ] Tool picker shows the document tools (`createWordDocument`, `createSpreadsheet`, `createPdfDocument`, `createPresentation`, `readDocument`) for a **member**, not only an admin
- [ ] In a chat, ask for a short Word report: a `.docx` attachment appears, downloads and opens in Word
- [ ] Same for PDF, Excel (multiple sheets) and PowerPoint
- [ ] Ask for a report with a chart: the chart is embedded. If the tool reports it as skipped, note the reason (outbound fetch). That does not justify a rollback.
- [ ] Upload a `.docx`, then ask the model to read it back (`readDocument`). Another user's attachment is refused.
- [ ] Run an agent or scheduled job that produces a document. It works without a browser (the path ADR-0112 fixes).
- [ ] The storage console shows the generated files counted under the user's usage

**Close the seed gap (decision; recommended, done in the product UI).** For
each of the four Builder skills (Skills → the skill → edit), add the matching
tool to `allowed-tools`:

| Skill | Add to `allowed-tools` |
|---|---|
| Word Document Builder | `createWordDocument` |
| Spreadsheet Builder | `createSpreadsheet` |
| PDF Builder | `createPdfDocument` |
| Presentation Builder | `createPresentation` |

Editing in the UI keeps any admin edits to the skill body. Do **not** delete
the rows to force a re-seed. That discards admin edits and anything that
references the skill.

## 6. Rollback

The schema did not change, so rollback swaps back to the old digest. Rows and
files written by the new image stay, and the old image can read them
(generated documents are ordinary cataloged attachments).

```bash
cp .env .env.bak-$(date +%Y%m%d-%H%M%S)
sed -i 's|^APP_IMAGE=.*|APP_IMAGE=ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:<full 1a615b98… digest from §3 step 3>|' .env
./update.sh
```

Use the **digest pin**, not `latest`, for the way back: `latest` would pull
the new build again. If `update.sh` itself exited 1 and the app is down,
`./compose.sh up -d app` is safe here: `.env` and the database agree
(1.41.0), unlike after a `REQUIRES-REVIEW` delta. Restore from the safety dump
(`./restore.sh --yes backups/neogen-<ts>.dump`) only if a data problem is
proven. It discards everything written since that dump.

## 7. Aftercare

- [ ] Record the rolled digest, its `rev=` label, the time, and the `update.sh` log in your ops log
- [ ] **Pin what you rolled** (recommended). Change `APP_IMAGE` to `ghcr.io/negentrophi/nxpi:latest@sha256:<digest>`. `latest` keeps moving, and the next `./install.sh` or `./compose.sh pull` would otherwise roll an unreviewed build outside `update.sh`.
- [ ] Seed gap closed on each host (§5), or recorded as deferred
- [ ] Delete `.env.bak-*` once confident
- [ ] Repeat on the next host: `neogen-nayara` → `neogen-vm` (NX-PI once it is at 1.41.0)
- [ ] Next build: re-run §1's checks over `<deployed rev>..origin/main`. If a new `db/<version>` ships (a migration under the app's `src/lib/db/migrations`), sync the package first (`tools/sync-from-app-copy.sh`). A single additive release still goes through `./update.sh` with `DB_VERSION` bumped. A `REQUIRES-REVIEW` or multi-release jump goes through `docs/DEPLOYMENT-GUIDE.md` §4.2.
