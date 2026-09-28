# Release upgrade runbook — db 1.15.0 → 1.41.0 and the current image, on a live VM

The single-VM stack in this package, currently at db ≤ 1.15.0 on an image
from the frozen `ghcr.io/negentrophi/nxpi_dev` registry, moves to db 1.41.0
and `ghcr.io/negentrophi/nxpi:<tag>@sha256:<digest>` in **one maintenance
window**, driven by `./upgrade-release.sh`. Zero data loss is verified at
every step, not assumed. This runbook is the operator's timeline; the README
section *Upgrading to db 1.41.0* explains what each delta does.

## 0. Why a window, and what can and cannot be undone

- Three pending deltas are **roll-forward-only**: 1.26.0 (audit chain keyed
  per organization — the old image cannot write audit rows), 1.29.0 (row-level
  security FORCED — the old image reads empty tables), 1.35.0 (constraint
  renames, `document_chunk` FK → CASCADE, orphan `agent_memory` dropped).
  `./update.sh`'s auto-rollback assumes the old image stays compatible, which
  is exactly what these break — so the app is stopped for the duration.
- Two deltas delete rows **by design**: 1.22.0 and 1.25.0 remove the
  materialised system-role defaults the catalog now supplies. Custom roles,
  deny rows and per-instance grants are untouched; the upgrade proves it by
  snapshotting the custom RBAC rows before and comparing byte-for-byte after.
- The way back is **the bundle** the window takes first (dump + uploads tar +
  secrets/env/certs + caddy volumes, sha256-manifested), restored by
  `./upgrade-release.sh --rollback`. After the stack is opened to users again,
  a rollback discards what they wrote since — the script refuses that without
  `--accept-data-loss-since`.
- The registry rename is part of this: `.env`'s `APP_IMAGE` is rewritten to the
  new, digest-pinned name at the last step before the roll.

## 1. T-7 days — prove it somewhere else first

1. **Make the image pullable from the VM.** `ghcr.io/negentrophi/nxpi` must be
   public (like `nxpi_dev`, `nxpi-hash`, `nxpi-postgres`) or the VM must be
   logged in with a `read:packages` token. Check from the VM:
   `docker manifest inspect ghcr.io/negentrophi/nxpi:<tag>`.
2. **Record the VM's current image digest** — it is the rollback image and the
   rehearsal's starting point:
   `./compose.sh ps -q app | xargs docker inspect --format '{{index .RepoDigests 0}}'`.
3. **Run the rehearsal locally** with that digest and the target image, and
   keep the log and its phase timings (they become the window's timeline, ×2):
   ```bash
   tests/rehearsal.sh --old-image ghcr.io/negentrophi/nxpi_dev@sha256:<vm-digest> \
                      --new-image ghcr.io/negentrophi/nxpi:<tag>@sha256:<digest>
   ```
   It must end `… 0 failed` — including the rollback half. A schema-only pass
   (no old image pullable) proves the SQL but not the image contract, and does
   not authorise the window.
4. **Copy `secrets/` off the VM** (it is not in any backup). Losing
   `better_auth_secret` means losing every stored integration credential.
5. If PITR (`pgbackrest.sh`) is enabled, take a full backup and note its time.

## 2. T-1 day — converge the VM, decide the decisions

On the VM, in the package directory (`git status --porcelain` must be empty;
`.env`, `.env.app`, `secrets/`, `backups/` are gitignored and survive a pull):

```bash
git pull                       # brings db/1.16.0 … db/1.41.0 and the tooling
./install.sh                   # WITH .env still at the current DB_VERSION / APP_IMAGE:
                               # generates secrets/postgres_privileged_url + redis_cache_url,
                               # appends TRUSTED_PROXY_MODE=xff and METRICS_TOKEN to .env.app,
                               # re-gates the OLD image. It never touches the database.
./discover.sh                  # read-only; must end READY (BLOCKERS are yours to fix first)
```

Resolve what `discover.sh` lists under **DECISIONS**:

| Decision | Recommended | How to record it |
|---|---|---|
| Privileged pool after 1.29.0 (background sweeps) | provision it | `POSTGRES_PRIVILEGED_URL_FILE=/run/secrets/postgres_privileged_url` in `.env`; the orchestrator runs `./provision-privileged-role.sh` |
| Uncataloged upload files (404 under the new image) | inventory, then decide per file | catalog them in the product / move under `uploads/shared/` / accept — then `--accept-uncataloged-uploads` |
| `agent_memory` rows > 0 (1.35.0 drops the table) | expect 0 | if non-zero, investigate; `--ack DROP-AGENT-MEMORY` accepts the loss |
| 1.25.0 pre-check BLOCKs (bad grants, team members outside their org, …) | fix in the product | the delta refuses them; nothing here deletes data for you |

Then the dry run — it must reach *Dry run complete* with the exact pending
list, the allow-list of row changes, every review header, and zero blockers:

```bash
./upgrade-release.sh --image ghcr.io/negentrophi/nxpi:<tag>@sha256:<digest> --dry-run
```

Announce the window. Budget: rehearsal wall-clock × 2, plus the health gates
(300 s each, twice) and your own go/no-go checks. Measured on 2026-09-28 on a
laptop (amd64 images emulated on Apple Silicon, a seed-sized database):
`upgrade-release.sh` 353 s end to end (preflight incl. the scratch rehearsal
≈ 3 min, the 27 deltas ≈ 1 min, roll + health gate ≈ 1 min), rollback 17 s.
A VM runs the images natively but migrates real data: time the pending set
against the row counts `discover.sh` prints (1.25.0 rewrites `org_resource_grant`
and 1.26.0/1.31.0 build indexes on `admin_audit_log`).

## 3. The window

```bash
cd ~/nxpi_config
./backup.sh                                  # one more, and ship it: az storage blob upload …
./upgrade-release.sh --image ghcr.io/negentrophi/nxpi:<tag>@sha256:<digest> \
    [--accept-uncataloged-uploads] [--ack DROP-AGENT-MEMORY] [--ack KNOWN-LIMIT]
# → type UPGRADE once
```

What you will see, in order: preflight (discovery, pull, dry run, gates) →
*2. Stop the app* → *3. Safety bundle* (`backups/release-<id>/`) → *4. Schema
parity* against the current release → *5. Rehearsal* on the fresh dump →
*6. Privileged pool* → *7. Migrate* (26 single-transaction deltas) → *8. Point
.env at the new image* → *9. Roll* (update.sh, health gate) → *10.
Post-verification* → *Upgrade complete* with `backups/release-<id>/summary.txt`.

**Go / no-go before you open it to users** (in addition to the script's own
verification block, which must be all ✔):

- sign in as a real admin; open a chat; open **Plugins** and
  **Organizations → Roles & Permissions** (the screens that 42703 when a
  column is missing); open the storage console
- `./compose.sh logs --tail 100 app` — no `POSTGRES_PRIVILEGED_URL` fallback
  warning when you provisioned the role; no sentinel warnings
- `./schema-parity.sh 1.41.0` — *live catalog matches* (the orchestrator ran
  it; re-run if you changed anything)
- API integrations: keys without an organization hold no org authority until
  re-bound (1.20.0) — re-issue the ones that matter

If any of that fails, roll back **now**, before `OPENED_AT` matters:

```bash
./upgrade-release.sh --rollback              # type ROLLBACK → exit 5 = back and healthy
```

## 4. Exit codes and what to do

| Exit | Meaning | Action |
|---|---|---|
| 0 | upgraded, every verification passed | close the window |
| 1 | preflight/usage failure, nothing changed | fix, re-run |
| 2 | refused at a gate before any database mutation; the OLD app was restarted | resolve the gate (uploads, parity, rehearsal), re-run |
| 3 | database migrated, app NOT rolled — **down** | fix and `--resume <id>`, or `--rollback <id>` |
| 4 | serving on the new image, a verification differs | investigate; rollback still valid |
| 5 | rollback completed healthy | you are back at the pre-upgrade state (the `.rollback-image.yml` pin stays until the next successful `./update.sh`) |
| 6 | rollback failed | `./compose.sh ps`, `./compose.sh logs app`, the restore log under `backups/`; the bundle files are intact |

## 5. Aftercare

- Keep `backups/release-<id>/` (bundle + every snapshot and parity report)
  until the next backup cycle has proven itself; `backups/pre-1.41.0-*` and
  `.env.bak-*` can go once you are confident.
- Set `DB_PRIVILEGED_PREFLIGHT_MODE=enforce` in `.env.app` once the privileged
  pool is confirmed working, so a future regression refuses to boot instead
  of warning.
- Record the decisions (privileged pool, uploads, acks) — `summary.txt` and
  the run log carry them; nothing else will say so later.
- Cron backups need nothing: `backup.sh`'s exit-code contract and filenames
  are unchanged; the retention floor keeps the newest N of each artifact kind.
