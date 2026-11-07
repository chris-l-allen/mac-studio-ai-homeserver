#!/bin/sh
# Keep the chatty padbridge log from growing without bound.
set -eu
HOST="callen@10.0.0.54"
KEY="$HOME/.ssh/id_rsa.tmp"
ssh -i "$KEY" "$HOST" '
LOG="$HOME/Library/Logs/padbridge.log"
SIZE=$(wc -c < "$LOG" 2>/dev/null || echo 0)
if [ "$SIZE" -gt 1048576 ]; then
  tail -2000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  echo "rotated (was $SIZE bytes)"
else
  echo "ok ($SIZE bytes)"
fi
'
