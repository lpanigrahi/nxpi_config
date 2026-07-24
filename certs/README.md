# Certificates (custom-certificate mode)

This directory is bind-mounted **read-only** into the caddy container at
`/etc/caddy/certs`. It is only used when you bring your own certificate
instead of Caddy's automatic Let's Encrypt (corporate CA, wildcard cert, or
a VM the ACME servers cannot reach). In IP-only and plain domain mode it
stays empty. Real cert/key files here must never be committed.

## Usage

1. Copy the certificate (full chain, PEM) and private key here, e.g.:

   ```
   certs/site.crt   # leaf + intermediates, PEM
   certs/site.key   # matching private key, PEM
   ```

2. In `../.env` set the **container** paths and the matching hostname:

   ```
   SITE_ADDRESS=your.domain.com          # must match the cert's SAN/CN
   TLS_CERT_PATH=/etc/caddy/certs/site.crt
   TLS_KEY_PATH=/etc/caddy/certs/site.key
   BETTER_AUTH_URL=https://your.domain.com
   ```

3. Apply: `../compose.sh up -d caddy` (or re-run `../install.sh`).

Set **both** vars or neither — `../install.sh` fails fast on a half-set pair.
After renewing/replacing the files, restart caddy to load them:
`../compose.sh restart caddy`.

## Permissions

The mount keeps host ownership and caddy runs as root in the stock
`caddy:2-alpine` image, so `chmod 644 site.crt` and `chmod 600 site.key`
(root-owned) work. The key never needs to be group/world readable.

> If the certificate is signed by a **private/corporate CA** not in the VM's
> trust store, the deploy health gate (`lib.sh`), which probes
> `https://<SITE_ADDRESS>` against the real certificate, will fail
> verification — add the CA to the VM's trust store (e.g.
> `/usr/local/share/ca-certificates/` + `update-ca-certificates`).
