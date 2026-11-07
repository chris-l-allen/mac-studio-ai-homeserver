#!/usr/bin/env python3
"""Find a purchasable track and hand off to the iTunes Store, then ingest it.

No store exposes a public "charge this card" API. This helper finds the exact
track, prints price and store URL, opens the store page in Music, and can wait
for the purchased file to appear in the media folder before running ingest.

The final charge is confirmed by the signed-in user in Music (password/Touch ID),
which is a platform requirement and cannot be automated.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys
import time
import urllib.parse
import urllib.request

HOME = pathlib.Path.home()
SEARCH = "https://itunes.apple.com/search"
MEDIA_ROOTS = (HOME / "Media", HOME / "Music" / "Music" / "Media.localized",
               HOME / "Music" / "Music" / "Media")
INGEST = pathlib.Path(__file__).with_name("ingest_song.py")


def search(term: str, country: str) -> list[dict]:
    q = urllib.parse.urlencode({"term": term, "entity": "song",
                                "limit": 25, "country": country})
    with urllib.request.urlopen(f"{SEARCH}?{q}", timeout=20) as r:
        return json.load(r).get("results", [])


def purchasable(r: dict) -> bool:
    price = r.get("trackPrice")
    return price is not None and price > 0 and bool(r.get("trackViewUrl"))


def score(r: dict, title: str, artist: str) -> int:
    t = (r.get("trackName") or "").lower().strip()
    a = (r.get("artistName") or "").lower().strip()
    s = 0
    if title:
        if t == title.lower().strip():
            s += 5
        elif title.lower().strip() in t:
            s += 2
    if artist:
        if a == artist.lower().strip():
            s += 4
        elif artist.lower().strip() in a:
            s += 2
    return s


def media_files() -> set[pathlib.Path]:
    found: set[pathlib.Path] = set()
    for root in MEDIA_ROOTS:
        if root.exists():
            found.update(p for p in root.rglob("*")
                         if p.suffix.lower() in (".m4a", ".m4p", ".mp3", ".flac"))
    return found


def wait_for_purchase(before: set[pathlib.Path], title: str,
                      timeout: int) -> pathlib.Path | None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        new = media_files() - before
        for p in sorted(new, key=lambda x: x.stat().st_mtime, reverse=True):
            if title.lower().replace(" ", "") in p.name.lower().replace(" ", ""):
                return p
        if new:
            return sorted(new, key=lambda x: x.stat().st_mtime, reverse=True)[0]
        time.sleep(3)
    return None


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Find/open a purchasable track and optionally ingest it.")
    ap.add_argument("--title", required=True)
    ap.add_argument("--artist")
    ap.add_argument("--country", default="US")
    ap.add_argument("--pick", type=int, default=1)
    ap.add_argument("--list", action="store_true", help="list matches only")
    ap.add_argument("--open", action="store_true", help="open store page in Music")
    ap.add_argument("--wait", type=int, default=0, metavar="SECONDS",
                    help="wait for the purchased file to appear")
    ap.add_argument("--ingest", action="store_true",
                    help="run ingest_song.py on the purchased file")
    ap.add_argument("--pack", default="Hannah's Picks")
    ap.add_argument("--file", type=pathlib.Path,
                    help="skip waiting; ingest this file directly")
    args = ap.parse_args()

    if args.file:
        run_ingest(args.file, args.title, args.artist, args.pack)
        return

    term = f"{args.title} {args.artist or ''}".strip()
    try:
        raw = search(term, args.country)
    except Exception as exc:
        sys.exit(f"search failed: {exc}")

    results = [r for r in raw if purchasable(r)]
    results.sort(key=lambda r: score(r, args.title, args.artist or ""),
                 reverse=True)
    if not results:
        sys.exit("no purchasable match (Apple Music streams have no trackPrice)")

    print(f"{'#':>2}  {'track':40.40} {'artist':22.22} {'price':>10}  album")
    for i, r in enumerate(results[:10], 1):
        price = f"{r.get('currency', '')} {r.get('trackPrice')}"
        print(f"{i:>2}  {r['trackName'][:40]:40.40} "
              f"{r['artistName'][:22]:22.22} {price:>10}  "
              f"{(r.get('collectionName') or '')[:30]}")
    if args.list:
        return

    if not 1 <= args.pick <= min(10, len(results)):
        sys.exit(f"--pick must be 1..{min(10, len(results))}")

    chosen = results[args.pick - 1]
    url = chosen["trackViewUrl"]
    seconds = int((chosen.get("trackTimeMillis") or 0) / 1000)
    print(f"\nchosen : {chosen['trackName']} — {chosen['artistName']} "
          f"({seconds}s)")
    print(f"price  : {chosen.get('currency', '')} {chosen['trackPrice']}")
    print(f"store  : {url}")
    print("auth   : Store account already signed in; Music will ask you to")
    print("         confirm the charge (password/Touch ID). This step is not")
    print("         automatable by any store.")

    before = media_files()
    if args.open:
        subprocess.run(["open", url], check=False)
        print("opened the store page in Music")

    if args.wait:
        print(f"waiting up to {args.wait}s for the purchased file…")
        path = wait_for_purchase(before, chosen["trackName"], args.wait)
        if not path:
            print("no new file yet; re-run with --file PATH once it downloads")
            return
        if path.suffix.lower() == ".m4p":
            sys.exit(f"downloaded file is DRM-protected: {path}")
        print(f"found  : {path}")
        if args.ingest:
            run_ingest(path, chosen["trackName"], chosen["artistName"],
                       args.pack, bpm=None)


def run_ingest(path: pathlib.Path, title: str, artist: str | None,
               pack: str, bpm: float | None = None) -> None:
    cmd = [sys.executable, str(INGEST), "--file", str(path.expanduser()),
           "--title", title, "--pack", pack]
    if artist:
        cmd += ["--artist", artist]
    if bpm:
        cmd += ["--bpm", str(bpm)]
    print("ingest :", " ".join(cmd))
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
