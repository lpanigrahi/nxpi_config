# Secrets (Docker Compose file-based `secrets:`)

`../docker-compose.yml` reads these files as Docker secrets (mounted at
`/run/secrets/<name>` inside the containers). **`../install.sh` generates all
of them automatically** — you only need this README if you manage them by
hand. Real files here must never be committed or shared.

## Files

| Secret file | Consumed by | Notes |
|---|---|---|
| `postgres_password` | `postgres` (`POSTGRES_PASSWORD_FILE`) | The Postgres superuser (`neogen_admin`) password. |
| `redis_password` | `redis` (`requirepass` via config) | The Redis AUTH password. |
| `postgres_url` | `app` (via the entrypoint shim) | The APP connection string — the least-privilege `neo_gen` DML-only role. Its password is free-standing: `install.sh` sets it on the role (`ALTER ROLE neo_gen PASSWORD …`) from THIS URL during provisioning. |
| `redis_url` | `app` (via the shim) | Full Redis URL; its password **must equal** `redis_password`. |
| `better_auth_secret` | `app` (via the shim) | Better Auth session signing secret. |

## Manual bootstrap (install.sh does all of this)

```bash
cd secrets
openssl rand -hex 32 | tr -d '\n'          > better_auth_secret
openssl rand -hex 24 | tr -d '\n'          > postgres_password
openssl rand -hex 24 | tr -d '\n'          > redis_password
# keep the URLs in sync with the passwords above:
printf 'postgres://neo_gen:%s@postgres:5432/neogen' "$(openssl rand -hex 24)"        > postgres_url
printf 'redis://:%s@redis:6379' "$(cat redis_password)"                              > redis_url

# Permissions — compose file-secrets are BIND MOUNTS that keep host ownership,
# so each file must be readable by the uid of the container that consumes it:
#   • postgres_url / redis_url / better_auth_secret → read by the APP, which
#     runs as uid 1001 (nextjs). root:root 600 breaks it (the entrypoint shim
#     fails fast with "not readable by uid 1001").
#   • postgres_password / redis_password → read by root-run containers; 600.
sudo chown 1001 postgres_url redis_url better_auth_secret
sudo chmod 400  postgres_url redis_url better_auth_secret
chmod 600 postgres_password redis_password
```

> Secret files should have **no trailing newline** (the app shim and `$(cat)`
> usages strip a single trailing newline, but it is cleaner to omit it).
>
> **If you substitute your own passwords** instead of the hex recipe above:
> the password embedded in `postgres_url`/`redis_url`
> must be **percent-encoded** (characters like `@ : / % #` break URL parsing —
> the raw `postgres_password` file would still work, giving a maximally
> confusing auth/host skew). Also edit the files with a Unix-newline editor:
> the shim strips a trailing `\n` only, so a CRLF file leaves an invisible
> `\r` inside the secret value.
>
> **Password loss = no recovery**: a bootstrap re-run adopts the existing
> database, it never resets passwords. Keep backups of this directory
> somewhere safe (it IS the keys to your data).
