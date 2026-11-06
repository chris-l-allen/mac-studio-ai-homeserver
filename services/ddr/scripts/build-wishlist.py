#!/usr/bin/env python3
"""Build media/wishlist.html: 30-second iTunes previews for Danny Go and the
songs on Hannah's playlist, with checkboxes + buy links, so she can pick."""
from __future__ import annotations

import html
import json
import pathlib
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "media" / "wishlist.html"

QUERIES = [
    ("Danny Go", "song", 60),
    ("We Don't Talk About Bruno Encanto", "song", 4),
    ("Taylor Swift The Fate of Ophelia", "song", 3),
    ("Electric Callboy Elevator Operator", "song", 3),
]


def itunes(term: str, entity: str, limit: int):
    url = ("https://itunes.apple.com/search?term=" + urllib.parse.quote(term)
           + f"&entity={entity}&country=CA&limit={limit}")
    try:
        with urllib.request.urlopen(url, timeout=25) as r:
            return json.load(r).get("results", [])
    except Exception:
        return []


def main() -> None:
    tracks, seen = [], set()
    for term, entity, limit in QUERIES:
        for r in itunes(term, entity, limit):
            tid = r.get("trackId")
            preview = r.get("previewUrl")
            if not tid or tid in seen or not preview:
                continue
            seen.add(tid)
            tracks.append({
                "id": tid,
                "title": r.get("trackName", ""),
                "artist": r.get("artistName", ""),
                "album": r.get("collectionName", ""),
                "price": f"{r.get('trackPrice', '')} {r.get('currency', '')}".strip(),
                "buy": r.get("trackViewUrl", ""),
                "preview": preview,
            })

    payload = json.dumps(tracks, ensure_ascii=False)
    page = """<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hannah's DDR wishlist</title>
<style>
 body{font:15px/1.4 -apple-system,system-ui,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem}
 h1{margin:0 0 .2rem} .sub{color:#777;margin:0 0 1rem}
 #now{font-weight:600;margin:.6rem 0} audio{width:100%}
 .bar{display:flex;gap:.5rem;flex-wrap:wrap;margin:.7rem 0}
 input,button{font:inherit;padding:.35rem .55rem}
 .row{display:flex;align-items:center;gap:.6rem;padding:.35rem .3rem;border-bottom:1px solid #eee}
 .row:hover{background:#f7f7f7} .row.cur{background:#e8f0fe}
 .meta{flex:1;min-width:0} .t{display:block;font-weight:600}
 .a{color:#666;font-size:.85em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
 .price{color:#444;font-size:.85em;white-space:nowrap}
 a.buy{font-size:.85em}
 #list{max-height:58vh;overflow:auto;border:1px solid #ddd;border-radius:6px}
</style></head><body>
<h1>Hannah's DDR wishlist</h1>
<p class="sub">30-second previews. Tick the ones she likes, then hit “Copy selected”.</p>
<p class="sub"><b>Buying:</b> “buy in Music” opens the Music app. If it shows Apple Music, click <b>iTunes Store</b> in the sidebar and search the title — purchases there are DRM-free.</p>
<div id="now">—</div>
<audio id="a" controls></audio>
<div class="bar">
  <button onclick="prev()">⏮ Prev</button>
  <button onclick="next()">Next ⏭</button>
  <button onclick="copySel()">Copy selected</button>
  <button onclick="location.href='itms://itunes.apple.com/ca/'">Open iTunes Store</button>
  <input id="q" placeholder="Search…" oninput="render()">
</div>
<div id="list"></div>
<script>
const ALL = __PAYLOAD__;
let i = 0;
const a = document.getElementById('a'), now = document.getElementById('now');
function render() {
  const q = document.getElementById('q').value.toLowerCase();
  const list = document.getElementById('list'); list.innerHTML = '';
  ALL.forEach((t, idx) => {
    if (q && !(t.title + ' ' + t.artist).toLowerCase().includes(q)) return;
    const d = document.createElement('div');
    d.className = 'row' + (idx === i ? ' cur' : '');
    d.innerHTML = '<input type="checkbox" data-i="' + idx + '">'
      + '<div class="meta"><span class="t">' + esc(t.title) + '</span>'
      + '<span class="a">' + esc(t.artist) + ' — ' + esc(t.album) + '</span></div>'
      + '<span class="price">' + esc(t.price) + '</span>'
      + '<a class="buy" href="' + itms(t.buy) + '">buy in Music</a>';
    d.querySelector('.meta').onclick = () => load(idx);
    d.querySelector('input').onclick = () => load(idx);
    list.appendChild(d);
  });
}
function esc(s){return String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));}
function itms(u){return (u||'').replace('https://music.apple.com/','itms://itunes.apple.com/').replace(/&uo=\\d+/,'');}
function load(n) {
  i = (n + ALL.length) % ALL.length;
  const t = ALL[i];
  a.src = t.preview;
  now.textContent = (i + 1) + '/' + ALL.length + ' — ' + t.title + '  [' + t.artist + ']';
  a.play(); render();
}
function next(){load(i+1)} function prev(){load(i-1)}
function copySel() {
  const picks = [...document.querySelectorAll('input[type=checkbox]:checked')]
    .map(cb => ALL[+cb.dataset.i]).map(t => t.title + ' — ' + t.artist + ' — ' + t.price + ' — ' + t.buy);
  navigator.clipboard.writeText(picks.join('\\n')).then(() => alert(picks.length + ' copied'));
}
a.onended = () => next();
render();
if (ALL.length) load(0);
</script></body></html>"""
    OUT.write_text(page.replace("__PAYLOAD__", payload))
    print(f"wrote {OUT} ({len(tracks)} previews)")


if __name__ == "__main__":
    main()
