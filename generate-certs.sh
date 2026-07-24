#!/bin/bash
set -e

# Configuration — the PFX path may be passed as $1 (install.sh auto-detects
# any *.pfx at the project root and passes it); default kept for manual runs.
PFX_FILE="${1:-wildcard_nbcbearings_in.pfx}"
CERTS_DIR="certs"

echo "Step 1: Checking for the PFX file..."
if [ ! -f "$PFX_FILE" ]; then
    echo "ERROR: $PFX_FILE not found in the current directory."
    echo "Please upload the file to this directory first, then run this script."
    exit 1
fi

echo "Step 2: Preparing certs directory..."
mkdir -p "$CERTS_DIR"

echo "Step 3: Entering certs directory..."
# Entering the directory just like you would manually
cd "$CERTS_DIR"

echo "Step 4: Extracting server key..."
openssl pkcs12 -legacy -in "../$PFX_FILE" -nocerts -nodes -out server.key -passin pass:""

echo "Step 5: Extracting server certificate..."
openssl pkcs12 -legacy -in "../$PFX_FILE" -clcerts -nokeys -out server.crt -passin pass:""

echo "Step 6: Extracting intermediate certificate..."
openssl pkcs12 -legacy -in "../$PFX_FILE" -cacerts -nokeys -out intermediate.crt -passin pass:""

echo "Step 7: Building fullchain..."
cat server.crt intermediate.crt > fullchain.crt

echo "Step 8: Setting secure permissions..."
chmod 640 server.key
chmod 644 fullchain.crt

echo "Step 9: Cleaning up temporary files..."
rm server.crt intermediate.crt

echo "Step 10: Writing Caddy TLS snippet..."
# Imported by ../Caddyfile via `import /certs/*.caddy` — its presence enables
# custom-cert mode. Single-quoted: the {$VAR} placeholders are expanded by
# Caddy at startup (from the compose-provided env), never by this shell.
printf 'tls {$TLS_CERT_PATH} {$TLS_KEY_PATH}\n' > tls.caddy

# Leave the certs directory to return to the project root
cd ..

echo "✅ Success! Certificates have been generated in the $CERTS_DIR folder."
