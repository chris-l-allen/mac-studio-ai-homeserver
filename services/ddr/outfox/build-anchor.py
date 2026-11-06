#!/usr/bin/env python3
"""Build the vintage-metal Anchor noteskin.

Reuses OutFox's default dance noteskin for holds/effects/circles and replaces the
arrow sheet + receptor with original metal-anchor art.
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
THEME = ROOT / "Appearance/Themes/mermaid"
SKIN = ROOT / "Appearance/NoteSkins/dance/anchor"
DEFAULT = pathlib.Path("/tmp/outfox-mnt/OutFox/Appearance/NoteSkins/dance/default")
TMP = pathlib.Path(tempfile.mkdtemp(prefix="anchor-"))

# five-stop metal gradients, one per quantisation
PALETTES = [
    ["#fff1b8", "#d9a83f", "#8a5a1f", "#e8c06a", "#6b4410"],  # gold
    ["#ffd9a8", "#c07a3a", "#6e3a14", "#e0a05a", "#4a2408"],  # bronze
    ["#ffffff", "#c9d2dc", "#6b7480", "#eef3f8", "#3f4650"],  # silver
    ["#ffd0b0", "#c86a3a", "#7a2e12", "#e89a6a", "#4a1a08"],  # copper
    ["#d8fff4", "#5fc7b0", "#1f6b5a", "#9fe8d8", "#0d3b30"],  # patina teal
    ["#ffe0e8", "#d98a9a", "#8a3a4a", "#f0b0c0", "#5a2030"],  # rose gold
    ["#d8dde6", "#7a8494", "#2f3640", "#aab4c4", "#151a22"],  # gunmetal
    ["#ffffff", "#e8e8f0", "#a0a0b8", "#f8f8ff", "#606078"],  # pearl
]
OFFSETS = [0, 0.25, 0.5, 0.75, 1]


def grad(pal: list[str]) -> str:
    stops = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in zip(OFFSETS, pal))
    return f'<linearGradient id="m" x1="0" y1="0" x2="0.25" y2="1">{stops}</linearGradient>'


def anchor_svg(pal: list[str]) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs>{grad(pal)}
<filter id="sh" x="-20%" y="-20%" width="140%" height="140%">
  <feDropShadow dx="0" dy="2" stdDeviation="1.6" flood-color="#000" flood-opacity="0.45"/>
</filter></defs>
<g filter="url(#sh)" stroke-linejoin="round" stroke-linecap="round">
  <!-- ring -->
  <circle cx="64" cy="21" r="12" fill="none" stroke="#2a1a08" stroke-width="11"/>
  <circle cx="64" cy="21" r="12" fill="none" stroke="url(#m)" stroke-width="7"/>
  <circle cx="60" cy="17" r="4" fill="#ffffff" opacity="0.35"/>
  <!-- shaft -->
  <rect x="56" y="31" width="16" height="67" rx="5" fill="url(#m)" stroke="#2a1a08" stroke-width="3"/>
  <rect x="60" y="37" width="4" height="53" rx="2" fill="#ffffff" opacity="0.32"/>
  <!-- crossbar -->
  <rect x="31" y="50" width="66" height="11" rx="5" fill="url(#m)" stroke="#2a1a08" stroke-width="3"/>
  <rect x="35" y="52" width="58" height="3" rx="1.5" fill="#ffffff" opacity="0.35"/>
  <!-- arms -->
  <path d="M26 74 C26 109 102 109 102 74" fill="none" stroke="#2a1a08" stroke-width="16"/>
  <path d="M26 74 C26 109 102 109 102 74" fill="none" stroke="url(#m)" stroke-width="11"/>
  <path d="M34 82 C42 101 86 101 94 82" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.35"/>
  <!-- flukes -->
  <polygon points="17,61 37,68 26,85" fill="url(#m)" stroke="#2a1a08" stroke-width="3"/>
  <polygon points="111,61 91,68 102,85" fill="url(#m)" stroke="#2a1a08" stroke-width="3"/>
</g></svg>'''


def receptor_svg() -> str:
    pal = PALETTES[4]  # patina teal
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs>{grad(pal)}</defs>
<circle cx="64" cy="64" r="55" fill="none" stroke="#2a1a08" stroke-width="10"/>
<circle cx="64" cy="64" r="55" fill="none" stroke="url(#m)" stroke-width="6"/>
<circle cx="64" cy="64" r="45" fill="none" stroke="#6ee7ff" stroke-width="3" opacity="0.85"/>
<circle cx="64" cy="64" r="50" fill="none" stroke="#ff8ad8" stroke-width="1.5" opacity="0.6"/>
</svg>'''


def render(svg: str, name: str) -> pathlib.Path:
    src = TMP / (name + ".svg")
    src.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", "128", "-o", str(TMP), str(src)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return TMP / (src.name + ".png")


def main() -> None:
    if not SKIN.exists():
        if not DEFAULT.exists():
            raise SystemExit("default noteskin not found; mount OutFox DMG first")
        shutil.copytree(DEFAULT, SKIN)

    frames = [render(anchor_svg(p), f"a{i}") for i, p in enumerate(PALETTES)]
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for f in frames:
        cmd += ["-i", str(f)]
    cmd += ["-filter_complex", "vstack=inputs=8", str(SKIN / "_arrow 1x8 (doubleres).png")]
    subprocess.run(cmd, check=True)

    rec = render(receptor_svg(), "rec")
    rec.replace(SKIN / "_receptor (doubleres).png")

    # make the theme use the anchor noteskin
    metrics = THEME / "metrics.ini"
    s = metrics.read_text()
    s = s.replace('DefaultNoteSkinName="outfox-itg"', 'DefaultNoteSkinName="anchor"')
    metrics.write_text(s)

    print("built anchor noteskin:", SKIN)


if __name__ == "__main__":
    main()
