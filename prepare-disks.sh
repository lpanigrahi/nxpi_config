#!/usr/bin/env bash
# =============================================================================
# prepare-disks.sh — format, mount and persist the dedicated data disks the
# compose file can bind-pin its stateful volumes to. OPT-IN: this package ships
# docker-compose.yml's driver_opts blocks COMMENTED OUT, so an ordinary
# deployment needs neither these disks nor this script. Uncomment them to use
# the hardened layout — and on a LIVE deployment read docs/CUTOVER-RUNBOOK.md
# first, because Docker refuses to re-point an existing volume.
#
# MUST run before the first `./install.sh` on a machine using the pinned layout.
# `docker-compose.yml` binds postgres-data / postgres-wal / redis-data to
# subdirectories of these mounts, and Docker's local bind driver does NOT create
# a missing device path — so without this the data tier refuses to start. That
# refusal is deliberate: binding the MOUNTPOINT instead would hand Postgres an
# empty directory on an unmounted disk and it would initdb a brand-new empty
# cluster, boot healthy, and serve zero rows.
#
# Idempotent: every step is guarded by "already done?". Run it again freely.
#
#   ./prepare-disks.sh            format/mount/persist, then verify
#   ./prepare-disks.sh --check    verify only; changes nothing, exits 1 on a gap
#
# Disks are addressed by LUN (/dev/disk/azure/scsi1/lunNN), never /dev/sdX —
# kernel names reorder across reboots and a swapped PGDATA/WAL disk is
# unrecoverable. The app repo's scripts/azure-provision.sh attaches them at the
# LUNs below; any provisioning tooling works as long as it uses these LUNs.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# mountpoint | lun | label | owner uid:gid | subdirectory the compose file binds
DISKS="
/srv/pgdata|10|nxpi-pgdata|999:999|data
/srv/pgwal|11|nxpi-pgwal|999:999|wal
/srv/redis|12|nxpi-redis|999:999|data
"

GAPS=0
note_gap() { GAPS=$((GAPS + 1)); warn "$*"; }

as_root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

for spec in $DISKS; do
  [ -n "$spec" ] || continue
  MP="${spec%%|*}"; rest="${spec#*|}"
  LUN="${rest%%|*}"; rest="${rest#*|}"
  LABEL="${rest%%|*}"; rest="${rest#*|}"
  OWNER="${rest%%|*}"; SUBDIR="${rest#*|}"
  DEV="/dev/disk/azure/scsi1/lun${LUN}"

  hdr "${MP} (lun ${LUN})"

  if [ ! -e "$DEV" ]; then
    note_gap "no disk attached at ${DEV} — attach a disk at LUN ${LUN} first (the app repo's scripts/azure-provision.sh does this)"
    continue
  fi

  # ── format ────────────────────────────────────────────────────────────────
  FSTYPE="$(as_root blkid -o value -s TYPE "$DEV" 2>/dev/null || true)"
  if [ -z "$FSTYPE" ]; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
      note_gap "${DEV} is unformatted"
    else
      log "formatting ${DEV} as ext4 (label ${LABEL})…"
      # -m 0: no root reserve. This disk holds one service's data, not the OS,
      # and 5% of a 256 GB disk is 13 GB of nothing.
      as_root mkfs.ext4 -m 0 -L "$LABEL" "$DEV"
      FSTYPE=ext4
    fi
  else
    ok "already formatted (${FSTYPE})"
  fi

  # ── fstab (by UUID, with nofail) ───────────────────────────────────────────
  UUID="$(as_root blkid -o value -s UUID "$DEV" 2>/dev/null || true)"
  if [ -n "$UUID" ]; then
    if fstab_has_mount "$(cat /etc/fstab)" "$MP"; then
      ok "fstab entry present"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
      note_gap "${MP} is not in /etc/fstab — it will not survive a reboot"
    else
      # nofail is load-bearing: without it a detached disk makes the VM
      # UNBOOTABLE, and you lose SSH along with it.
      log "adding fstab entry for ${MP}…"
      printf 'UUID=%s %s ext4 defaults,noatime,nofail 0 2\n' "$UUID" "$MP" \
        | as_root tee -a /etc/fstab >/dev/null
    fi
  fi

  # ── mount ─────────────────────────────────────────────────────────────────
  [ -d "$MP" ] || { [ "$CHECK_ONLY" -eq 1 ] || as_root mkdir -p "$MP"; }
  if ! mount_ok "$(mount_info "$MP")"; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
      note_gap "${MP} is not mounted read-write"
    else
      log "mounting ${MP}…"
      as_root mount "$MP" 2>/dev/null || as_root mount -a
    fi
  fi
  if mount_ok "$(mount_info "$MP")"; then ok "mounted rw"; else
    [ "$CHECK_ONLY" -eq 1 ] || note_gap "${MP} still not mounted after mount -a"
    continue
  fi

  # ── the bound subdirectory ────────────────────────────────────────────────
  # Created AFTER mounting, so it exists on the DISK and not on the underlying
  # root filesystem. That is precisely what makes an unmounted disk fail loudly.
  TARGET="${MP}/${SUBDIR}"
  if [ -d "$TARGET" ]; then
    ok "${TARGET} exists"
  elif [ "$CHECK_ONLY" -eq 1 ]; then
    note_gap "${TARGET} is missing — the container bind will fail"
  else
    log "creating ${TARGET}…"
    as_root mkdir -p "$TARGET"
  fi
  if [ -d "$TARGET" ] && [ "$CHECK_ONLY" -eq 0 ]; then
    # Postgres refuses to start on a data directory readable by group/other.
    as_root chown "$OWNER" "$TARGET"
    as_root chmod 700 "$TARGET"
  fi

  # Guard against the mount silently landing on the root filesystem.
  if [ "$(stat -c %d "$MP" 2>/dev/null)" = "$(stat -c %d / 2>/dev/null)" ]; then
    note_gap "${MP} is on the SAME filesystem as / — the disk is not really mounted"
  fi
done

hdr "Result"
if [ "$GAPS" -gt 0 ]; then
  die "${GAPS} problem(s) above. The data tier will not start until they are fixed."
fi
ok "all data disks formatted, mounted, persisted and owned"
