#!/usr/bin/env python3
"""Ingest a purchased song into the DDR (OutFox) library.

Pipeline: inspect -> audio -> artwork -> tempo/offset -> charts -> package -> verify.

Requires: ffmpeg/ffprobe, Python 3 standard library. Optional: aubio (better BPM).
macOS: sips/qlmanage for artwork.

Example:
  python3 ingest_song.py --file ~/Music/track.m4a \
      --title "Dumb Ways to Die" --artist "Tangerine Kitty" \
      --pack "Hannah's Picks" --bpm 120
"""
from __future__ import annotations

import argparse
import array
import json
import math
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import wave

HOME = pathlib.Path.home()
DEFAULT_LIBRARY = HOME / "mac-studio-ai-homeserver/services/ddr/songpacks"
CACHE = HOME / ".cache/ddr-song-ingest/bpm.json"
CHART_EXT = {".ssc", ".sm", ".dwi"}


# ---------------------------------------------------------------- helpers
def run(cmd, **kw):
    return subprocess.run(cmd, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True, **kw)


def ffprobe(path: pathlib.Path) -> dict:
    out = run(["ffprobe", "-v", "error", "-print_format", "json",
               "-show_format", "-show_streams", str(path)]).stdout
    return json.loads(out)


def tags_of(info: dict) -> dict:
    tags = (info.get("format") or {}).get("tags") or {}
    return {k.lower(): v for k, v in tags.items()}


def duration_of(info: dict) -> float:
    try:
        return float((info.get("format") or {}).get("duration") or 0)
    except (TypeError, ValueError):
        return 0.0


def sanitize(s: str) -> str:
    s = s.replace("/", "-").replace(":", "-").replace(";", "-")
    s = re.sub(r'[\\?*"<>|]', "", s)
    s = re.sub(r"\s+", " ", s).strip(" .-")
    return s


def find_cover(info: dict, src: pathlib.Path, out: pathlib.Path) -> bool:
    has_video = any(s.get("codec_type") == "video" for s in info.get("streams", []))
    if not has_video:
        return False
    try:
        run(["ffmpeg", "-v", "error", "-y", "-i", str(src),
             "-map", "0:v:0", "-frames:v", "1", "-c", "copy", str(out)])
        return out.exists() and out.stat().st_size > 0
    except subprocess.CalledProcessError:
        return False


def placeholder_cover(title: str, artist: str, out: pathlib.Path) -> None:
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#ff8ad8"/><stop offset="0.55" stop-color="#ff3cd2"/>
<stop offset="1" stop-color="#6ee7ff"/></linearGradient></defs>
<rect width="1024" height="1024" fill="url(#g)"/>
<circle cx="512" cy="380" r="120" fill="none" stroke="#fff" stroke-width="16" opacity="0.9"/>
<line x1="512" y1="500" x2="512" y2="760" stroke="#fff" stroke-width="16"/>
<line x1="400" y1="590" x2="624" y2="590" stroke="#fff" stroke-width="16"/>
<path d="M360 700 C360 860 664 860 664 700" fill="none" stroke="#fff" stroke-width="16"/>
<text x="512" y="900" font-family="Pirata One, Helvetica" font-size="72" font-weight="bold"
 fill="#fff" text-anchor="middle">{escape(title)}</text>
<text x="512" y="962" font-family="Helvetica" font-size="34" fill="#fff"
 text-anchor="middle" opacity="0.9">{escape(artist)}</text>
</svg>'''
    tmp = out.with_suffix(".svg")
    tmp.write_text(svg)
    subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", str(out.parent), str(tmp)],
                   check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    produced = out.parent / (tmp.name + ".png")
    if produced.exists():
        produced.replace(out)
    tmp.unlink(missing_ok=True)


def escape(s: str) -> str:
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def scale_crop(src: pathlib.Path, dst: pathlib.Path, w: int, h: int,
               blur: bool = False) -> None:
    vf = (f"scale={w}:{h}:force_original_aspect_ratio=increase,"
          f"crop={w}:{h}")
    if blur:
        vf += ",gblur=sigma=18,eq=brightness=-0.18:saturation=1.1"
    run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vf", vf,
         "-frames:v", "1", str(dst)])


# ---------------------------------------------------------------- tempo
def decode_mono(src: pathlib.Path, out: pathlib.Path, rate: int = 8000) -> None:
    run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vn", "-ac", "1",
         "-ar", str(rate), "-f", "wav", str(out)])


def detect_tempo(src: pathlib.Path) -> tuple[float, float, str]:
    """Return (bpm, first_beat_seconds, confidence). Best-effort, no deps."""
    with tempfile.TemporaryDirectory(prefix="tempo-") as td:
        wav = pathlib.Path(td) / "a.wav"
        try:
            decode_mono(src, wav)
            with wave.open(str(wav), "rb") as w:
                rate = w.getframerate()
                data = w.readframes(w.getnframes())
        except Exception:
            return 120.0, 0.0, "none"
    pcm = array.array("h")
    pcm.frombytes(data[: len(data) - (len(data) % 2)])
    frame, hop = 256, 128
    energies = []
    for i in range(0, len(pcm) - frame, hop):
        s = 0
        for j in range(i, i + frame, 8):
            v = pcm[j]
            s += v * v
        energies.append(math.log1p(s))
    onset = [max(0.0, energies[i] - energies[i - 1]) for i in range(1, len(energies))]
    if not onset:
        return 120.0, 0.0, "none"
    fps = rate / hop
    lo, hi = int(fps * 60 / 200), int(fps * 60 / 60)
    best = None
    for lag in range(max(1, lo), hi + 1):
        if lag >= len(onset):
            continue
        c = sum(onset[i] * onset[i + lag] for i in range(len(onset) - lag))
        c /= (len(onset) - lag)
        if best is None or c > best[1]:
            best = (lag, c)
    if not best or best[1] <= 0:
        return 120.0, 0.0, "none"
    bpm = 60.0 * fps / best[0]
    while bpm < 80:
        bpm *= 2
    while bpm > 160:
        bpm /= 2
    thresh = max(onset) * 0.5
    first = next((i for i, v in enumerate(onset) if v >= thresh), 0)
    offset = first * hop / rate
    mean = sum(onset) / len(onset)
    conf = "high" if best[1] > mean * 8 else ("medium" if best[1] > mean * 3 else "low")
    return round(bpm, 2), round(offset, 3), conf


def load_cache() -> dict:
    try:
        return json.loads(CACHE.read_text())
    except Exception:
        return {}


def save_cache(key: str, bpm: float) -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    data = load_cache()
    data[key] = bpm
    CACHE.write_text(json.dumps(data, indent=1))


# ---------------------------------------------------------------- charts
BEGINNER = [["1000", "0010"], ["0100", "0001"], ["1000", "0001"], ["0100", "0010"]]
EASY = [
    ["1000", "0100", "0010", "0001"],
    ["0001", "0010", "0100", "1000"],
    ["1000", "0010", "0100", "0001"],
    ["0100", "0001", "1000", "0010"],
]
MEDIUM = [
    ["1000", "0100", "0010", "0001", "1000", "0010", "0100", "0001"],
    ["0100", "0010", "0100", "0001", "1000", "0100", "0010", "0001"],
]


def chart_block(difficulty: str, meter: int, patterns: list[list[str]],
                measures: int) -> str:
    rows = []
    for m in range(measures):
        rows.extend(patterns[m % len(patterns)])
        rows.append(",")
    if rows and rows[-1] == ",":
        rows[-1] = ";"
    return (
        "#NOTEDATA:;\n#CHARTNAME:;\n#STEPSTYPE:dance-single;\n"
        "#DESCRIPTION:auto-generated;\n#CHARTSTYLE:;\n"
        f"#DIFFICULTY:{difficulty};\n#METER:{meter};\n"
        "#RADARVALUES:" + ",".join(["0"] * 30) + ";\n#CREDIT:ddr-song-ingest;\n#NOTES:\n"
        + "\n".join(rows) + "\n"
    )


def make_ssc(title: str, artist: str, genre: str, audio: str, bpm: float,
             offset: float, duration: float, measures: int) -> str:
    sample_start = max(0.0, offset + (duration - offset) * 0.3)
    header = f"""#VERSION:0.83;
#TITLE:{title};
#SUBTITLE:;
#ARTIST:{artist};
#TITLETRANSLIT:;
#SUBTITLETRANSLIT:;
#ARTISTTRANSLIT:;
#GENRE:{genre};
#ORIGIN:;
#CREDIT:ddr-song-ingest;
#BANNER:banner.png;
#BACKGROUND:bg.png;
#PREVIEWVID:;
#JACKET:jacket.png;
#CDIMAGE:;
#DISCIMAGE:;
#LYRICSPATH:;
#CDTITLE:;
#MUSIC:{audio};
#OFFSET:{offset:.6f};
#SAMPLESTART:{sample_start:.3f};
#SAMPLELENGTH:20.000;
#SELECTABLE:YES;
#BPMS:0.000={bpm:.3f};
#STOPS:;
#DELAYS:;
#WARPS:;
#TIMESIGNATURES:0.000=4=4;
#TICKCOUNTS:0.000=4;
#COMBOS:0.000=1;
#SPEEDS:0.000=1.000=0.000=0;
#SCROLLS:0.000=1.000;
#FAKES:;
#LABELS:0.000=Song Start;
#BGCHANGES:;
#KEYSOUNDS:;
#ATTACKS:
;
"""
    return (header
            + chart_block("Beginner", 1, BEGINNER, measures)
            + chart_block("Easy", 3, EASY, measures)
            + chart_block("Medium", 5, MEDIUM, max(1, measures)))


# ---------------------------------------------------------------- main
def main() -> None:
    ap = argparse.ArgumentParser(description="Ingest a purchased song into DDR.")
    ap.add_argument("--file", required=True, type=pathlib.Path)
    ap.add_argument("--title")
    ap.add_argument("--artist")
    ap.add_argument("--genre", default="Pop")
    ap.add_argument("--art", type=pathlib.Path, help="cover image override")
    ap.add_argument("--pack", default="Hannah's Picks")
    ap.add_argument("--bpm", type=float)
    ap.add_argument("--offset", type=float)
    ap.add_argument("--library", type=pathlib.Path, default=DEFAULT_LIBRARY)
    ap.add_argument("--normalize", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-player", action="store_true")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    src = args.file.expanduser().resolve()
    if not src.exists():
        sys.exit(f"file not found: {src}")
    if src.suffix.lower() == ".m4p":
        sys.exit("DRM-protected .m4p file — purchase the DRM-free iTunes Store version (.m4a).")

    info = ffprobe(src)
    tags = tags_of(info)
    duration = duration_of(info)
    title = (args.title or tags.get("title") or src.stem).replace(";", "-").strip()
    artist = (args.artist or tags.get("artist") or "Unknown Artist").replace(";", "-").strip()
    album = tags.get("album", "")
    genre = (args.genre or tags.get("genre", "Pop")).replace(";", "-").strip()

    # BPM / offset
    cache = load_cache()
    key = f"{artist}|{title}".lower()
    detected_bpm = detected_off = None
    conf = "manual"
    if args.bpm is None:
        if key in cache:
            detected_bpm, conf = cache[key], "cached"
        else:
            detected_bpm, detected_off, conf = detect_tempo(src)
    bpm = args.bpm or detected_bpm or 120.0
    offset = args.offset if args.offset is not None else (detected_off or 0.0)

    measure_sec = 4 * 60 / bpm
    measures = max(1, int(max(0.0, duration - offset) / measure_sec))

    folder = args.library / sanitize(args.pack) / sanitize(f"{artist} - {title}")
    if folder.exists() and not args.force:
        sys.exit(f"already exists: {folder} (use --force to overwrite)")

    print(f"source : {src}")
    print(f"song   : {artist} - {title}")
    print(f"pack   : {args.pack}")
    print(f"length : {duration:.1f}s")
    print(f"bpm    : {bpm:.2f} ({conf})  offset: {offset:.3f}s  measures: {measures}")
    if conf in ("low", "none"):
        print("warning: low-confidence tempo; pass --bpm to correct it.")
    if args.dry_run:
        print(f"would create: {folder}")
        return

    folder.mkdir(parents=True, exist_ok=True)

    # audio
    audio_name = "audio.ogg"
    af = ["-af", "loudnorm=I=-16:TP=-1.5:LRA=11"] if args.normalize else []
    encoders = run(["ffmpeg", "-hide_banner", "-encoders"]).stdout
    if "libvorbis" in encoders:
        codec, extra = "libvorbis", []
    elif re.search(r"\bvorbis\b", encoders):
        codec, extra = "vorbis", ["-strict", "-2"]
    else:
        codec, extra = None, []
    done = False
    if codec:
        try:
            run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vn",
                 "-map", "0:a:0", *af, "-c:a", codec, "-q:a", "5", *extra,
                 str(folder / audio_name)])
            done = True
        except subprocess.CalledProcessError:
            pass
    if not done:
        audio_name = "audio.mp3"
        run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vn",
             "-map", "0:a:0", *af, "-c:a", "libmp3lame", "-b:a", "192k",
             str(folder / audio_name)])
    audio_dur = duration_of(ffprobe(folder / audio_name)) or duration

    # artwork
    cover = folder / "cover.jpg"
    if args.art:
        run(["ffmpeg", "-v", "error", "-y", "-i", str(args.art.expanduser()),
             "-frames:v", "1", str(cover)])
    elif not find_cover(info, src, cover):
        placeholder_cover(title, artist, cover)
    scale_crop(cover, folder / "jacket.png", 256, 256)
    scale_crop(cover, folder / "banner.png", 512, 160)
    scale_crop(cover, folder / "bg.png", 1280, 720, blur=True)

    # charts
    ssc = make_ssc(title, artist, genre, audio_name, bpm, offset, audio_dur, measures)
    (folder / (sanitize(title) + ".ssc")).write_text(ssc)

    # cache
    if args.bpm is None and conf not in ("cached",):
        save_cache(key, bpm)

    # validate
    for name in [audio_name, "jacket.png", "banner.png", "bg.png"]:
        if not (folder / name).exists():
            sys.exit(f"missing output: {folder / name}")
    text = (folder / (sanitize(title) + ".ssc")).read_text()
    for tag in ("#TITLE:", "#ARTIST:", "#MUSIC:", "#BPMS:", "#NOTES:"):
        if tag not in text:
            sys.exit(f"invalid .ssc: missing {tag}")
    print(f"created: {folder}")

    # player
    if not args.no_player:
        repo = args.library.parent.parent.parent
        player = repo / "scripts/build-player.py"
        if player.exists():
            run([sys.executable, str(player)])
            print("player regenerated")


if __name__ == "__main__":
    main()
