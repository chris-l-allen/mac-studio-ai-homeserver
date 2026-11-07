#!/bin/sh
# Show whether padbridge is running and print the last few pad events.
set -eu
HOST="callen@10.0.0.54"
KEY="$HOME/.ssh/id_rsa.tmp"
ssh -i "$KEY" "$HOST" '
launchctl print "gui/$(id -u)/com.callen.padbridge" 2>/dev/null | grep -E "state =|pid =|last exit" || true
pgrep -fl "/Users/callen/bin/padbridge" || echo "padbridge: not running"
echo "--- last events ---"
tail -8 "$HOME/Library/Logs/padbridge.log" 2>/dev/null || true
'
