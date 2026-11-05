#!/usr/bin/env bash
# Install and load every launchd unit for the merged home server.
# Run on the NEW Mac after the repo and runtime data are in place.
#
#   DRY_RUN=1 ./scripts/migrate/install-services.sh   # preview
#   ./scripts/migrate/install-services.sh             # install
#
# Rewrites /Users/callen -> $HOME so a different short username still works.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
AGENTS="$HOME/Library/LaunchAgents"
DRY="${DRY_RUN:-0}"

SERVICES=(
  com.local.ollama
  local.home-network.portal
  local.home-network.caddy
  com.local.homeddr
  com.callen.holdem.agent
  local.hypometer.server
  com.gmail-events.daemon
)

mkdir -p "$AGENTS"

for s in "${SERVICES[@]}"; do
  src="$REPO/launchd/$s.plist"
  dst="$AGENTS/$s.plist"
  if [ ! -f "$src" ]; then echo "skip (missing): $src"; continue; fi
  if [ "$DRY" = "1" ]; then echo "would install $s -> $dst"; continue; fi
  /usr/bin/sed "s#/Users/callen#$HOME#g" "$src" > "$dst"
  launchctl unload "$dst" 2>/dev/null || true
  launchctl load "$dst"
  echo "loaded $s"
done

echo
echo "Check: launchctl list | grep -E 'home-network|homeddr|holdem|hypometer|gmail|ollama'"
