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
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(os.environ.get("HOMEDDR_ROOT", Path(__file__).resolve().parent.parent))
HOST = os.environ.get("HOMEDDR_HOST", "127.0.0.1")
PORT = int(os.environ.get("HOMEDDR_PORT", "8787"))

SECTIONS = (
    ("songs", "Song packs", "StepMania / OutFox packs (.sm, .ssc)"),
    ("media", "Media", "Karaoke backing tracks and audio"),
)


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


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self) -> None:  # noqa: N802 (stdlib naming)
        if self.path in ("/", "/index.html"):
            self._send_html(render_landing())
        elif self.path == "/health":
            self._send_json({"status": "ok", "root": str(ROOT)})
        else:
            super().do_GET()

    def _send_html(self, markup: str) -> None:
        payload = markup.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _send_json(self, data: dict) -> None:
        payload = json.dumps(data).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
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
