#!/usr/bin/env python3
"""Build the fail-screen assets: trimmed video, pastel-pink background, and a
nautical title (Pirata One)."""
from __future__ import annotations

import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
GFX = ROOT / "Appearance/Themes/mermaid/Graphics"
SRC = pathlib.Path("/Users/callen/Desktop/hannah-video/VID_20260425_124758_144.mp4")
TMP = pathlib.Path(tempfile.mkdtemp(prefix="failscreen-"))


def render(svg: str, name: str) -> pathlib.Path:
    src = TMP / (name + ".svg")
    src.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", "1920", "-o", str(TMP), str(src)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return TMP / (src.name + ".png")


def main() -> None:
    GFX.mkdir(parents=True, exist_ok=True)

    # 1) trim the first second, H.264 720x1280
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-ss", "1", "-i", str(SRC),
        "-vf", "scale=720:1280",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20",
        "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart",
        str(GFX / "fail.mp4"),
    ], check=True)

    # 2) pastel-pink background with bubbles + rope border
    bg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#ffe6f3"/><stop offset="0.45" stop-color="#ffc9e4"/>
  <stop offset="1" stop-color="#a7f0ff"/>
</linearGradient></defs>
<rect width="1920" height="1920" fill="#ffe6f3"/>
<g transform="translate(0,420)">
<rect width="1920" height="1080" fill="url(#g)"/>
<g fill="#ffffff" opacity="0.35">
  <circle cx="220" cy="180" r="52"/><circle cx="1700" cy="160" r="34"/>
  <circle cx="1540" cy="880" r="60"/><circle cx="360" cy="900" r="26"/>
  <circle cx="980" cy="120" r="18"/><circle cx="760" cy="980" r="14"/>
</g>
<rect x="26" y="26" width="1868" height="1028" rx="42" fill="none"
      stroke="#c79a5b" stroke-width="10" stroke-dasharray="26 16"/>
<rect x="46" y="46" width="1828" height="988" rx="32" fill="none"
      stroke="#fff2d6" stroke-width="3" opacity="0.85"/>
</g></svg>'''
    big = render(bg, "bg")
    subprocess.run(["sips", "-c", "1080", "1920", str(big), "--out", str(GFX / "fail-bg.png")],
                   check=True, stdout=subprocess.DEVNULL)

    # 3) nautical title
    title = '''<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920">
<rect width="1920" height="1920" fill="#ff00ff"/>
<g font-family="Pirata One" text-anchor="middle">
<text x="960" y="946" font-size="210" fill="#7a2e4a" opacity="0.35">You failed</text>
<text x="960" y="940" font-size="210" fill="#fff6e0" stroke="#2a1a08" stroke-width="5" paint-order="stroke">You failed</text>
<text x="960" y="1086" font-size="120" fill="#7a2e4a" opacity="0.35">try again!</text>
<text x="960" y="1080" font-size="120" fill="#ffd166" stroke="#2a1a08" stroke-width="4" paint-order="stroke">try again!</text>
</g></svg>'''
    t = render(title, "title")
    cropped = TMP / "title-crop.png"
    subprocess.run(["sips", "-c", "480", "1920", str(t), "--out", str(cropped)],
                   check=True, stdout=subprocess.DEVNULL)
    # key out the magenta matte so only the text remains
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(cropped),
        "-vf", "format=rgba,colorkey=0xff00ff:0.30:0.08",
        "-frames:v", "1", str(GFX / "fail-title.png"),
    ], check=True)

    print("wrote", GFX / "fail.mp4", GFX / "fail-bg.png", GFX / "fail-title.png")


if __name__ == "__main__":
    main()
