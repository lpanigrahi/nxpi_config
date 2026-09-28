#!/usr/bin/env bash
# =============================================================================
# parity-inventory-harness.sh — assertions for parity-inventory.sql's function
# rendering, on a throwaway postgres (needs docker; ~10 s).
#
#   bash tests/parity-inventory-harness.sh
#
# WHY. A database that reached a release through migrate-*.sql deltas keeps the
# SQL comments those files carry inside function bodies (pg_proc.prosrc), while
# db/<ver>/schema.sql — a pg_dump of a fresh database — was written without
# them. neogen-vm (installed at 1.2.0, migrated to 1.15.0) rendered
# admin_audit_log_immutable() with 1.9.0's comment block; the 1.15.0 scratch
# rendered it without, the body hashes differed, and upgrade-release.sh step 4
# refused with "the live database is MISSING objects". The body is the same
# code. The inventory must hash the code, not the commentary — and must still
# tell a real body change apart.
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)
WORK=$(mktemp -d); trap 'rm -rf "$WORK"; scratch_pg_stop' EXIT
cd "$WORK" || exit 1
: > .env
# shellcheck disable=SC1091
. "$PKG/lib.sh"
PASS=0; FAIL=0
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }

command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 || { echo "SKIP: docker is not available"; exit 0; }
DOCKER=docker
PG_IMAGE=${PG_IMAGE:-pgvector/pgvector:pg17}
scratch_pg_start "$PG_IMAGE"

# Three renderings of admin_audit_log_immutable()'s body:
#   lineage  — as db/1.9.0/migrate-1.9.0.sql creates it (comment block, blank lines)
#   snapshot — as db/1.15.0/schema.sql renders it (no comments)
#   changed  — the same shape with ONE literal changed (must NOT hash equal)
cat > fns.sql <<'EOF'
CREATE FUNCTION public.fn_lineage() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted';
  END IF;

  -- "Every other column unchanged" is checked structurally (whole-row jsonb
  -- minus the three FK columns), NOT by enumerating column names: a
  -- hand-mirrored column list would silently stop covering columns added
  -- later (the ADR-0031 drift class). Only the carve-out itself names
  -- columns, because the three FK columns ARE its definition.
  IF (to_jsonb(NEW) - 'actor_id') IS DISTINCT FROM (to_jsonb(OLD) - 'actor_id') THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): only FK anonymization (SET NULL) may update a row';
  END IF;

  RETURN NEW;
END;
$$;
CREATE FUNCTION public.fn_snapshot() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted';
  END IF;
  IF (to_jsonb(NEW) - 'actor_id') IS DISTINCT FROM (to_jsonb(OLD) - 'actor_id') THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): only FK anonymization (SET NULL) may update a row';
  END IF;
  RETURN NEW;
END;
$$;
CREATE FUNCTION public.fn_block_comment() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  /* a block comment
     spanning lines */
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted';
  END IF;
  IF (to_jsonb(NEW) - 'actor_id') IS DISTINCT FROM (to_jsonb(OLD) - 'actor_id') THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): only FK anonymization (SET NULL) may update a row';
  END IF;
  RETURN NEW;
END;
$$;
CREATE FUNCTION public.fn_changed() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): DELETE is not permitted';
  END IF;
  IF (to_jsonb(NEW) - 'target_user_id') IS DISTINCT FROM (to_jsonb(OLD) - 'target_user_id') THEN
    RAISE EXCEPTION 'admin_audit_log is append-only (ADR-0037): only FK anonymization (SET NULL) may update a row';
  END IF;
  RETURN NEW;
END;
$$;
EOF
PSQL_TARGET=scratch psql_admin -q < fns.sql >/dev/null || { echo "could not create the fixture functions"; exit 1; }
PSQL_TARGET=scratch psql_admin -tA < "$PKG/parity-inventory.sql" 2>/dev/null | grep '^function|public\.fn_' > inv.txt
hash_of() { awk -F'|' -v n="public.$1()" '$2==n{print $NF}' inv.txt; }

t "inventory renders every fixture function" "4" "$(grep -c . inv.txt | tr -d ' ')"
t "line comments do not change the body hash (lineage == snapshot)" "$(hash_of fn_snapshot)" "$(hash_of fn_lineage)"
t "block comments do not change the body hash"                      "$(hash_of fn_snapshot)" "$(hash_of fn_block_comment)"
t "a changed literal still changes the body hash" "different" "$([ "$(hash_of fn_snapshot)" = "$(hash_of fn_changed)" ] && echo same || echo different)"
t "the hash is a real md5 (32 hex chars)" "yes" "$(hash_of fn_lineage | grep -qE '^[0-9a-f]{32}$' && echo yes || echo no)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
