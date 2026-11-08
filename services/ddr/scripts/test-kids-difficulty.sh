#!/usr/bin/env bash
# End-to-end test for per-song difficulty selection.
#
# Requires the locked duplicate keymap (scripts/fix-keymap.py): the pad's
# Left/Right are the gameplay directions AND MenuLeft/Right, so the engine logs
# ScreenSelectMusic::ChangeSteps( 0, ±1 ) when they are pressed on song select.
#
# 1P: Right then Left must call ChangeSteps(0, +1) and ChangeSteps(0, -1).
# 2P: after late-joining P2 with SPACE, A/D must call ChangeSteps(1, ±1).
#
# Restarts OutFox for a known starting screen. Reads the main log.
set -euo pipefail

OUTFOX_APP="${OUTFOX_APP:-$HOME/Applications/OutFox/OutFox.app}"
LOG_DIR="${LOG_DIR:-$HOME/Library/Logs/Project OutFox}"

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

enter_music(){
  local M="$1"; local m0; m0=$(wc -l < "$M")
  key 36
  if wait_after "$m0" "$M" 'PushScreen: "ScreenSelectMusic"' 8; then sleep 3; return 0; fi
  key 36
  wait_after "$m0" "$M" 'PushScreen: "ScreenSelectMusic"' 10 && sleep 3
}

assert_step(){  # <label> <keycode> <expected ChangeSteps regex>
  local label="$1" code="$2" re="$3" M; M=$(newest "ProjectOutfox.MainLog.*")
  local m0; m0=$(wc -l < "$M")
  key "$code"
  sleep 2
  if tail -n "+$((m0+1))" "$M" | grep -aqE "$re"; then
    say "OK: $label"
  else
    fail "$label (expected /$re/)"
  fi
}

say "== 1P: Left/Right cycle difficulty =="
restart || { fail "OutFox did not reach ScreenSelectPlayers"; exit "$RET"; }
M=$(newest "ProjectOutfox.MainLog.*")
enter_music "$M" || { fail "did not reach ScreenSelectMusic"; exit "$RET"; }
assert_step "Right -> harder" 124 'ScreenSelectMusic::ChangeSteps\( 0, 1 \)'
assert_step "Left -> easier"  123 'ScreenSelectMusic::ChangeSteps\( 0, -1 \)'

say "== 2P: chooser selects 2P, then A/D cycles difficulty =="
restart || { fail "OutFox did not restart"; exit "$RET"; }
key 124   # chooser: arrow moves the selection to "2 PLAYERS"
sleep 1
M=$(newest "ProjectOutfox.MainLog.*")
enter_music "$M" || { fail "did not reach ScreenSelectMusic (2P)"; exit "$RET"; }
if grep -aq 'Players joined: P1, P2' "$M"; then
  say "OK: P2 joined"
else
  fail "chooser did not join P2"
fi
assert_step "P2 A -> easier" 0 'ScreenSelectMusic::ChangeSteps\( 1, -1 \)'
assert_step "P2 D -> harder" 2 'ScreenSelectMusic::ChangeSteps\( 1, 1 \)'

pkill -9 -x OutFox 2>/dev/null || true
if [ "$RET" -eq 0 ]; then say PASS; else say FAILED; fi
exit "$RET"
