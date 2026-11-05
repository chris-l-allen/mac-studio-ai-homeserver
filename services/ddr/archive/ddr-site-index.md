---
layout: default
title: HomeDDR + HomeServer
---

# HomeDDR + HomeServer

A kid-friendly **Dance Dance Revolution / rhythm station** built on
[Project OutFox](https://projectoutfox.com/), plus a tiny dependency-free
**HomeServer** that publishes song packs and karaoke media on the home LAN.

No console, no subscription, no per-song purchases.

## Documentation

- [DDR setup](ddr-setup.html) — OutFox, the L-TEK pad, kid-friendly charts, and
  custom songs.
- [HomeServer](homeserver.html) — running the static server, configuration,
  endpoints, persistence, and LAN security.

## Current status

- **Engine:** Project OutFox 0.5.0 Final Alpha (Universal macOS DMG).
- **Target box:** dedicated HomeServer — refurbished **Mac mini M4 16GB/512GB**
  at $1,189 CAD recommended (16/256 at $1,059 is the budget option; not yet bought).
- **Pad:** cheap local **soft pad now** (bridge); **L-TEK Core** ordered only after
  the setup and tests pass. Project concludes when the final L-TEK arrives.
- **Host constraint:** OutFox is deliberately **not** installed on the current
  family Mac.
- **HomeServer:** verified locally (`/health` returns `ok`, `/` returns 200).

## Repository

The full project state, decisions, and next actions live in the repo:

- [README](https://github.com/chris-l-allen/home-ddr/blob/main/README.md)
- [HANDOFF](https://github.com/chris-l-allen/home-ddr/blob/main/HANDOFF.md)
- [All files](https://github.com/chris-l-allen/home-ddr)

## Evidence discipline

Claims in this project are labelled **FACT** (verified), **INFERENCE** (follows
from evidence), or **GUESS** (plausible but unverified). Nothing is called
"working" until it has been tested here.
