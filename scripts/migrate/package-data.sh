#!/usr/bin/env bash
# Bundle the runtime data (secrets + media) for transfer to the new Mac.
# Run on the OLD machine. The archive is NOT encrypted — move it directly, then
# shred it. Never commit or email it.
set -euo pipefail

OLD_HOME="${OLD_HOME:-$HOME}"
OUT="${1:-$HOME/Desktop/homelab-migration-$(date +%Y%m%d-%H%M).tar.gz}"

cat <<EOF
WARNING: this archive will contain:
  - the private CA root + intermediate keys
  - all issued TLS certs
  - OAuth credentials.json / token.json
  - any .env secrets
Move it over AirDrop/SSH, unpack it, then shred it:
  rm -P "$OUT"

Archive: $OUT
EOF

tar -czf "$OUT" -C "$OLD_HOME" \
  home-network/data \
  mac-studio-ai-homeserver/services/ddr/songpacks \
  "mac-studio-ai-homeserver/services/ddr/outfox/Appearance/Themes/mermaid/Graphics/Mermaid Loading.local.png" \
  mac-studio-ai-homeserver/services/ddr/outfox/Appearance/Themes/mermaid/Graphics/fail.mp4 \
  gmail-events/credentials.json \
  gmail-events/token.json \
  gmail-events/.env \
  leafs-hypometer/data \
  leafs-hypometer/certs 2>/dev/null || true

echo "Done: $(du -sh "$OUT" 2>/dev/null | cut -f1)  $OUT"
