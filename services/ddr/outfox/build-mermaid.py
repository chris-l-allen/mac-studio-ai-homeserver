#!/usr/bin/env python3
"""Build the Mermaid theme + Anchor noteskin from SVG assets.

Requires: qlmanage (macOS), ffmpeg (vstack), sips.
Run from services/ddr/outfox.
"""
from __future__ import annotations

import pathlib
import re
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
THEME = ROOT / "Appearance/Themes/mermaid"
SKIN = ROOT / "Appearance/NoteSkins/dance/anchor"
TMP = pathlib.Path(tempfile.mkdtemp(prefix="mermaid-"))

# quantization colours (4th, 8th, 12th, 16th, 24th, 48th, 64th, 192nd)
COLOURS = ["#FF3CD2", "#FF8AD8", "#6EE7FF", "#7C4DFF",
           "#FF5E5B", "#FFD166", "#4DD0E1", "#FFFFFF"]


def anchor_svg(colour: str, size: int = 128, stroke: int = 12) -> str:
    s = size
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{s}" height="{s}" viewBox="0 0 128 128">
<g fill="none" stroke="{colour}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round">
<circle cx="64" cy="24" r="10"/>
<line x1="64" y1="34" x2="64" y2="98"/>
<line x1="36" y1="54" x2="92" y2="54"/>
<path d="M26 76 C26 110 102 110 102 76"/>
</g></svg>'''


def receptor_svg() -> str:
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<g fill="none" stroke-linecap="round" stroke-linejoin="round">
<circle cx="64" cy="64" r="54" stroke="#6EE7FF" stroke-width="6"/>
<g stroke="#FF3CD2" stroke-width="8">
<circle cx="64" cy="34" r="7"/>
<line x1="64" y1="41" x2="64" y2="88"/>
<line x1="44" y1="56" x2="84" y2="56"/>
<path d="M38 74 C38 100 90 100 90 74"/>
</g></g></svg>'''


def loading_svg() -> str:
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#ff5ec4"/><stop offset="0.5" stop-color="#ff8ad8"/><stop offset="1" stop-color="#6ee7ff"/>
</linearGradient>
</defs>
<rect width="1920" height="1920" fill="url(#g)"/>
<g fill="none" stroke="#ffffff" stroke-width="26" stroke-linecap="round" stroke-linejoin="round" opacity="0.95">
<circle cx="960" cy="760" r="70"/>
<line x1="960" y1="830" x2="960" y2="1180"/>
<line x1="790" y1="930" x2="1130" y2="930"/>
<path d="M770 1100 C770 1300 1150 1300 1150 1100"/>
</g>
<text x="960" y="1470" font-family="Helvetica" font-size="190" font-weight="bold" fill="#ffffff" text-anchor="middle">Mermaid</text>
<text x="960" y="1560" font-family="Helvetica" font-size="54" fill="#ffffff" text-anchor="middle" opacity="0.9">Rocinante DDR</text>
</svg>'''


def render(svg: str, out: pathlib.Path, size: int) -> pathlib.Path:
    src = TMP / (out.stem + ".svg")
    src.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", str(size), "-o", str(TMP), str(src)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    produced = TMP / (src.name + ".png")
    if not produced.exists():
        raise SystemExit(f"qlmanage did not produce {produced}")
    out.parent.mkdir(parents=True, exist_ok=True)
    produced.replace(out)
    return out


def main() -> None:
    frames = []
    for i, colour in enumerate(COLOURS):
        p = render(anchor_svg(colour), TMP / f"frame{i}.png", 128)
        frames.append(p)

    # stack 8 frames vertically -> 128x1024
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for p in frames:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", "vstack=inputs=8", str(SKIN / "_arrow 1x8 (doubleres).png")]
    subprocess.run(cmd, check=True)

    render(receptor_svg(), SKIN / "_receptor (doubleres).png", 128)

    # loading/init background: render square, then centre-crop to 16:9
    big = render(loading_svg(), TMP / "loading.png", 1920)
    subprocess.run(["sips", "-c", "1080", "1920", str(big),
                    "--out", str(THEME / "Graphics/Mermaid Loading.png")],
                   check=True, stdout=subprocess.DEVNULL)

    # BGAnimations for init + song reload
    bg = '''local t = Def.ActorFrame {};
t[#t+1] = Def.Sprite {
    Texture="Mermaid Loading.png";
    InitCommand=function(self) self:center():setsize(SCREEN_WIDTH, SCREEN_HEIGHT); end;
};
return t;
'''
    for screen in ("ScreenInit background", "ScreenReloadSongs background"):
        d = THEME / "BGAnimations" / screen
        d.mkdir(parents=True, exist_ok=True)
        (d / "mermaid.lua").write_text(bg)

    # pink/aqua player colours
    main = THEME / "Scripts/Main.lua"
    if main.exists():
        s = main.read_text()
        s = s.replace("#FF773C", "#FF8AD8").replace("#FF3CD2", "#6EE7FF")
        main.write_text(s)

    print("built:")
    print(" ", SKIN / "_arrow 1x8 (doubleres).png")
    print(" ", SKIN / "_receptor (doubleres).png")
    print(" ", THEME / "Graphics/Mermaid Loading.png")


if __name__ == "__main__":
    main()
