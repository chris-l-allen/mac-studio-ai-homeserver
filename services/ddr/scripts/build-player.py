#!/usr/bin/env python3
"""Build media/player.html: a browser player for every audio file in the
song packs plus the media folder. Re-run after adding/removing packs."""
from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO = {".mp3", ".ogg", ".opus", ".wav"}


def title_of(songdir: pathlib.Path) -> str:
    for chart in list(songdir.glob("*.ssc")) + list(songdir.glob("*.sm")) + list(songdir.glob("*.dwi")):
        try:
            m = re.search(r"#TITLE:([^;]*)", chart.read_text(errors="ignore"))
            if m:
                return m.group(1).strip()
        except OSError:
            pass
    return songdir.name


def main() -> None:
    tracks: list[dict[str, str]] = []
    for songdir in sorted(ROOT.glob("songpacks/*/*")):
        if not songdir.is_dir():
            continue
        audio = next((f for f in songdir.iterdir() if f.suffix.lower() in AUDIO), None)
        if not audio:
            continue
        tracks.append({
            "title": songdir.name,
            "pack": songdir.parent.name,
            "file": str(audio.relative_to(ROOT)),
        })
    # media/ was removed 2026-11-05; only step packs remain.

    payload = json.dumps(tracks, ensure_ascii=False)
    page = """<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>DDR library player</title>
<style>
  body{font:15px/1.4 -apple-system,system-ui,sans-serif;max-width:860px;margin:2rem auto;padding:0 1rem}
  h1{margin:0 0 .4rem} #now{font-weight:600;margin:.6rem 0}
  audio{width:100%} .bar{display:flex;gap:.5rem;flex-wrap:wrap;margin:.6rem 0}
  input,select,button{font:inherit;padding:.35rem .5rem}
  .row{display:flex;justify-content:space-between;gap:1rem;padding:.25rem .3rem;cursor:pointer;border-bottom:1px solid #eee}
  .row:hover{background:#f6f6f6} .row.cur{background:#e8f0fe;font-weight:600}
  .pack{color:#888;font-size:.85em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:45%}
  #list{max-height:60vh;overflow:auto;border:1px solid #ddd;border-radius:6px;margin-top:.6rem}
</style></head><body>
<h1>DDR library player</h1>
<div id="now">—</div>
<audio id="a" controls></audio>
<div class="bar">
  <button onclick="prev()">⏮ Prev</button>
  <button onclick="next()">Next ⏭</button>
  <input id="q" placeholder="Search title…" oninput="render()">
  <select id="pk" onchange="render()"><option value="">All packs</option></select>
</div>
<div id="list"></div>
<script>
const ALL = __PAYLOAD__;
let i = 0;
const a = document.getElementById('a'), now = document.getElementById('now');
const packs = [...new Set(ALL.map(t => t.pack))].sort();
const pk = document.getElementById('pk');
packs.forEach(p => { const o = document.createElement('option'); o.value = o.textContent = p; pk.appendChild(o); });
function esc(s){return String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));}
function view() {
  const q = document.getElementById('q').value.toLowerCase();
  const pf = pk.value;
  return ALL.map((t, idx) => ({t, idx})).filter(({t}) =>
    (!pf || t.pack === pf) && (!q || t.title.toLowerCase().includes(q)));
}
function render() {
  const list = document.getElementById('list'); list.innerHTML = '';
  view().forEach(({t, idx}) => {
    const d = document.createElement('div');
    d.className = 'row' + (idx === i ? ' cur' : '');
    d.dataset.i = idx;
    d.innerHTML = '<span>' + (idx + 1) + '. ' + esc(t.title) + '</span><span class="pack">' + esc(t.pack) + '</span>';
    d.onclick = () => load(idx);
    list.appendChild(d);
  });
}
function mark() {
  document.querySelectorAll('.row').forEach(el => el.classList.toggle('cur', +el.dataset.i === i));
}
function load(n, autoplay = true) {
  i = (n + ALL.length) % ALL.length;
  const t = ALL[i];
  a.src = '/' + t.file.split('/').map(encodeURIComponent).join('/');
  now.textContent = (i + 1) + '/' + ALL.length + ' — ' + t.title + '  [' + t.pack + ']';
  if (autoplay) { const p = a.play(); if (p && p.catch) p.catch(() => {}); }
  mark();
}
function next() { load(i + 1); }
function prev() { load(i - 1); }
a.onended = () => next();
a.onerror = () => { now.textContent = 'Could not play this file — try another.'; };
render();
if (ALL.length) { load(0, false); now.textContent = 'Ready — click a track to play.'; }
</script></body></html>"""
    out = ROOT / "player.html"
    out.write_text(page.replace("__PAYLOAD__", payload))
    print(f"wrote {out} ({len(tracks)} tracks)")


if __name__ == "__main__":
    main()
