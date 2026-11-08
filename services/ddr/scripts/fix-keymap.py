#!/usr/bin/env python3
"""Write the known-good OutFox keymap for the kids DDR station.

Design constraint (verified): OutFox rewrites Keymaps.ini on exit and, when a
key is bound to BOTH a gameplay direction and the matching menu button, it
clears the direction side. That killed the pad's Down/Left in v1.0.0.

But the pad's arrows must drive gameplay directions *and* the song wheel /
difficulty menus at the same time. The way to keep both is to make the file
immutable (`chflags uchg`) after writing it: OutFox's exit-time rename then
fails (it only logs a warning) and the duplicate bindings survive, so the next
launch still has working directions AND menu navigation.

Run while OutFox is closed (a running instance holds the old maps in memory).

Usage:
    python3 fix-keymap.py [--check] [--file PATH] [--no-lock]

--check validates the content and that the file is locked (immutable).
--no-lock writes/validates without the immutable flag (used by unit tests).
"""

from __future__ import annotations

import argparse
import shutil
import stat
import subprocess
import sys
import time
from pathlib import Path

SECTION = "dance"

# The pad sends arrow keys for P1 and W/A/S/D for P2. Both the direction and the
# menu button are bound to the same key so the wheel/difficulty work; the file
# must then be locked (see module docstring).
ARROWS = {
    "Up": "Key_up",
    "Down": "Key_down",
    "Left": "Key_left",
    "Right": "Key_right",
}
P2_KEYS = {
    "Up": "Key_w",
    "Down": "Key_s",
    "Left": "Key_a",
    "Right": "Key_d",
}

CANONICAL: dict[str, str] = {}
for d in ("Up", "Down", "Left", "Right"):
    CANONICAL[f"1_{d}"] = ARROWS[d]
    CANONICAL[f"1_Menu{d}"] = ARROWS[d]
    CANONICAL[f"2_{d}"] = P2_KEYS[d]
    CANONICAL[f"2_Menu{d}"] = P2_KEYS[d]
CANONICAL.update(
    {
        "1_Start": "Key_enter",
        "1_Back": "Key_escape",
        "1_Select": "Key_/",
        "1_Coin": "Key_F1",
        "1_Operator": "Key_scroll lock",
        "1_EffectUp": "",
        "1_EffectDown": "",
        "1_UpLeft": "",
        "1_UpRight": "",
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
)

# Keys that must never be bound to a direction/menu button.
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

DIRECTION_ACTIONS = {
    f"{p}_{d}"
    for p in ("1", "2")
    for d in ("Up", "Down", "Left", "Right", "MenuUp", "MenuDown", "MenuLeft", "MenuRight")
}


def default_path() -> Path:
    return Path.home() / "Library/Preferences/Project OutFox/Keymaps.ini"


def parse(text: str) -> tuple[list[str], dict[str, str], list[str]]:
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


def is_locked(path: Path) -> bool:
    try:
        return bool(os_stat_flags(path) & stat.UF_IMMUTABLE)
    except Exception:
        return False


def os_stat_flags(path: Path) -> int:
    return getattr(path.stat(), "st_flags", 0)


def set_locked(path: Path, locked: bool) -> None:
    flag = "uchg" if locked else "nouchg"
    subprocess.run(["chflags", flag, str(path)], check=True)


def overlaps(entries: dict[str, str]) -> list[str]:
    def keys(actions):
        out = set()
        for a in actions:
            out.update(filter(None, (entries.get(a) or "").split("::::")))
        return out

    directions = {f"{p}_{d}" for p in ("1", "2") for d in ("Up", "Down", "Left", "Right")}
    menus = {f"{p}_Menu{d}" for p in ("1", "2") for d in ("Up", "Down", "Left", "Right")}
    return sorted(keys(directions) & keys(menus))


def problems(entries: dict[str, str]) -> list[str]:
    out = []
    for action, want in CANONICAL.items():
        got = entries.get(action)
        if got != want:
            out.append(f"{action}: expected {want!r}, got {got!r}")
    for action in sorted(DIRECTION_ACTIONS):
        for binding in filter(None, (entries.get(action) or "").split("::::")):
            if binding in FORBIDDEN_IN_DIRECTIONS:
                out.append(f"{action}: forbidden key {binding!r}")
    return out


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="validate only")
    ap.add_argument("--file", type=Path, default=default_path())
    ap.add_argument(
        "--no-lock", action="store_true", help="do not set/require the immutable flag"
    )
    args = ap.parse_args(argv)

    if not args.file.exists():
        print(f"error: {args.file} not found", file=sys.stderr)
        return 2

    prefix, entries, trailer = parse(args.file.read_text())
    if not prefix or prefix[-1].strip().lower() != f"[{SECTION}]":
        print("error: no [dance] section", file=sys.stderr)
        return 2

    overlap = overlaps(entries)

    if args.check:
        probs = problems(entries)
        if probs:
            print("keymap FAILED:")
            for p in probs:
                print(f"  {p}")
            return 1
        if overlap and not args.no_lock and not is_locked(args.file):
            print(
                "keymap FAILED:\n"
                f"  direction/menu share keys {overlap} but the file is not locked;\n"
                "  OutFox will clear one side on exit (run without --check to fix)"
            )
            return 1
        print("keymap OK" + (" (locked)" if is_locked(args.file) else ""))
        return 0

    if is_locked(args.file):
        set_locked(args.file, False)

    merged = dict(entries)
    merged.update(CANONICAL)
    merged.setdefault("1_", "")
    merged.setdefault("2_", "")
    merged_overlap = overlaps(merged)

    backup = args.file.with_name(
        args.file.name + ".bak-fixkeymap-" + time.strftime("%Y%m%d-%H%M%S")
    )
    shutil.copy2(args.file, backup)
    args.file.write_text(render(prefix, merged, trailer))
    print(f"wrote {args.file} (backup {backup.name})")

    if merged_overlap and not args.no_lock:
        set_locked(args.file, True)
        print("locked keymap (chflags uchg) so OutFox cannot clear duplicate bindings")

    remaining = problems(merged)
    if remaining:
        print("warning: post-write check failed:")
        for p in remaining:
            print(f"  {p}")
        return 1
    print("keymap OK" + (" (locked)" if is_locked(args.file) else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
