#!/usr/bin/env bash
# End-to-end test for per-song difficulty selection.
#
# 1P: Left/Right on the pad/keyboard must call the engine's ChangeSteps(0, ±1).
# 2P: P2's A/D keys must call ChangeSteps(1, ±1)  (proves P2 keymap reaches
#     the engine).
#
# Drives the real engine via AppleScript and reads the main log. Restarts
# OutFox. Preconditions: mermaid-kids theme installed and keymap fixed
# (scripts/fix-keymap.py).
set -euo pipefail

OUTFOX_APP="${OUTFOX_APP:-$HOME/Applications/OutFox/OutFox.app}"
LOG_DIR="${LOG_DIR:-$HOME/Library/Logs/Project OutFox}"
THEME="${THEME:-mermaid-kids}"

RET=0
say(){ printf '%s\n' "$*"; }
fail(){ say "FAIL: $*"; RET=1; }
newest(){ ls -t "$LOG_DIR"/$1 2>/dev/null | head -1 || true; }
key(){ osascript -e 'tell application "System Events" to set frontmost of process "OutFox" to true' \
        -e 'delay 0.4' -e "tell application \"System Events\" to key code $1" >/dev/null 2>&1; }
wait_after(){ local s="$1" f="$2" p="$3" t="${4:-15}" i=0
  while [ "$i" -lt "$t" ]; do tail -n "+$((s+1))" "$f" | grep -aq "$p" && return 0; sleep 1; i=$((i+1)); done; return 1; }

restart(){
  local before; before=$(newest "ProjectOutfox.MainLog.*" || true)
  pkill -9 -x OutFox 2>/dev/null || true; sleep 2
  open -n "$OUTFOX_APP"
  local i=0 M
  while [ "$i" -lt 40 ]; do
    M=$(newest "ProjectOutfox.MainLog.*")
    if [ -n "$M" ] && [ "$M" != "$before" ] && grep -aq 'PushScreen: "ScreenSelectPlayers"' "$M" 2>/dev/null; then
      sleep 1; return 0
    fi
    sleep 1; i=$((i+1))
  done
  return 1
}

enter_songselect(){  # key(s) to press while on the chooser already done by caller
  local M; M=$(newest "ProjectOutfox.MainLog.*")
  local m0; m0=$(wc -l < "$M")
  key 36
  if ! wait_after "$m0" "$M" 'PushScreen: "ScreenSelectMusic"' 15; then
    return 1
  fi
  sleep 4
  return 0
}

assert_step(){  # <label> <expected regex>
  local label="$1" re="$2" M; M=$(newest "ProjectOutfox.MainLog.*")
  local m0; m0=$(wc -l < "$M")
  key "$3"
  sleep 2
  if tail -n "+$((m0+1))" "$M" | grep -aqE "$re"; then
    say "OK: $label"
  else
    fail "$label (expected /$re/)"
  fi
}

say "== 1P difficulty: Left/Right = ChangeSteps(0, ±1) =="
restart || { fail "OutFox did not reach ScreenSelectPlayers"; exit "$RET"; }
enter_songselect || { fail "did not reach ScreenSelectMusic (1P)"; exit "$RET"; }
assert_step "Right cycles difficulty" 'ScreenSelectMusic::ChangeSteps\( 0, 1 \)' 124
assert_step "Left cycles difficulty"  'ScreenSelectMusic::ChangeSteps\( 0, -1 \)' 123

say "== 2P difficulty: A/D = ChangeSteps(1, ±1) =="
restart || { fail "OutFox did not restart"; exit "$RET"; }
# On the chooser, Right selects "2 PLAYERS", Start confirms and joins P1+P2.
key 124; sleep 1
enter_songselect || { fail "did not reach ScreenSelectMusic (2P)"; exit "$RET"; }
assert_step "P2 A cycles difficulty" 'ScreenSelectMusic::ChangeSteps\( 1, -1 \)' 0
assert_step "P2 D cycles difficulty" 'ScreenSelectMusic::ChangeSteps\( 1, 1 \)' 2

pkill -9 -x OutFox 2>/dev/null || true
if [ "$RET" -eq 0 ]; then say PASS; else say FAILED; fi
exit "$RET"
