#!/usr/bin/env python3
"""Build the "Kids Easy" pack: Beginner (or Easy) versions of the easiest songs.

Songs are selected by #TITLE (not folder name), because the live machine and
the repo mirror use different folder names for the Disney Channel pack.

Each song folder in songpacks/Kids Easy contains a filtered .sm/.ssc with only
the dance-single Beginner chart (falling back to Easy when there is no
Beginner), plus relative symlinks to the original media.
Run from the repo root:  python3 scripts/build-kids-easy.py
"""
from __future__ import annotations

import os
import pathlib
import re
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "songpacks"
DST = SRC / "Kids Easy"

# Case/punctuation-insensitive; matched against #TITLE.
TITLES = [
    "Ev'rybody Wants to Be a Cat",
    "Hakuna Matata",
    "The Tiki, Tiki, Tiki Room",
    "I Wan'na Be Like You",
    "Cruella De Vil",
    "A Dream Is a Wish Your Heart Makes",
    "The Bare Necessities",
    "Zip-A-Dee-Doo-Dah",
    "He Mele No Lilo",
    "Bibbidi-Bobbidi-Boo",
    "I Just Can't Wait to Be King",
    "Circle of Life",
    "The Party's Just Begun",
    "Cheetah Sisters",
    "Get'cha Head in the Game",
    "Bop to the Top",
    "We're All in This Together",
    "The Best of Both Worlds",
    "Dumb Ways to Die",
    # --- new packs (2026-11-07) ---
    "Baby Shark",
    "Alvin and the Chipmunks Theme",
    "The Fox",
    "Ghostbusters Theme",
    "5, 6, 7, 8",
    "Crab Rave",
    "Spider Pig",
    "Dancing Lasha Tumbai",
    "Let's Dance",
    "Bye Bye Bye",
    "Tetris",
    # --- K-Pop (2026-11-07) ---
    "Free",
    "Golden",
    "How It's Done",
    "Soda Pop",
    "Strategy",
    "TAKEDOWN",
    "What It Sounds Like",
    "Your Idol",
]

# Prefer the kid-facing packs if a title appears more than once.
PACK_PRIORITY = {
    "Dance Dance Revolution Disney Channel Edition (PS2) (NA)": 0,
    "Dance Dance Revolution Disney Grooves (Wii) (NA)": 1,
    "Hannah's Picks": 2,
    "Highflyer's Rhythmic Garbage": 3,
    "Torukine": 4,
    "K-Pop Demon Hunters": 5,
}

CHART_SUFFIXES = {".sm", ".ssc"}


def tag(txt: str, name: str) -> str:
    m = re.search(r"#" + name + r":([^;]*)", txt, re.I)
    return m.group(1).strip() if m else ""


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def kidsify_note_lines(text: str) -> str:
    """Turn hold/roll heads into taps, drop tails/mines, and collapse jumps.

    .sm/.ssc note columns are L,D,U,R; 1=tap, 2/4=hold/roll head, 3=tail, M=mine.
    """
    out = []
    for line in text.splitlines():
        row = line.strip()
        if re.fullmatch(r"[0-9A-Z]{4}", row):
            new = "0000"
            for j, c in enumerate(row):
                if c in "124":
                    new = ("0" * j) + "1" + ("0" * (3 - j))
                    break
            out.append(new)
        else:
            out.append(line)
    return "\n".join(out)


def filter_sm(txt: str) -> str | None:
    parts = txt.split("#NOTES:")
    keep = []
    for part in parts[1:]:
        nonempty = [line.strip().rstrip(":") for line in part.splitlines() if line.strip()]
        if len(nonempty) < 4:
            continue
        stepstype, difficulty = nonempty[0].lower(), nonempty[2].lower()
        if stepstype == "dance-single" and difficulty in ("beginner", "easy"):
            keep.append(kidsify_note_lines(part))
    if not keep:
        return None
    return parts[0] + "".join("#NOTES:" + part for part in keep)


def filter_ssc(txt: str) -> str | None:
    parts = txt.split("#NOTEDATA:")
    keep = []
    for part in parts[1:]:
        if re.search(r"#STEPSTYPE:\s*dance-single\s*;", part, re.I) and \
           re.search(r"#DIFFICULTY:\s*(beginner|easy)\s*;", part, re.I):
            keep.append(kidsify_note_lines(part))
    if not keep:
        return None
    return parts[0] + "".join("#NOTEDATA:" + part for part in keep)


def index_songs() -> dict[str, list[tuple[str, str, pathlib.Path]]]:
    index: dict[str, list[tuple[str, str, pathlib.Path]]] = {}
    for song_dir in sorted(SRC.glob("*/*")):
        if not song_dir.is_dir() or song_dir.parent.name == DST.name:
            continue
        for chart in sorted(song_dir.glob("*.ssc")) + sorted(song_dir.glob("*.sm")):
            title = tag(chart.read_text(errors="ignore"), "TITLE")
            if title:
                index.setdefault(norm(title), []).append(
                    (song_dir.parent.name, song_dir.name, song_dir)
                )
                break
    return index


def build() -> None:
    index = index_songs()
    if DST.exists():
        shutil.rmtree(DST)
    DST.mkdir(parents=True)
    built = 0
    for wanted in TITLES:
        matches = index.get(norm(wanted), [])
        if not matches:
            print(f"MISSING {wanted}")
            continue
        matches.sort(key=lambda m: PACK_PRIORITY.get(m[0], 9))
        _pack, folder, src = matches[0]
        out = DST / folder
        out.mkdir()
        chart_written = False
        for entry in src.iterdir():
            if entry.name.startswith("."):
                continue
            if entry.suffix.lower() in CHART_SUFFIXES:
                txt = entry.read_text(errors="ignore")
                filtered = filter_sm(txt) if entry.suffix.lower() == ".sm" else filter_ssc(txt)
                if filtered:
                    (out / entry.name).write_text(filtered)
                    chart_written = True
                continue
            os.symlink(os.path.relpath(entry, out), out / entry.name)
        if chart_written:
            built += 1
        else:
            shutil.rmtree(out)
            print(f"NO BEGINNER CHART {folder}")
    print(f"built {built} songs in {DST}")


if __name__ == "__main__":
    build()
