# K-Pop Demon Hunters — promo image replacement manifest (2026-11-07)

The pack's original banners (`<track>-bn(2).png`, noisy screenshots with baked-in
titles) and shared `cd.png` (generic "CHART BY" card) were replaced with official
promotional artwork. This file is the record of the mapping, sources, and edits.

## Track → image mapping

| Track (dir) | Banner (1024×400) | Background (1920×1080) | Jacket (300×300 / 900×900) | CD title (612×400) | Artwork source |
|---|---|---|---|---|---|
| Golden | `Golden/Golden-banner.png` | `Golden/Golden-bg.png` | `Golden/Golden-cover.png` | `Golden/Golden-cd.png` | Wikipedia `Huntr-x - Golden.png` (HUNTR/X single) |
| TAKEDOWN | `TAKEDOWN/Takedown-banner.png` | `TAKEDOWN/Takedown-bg.png` | `TAKEDOWN/Takedown-cover.png` | `TAKEDOWN/Takedown-cd.png` | Wikipedia `Twice - Takedown.png` (film-version cover, artist tagged HUNTR/X in chart) |
| Free | `Free/Free-banner.png` | `Free/Free-bg.png` | `Free/Free-cover.png` | `Free/Free-cd.png` | Standard soundtrack cover (no standalone single cover exists) |
| What It Sounds Like | `What It Sounds Like/What It Sounds Like-banner.png` | `…/bg.png` | `…/cover.png` | `…/cd.png` | Wikipedia `Huntrix - What It Sounds Like.png` |
| Soda Pop | `Soda Pop/Soda Pop-banner.png` | `…/bg.png` | `…/cover.png` | `…/cd.png` | Wikipedia `Saja Boys - Soda Pop.png` |
| How It's Done | `How It's Done/How It's Done-banner.png` | `…/bg.png` | `…/cover.png` | `…/cd.png` | Wikipedia `Huntr-x - How It's Done.png` |
| Strategy | `Strategy/Strategy-banner.png` | `…/bg.png` | `…/cover.png` | `…/cd.png` | Wikipedia `Twice - Strategy 2.0.png` (chart artist is TWICE) |
| Your Idol | `Your Idol/Your Idol-banner.png` | `…/bg.png` | `…/cover.png` | `…/cd.png` | Wikipedia `Saja Boys - Your Idol.png` |
| (pack) | `K-Pop Demon Hunters-packbn.png` | — | — | — | Standard soundtrack cover, 1200×1200 |

(`…` = the track's own directory. Background/CD files follow the
`<TrackName>-bg.png` / `<TrackName>-cd.png` pattern.)

## Source artwork (verified 2026-11-07)

| File | Source | Size | Verification |
|---|---|---|---|
| HUNTR/X single covers ×4 | Wikipedia en (upload.wikimedia.org) | 300×300 PNG | VLM-confirmed group + title per cover |
| Saja Boys single covers ×2 | Wikipedia en | 300×300 PNG | VLM-confirmed |
| TWICE single covers ×2 (Takedown, Strategy) | Wikipedia en | 300×300 PNG | VLM-confirmed; correct for these charts (Takedown banner art shows the film's TWICE-style styling; Strategy chart artist is TWICE) |
| Standard soundtrack cover | Apple Music / iTunes (mzstatic `25UMGIM82363.rgb.jpg`) | 1200×1200 JPEG | VLM-confirmed: HUNTR/X trio, "Soundtrack from the Netflix Film" |
| Deluxe soundtrack cover (backup only) | Apple Music (mzstatic `25UM1IM35857.rgb.jpg`) | 1200×1200 JPEG | VLM-confirmed |

Source URLs:

- https://upload.wikimedia.org/wikipedia/en/6/6f/Huntr-x_-_Golden.png
- https://upload.wikimedia.org/wikipedia/en/7/74/Twice_-_Takedown.png
- https://upload.wikimedia.org/wikipedia/en/1/11/Huntrix_-_What_It_Sounds_Like.png
- https://upload.wikimedia.org/wikipedia/en/3/3e/Saja_Boys_-_Soda_Pop.png
- https://upload.wikimedia.org/wikipedia/en/7/77/Huntr-x_-_How_It%27s_Done.png
- https://upload.wikimedia.org/wikipedia/en/6/66/Saja_Boys_-_Your_Idol.png
- https://upload.wikimedia.org/wikipedia/en/6/60/Twice_-_Strategy_2.0.png
- https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/e1/15/42/e1154273-8ecd-5702-e6e6-597f28001681/25UMGIM82363.rgb.jpg/1200x1200bb.jpg

"Free" (Rumi & Jinu) has no standalone single cover on Wikipedia; the standard
soundtrack cover (center-cropped) is used, consistent with how Apple Music serves
it.

## Processing (Pillow)

- **Banner / CD-title / pack banner:** cover tile repeated horizontally →
  Gaussian blur 28 → darkened (0.42); sharp cover panel on the right with soft
  shadow; song title (Avenir Next Condensed, auto-fitted) + artist
  (Avenir Next) on the left with drop shadow. No baked-in screenshot content.
- **Background:** same ambient treatment, brighter (0.7), plus a bottom
  gradient for readability under notes.
- **Jacket:** the raw single cover, unmodified.
- Old `bg.png` and `cd.png` remain in the pack root, unreferenced (kept for
  rollback). Old `<track>-bn.png` / `<track>-bn(2).png` also kept.

## Chart files edited (15)

`#BANNER`, `#BACKGROUND`, `#JACKET` (where present), and `#CDTITLE` were
repointed to the per-track files above. Files: every `.sm` (8) and `.ssc` (7)
in the pack. `.ssc.oldsync` backups untouched. `pack.ini` unchanged
(`Banner=K-Pop Demon Hunters-packbn.png` — that file was regenerated in place).

## Verification

- FACT: all 15 chart files now reference the new per-track banners/backgrounds/
  CD titles (grep-verified after edit).
- FACT: banner/CD/pack-banner dimensions are 1024×400 / 612×400 / 1024×400.
- FACT: VLM readability check on Golden, Takedown, Free, and the pack banner:
  5/5, correct transcribed text.
- UNVERIFIED: rendering in a live OutFox song select / gameplay (next step).
