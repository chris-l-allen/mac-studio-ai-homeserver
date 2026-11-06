#!/usr/bin/env python3
"""Normalize song folders to `Artist - Title` and clean the chart tags.

Dry-run by default; pass --apply to rewrite tags and rename folders.
Handles .ssc, .sm and .dwi. The pack folder is left as the parent directory.
"""
from __future__ import annotations

import argparse
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHART_EXT = {".ssc", ".sm", ".dwi"}

ARTIST_FIX = {
    "Beyonce": "Beyoncé",
    "Beyonce feat Jay Z": "Beyoncé feat. Jay-Z",
    "Carly Rae Japsen": "Carly Rae Jepsen",
    "Clean Bandit ft. Jess Glynne": "Clean Bandit feat. Jess Glynne",
    "Disney Grooves": "Disney",
    "Fitz & The Tantrums": "Fitz and the Tantrums",
    "HANNAH MONTANA": "Hannah Montana",
    "HIGH SCHOOL MUSICAL": "High School Musical",
    "LADY GAGA": "Lady Gaga",
    "Lady GaGa": "Lady Gaga",
    "MAROON 5": "Maroon 5",
    "MEGHAN TRAINOR": "Meghan Trainor",
    "Omi": "OMI",
    "PSY": "PSY",
    "Shakira Feat. Wyclef Jean": "Shakira feat. Wyclef Jean",
    "Sia ft. Kendrick Lamar": "Sia feat. Kendrick Lamar",
    "Taylor Swift ft. Kendrick Lamar": "Taylor Swift feat. Kendrick Lamar",
    "THE CHEETAH GIRLS": "The Cheetah Girls",
    "WALK THE MOON": "Walk the Moon",
}

TITLE_FIX = {
    "SHUT UP + DANCE": "Shut Up and Dance",
    "Can't Stop The Feeling!": "Can't Stop the Feeling!",
    "Hips don't lie": "Hips Don't Lie",
    "Turn Down For What?": "Turn Down for What?",
}

SMALL = {"a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into",
         "nor", "of", "on", "onto", "or", "over", "per", "so", "the", "to", "up",
         "via", "with", "vs", "vs."}


def tag(txt: str, name: str) -> str:
    m = re.search(r"#" + name + r":([^;]*)", txt)
    return m.group(1).strip() if m else ""


def read_meta(folder: pathlib.Path):
    title = artist = ""
    for f in sorted(folder.iterdir()):
        if f.suffix.lower() not in CHART_EXT:
            continue
        try:
            txt = f.read_text(errors="ignore")
        except OSError:
            continue
        title = title or tag(txt, "TITLE")
        artist = artist or tag(txt, "ARTIST")
    if not title:
        title = folder.name
    if not artist and " - " in folder.name:
        left, right = folder.name.split(" - ", 1)
        title, artist = left, right
    return title, artist


def smart_title(s: str) -> str:
    words = s.split()
    out = []
    for i, w in enumerate(words):
        m = re.search(r"[A-Za-z]", w)
        if not m:
            out.append(w)
            continue
        idx = m.start()
        core = re.sub(r"[^A-Za-z]", "", w).lower()
        if 0 < i < len(words) - 1 and core in SMALL:
            out.append(w[:idx] + w[idx:].lower())
        else:
            out.append(w[:idx] + w[idx].upper() + w[idx + 1:].lower())
    return " ".join(out)


def norm_artist(s: str) -> str:
    s = s.strip()
    if s in ARTIST_FIX:
        return ARTIST_FIX[s]
    s = s.replace(" ft. ", " feat. ").replace(" feat ", " feat. ")
    s = s.replace("Beyonce", "Beyoncé").replace("Jay Z", "Jay-Z")
    if s.isupper() and any(c.isalpha() for c in s):
        s = smart_title(s)
    return s or "Various Artists"


def fix_small_words(s: str) -> str:
    words = s.split()
    out = []
    for i, w in enumerate(words):
        core = re.sub(r"[^A-Za-z]", "", w).lower()
        if 0 < i < len(words) - 1 and core in SMALL:
            out.append(re.sub(r"[A-Za-z]+", lambda m: m.group(0).lower(), w, count=1))
        else:
            out.append(w)
    return " ".join(out)


def norm_title(s: str) -> str:
    s = s.strip()
    if s in TITLE_FIX:
        return TITLE_FIX[s]
    letters = re.sub(r"[^A-Za-z]", "", s)
    if letters and letters.isupper():
        s = smart_title(s)
    return fix_small_words(s)


def sanitize(s: str) -> str:
    s = s.replace("/", "-").replace(":", "-").replace(";", "-")
    s = re.sub(r'[\\?*"<>|]', "", s)
    s = re.sub(r"\s+", " ", s).strip(" .-")
    return s


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    plan = []
    for pack in sorted(ROOT.glob("songpacks/*")):
        if not pack.is_dir():
            continue
        used = {d.name.lower(): d for d in pack.iterdir() if d.is_dir()}
        for folder in sorted(d for d in pack.iterdir() if d.is_dir()):
            title, artist = read_meta(folder)
            if folder.name == "Stronger (What Doesn't Kill You)":
                title = folder.name
            artist = norm_artist(artist)
            title = norm_title(title)
            name = sanitize(f"{artist} - {title}")
            if not name:
                continue
            base, n = name, 2
            while name.lower() in used and used[name.lower()] != folder:
                name = f"{base} ({n})"
                n += 1
            used[name.lower()] = folder
            plan.append((pack, folder, name, artist, title))

    for pack, folder, name, artist, title in plan:
        changed = "RENAME" if folder.name != name else "ok    "
        print(f"{changed} | {pack.name[:28]:28} | {folder.name[:44]:44} -> {name}")

    if not args.apply:
        print(f"\nDry run: {len(plan)} songs. Re-run with --apply to write.")
        return

    for pack, folder, name, artist, title in plan:
        for f in sorted(folder.iterdir()):
            if f.suffix.lower() not in CHART_EXT:
                continue
            txt = f.read_text(errors="ignore")
            if re.search(r"#TITLE:", txt):
                txt = re.sub(r"#TITLE:[^;]*;", f"#TITLE:{title};", txt, count=1)
            else:
                txt = f"#TITLE:{title};\n" + txt
            if re.search(r"#ARTIST:", txt):
                txt = re.sub(r"#ARTIST:[^;]*;", f"#ARTIST:{artist};", txt, count=1)
            else:
                txt = f"#ARTIST:{artist};\n" + txt
            f.write_text(txt)
        if folder.name != name:
            folder.rename(folder.parent / name)
    print(f"\nApplied: {len(plan)} songs.")


if __name__ == "__main__":
    main()
