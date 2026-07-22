#!/bin/sh
# Phase 7 — file-secret → env bridge for the env-only application.
#
# Docker Compose `secrets:` are mounted as files at /run/secrets/<name>, but the
# app reads POSTGRES_URL / POSTGRES_PRIVILEGED_URL / REDIS_URL / BETTER_AUTH_SECRET
# from process.env only (no native *_FILE support). For every `<VAR>_FILE` env var
# that points at a readable file, this shim exports `<VAR>=<file contents>` and
# then hands control to the image's real init (tini) + command — so secrets never
# appear in `docker inspect`, the shell history, or the process env of `ps`.
#
# Wired via `entrypoint: ["sh","/secrets-entrypoint.sh"]` (no +x bit needed). The
# image CMD (e.g. ["node","server.js"]) arrives as "$@".
set -eu

# Names of all *_FILE env vars (left-hand side only → never contains spaces).
file_vars=$(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*_FILE\)=.*/\1/p')

for fv in $file_vars; do
  # Resolve the file path held by $fv (the value of the variable named in $fv).
  path=$(eval "printf '%s' \"\${$fv:-}\"")
  [ -n "$path" ] && [ -e "$path" ] || continue
  # Fail FAST on an unreadable secret. Compose file-secrets are bind mounts that
  # keep host ownership/permissions; if the host file is e.g. root:root 600 and
  # this container runs non-root (app = uid 1001), `cat` fails and the app would
  # otherwise boot with an EMPTY env var — surfacing later as a baffling
  # ECONNREFUSED loop instead of the actual cause.
  if [ ! -r "$path" ]; then
    echo "secrets-entrypoint: FATAL: $fv -> $path exists but is not readable by uid $(id -u)." >&2
    echo "  Fix on the HOST: chown <container-uid> '$path' && chmod 400 '$path'  (bind-mounted secrets keep host permissions)." >&2
    exit 1
  fi
  target=${fv%_FILE}
  # Command substitution strips the trailing newline secret files often carry.
  export "$target=$(cat "$path")"
done

# Preserve the Phase-6 init (signal forwarding + zombie reaping) when present.
if [ -x /sbin/tini ]; then
  exec /sbin/tini -- "$@"
else
  exec "$@"
fi
