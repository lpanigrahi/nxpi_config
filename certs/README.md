# Certificates (custom-certificate mode)

This directory is bind-mounted **read-only** into the caddy container at
`/certs`. It is only used when you bring your own certificate instead of
Caddy's automatic Let's Encrypt (corporate CA, wildcard cert, or a VM the
ACME servers cannot reach). In IP-only and plain domain mode it stays
empty. Real cert/key files here must never be committed.

## Usage

1. Put the PFX bundle at the **project root** (it is gitignored there) and
   run the installer — it auto-detects any `*.pfx` there (exactly one) and
   extracts it, skipping the step on re-runs when the generated files are
   already up to date:

   ```bash
   cd ..                      # project root
   ./install.sh               # detects the .pfx and extracts it
   # or manually, outside an install run:
   ./generate-certs.sh [your-bundle.pfx]   # defaults to wildcard_nbcbearings_in.pfx
   ```

   Extraction prompts for the PFX **export password** (press Enter if the
   bundle has none). For non-interactive runs either set `PFX_PASSWORD=...`
   in `../.env` (quote it if it contains spaces or `#`; safe to remove once
   the certs are generated) or pre-set it in the environment:
   `PFX_PASSWORD='...' ./install.sh`. Either way it is passed to openssl via
   the environment, never on the command line. A `Mac verify error: invalid
   password?` means the password was wrong (or the `.pfx` was corrupted in
   transfer — re-upload it in binary mode and compare checksums).

   Extraction produces, in this directory:

   ```
   fullchain.crt   # leaf + intermediate, PEM
   server.key      # matching private key, PEM
   tls.caddy       # `tls {$TLS_CERT_PATH} {$TLS_KEY_PATH}` — the mode switch
   ```

   `tls.caddy` is what ENABLES the mode: the Caddyfile does
   `import /certs/*.caddy`, and an empty glob is ignored by Caddy — so
   without the snippet, IP-only / Let's Encrypt behavior is untouched.

2. In `../.env` set the hostname the certificate names:

   ```
   SITE_ADDRESS=your.domain.com          # must match the cert's SAN/CN
   BETTER_AUTH_URL=https://your.domain.com
   ```

   `TLS_CERT_PATH`/`TLS_KEY_PATH` are only needed to override the defaults
   (`/certs/fullchain.crt` / `/certs/server.key` — container paths).

3. Apply: `../compose.sh up -d caddy` (or re-run `../install.sh`, which also
   validates the setup and fails fast on inconsistencies).

**Renewal**: replace the `.pfx` with the newer bundle and re-run
`../install.sh` — it re-extracts (the `.pfx` being newer than
`fullchain.crt` triggers it) and restarts caddy automatically. The manual
flow still works: `../generate-certs.sh`, then `../compose.sh restart caddy`.
**Disable the mode**: delete `tls.caddy` here (and the root `.pfx`, or the
next install re-creates it) and restart caddy.

## Permissions

The mount keeps host ownership, and although caddy runs as root in the
stock `caddy:2-alpine` image, the compose service **drops all Linux
capabilities** — without `CAP_DAC_OVERRIDE`, container-root is subject to
plain permission bits like any other user. Required state (set up
automatically by `../install.sh` after extraction):

```
drwxr-xr-x  certs/              # 755 — traversable by the container
-rw-r--r--  fullchain.crt       # 644 — public material
-rw-r--r--  tls.caddy           # 644 — non-secret snippet
-rw-------  server.key  root:root  # 600 — container-root reads it as OWNER
```

After a **manual** `../generate-certs.sh` run, apply the key ownership
yourself (or just re-run `../install.sh`):

```bash
sudo chown root:root certs/server.key && sudo chmod 600 certs/server.key
```

> If the certificate is signed by a **private/corporate CA** not in the VM's
> trust store, the deploy health gate (`lib.sh`), which probes
> `https://<SITE_ADDRESS>` against the real certificate, will fail
> verification — add the CA to the VM's trust store (e.g.
> `/usr/local/share/ca-certificates/` + `update-ca-certificates`).
