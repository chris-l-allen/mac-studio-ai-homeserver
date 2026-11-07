#!/usr/bin/env python3
"""Rewrite the Dumb Ways to Die Beginner chart from the song itself.

The old chart was a fixed 2-note rotating pattern. This generates a mapped
Beginner chart:
  - beat grid at 128 BPM, offset aligned to the song's strong accents
  - note density follows the measured energy per measure (1-4 notes)
  - patterns change every 4 measures (phrase), with jacks avoided
  - Only dance-single Beginner is written.

Run from the repo root:  python3 scripts/chart-dumb-ways.py
"""
from __future__ import annotations

import array
import math
import pathlib
import re
import subprocess
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
SONG = ROOT / "songpacks/Hannah's Picks/Tangerine Kitty - Dumb Ways to Die"
SSC = SONG / "Dumb Ways to Die.ssc"
AUDIO = SONG / "audio.ogg"

BPM = 128.0
BEAT = 60.0 / BPM
# Measured from the song's strong accents (beats 2,4,6,... are the accents).
OFFSET = 0.020
MEASURES = 96

# Column order in .ssc dance-single is L, D, U, R.
ARROW = {
    "L": "1000",
    "D": "0100",
    "U": "0010",
    "R": "0001",
    "": "0000",
}
PATTERNS = [
    "LURD", "URDL", "RDLU", "DLUR",
    "LRUD", "UDLR", "LULD", "RURD",
    "LDRU", "ULDR",
]


def measure_energy(audio: pathlib.Path) -> list[float]:
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(audio),
         "-ac", "1", "-ar", "22050", wav_path],
        check=True,
    )
    w = wave.open(wav_path, "rb")
    sr, ch = w.getframerate(), w.getnchannels()
    a = array.array("h")
    a.frombytes(w.readframes(w.getnframes()))
    w.close()
    pathlib.Path(wav_path).unlink(missing_ok=True)
    if ch > 1:
        a = array.array("h", [(a[i] + a[i + 1]) // 2 for i in range(0, len(a) - 1, 2)])

    measure = 4 * BEAT          # 1.875 s
    db = []
    for m in range(MEASURES):
        i0 = int(m * measure * sr)
        i1 = min(len(a), int((m + 1) * measure * sr))
        seg = a[i0:i1]
        power = sum((v / 32768.0) ** 2 for v in seg) / max(1, len(seg))
        db.append(10 * math.log10(power + 1e-12))
    return db


def density(db: float) -> int:
    if db >= -14.5:
        return 4
    if db >= -16.5:
        return 3
    if db >= -20.0:
        return 2
    return 1


def build_measures(db: list[float]) -> list[str]:
    rows_by_measure: list[list[str]] = []
    prev_last = ""
    for m in range(MEASURES):
        if m == MEASURES - 1:          # final measure is silence on the track
            rows_by_measure.append(["0000"] * 4)
            continue
        d = density(db[m])
        pat_index = ((m // 4) * 7 + 3) % len(PATTERNS)
        pat = PATTERNS[pat_index]
        # Avoid a jack at the measure boundary by using the next pattern whose
        # first arrow differs. Never reorder a pattern (that can create a jack).
        if prev_last and pat[0] == prev_last:
            for jump in range(1, len(PATTERNS)):
                candidate = PATTERNS[(pat_index + jump) % len(PATTERNS)]
                if candidate[0] != prev_last:
                    pat = candidate
                    break
        if d == 4:
            arrows = list(pat)
        elif d == 3:
            arrows = [pat[0], pat[1], pat[2]]
        elif d == 2:
            arrows = [pat[0], pat[2]]
        else:
            arrows = [pat[0]]

        rows = ["0000"] * 4
        if d == 4:
            for i, a in enumerate(arrows):
                rows[i] = ARROW[a]
        elif d == 3:
            for i, a in enumerate(arrows):
                rows[i] = ARROW[a]
        elif d == 2:
            rows[0] = ARROW[arrows[0]]
            rows[2] = ARROW[arrows[1]]
        else:
            rows[0] = ARROW[arrows[0]]

        prev_last = arrows[-1]
        rows_by_measure.append(rows)
    return ["\n".join(rows) + "\n" for rows in rows_by_measure]


def main() -> None:
    db = measure_energy(AUDIO)
    measures = build_measures(db)
    data = ",\n".join(m.rstrip("\n") for m in measures) + "\n"

    txt = SSC.read_text()
    header = txt.split("#NOTEDATA:", 1)[0]
    header = re.sub(r"#OFFSET:[^;]*;", f"#OFFSET:{OFFSET:.6f};", header, count=1)

    notes = (
        "#NOTEDATA:;\n"
        "#CHARTNAME:;\n"
        "#STEPSTYPE:dance-single;\n"
        "#DESCRIPTION:kids-mapped;\n"
        "#CHARTSTYLE:;\n"
        "#DIFFICULTY:Beginner;\n"
        "#METER:2;\n"
        "#RADARVALUES:0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;\n"
        "#CREDIT:callen;\n"
        "#NOTES:\n"
        + data
        + ";\n"
    )

    SSC.write_text(header + notes)
    counts = [m.count("1") for m in measures]
    print(f"wrote {SSC}")
    print(f"offset {OFFSET:.3f}s, measures {MEASURES}, notes {sum(counts)}")
    print("density first 32:", counts[:32])


if __name__ == "__main__":
    main()
