#!/usr/bin/env python3
"""Write a known-good OutFox keymap for the kids DDR station.

The theme's song wheel uses the engine's *menu* buttons:
  PreviousSongButton/NextSongButton       = MenuUp / MenuDown
  PreviousDifficultyButton/NextDifficulty = MenuLeft / MenuRight
The pad sends plain arrow keys, so the menu buttons must be bound to the same
arrows or the pad cannot move the wheel or change difficulty.

P2 is a normal keyboard: W/A/S/D must be bound to the *direction* buttons
(gameplay) AND the menu buttons (wheel/difficulty), otherwise only Up/Right
register (the original W/A/S/D bug).

OutFox rewrites Keymaps.ini on exit, so this must run while OutFox is closed.

Usage:
    python3 fix-keymap.py [--check] [--file PATH] [--force]

--check only validates; exit status 1 if the file does not meet the contract.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

SECTION = "dance"

# action -> device-input value (":" separated bindings)
CANONICAL: dict[str, str] = {
    # P1: pad arrows are the gameplay directions only.
    #
    # Do NOT also bind MenuUp/Down/Left/Right to the same arrows: OutFox resolves
    # a key bound to two game buttons by clearing one of them when it rewrites
    # Keymaps.ini on exit, which killed the pad's Down/Left after a restart.
    # Difficulty is handled by a Lua input callback on the direction buttons
    # (see ScreenSelectMusic overlay.lua), so the menu buttons can stay unbound.
    "1_Up": "Key_up",
    "1_Down": "Key_down",
    "1_Left": "Key_left",
    "1_Right": "Key_right",
    "1_MenuUp": "",
    "1_MenuDown": "",
    "1_MenuLeft": "",
    "1_MenuRight": "",
    "1_Start": "Key_enter",
    "1_Back": "Key_escape",
    "1_Select": "Key_/",
    "1_Coin": "Key_F1",
    "1_Operator": "Key_scroll lock",
    "1_EffectUp": "",
    "1_EffectDown": "",
    "1_UpLeft": "",
    "1_UpRight": "",
    # P2: W/A/S/D directions only (no menu duplicates).
    "2_Up": "Key_w",
    "2_Down": "Key_s",
    "2_Left": "Key_a",
    "2_Right": "Key_d",
    "2_MenuUp": "",
    "2_MenuDown": "",
    "2_MenuLeft": "",
    "2_MenuRight": "",
    "2_Start": "Key_space",
    "2_Back": "Key_escape",
    "2_Select": "",
    "2_Coin": "",
    "2_Operator": "",
    "2_EffectUp": "",
    "2_EffectDown": "",
    "2_UpLeft": "",
    "2_UpRight": "",
}

# Keys that must never be bound to a direction/menu button: they can leave the
# game, change windows, or trigger system UI on macOS.
FORBIDDEN_IN_DIRECTIONS = {
    "Key_escape",
    "Key_tab",
    "Key_backspace",
    "Key_delete",
    "Key_home",
    "Key_end",
    "Key_pgup",
    "Key_pgdn",
    "Key_F1",
    "Key_F2",
    "Key_F3",
    "Key_F4",
    "Key_F5",
}

DIRECTION_ONLY = {
    f"{p}_{d}" for p in ("1", "2") for d in ("Up", "Down", "Left", "Right")
}
MENU_ONLY = {
    f"{p}_Menu{d}" for p in ("1", "2") for d in ("Up", "Down", "Left", "Right")
}
DIRECTION_ACTIONS = DIRECTION_ONLY | MENU_ONLY


def default_path() -> Path:
    return Path.home() / "Library/Preferences/Project OutFox/Keymaps.ini"


def parse(text: str) -> tuple[list[str], dict[str, str], list[str]]:
    """Return (prefix lines before [dance], dance entries, trailing lines)."""
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.strip().lower() == f"[{SECTION}]":
            start = i
            break
    if start is None:
        return lines, {}, []

    entries: dict[str, str] = {}
    end = len(lines)
    for j in range(start + 1, len(lines)):
        line = lines[j]
        if line.startswith("["):
            end = j
            break
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        entries[key.strip()] = val.strip()
    return lines[: start + 1], entries, lines[end:]


def render(prefix: list[str], entries: dict[str, str], trailer: list[str]) -> str:
    out = list(prefix)
    for key in sorted(entries):
        out.append(f"{key}={entries[key]}")
    if out and trailer:
        out.append("")
    out.extend(trailer)
    return "\n".join(out).rstrip("\n") + "\n"


def problems(entries: dict[str, str]) -> list[str]:
    out = []
    for action, want in CANONICAL.items():
        got = entries.get(action)
        if got != want:
            out.append(f"{action}: expected {want!r}, got {got!r}")
    for action in sorted(DIRECTION_ACTIONS):
        val = entries.get(action) or ""
        for binding in filter(None, val.split("::::")):
            if binding in FORBIDDEN_IN_DIRECTIONS:
                out.append(f"{action}: forbidden key {binding!r}")

    # A key bound to both a gameplay direction and the matching menu button is
    # not stable: OutFox clears one side when it rewrites Keymaps.ini on exit.
    def keys(actions):
        out_keys = set()
        for action in actions:
            out_keys.update(filter(None, (entries.get(action) or "").split("::::")))
        return out_keys

    for key in sorted(keys(DIRECTION_ONLY) & keys(MENU_ONLY)):
        out.append(
            f"key {key!r} is bound to both a direction and a menu button "
            "(OutFox clears one on exit)"
        )
    return out


def outfox_running() -> bool:
    try:
        return subprocess.run(
            ["pgrep", "-x", "OutFox"], capture_output=True, timeout=5
        ).returncode == 0
    except Exception:
        return False


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="validate only")
    ap.add_argument("--file", type=Path, default=default_path())
    ap.add_argument("--force", action="store_true", help="apply even if OutFox runs")
    args = ap.parse_args(argv)

    if not args.file.exists():
        print(f"error: {args.file} not found", file=sys.stderr)
        return 2

    prefix, entries, trailer = parse(args.file.read_text())
    if not prefix or not prefix[-1].strip().lower().startswith("[dance]"):
        print("error: no [dance] section", file=sys.stderr)
        return 2

    if args.check:
        probs = problems(entries)
        if probs:
            print("keymap FAILED:")
            for p in probs:
                print(f"  {p}")
            return 1
        print("keymap OK")
        return 0

    if outfox_running() and not args.force:
        print(
            "OutFox is running; quit it first (it rewrites Keymaps.ini on exit).",
            file=sys.stderr,
        )
        return 1

    merged = dict(entries)
    merged.update(CANONICAL)
    merged.setdefault("1_", "")
    merged.setdefault("2_", "")

    backup = args.file.with_name(
        args.file.name + ".bak-fixkeymap-" + __import__("time").strftime("%Y%m%d-%H%M%S")
    )
    shutil.copy2(args.file, backup)
    args.file.write_text(render(prefix, merged, trailer))
    print(f"wrote {args.file} (backup {backup.name})")

    remaining = problems(merged)
    if remaining:
        print("warning: post-write check failed:")
        for p in remaining:
            print(f"  {p}")
        return 1
    print("keymap OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
