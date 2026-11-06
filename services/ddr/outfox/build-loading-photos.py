#!/usr/bin/env python3
"""Mermaid loading screen with Hannah's 2026 photos.

Sources:
  ~/Desktop/images/*.jpg           (2026-09-07)
  art-candidates/elena-ringo.jpg   (#6, CC BY 4.0)
  art-candidates/rawpixel-207.jpg  (#2, CC0)
"""
from __future__ import annotations

import base64
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
THEME = ROOT / "Appearance/Themes/mermaid"
ART = ROOT / "art-candidates"
PHOTOS = pathlib.Path("/Users/callen/Desktop/hannah-photos")
TMP = pathlib.Path(tempfile.mkdtemp(prefix="merphotos-"))


def b64(path: pathlib.Path, mime: str) -> str:
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def square(src: pathlib.Path, size: int, out: pathlib.Path) -> pathlib.Path:
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(src),
        "-vf", f"scale={size}:{size}:force_original_aspect_ratio=increase,crop={size}:{size}",
        "-q:v", "3", str(out),
    ], check=True)
    return out


def main() -> None:
    photo_files = sorted(PHOTOS.glob("*.jpg"))[:6]
    if not photo_files:
        raise SystemExit("no photos in ~/Desktop/images")

    bg = TMP / "bg.jpg"
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(ART / "elena-ringo.jpg"),
        "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,"
               "crop=1920:1080,gblur=sigma=38,eq=brightness=-0.18:saturation=1.1",
        "-q:v", "3", str(bg),
    ], check=True)
    fg = TMP / "fg.png"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(ART / "elena-ringo.jpg"),
                    "-vf", "scale=-1:960", str(fg)], check=True)
    m2 = square(ART / "rawpixel-207.jpg", 460, TMP / "m2.jpg")
    cells = [square(p, 420, TMP / f"c{i}.jpg") for i, p in enumerate(photo_files)]

    pw, ph, px, py = 706, 962, 1120, 58
    cell, gap = 210, 14
    grid_x, grid_y = 110, 310

    cell_svg = ""
    for i, c in enumerate(cells):
        x = grid_x + (i % 3) * (cell + gap)
        y = grid_y + (i // 3) * (cell + gap)
        cell_svg += f'''<g transform="translate({x},{y})">
<image x="0" y="0" width="{cell}" height="{cell}" clip-path="url(#cellClip)" href="{b64(c, 'image/jpeg')}" preserveAspectRatio="xMidYMid slice"/>
<rect x="0" y="0" width="{cell}" height="{cell}" rx="12" fill="none" stroke="#ffffff" stroke-width="5"/>
</g>'''

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920" viewBox="0 0 1920 1920">
<defs>
  <linearGradient id="ov" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#4a0f42" stop-opacity="0.78"/>
    <stop offset="0.55" stop-color="#7a1b64" stop-opacity="0.45"/>
    <stop offset="1" stop-color="#0a3b4a" stop-opacity="0.82"/>
  </linearGradient>
  <linearGradient id="wave" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#6ee7ff" stop-opacity="0.35"/>
    <stop offset="1" stop-color="#1a0d22" stop-opacity="0"/>
  </linearGradient>
  <clipPath id="pclip"><rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="26"/></clipPath>
  <clipPath id="cellClip"><rect x="0" y="0" width="{cell}" height="{cell}" rx="12"/></clipPath>
  <clipPath id="mclip"><circle cx="900" cy="530" r="112"/></clipPath>
  <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
    <feGaussianBlur stdDeviation="10" result="b"/>
    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
</defs>

<rect width="1920" height="1920" fill="#140b18"/>
<g transform="translate(0,420)">
<image x="0" y="0" width="1920" height="1080" href="{b64(bg, 'image/jpeg')}" preserveAspectRatio="xMidYMid slice"/>
<rect width="1920" height="1080" fill="url(#ov)"/>

<g fill="#ffffff" opacity="0.12">
  <circle cx="180" cy="150" r="40"/><circle cx="980" cy="130" r="24"/>
  <circle cx="1250" cy="900" r="32"/><circle cx="760" cy="900" r="18"/>
  <circle cx="1540" cy="240" r="16"/><circle cx="80" cy="800" r="14"/>
</g>

<text x="110" y="205" font-family="Helvetica" font-size="150" font-weight="bold" fill="#ffffff">Hannah</text>
<text x="114" y="268" font-family="Helvetica" font-size="40" fill="#ffd6f4" letter-spacing="5">MERMAID · ROCINANTE DDR</text>

{cell_svg}

<!-- #2 medallion -->
<circle cx="900" cy="530" r="118" fill="#ffffff"/>
<image x="788" y="418" width="224" height="224" clip-path="url(#mclip)" href="{b64(m2, 'image/jpeg')}" preserveAspectRatio="xMidYMid slice"/>
<circle cx="900" cy="530" r="112" fill="none" stroke="#6ee7ff" stroke-width="8"/>
<circle cx="900" cy="530" r="120" fill="none" stroke="#ff8ad8" stroke-width="3" opacity="0.8"/>

<!-- #6 painting -->
<g filter="url(#glow)">
  <rect x="{px-8}" y="{py-8}" width="{pw+16}" height="{ph+16}" rx="32" fill="#140a1a" opacity="0.85"/>
</g>
<image x="{px}" y="{py}" width="{pw}" height="{ph}" clip-path="url(#pclip)" href="{b64(fg, 'image/png')}" preserveAspectRatio="xMidYMid slice"/>
<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="26" fill="none" stroke="#ff8ad8" stroke-width="6" opacity="0.9"/>

<path d="M0 940 C 320 880 520 1010 860 960 C 1200 910 1500 1020 1920 950 L1920 1080 L0 1080 Z" fill="url(#wave)"/>
<path d="M0 1000 C 360 960 640 1040 980 1000 C 1320 960 1600 1040 1920 1000 L1920 1080 L0 1080 Z" fill="#6ee7ff" opacity="0.10"/>
</g></svg>'''

    src = TMP / "loading.svg"
    src.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", "1920", "-o", str(TMP), str(src)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    produced = TMP / (src.name + ".png")
    out = THEME / "Graphics/Mermaid Loading.local.png"
    subprocess.run(["sips", "-c", "1080", "1920", str(produced),
                    "--out", str(out)],
                   check=True, stdout=subprocess.DEVNULL)
    print("wrote", out)


if __name__ == "__main__":
    main()
