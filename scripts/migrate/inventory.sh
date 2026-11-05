#!/usr/bin/env bash
# List everything that must move from the old Mac to the Mac Studio.
# Run on the OLD machine. Read-only.
set -euo pipefail

OLD_HOME="${OLD_HOME:-$HOME}"

echo "== Runtime data (contains secrets — never commit) =="
for p in \
  "$OLD_HOME/home-network/data" \
  "$OLD_HOME/home-ddr/songpacks" \
  "$OLD_HOME/home-ddr/media" \
  "$OLD_HOME/gmail-events/credentials.json" \
  "$OLD_HOME/gmail-events/token.json" \
  "$OLD_HOME/gmail-events/.env" \
  "$OLD_HOME/leafs-hypometer/data" \
  "$OLD_HOME/leafs-hypometer/certs"; do
  if [ -e "$p" ]; then
    printf '  %-52s %s\n' "$p" "$(du -sh "$p" 2>/dev/null | cut -f1)"
  else
    printf '  MISSING: %s\n' "$p"
  fi
done

echo
echo "== Repos / apps to bring over =="
for d in \
  "$OLD_HOME/workspace/poker-game" \
  "$OLD_HOME/leafs-hypometer" \
  "$OLD_HOME/gmail-events"; do
  [ -d "$d" ] && echo "  $d" || echo "  MISSING: $d"
done

echo
echo "== Currently loaded home services =="
launchctl list 2>/dev/null | grep -E 'local\.home-network|com\.local\.homeddr|com\.callen\.holdem|local\.hypometer|com\.gmail-events|com\.local\.ollama|com\.ollama' || true
