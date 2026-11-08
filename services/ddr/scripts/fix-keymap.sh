#!/bin/sh
# Backwards-compatible wrapper for fix-keymap.py.
#
# Maps the pad's arrow keys onto OutFox's menu/direction buttons so the wheel
# and difficulty respond, and gives P2 the full W/A/S/D set.
#
# Must run while OutFox is NOT running: OutFox rewrites Keymaps.ini on exit,
# which silently reverts any edit made while the game is open.
set -eu
exec python3 "$(cd "$(dirname "$0")" && pwd)/fix-keymap.py" "$@"
