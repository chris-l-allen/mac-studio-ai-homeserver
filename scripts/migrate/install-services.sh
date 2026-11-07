#!/usr/bin/env bash
# Install every unit as a boot-time LaunchDaemon (starts before login).
# Run on the server with sudo:
#
#   sudo ./scripts/migrate/install-services.sh
#   DRY_RUN=1 sudo ./scripts/migrate/install-services.sh
#
# Caddy runs as root (binds 80/443). All other units run as the invoking user,
# so they start at boot without a login session.
set -euo pipefail

if [ "$(id -u)" != "0" ]; then
  echo "Run with sudo (installs to /Library/LaunchDaemons)." >&2
  exit 1
fi

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
DAEMONS="/Library/LaunchDaemons"
DRY="${DRY_RUN:-0}"
USER_NAME="${SERVICE_USER:-${SUDO_USER:-callen}}"
AGENTS="/Users/$USER_NAME/Library/LaunchAgents"
AGENT_UID="${SUDO_UID:-$(id -u "$USER_NAME" 2>/dev/null || echo 0)}"

SERVICES=(
  com.local.ollama
  local.home-network.portal
  local.home-network.caddy
  com.local.homeddr
  com.callen.holdem.agent
  local.hypometer.server
  com.gmail-events.daemon
)

mkdir -p "$DAEMONS"

for s in "${SERVICES[@]}"; do
  src="$REPO/launchd/$s.plist"
  if [ ! -f "$src" ]; then echo "skip (missing): $src"; continue; fi
  dst="$DAEMONS/$s.plist"
  if [ "$DRY" = "1" ]; then echo "would install $s -> $dst (User=$USER_NAME)"; continue; fi

  /usr/bin/python3 - "$src" "$dst" "$s" "$USER_NAME" <<'PY'
import plistlib, sys
src, dst, label, user = sys.argv[1:5]
with open(src, "rb") as f:
    d = plistlib.load(f)

def repl(x):
    if isinstance(x, str):
        return x.replace("/Users/callen", "/Users/" + user)
    if isinstance(x, list):
        return [repl(i) for i in x]
    if isinstance(x, dict):
        return {k: repl(v) for k, v in x.items()}
    return x

d = repl(d)
d["UserName"] = "root" if "caddy" in label else user
env = d.get("EnvironmentVariables", {})
env["HOME"] = "/Users/" + user
env["PATH"] = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
d["EnvironmentVariables"] = env
d["RunAtLoad"] = True
d["KeepAlive"] = True
with open(dst, "wb") as f:
    plistlib.dump(d, f)
PY

  chown root:wheel "$dst"
  chmod 644 "$dst"
  launchctl bootout "system/$s" 2>/dev/null || true
  launchctl bootstrap system "$dst"
  launchctl enable "system/$s" 2>/dev/null || true

  if [ -f "$AGENTS/$s.plist" ]; then
    launchctl bootout "gui/$AGENT_UID/$s" 2>/dev/null || true
    mkdir -p "$AGENTS/disabled"
    mv "$AGENTS/$s.plist" "$AGENTS/disabled/" 2>/dev/null || true
  fi

  run_as="root"; [ "$s" = "local.home-network.caddy" ] || run_as="$USER_NAME"
  echo "loaded daemon $s (User=$run_as)"
done

echo
echo "Check: sudo launchctl list | grep -E 'home-network|homeddr|holdem|hypometer|gmail|ollama'"
echo "Boot test: reboot; services must be up with no user logged in."
