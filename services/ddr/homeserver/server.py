#!/usr/bin/env python3
"""HomeServer — dependency-free static server for the HomeDDR project.

Serves a landing page plus the shared song and media libraries over the LAN.

Endpoints:
    /            landing page (lists song packs and media)
    /songs/      browse / download song packs
    /media/      browse / download karaoke and audio
    /health      JSON health check

Configure with environment variables:
    HOMEDDR_HOST  bind address (default 127.0.0.1; use 0.0.0.0 for LAN)
    HOMEDDR_PORT  port (default 8787)
    HOMEDDR_ROOT  content root (default: repo root, one level above this file)
"""

from __future__ import annotations

import html
import json
import os
import re
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(os.environ.get("HOMEDDR_ROOT", Path(__file__).resolve().parent.parent))
HOST = os.environ.get("HOMEDDR_HOST", "127.0.0.1")
PORT = int(os.environ.get("HOMEDDR_PORT", "8787"))

SECTIONS = (
    ("songpacks", "Song packs", "StepMania / OutFox packs (.sm, .ssc)"),
    ("media", "Media", "Karaoke backing tracks and audio"),
)

# Audio types the stdlib table misses (notably .opus from OutFox Serenity)
SimpleHTTPRequestHandler.extensions_map.update({
    ".mp3": "audio/mpeg",
    ".ogg": "audio/ogg",
    ".opus": "audio/ogg",
    ".wav": "audio/wav",
})


def list_files(folder: Path) -> list[str]:
    if not folder.is_dir():
        return []
    return sorted(p.name for p in folder.iterdir() if not p.name.startswith("."))


def render_landing() -> str:
    blocks = []
    for slug, title, subtitle in SECTIONS:
        files = list_files(ROOT / slug)
        if files:
            items = "\n".join(
                f'<li><a href="/{slug}/{html.escape(name)}">{html.escape(name)}</a></li>'
                for name in files
            )
            body = f"<ul>{items}</ul>"
        else:
            body = '<p class="empty">Nothing here yet.</p>'
        blocks.append(
            f'<section><h2>{html.escape(title)}</h2>'
            f'<p class="sub">{html.escape(subtitle)}</p>{body}</section>'
        )

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>HomeDDR</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font: 16px/1.5 -apple-system, system-ui, sans-serif; max-width: 720px;
         margin: 3rem auto; padding: 0 1.25rem; }}
  h1 {{ margin-bottom: .25rem; }}
  .tag {{ color: #888; margin-top: 0; }}
  section {{ margin-top: 2rem; }}
  .sub {{ color: #888; margin: .25rem 0 .75rem; }}
  .empty {{ color: #999; font-style: italic; }}
  a {{ overflow-wrap: anywhere; }}
</style>
</head>
<body>
  <h1>HomeDDR</h1>
  <p class="tag">Dance + song library, served locally.</p>
  {''.join(blocks)}
</body>
</html>
"""


AUDIO_EXT = {".ogg", ".mp3", ".opus", ".wav"}


def scan_tracks() -> list[dict]:
    """Live scan of songpacks so the player reflects new songs immediately."""
    tracks = []
    for song in sorted((ROOT / "songpacks").glob("*/*")):
        if not song.is_dir():
            continue
        audio = next((f for f in sorted(song.iterdir())
                      if f.is_file() and f.suffix.lower() in AUDIO_EXT), None)
        if not audio:
            continue
        tracks.append({
            "title": song.name,
            "pack": song.parent.name,
            "file": str(audio.relative_to(ROOT)),
        })
    return tracks


class RangeFile:
    """Wrapper that limits a file read to a byte range."""

    def __init__(self, f, length: int):
        self.f = f
        self.remaining = length

    def read(self, n: int = -1) -> bytes:
        if self.remaining <= 0:
            return b""
        if n is None or n < 0 or n > self.remaining:
            n = self.remaining
        data = self.f.read(n)
        self.remaining -= len(data)
        return data

    def close(self) -> None:
        self.f.close()


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self) -> None:  # noqa: N802 (stdlib naming)
        if self.path in ("/", "/index.html"):
            self._send_html(render_landing())
        elif self.path == "/health":
            self._send_json({"status": "ok", "root": str(ROOT)})
        elif self.path.split("?", 1)[0] == "/api/tracks":
            self._send_json(scan_tracks())
        else:
            super().do_GET()

    def send_head(self):
        """Serve files with HTTP Range support so audio/video can be seeked."""
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            return super().send_head()
        ctype = self.guess_type(path)
        try:
            f = open(path, "rb")
        except OSError:
            self.send_error(404, "File not found")
            return None
        try:
            fs = os.fstat(f.fileno())
            size = fs.st_size
            rng = self.headers.get("Range")
            m = re.match(r"bytes=(\d*)-(\d*)$", rng.strip()) if rng else None
            if m:
                start_s, end_s = m.groups()
                if start_s == "":
                    length = int(end_s or 0)
                    start, end = max(0, size - length), size - 1
                else:
                    start = int(start_s)
                    end = int(end_s) if end_s else size - 1
                end = min(end, size - 1)
                if start > end or start >= size:
                    self.send_error(416, "Requested Range Not Satisfiable")
                    f.close()
                    return None
                length = end - start + 1
                f.seek(start)
                self.send_response(206)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
                self.send_header("Content-Length", str(length))
                self.send_header("Accept-Ranges", "bytes")
                self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
                self.end_headers()
                return RangeFile(f, length)
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(size))
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
            self.end_headers()
            return f
        except Exception:
            f.close()
            raise

    def _send_html(self, markup: str) -> None:
        payload = markup.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _send_json(self, data) -> None:
        payload = json.dumps(data).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"HomeServer: http://{HOST}:{PORT}  (root: {ROOT})")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping HomeServer.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
