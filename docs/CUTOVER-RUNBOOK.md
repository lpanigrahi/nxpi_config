# Cutover runbook — moving a live deployment onto dedicated data disks

This is the procedure for taking an existing VM (single OS disk, one Redis) to
the hardened layout: a zonal VM with dedicated Premium SSD v2 disks for PGDATA
and WAL, a separate disk for the Redis AOF, and two Redis tiers.

**Read this before running anything.** There is production data involved.

---

## Why this is a rebuild, not an edit

Premium SSD v2 must sit in the same availability zone as the VM, and **a zone is
fixed at VM creation** — it cannot be added to an existing machine. The target
state therefore needs a new VM regardless.

That turns the riskiest step into a non-event. On a new VM, `/srv/pgdata/data`
starts empty and is filled by a *restore*; there is no `docker volume rm` on the
box holding the only copy of production data, and the old VM keeps serving until
DNS moves. **Do not flip `driver_opts` on the live volume.**

If you nevertheless need to re-pin a volume in place, know that **Docker never
re-points an existing volume** — it refuses on conflicting options. The volume
must be removed so Docker recreates it, which means the copy must be verified
first. `install.sh` now refuses with a `mismatch` verdict rather than letting you
discover this halfway through.

---

## The failure this layout is designed to make loud

If a data disk silently fails to mount, binding the **mountpoint** would hand
Postgres an empty directory. It would `initdb` a brand-new empty cluster, the
app would boot, every health check would pass, and it would serve zero rows.

So the compose file binds a **subdirectory** — `/srv/pgdata/data`, not
`/srv/pgdata`. That subdirectory exists only *on the disk*, and Docker's bind
driver will not create it, so an unmounted disk fails the container start
instead. It also sidesteps `lost+found`, which would otherwise make a freshly
formatted ext4 volume "non-empty" and block initdb on a genuinely fresh install.

Reinforce it: fstab entries by **UUID** with `nofail` (without `nofail` a
detached disk makes the VM unbootable and you lose SSH with it), and a
`RequiresMountsFor=/srv/pgdata /srv/pgwal /srv/redis` drop-in on `docker.service`.

---

## 1 — Baseline (no downtime, nothing changes)

On the **old** VM:

```bash
./backup.sh
```

Then, off the VM:

- copy the dump **and the entire `secrets/` directory** somewhere safe;
- verify the dump *at the destination*: `pg_restore --list <dump> | head`;
- record the comparison baseline you will check against in step 5:

```bash
./compose.sh exec -T postgres psql -U neogen_admin -d neogen -tAc \
  "select table_name, (xpath('/row/c/text()', query_to_xml(
     format('select count(*) c from %I.%I', table_schema, table_name),
     false, true, '')))[1]::text::int as rows
   from information_schema.tables
   where table_schema='public' order by 1"          > /tmp/rowcounts.before
./compose.sh exec -T postgres psql -U neogen_admin -d neogen -tAc \
  "select filename from public.deploy_schema_migrations order by 1" > /tmp/migrations.before
./compose.sh exec -T postgres psql -U neogen_admin -d neogen -tAc \
  "select extversion from pg_extension where extname='vector'"      > /tmp/pgvector.before
md5sum secrets/* > /tmp/secrets.before
```

Use exact counts, never `pg_stat_user_tables.n_live_tup` — that is an estimate.

**Stop point.** Nothing has changed.

---

## 2 — Provision the new VM and disks

```bash
RG=neogen-rg LOCATION=eastus VM_NAME=neogen-vm2 ZONE=1 \
SSH_SOURCE=$(curl -fsS https://ifconfig.me)/32 \
DRY_RUN=1 bash scripts/azure-provision.sh     # review the argv first
```

`scripts/azure-provision.sh` lives in the **application repository**, not in
this package. Provision by hand with `az vm create` / `az disk create` if you
do not have that checkout — the only things this runbook depends on are a
**zonal** VM and three disks attached at LUNs 10, 11 and 12 (the LUNs
`./prepare-disks.sh` looks for).

Re-run without `DRY_RUN=1` once the plan looks right. Verify flag spellings
against `az disk create --help` for your CLI version rather than trusting any
document, including this one.

---

## 3 — Prepare the disks

On the **new** VM, before anything else:

```bash
./prepare-disks.sh          # format, fstab by UUID, mount, create + own subdirs
./prepare-disks.sh --check  # verify only; exits non-zero on any gap
```

Address disks by LUN (`/dev/disk/azure/scsi1/lun10|11|12`), never `/dev/sdX` —
kernel names reorder across reboots and a swapped PGDATA/WAL disk is
unrecoverable. `prepare-disks.sh` already does this.

**Then turn the pinning on.** This package ships the three `driver_opts` blocks
in `docker-compose.yml` **commented out**, so that an ordinary deployment needs
no dedicated disks. Uncomment them now, on the new VM, before `./install.sh`:

```bash
grep -n 'driver_opts' docker-compose.yml   # the three blocks to uncomment
# then verify the file agrees with the disks you just prepared:
bash -c '. ./lib.sh; compose_volume_device docker-compose.yml postgres-data'
#   → /srv/pgdata/data   (empty output means the pinning is still commented)
```

Skipping this step is silent: `install.sh` reports `fresh`, provisions onto the
OS disk, and everything works — on the wrong disk. The `--check` gate in
`install.sh` only fires once the compose file actually declares a device.

---

## 4 — Copy secrets FIRST, then install and restore

```bash
scp -r secrets/ azureuser@<new-ip>:~/azure-deployment/     # BEFORE install.sh
```

This ordering is not a nicety. `gen_secret` is keep-if-present, so copied
secrets survive and **absent ones are regenerated** — and a fresh
`better_auth_secret` makes every stored integration credential permanently
undecryptable. The extended adoption guard now catches the case where the disk
already holds PGDATA but the volume does not exist yet, which is exactly the
rebuild scenario the old name-only check read as "fresh install".

```bash
./install.sh                       # provisions a fresh schema + throwaway admin
./restore.sh --yes backups/<dump>  # drops public/drizzle, restores the real data
```

`restore.sh` is used deliberately rather than a new "restore into empty" flag:
it is 300 lines of tested failure handling (drop-first, marker reconciliation,
grants re-apply, an EXIT trap that guarantees the app comes back).

WAL needs **no symlink surgery** on this path — `POSTGRES_INITDB_WALDIR` makes
initdb create it. Confirm the image honours it before relying on it:

```bash
docker run --rm pgvector/pgvector:pg17 \
  sh -c 'grep -i waldir /usr/local/bin/docker-entrypoint.sh'
```

---

## 5 — Verify

Data:

```bash
# …regenerate the three baseline queries into /tmp/*.after, then:
diff /tmp/rowcounts.before  /tmp/rowcounts.after
diff /tmp/migrations.before /tmp/migrations.after
diff /tmp/pgvector.before   /tmp/pgvector.after
md5sum -c /tmp/secrets.before
```

Placement — this is the part no application test can prove:

```bash
docker volume inspect neogen_postgres-data --format '{{.Options.device}} {{.Mountpoint}}'
./compose.sh exec -T postgres psql -U neogen_admin -d neogen -tAc 'show data_directory'
findmnt -no SOURCE,FSTYPE -T /srv/pgdata/data
df -h /srv/pgdata /srv/pgwal /srv/redis
```

WAL is genuinely on its own disk only if a new segment appears there:

```bash
./compose.sh exec -T postgres psql -U neogen_admin -d neogen -c 'select pg_switch_wal()'
ls -lt /srv/pgwal/wal | head
```

Tuning actually took effect:

```bash
./compose.sh exec -T postgres psql -U neogen_admin -d neogen -tAc \
  "select name, setting, unit from pg_settings
   where name in ('shared_buffers','maintenance_work_mem',
                  'max_parallel_maintenance_workers','random_page_cost')"
```

Application: `/api/health/ready` (`checks.redisCache` should read `ok`, not
`not_configured`, once `REDIS_CACHE_URL` is wired), a real super-admin login,
and one upload + download.

---

## 6 — Cut over

Prefer **domain mode** for the migration so cutover is a DNS change and
`BETTER_AUTH_URL` never moves. Copy the `caddy-data` volume to the new VM as
well, or Let's Encrypt duplicate-certificate limits can leave you without TLS
at the worst moment.

**Rollback point: everything through step 6.** The old VM never stopped serving.

## 7 — Retire

Only after several days of healthy operation: snapshot the old VM, then
deallocate it.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| `install.sh` dies with a `mismatch` verdict | The volume's device disagrees with `docker-compose.yml`. Docker will not re-point it — copy the data, verify, then remove the volume so it is recreated pinned. |
| Container start fails on a missing bind path | The disk is not mounted. Run `./prepare-disks.sh --check`. This is the designed failure — do **not** work around it by creating the directory on the root filesystem. |
| `initdb: directory exists but is not empty` | You bound the mountpoint instead of its subdirectory, and hit `lost+found`. |
| App healthy but zero data | A previous layout bound a mountpoint on an unmounted disk and initdb'd an empty cluster. Restore from backup; do not "fix forward". |
| `redis-cache` unhealthy | Non-fatal by design: `lib/cache` falls back to an in-process `MemoryCache` and keeps probing. `checks.redisCache` reports it; readiness does not gate on it. |
