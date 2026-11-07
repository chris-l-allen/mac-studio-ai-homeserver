#!/bin/sh
# Map OutFox's menu-navigation buttons onto the arrow keys, so the pad's
# arrows (which padbridge sends as Key_up/down/left/right) drive the music
# wheel: Up/Down = song, Left/Right = difficulty.
#
# Must run while OutFox is NOT running: OutFox rewrites Keymaps.ini on exit,
# which silently reverts any edit made while the game is open.
set -eu

PREFS="$HOME/Library/Preferences/Project OutFox"
K="$PREFS/Keymaps.ini"

if pgrep -x OutFox >/dev/null 2>&1; then
  echo "OutFox is running — quit it first (it rewrites Keymaps.ini on exit)." >&2
  exit 1
fi

[ -f "$K" ] || { echo "no $K"; exit 1; }

cp "$K" "$K.bak-$(date +%H%M%S)"

sed -i '' \
  -e 's/^1_MenuUp=.*/1_MenuUp=::::Key_up/' \
  -e 's/^1_MenuDown=.*/1_MenuDown=::::Key_down/' \
  -e 's/^1_MenuLeft=.*/1_MenuLeft=::::Key_left/' \
  -e 's/^1_MenuRight=.*/1_MenuRight=::::Key_right/' \
  "$K"

echo "keymap updated:"
grep -nE '^1_Menu' "$K"
