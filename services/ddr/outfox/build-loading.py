#!/usr/bin/env python3
"""Compose the Mermaid loading screen from the sourced art.

Art:
  #2  Rawpixel CC0 mermaid illustration        -> medallion (left)
  #6  The Little Mermaid, Elena Ringo, CC BY 4.0 -> framed portrait (right)
"""
from __future__ import annotations

import base64
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
ART = ROOT / "art-candidates"
THEME = ROOT / "Appearance/Themes/mermaid"
TMP = pathlib.Path(tempfile.mkdtemp(prefix="merload-"))


def b64(path: pathlib.Path, mime: str) -> str:
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def main() -> None:
    ringo = ART / "elena-ringo.jpg"
    raw = ART / "rawpixel-207.jpg"
    if not ringo.exists() or not raw.exists():
        raise SystemExit("missing source art in art-candidates/")

    bg = TMP / "bg.jpg"
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(ringo),
        "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,"
               "crop=1920:1080,gblur=sigma=38,eq=brightness=-0.18:saturation=1.1",
        "-q:v", "3", str(bg),
    ], check=True)

    fg = TMP / "fg.png"
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(ringo),
        "-vf", "scale=-1:960", str(fg),
    ], check=True)

    m2 = TMP / "m2.png"
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(raw),
        "-vf", "scale=640:640", str(m2),
    ], check=True)

    # painting frame: keep portrait aspect at height 960 -> ~705 wide
    pw, ph = 706, 962
    px, py = 1120, 58

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
<defs>
  <linearGradient id="ov" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#4a0f42" stop-opacity="0.75"/>
    <stop offset="0.55" stop-color="#7a1b64" stop-opacity="0.45"/>
    <stop offset="1" stop-color="#0a3b4a" stop-opacity="0.8"/>
  </linearGradient>
  <linearGradient id="wave" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#6ee7ff" stop-opacity="0.35"/>
    <stop offset="1" stop-color="#1a0d22" stop-opacity="0.0"/>
  </linearGradient>
  <clipPath id="pclip"><rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="26"/></clipPath>
  <clipPath id="mclip"><circle cx="410" cy="640" r="196"/></clipPath>
  <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
    <feGaussianBlur stdDeviation="10" result="b"/>
    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
</defs>

<image x="0" y="0" width="1920" height="1080" href="{b64(bg, 'image/jpeg')}" preserveAspectRatio="xMidYMid slice"/>
<rect x="0" y="0" width="1920" height="1080" fill="url(#ov)"/>

<!-- bubbles -->
<g fill="#ffffff" opacity="0.12">
  <circle cx="180" cy="180" r="42"/><circle cx="980" cy="130" r="26"/>
  <circle cx="1250" cy="900" r="34"/><circle cx="760" cy="860" r="20"/>
  <circle cx="1540" cy="240" r="18"/><circle cx="90" cy="760" r="16"/>
  <circle cx="880" cy="300" r="12"/><circle cx="300" cy="420" r="10"/>
</g>

<!-- painting -->
<g filter="url(#glow)">
  <rect x="{px-8}" y="{py-8}" width="{pw+16}" height="{ph+16}" rx="32" fill="#140a1a" opacity="0.85"/>
</g>
<image x="{px}" y="{py}" width="{pw}" height="{ph}" clip-path="url(#pclip)"
       href="{b64(fg, 'image/png')}" preserveAspectRatio="xMidYMid slice"/>
<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="26" fill="none" stroke="#ff8ad8" stroke-width="6" opacity="0.9"/>

<!-- medallion -->
<circle cx="410" cy="640" r="210" fill="#ffffff"/>
<image x="214" y="444" width="392" height="392" clip-path="url(#mclip)"
       href="{b64(m2, 'image/png')}" preserveAspectRatio="xMidYMid slice"/>
<circle cx="410" cy="640" r="200" fill="none" stroke="#6ee7ff" stroke-width="10"/>
<circle cx="410" cy="640" r="214" fill="none" stroke="#ff8ad8" stroke-width="4" opacity="0.8"/>

<!-- title -->
<text x="120" y="300" font-family="Helvetica" font-size="150" font-weight="bold"
      fill="#ffffff" letter-spacing="2">Mermaid</text>
<text x="124" y="372" font-family="Helvetica" font-size="46" fill="#ffd6f4"
      letter-spacing="6">ROCINANTE DDR</text>

<!-- waves -->
<path d="M0 940 C 320 880 520 1010 860 960 C 1200 910 1500 1020 1920 950 L1920 1080 L0 1080 Z" fill="url(#wave)"/>
<path d="M0 1000 C 360 960 640 1040 980 1000 C 1320 960 1600 1040 1920 1000 L1920 1080 L0 1080 Z" fill="#6ee7ff" opacity="0.10"/>
</svg>'''

    src = TMP / "loading.svg"
    src.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", "1920", "-o", str(TMP), str(src)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    produced = TMP / (src.name + ".png")
    subprocess.run(["sips", "-c", "1080", "1920", str(produced),
                    "--out", str(THEME / "Graphics/Mermaid Loading.png")],
                   check=True, stdout=subprocess.DEVNULL)
    print("wrote", THEME / "Graphics/Mermaid Loading.png")


if __name__ == "__main__":
    main()
