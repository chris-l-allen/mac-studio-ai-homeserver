# HomeDDR + HomeServer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-black.svg)]()
[![Status: scaffolded](https://img.shields.io/badge/status-scaffolded-yellow.svg)]()

> A kid-friendly **Dance Dance Revolution / rhythm station** on a family Mac
> (Project OutFox + USB dance pad), plus a tiny **HomeServer** that publishes the
> song library and karaoke media to the home LAN.

**Status:** 🟡 Scaffolded, waiting on hardware. OutFox is **not** installed on the
current family Mac by owner choice — it will run on a dedicated HomeServer box
(refurbished Mac mini recommended, not bought yet). The plan is **bridge now,
upgrade later**: buy a cheap local soft pad, prove the whole rig, then order the
metal **L-TEK Core**. The project concludes when the final L-TEK pad arrives.

**Docs site:** <https://chris-l-allen.github.io/home-ddr/>

---

## What this is

Two parts that share one box:

1. **HomeDDR** — a DDR setup for a 5-year-old who loves dancing and singing.
   [Project OutFox](https://projectoutfox.com/) (free, open-source, StepMania-based)
   drives a cheap USB dance pad. Song packs are curated for kids, with low
   difficulties, and can include custom charts for her favourite music.
2. **HomeServer** — a dependency-free Python static server that exposes the song
   packs and karaoke/audio media to phones, tablets, and TVs on the LAN, with a
   simple landing page and a health endpoint.

The point: no console, no subscription, no per-song purchases. One Mac + one pad +
free software, and a small local server so the whole house can reach the library.

---

## TL;DR

| | |
|---|---|
| **Target machine** | Dedicated HomeServer box — refurb **Mac mini M4 16/512 @ $1,189 CAD** recommended; 16/256 @ $1,059 alternative (not bought) |
| **DDR engine** | **Project OutFox** — free, StepMania-based, Universal macOS build |
| **Input** | **Cheap local soft pad now** (bridge, ~$32–60); **L-TEK Core** later (CAD 389 + ~$64 import) after tests pass |
| **Song content** | Free/community packs + optional custom charts (Alvin & the Chipmunks, etc.) |
| **HomeServer** | Python 3 stdlib `http.server`, no dependencies |
| **Server default** | `http://127.0.0.1:8787` (LAN: set `HOMEDDR_HOST=0.0.0.0`) |
| **Cost** | Phase 1: mini $1,189 + HST + bridge pad ~$35–70 ≈ **$1,379–1,414**; Phase 2: L-TEK Core ≈ **$600–665**; total ≈ **$1,979–2,079** (16/256 alternative ≈ $1,832–1,932) |

---

## Why

- She **loves dancing and singing**, plus **Alvin and the Chipmunks**.
- There is **no good DDR solution** in the house today.
- A Mac is already available, so a software DDR engine + dance pad is the shortest
  path to a real, replayable gift.
- Official DDR titles do not ship for macOS, and "Just Dance" is not native to Mac,
  which is exactly why the OutFox route matters.

---

## Architecture

```mermaid
flowchart LR
    subgraph LAN["Home LAN"]
        P["Phone / tablet / TV<br/>(browser)"]
    end

    subgraph MAC["Family Mac (macOS)"]
        PAD["USB dance pad"]
        OF["Project OutFox<br/>DDR engine"]
        HS["HomeServer<br/>python http.server :8787"]
        SONGS[("songpacks/")]
        MEDIA[("media/")]
        OF --> PAD
        OF --- SONGS
        HS --- SONGS
        HS --- MEDIA
    end

    P -->|HTTP| HS
```

**Flow**

1. The dance pad is plugged in over USB; OutFox sees it as arrow-key input.
2. Players pick a song pack and chart in OutFox; low difficulties for a 5-year-old.
3. The HomeServer serves the same `songpacks/` and `media/` over the LAN so phones
   and TVs can browse or download them.

---

## Current facts (verified)

Labeled per the project's evidence discipline (see `AGENTS.md`):

- **FACT** — host Mac is `x86_64` (Intel), macOS `26.5.2`, 16 GB RAM.
- **FACT** — Python `3.14.6`, Node `25.5.0`, git, `gh` (logged in), and Homebrew are
  installed.
- **FACT** — OutFox's site lists a **Universal macOS DMG** (Intel + Apple Silicon),
  dance-pad support, and standard StepMania `.sm`/`.ssc` song loading. Latest dev
  build on the site: **0.5.0 Final Alpha (2025-09-07)**; legacy **0.4.19 LTS** is
  marked outdated.
- **FACT** — No OutFox/StepMania installation is present in `/Applications` yet,
  and the owner declined installing it on this Mac (2026-11-05).
- **FACT** — Owner wants OutFox on a dedicated HomeServer box (refurbished Mac
  Studio or Mac mini), not purchased yet.
- **GUESS** — OutFox compatibility with the eventual box's macOS version is
  untested; verify at install time.

---

## Quick start

```bash
# 1. Run the HomeServer locally
./scripts/serve.sh                    # http://127.0.0.1:8787

# 2. Expose it to the LAN
HOMEDDR_HOST=0.0.0.0 ./scripts/serve.sh

# 3. (On the future HomeServer box) install the DDR engine
./scripts/install-outfox.sh           # opens the official download page

# 4. Point OutFox at the shared song library (after install)
./scripts/link-songpacks.sh
```

---

## Repository layout

```
.
├── README.md                 # this file
├── HANDOFF.md                # state + resume prompt for the next session
├── AGENTS.md                 # project rules (evidence discipline)
├── LICENSE
├── docs/
│   ├── index.md              # GitHub Pages landing page
│   ├── _config.yml           # GitHub Pages / Jekyll config
│   ├── ddr-setup.md          # OutFox + pad + kid difficulty + custom songs
│   └── homeserver.md         # HomeServer usage and security notes
├── homeserver/
│   └── server.py             # dependency-free static server + landing page
├── scripts/
│   ├── serve.sh              # wrapper: run HomeServer
│   ├── install-outfox.sh     # guided OutFox install
│   └── link-songpacks.sh     # symlink shared song library into OutFox
├── launchd/
│   └── com.local.homeddr.plist  # keep HomeServer running at login
├── songpacks/                # OutFox packs (.sm/.ssc) — gitignored
└── media/                    # karaoke/audio — gitignored
```

---

## Roadmap / open decisions

- [ ] Buy a refurbished **Mac mini M4 16GB/512GB ($1,189 CAD)** for the HomeServer box; 16/256 ($1,059) is the budget option.
- [ ] Buy a **cheap local soft pad** as a bridge (~$32–60).
- [ ] Install OutFox, load kid packs, test all four arrows + a 1–3 foot chart.
- [ ] Start HomeServer and pass the phone LAN test.
- [ ] **Only after tests pass:** order the **L-TEK Core** (CAD 389 + ~$64 import + shipping).
- [ ] Project concludes when the final L-TEK pad arrives and passes the same test.
- [ ] Install OutFox on the family Mac and verify it launches on macOS 26.5.2.
- [ ] Curate kid-friendly song packs; confirm low-difficulty charts exist.
- [ ] Decide whether to author custom Alvin & the Chipmunks charts (manual work).
- [ ] Put the HomeServer behind the existing homelab Caddy reverse proxy?
- [ ] Add HomeServer to `mac-studio-ai-homeserver` when the Mac Studio is built.
- [ ] Budget for a second pad (2-player) or a metal pad later.

---

## Evidence & sources

- Project OutFox — <https://projectoutfox.com/> (macOS builds, dance-pad support,
  version info)
- OutFox wiki — <https://outfox.wiki/>
- OutFox GitHub — <https://github.com/TeamRizu/OutFox>
- Apple Certified Refurbished (CA) — <https://www.apple.com/ca/shop/refurbished/mac>
- L-TEK official store — <https://www.iamats.com/shop/> (Core CAD 389 / 240€, Poland)
- DDRPad.com (US reseller) — <https://ddrpad.com/en-ca/products/l-tek-core-dance-pad>
- Prices checked 2026-11-05; see `HANDOFF.md` §7.1 for the detailed table.

Prices and availability move — re-check before buying.

---

## License

MIT — see [LICENSE](LICENSE).
