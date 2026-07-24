# Certificates (custom-certificate mode)

This directory is bind-mounted **read-only** into the caddy container at
`/certs`. It is only used when you bring your own certificate instead of
Caddy's automatic Let's Encrypt (corporate CA, wildcard cert, or a VM the
ACME servers cannot reach). In IP-only and plain domain mode it stays
empty. Real cert/key files here must never be committed.

## Usage

1. Put the PFX bundle at the **project root** (it is gitignored there) and
   run the extraction script:

   ```bash
   cd ..                      # project root
   ./generate-certs.sh        # expects wildcard_nbcbearings_in.pfx
   ```

   It produces, in this directory:

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

**Renewal**: replace the `.pfx`, re-run `../generate-certs.sh`, then
`../compose.sh restart caddy` to load the new files.
**Disable the mode**: delete `tls.caddy` here and restart caddy.

## Permissions

The mount keeps host ownership and caddy runs as root in the stock
`caddy:2-alpine` image, so the script's `chmod 640 server.key` /
`chmod 644 fullchain.crt` work as-is. The key never needs to be
group/world readable.

> If the certificate is signed by a **private/corporate CA** not in the VM's
> trust store, the deploy health gate (`lib.sh`), which probes
> `https://<SITE_ADDRESS>` against the real certificate, will fail
> verification — add the CA to the VM's trust store (e.g.
> `/usr/local/share/ca-certificates/` + `update-ca-certificates`).
