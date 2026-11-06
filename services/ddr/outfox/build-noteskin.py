#!/usr/bin/env python3
"""Build the palette-matched Mermaid arrow noteskin."""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
THEME = ROOT / "Appearance/Themes/mermaid"
SKIN = ROOT / "Appearance/NoteSkins/dance/mermaid"
DEFAULT = pathlib.Path("/tmp/outfox-mnt/OutFox/Appearance/NoteSkins/dance/default")
TMP = pathlib.Path(tempfile.mkdtemp(prefix="arrows-"))

# 8 quantisation palettes: light, mid, dark
PALETTES = [
    ["#ff9ade", "#ff3cd2", "#b0157f"],  # hot pink
    ["#ffe0f0", "#ff9ad5", "#d05a9a"],  # pastel pink
    ["#d8feff", "#6ee7ff", "#1f9fb8"],  # aqua
    ["#dcc8ff", "#7c4dff", "#4a1fb8"],  # purple
    ["#ffc8c0", "#ff5e5b", "#b82a2a"],  # coral
    ["#fff3c4", "#ffd166", "#c79a2b"],  # gold
    ["#ccfff5", "#4dd0e1", "#1f8a9a"],  # teal
    ["#ffffff", "#e8e8f0", "#a0a0b8"],  # pearl
]


def arrow_svg(pal: list[str]) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="{pal[0]}"/><stop offset="0.55" stop-color="{pal[1]}"/><stop offset="1" stop-color="{pal[2]}"/>
</linearGradient></defs>
<path d="M64 110 L14 44 L40 44 L40 18 L88 18 L88 44 L114 44 Z"
      fill="url(#g)" stroke="#2a1a08" stroke-width="5" stroke-linejoin="round"/>
<path d="M64 98 L28 49 L46 49 L46 27 L82 27 L82 49 L100 49 Z"
      fill="#ffffff" opacity="0.17"/>
</svg>'''


def receptor_svg() -> str:
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#ff8ad8"/><stop offset="1" stop-color="#6ee7ff"/>
</linearGradient></defs>
<rect x="9" y="9" width="110" height="110" rx="26" fill="none" stroke="#2a1a08" stroke-width="10" opacity="0.85"/>
<rect x="11" y="11" width="106" height="106" rx="24" fill="none" stroke="url(#g)" stroke-width="6"/>
<rect x="27" y="27" width="74" height="74" rx="16" fill="none" stroke="#ffd6ec" stroke-width="2.5" opacity="0.9"/>
</svg>'''


def render(svg: str, name: str) -> pathlib.Path:
    src = TMP / (name + ".svg")
    src.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", "128", "-o", str(TMP), str(src)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return TMP / (src.name + ".png")


def main() -> None:
    if SKIN.exists():
        shutil.rmtree(SKIN)
    if not DEFAULT.exists():
        raise SystemExit("default noteskin not found; mount OutFox DMG first")
    shutil.copytree(DEFAULT, SKIN)

    frames = [render(arrow_svg(p), f"a{i}") for i, p in enumerate(PALETTES)]
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for f in frames:
        cmd += ["-i", str(f)]
    cmd += ["-filter_complex", "vstack=inputs=8", str(SKIN / "_arrow 1x8 (doubleres).png")]
    subprocess.run(cmd, check=True)

    render(receptor_svg(), "rec").replace(SKIN / "_receptor (doubleres).png")

    metrics = THEME / "metrics.ini"
    s = metrics.read_text().replace('DefaultNoteSkinName="anchor"', 'DefaultNoteSkinName="mermaid"')
    s = s.replace('DefaultNoteSkinName="outfox-itg"', 'DefaultNoteSkinName="mermaid"')
    metrics.write_text(s)
    print("built", SKIN)


if __name__ == "__main__":
    main()
