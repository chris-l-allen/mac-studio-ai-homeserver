#!/bin/sh
# Start OutFox, then fail the smoke test if the wheel is empty or the log has a crash.
set -eu
HOST="callen@10.0.0.54"
KEY="$HOME/.ssh/id_rsa.tmp"

ssh -i "$KEY" "$HOST" '
killall -9 OutFox 2>/dev/null || true
sleep 2
open "$HOME/Desktop/DDR.app"
sleep 12
LOG=$(ls -t "$HOME/Library/Logs/Project OutFox/"ProjectOutfox.MainLog.* | head -1)
echo "log=$LOG"
THEME=$(grep -m1 "Theme: " "$LOG" | sed "s/.*Theme: *//")
echo "theme=$THEME"
if grep -q "No selectable songs or courses found in WheelData" "$LOG"; then
  echo "FAIL: empty MusicWheel"
  exit 1
fi
if grep -qiE "SIGABRT|Fatal signal|Segmentation fault" "$LOG"; then
  echo "FAIL: crash marker in log"
  exit 1
fi
pgrep -fl "/Applications/OutFox/OutFox.app" | head -1 || { echo "FAIL: OutFox not running"; exit 1; }
echo "PASS"
'
