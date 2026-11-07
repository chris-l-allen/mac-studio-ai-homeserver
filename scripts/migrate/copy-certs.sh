#!/usr/bin/env bash
# Copy the newest portal-issued leaf cert/key for each .allen host into the
# directory the Caddyfile reads: services/network/data/tls/<host>.crt|.key
#
# Issue the certs first in the portal (/issue) — this only copies them.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
NET="$REPO/services/network"
CERTS="$NET/data/certs"
TLS="$NET/data/tls"
HOSTS=(poker.allen homenetwork.allen hypometer.allen ddr.allen llm.allen hockey.allen)

mkdir -p "$TLS"
for h in "${HOSTS[@]}"; do
  d="$(ls -dt "$CERTS/${h}"_* 2>/dev/null | head -1 || true)"
  if [ -z "$d" ] || [ ! -f "$d/$h.crt" ] || [ ! -f "$d/$h.key" ]; then
    echo "MISSING: $h — issue it first at https://homenetwork.allen/issue (or the /api/certs/issue API)"
    continue
  fi
  cp "$d/$h.crt" "$TLS/$h.crt"
  cp "$d/$h.key" "$TLS/$h.key"
  chmod 644 "$TLS/$h.crt"
  chmod 600 "$TLS/$h.key"
  echo "copied $h  <- $(basename "$d")"
done
