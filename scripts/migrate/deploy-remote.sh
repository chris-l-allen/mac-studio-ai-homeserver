#!/usr/bin/env bash
# Run on Rocinante (or over SSH) after the deployment bundle is copied there.
# Assumes this repo is cloned at ~/mac-studio-ai-homeserver and the bundle is at
# ~/Desktop/Rocinante-Deploy.
#
#   BUNDLE=~/Desktop/Rocinante-Deploy PULL_MODEL=1 ./scripts/migrate/deploy-remote.sh
#
# Interactive leftovers: Homebrew (if missing), Google sign-in, IP/DNS choice,
# and choosing the theme in OutFox.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="${BUNDLE:-$HOME/Desktop/Rocinante-Deploy}"
PULL_MODEL="${PULL_MODEL:-0}"

say() { printf '\n== %s ==\n' "$*"; }

say "checks"
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only"; exit 1; }
echo "arch: $(uname -m)"

say "tools"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing. Install it once, then re-run:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi
for t in python3 node git caddy ollama; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "installing $t"
    brew install "$t"
  fi
done

say "unpack bundle"
if [ -d "$BUNDLE" ]; then
  tar -xzf "$BUNDLE/homelab-apps.tar.gz" -C "$HOME"
  tar -xzf "$BUNDLE/homelab-migration.tar.gz" -C "$HOME"
  mkdir -p "$HOME/workspace"
  tar -xzf "$BUNDLE/poker-game-code.tar.gz" -C "$HOME/workspace"
  if [ -d "$HOME/home-network/data" ]; then
    mkdir -p "$REPO/services/network/data"
    rsync -a "$HOME/home-network/data/" "$REPO/services/network/data/"
  fi
else
  echo "bundle not found at $BUNDLE — skipping extraction"
fi

say "app deps"
if [ -f "$HOME/gmail-events/package.json" ]; then
  (cd "$HOME/gmail-events" && npm install --silent) || echo "gmail npm install failed; check manually"
fi
if [ -f "$HOME/workspace/poker-game/package.json" ]; then
  (cd "$HOME/workspace/poker-game" && npm install --silent) || echo "poker npm install failed; check manually"
fi

say "OutFox"
DMG="$BUNDLE/OutFox-0.5.0-pre043.dmg"
if [ ! -d "/Applications/OutFox/Appearance" ] && [ -f "$DMG" ]; then
  hdiutil attach -nobrowse -mountpoint /tmp/outfox-mnt "$DMG"
  cp -R /tmp/outfox-mnt/OutFox /Applications/OutFox
  hdiutil detach /tmp/outfox-mnt
fi
if [ -d "/Applications/OutFox/Appearance" ]; then
  OUTFOX_ROOT=/Applications/OutFox "$REPO/scripts/migrate/outfox-setup.sh"
else
  echo "OutFox not installed; skipping theme setup"
fi

say "certs"
"$REPO/scripts/migrate/copy-certs.sh" || echo "cert copy failed; issue/re-issue in the portal"

say "model"
if [ "$PULL_MODEL" = "1" ]; then
  (cd "$REPO" && ./scripts/pull-models.sh)
else
  echo "skipping model pull (PULL_MODEL=1 to enable)"
fi

say "services"
(cd "$REPO" && ./scripts/migrate/install-services.sh)

cat <<'EOF'

Remaining (interactive):
  1. Choose the LAN IP: same-IP swap (10.0.0.11) or new IP; update dns.json,
     Caddy LAN_IP, poker PUBLIC_URL, router DNS.
  2. Re-auth Google for the Gmail daemon.
  3. Launch OutFox -> Options -> Theme -> Mermaid; Noteskin -> Mermaid.
  4. Verify every .allen host, Ollama, Gmail classify, DDR, and reboot.
EOF
