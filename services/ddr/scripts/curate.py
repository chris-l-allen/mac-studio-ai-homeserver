#!/usr/bin/env python3
"""Curation report for the DDR song library.

Scans songpacks/*/*, extracts BPM + dance-single difficulties, marks duplicates
and gimmicks, and applies the keep rule:
  keep = has Beginner/Easy dance-single AND median BPM <= 140
         AND not a gimmick AND not a duplicate (the preferred copy is kept).

Writes CURATION.md and prints a summary. Does not delete anything.
"""
from __future__ import annotations

import pathlib
import re
import statistics
from collections import defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK_ORDER = {  # lower = preferred when de-duplicating
    "Kids 50": 0,
    "Dance Dance Revolution Disney Channel Edition (PS2) (NA)": 1,
    "Dance Dance Revolution Disney Grooves (Wii) (NA)": 2,
    "Stepmania Pop Hits Collection": 3,
}


def tag(txt: str, name: str) -> str:
    m = re.search(r"#" + name + r":([^;]*)", txt)
    return m.group(1).strip() if m else ""


def charts(txt: str, suffix: str):
    out = []
    if suffix == ".ssc":
        for part in txt.split("#NOTEDATA:")[1:]:
            st = re.search(r"#STEPSTYPE:([^;]*)", part)
            df = re.search(r"#DIFFICULTY:([^;]*)", part)
            mt = re.search(r"#METER:([^;]*)", part)
            if df:
                out.append((st.group(1).strip() if st else "",
                            df.group(1).strip(), mt.group(1).strip() if mt else ""))
    else:
        for part in txt.split("#NOTES:")[1:]:
            lines = [l.strip().rstrip(":") for l in part.splitlines() if l.strip()]
            if len(lines) >= 4:
                out.append((lines[0], lines[2], lines[3]))
    return out


def norm(s: str) -> str:
    s = s.lower()
    s = re.sub(r"\(.*?\)|\[.*?\]", "", s)
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return " ".join(s.split())


def main() -> None:
    songs = []
    for d in sorted(ROOT.glob("songpacks/*/*")):
        if not d.is_dir():
            continue
        title = artist = ""
        bpms, diffs = [], []
        for f in sorted(d.glob("*.ssc")) + sorted(d.glob("*.sm")):
            try:
                txt = f.read_text(errors="ignore")
            except OSError:
                continue
            title = title or tag(txt, "TITLE")
            artist = artist or tag(txt, "ARTIST")
            b = tag(txt, "BPMS")
            if b and not bpms:
                for part in b.split(","):
                    if "=" in part:
                        try:
                            bpms.append(float(part.split("=")[1]))
                        except ValueError:
                            pass
            diffs += charts(txt, f.suffix.lower())
        med = statistics.median(bpms) if bpms else None
        single = [x for x in diffs if x[0] == "dance-single"]
        easy = any(d.lower() in ("beginner", "easy") for _, d, _ in single)
        gimmick = bool(re.search(r"\[|\]|speed changes|midare|gimmick", title, re.I))
        songs.append({
            "pack": d.parent.name, "folder": d.name,
            "title": title or d.name, "artist": artist,
            "bpm": med, "easy": easy, "gimmick": gimmick,
            "diffs": sorted({d for _, d, _ in single}, key=lambda x: x.lower()),
        })

    # duplicates by (normalized title, normalized artist); blank artist -> title only
    groups = defaultdict(list)
    for s in songs:
        key = (norm(s["title"]), norm(s["artist"]))
        groups[key].append(s)
    dup = {}
    for key, group in groups.items():
        if len(group) < 2:
            continue
        group.sort(key=lambda s: (PACK_ORDER.get(s["pack"], 9), not s["easy"]))
        keep = group[0]
        for s in group[1:]:
            dup[(s["pack"], s["folder"])] = keep

    for s in songs:
        reasons = []
        if not s["easy"]:
            reasons.append("no Beginner/Easy")
        if s["bpm"] is not None and s["bpm"] > 140:
            reasons.append("BPM>140")
        if s["gimmick"]:
            reasons.append("gimmick")
        if (s["pack"], s["folder"]) in dup:
            k = dup[(s["pack"], s["folder"])]
            reasons.append(f"duplicate of {k['pack']}/{k['title']}")
        s["cut"] = bool(reasons)
        s["reasons"] = reasons

    keep = [s for s in songs if not s["cut"]]
    cut = [s for s in songs if s["cut"]]
    by_reason = defaultdict(int)
    for s in cut:
        for r in s["reasons"]:
            by_reason[r.split(" of ")[0]] += 1

    lines = ["# Curation report", "",
             f"Total: **{len(songs)}** · Keep: **{len(keep)}** · Cut: **{len(cut)}**", "",
             "Rule: Beginner/Easy dance-single + median BPM ≤ 140 + not gimmick + not duplicate.",
             "Explicit: 9 removed already; 4 probable-false kept.", "",
             "## Cut list", "",
             "| Pack | Song | BPM | Difficulties | Why cut |", "|---|---|---|---|---|"]
    for s in sorted(cut, key=lambda x: (x["pack"], x["title"].lower())):
        bpm = f"{s['bpm']:.0f}" if s["bpm"] else "?"
        lines.append(f"| {s['pack']} | {s['title']} | {bpm} | {', '.join(s['diffs']) or '—'} | {', '.join(s['reasons'])} |")
    lines += ["", "## Keep list", "",
              "| Pack | Song | BPM | Difficulties |", "|---|---|---|---|"]
    for s in sorted(keep, key=lambda x: (x["pack"], x["title"].lower())):
        bpm = f"{s['bpm']:.0f}" if s["bpm"] else "?"
        lines.append(f"| {s['pack']} | {s['title']} | {bpm} | {', '.join(s['diffs'])} |")
    (ROOT / "CURATION.md").write_text("\n".join(lines) + "\n")

    print(f"total {len(songs)} | keep {len(keep)} | cut {len(cut)}")
    for r, n in by_reason.items():
        print(f"  {r}: {n}")
    print("\nkeep by pack:")
    for p in sorted({s['pack'] for s in keep}):
        print(f"  {p}: {sum(1 for s in keep if s['pack'] == p)}")
    print("\ncut by pack:")
    for p in sorted({s['pack'] for s in cut}):
        print(f"  {p}: {sum(1 for s in cut if s['pack'] == p)}")


if __name__ == "__main__":
    main()
