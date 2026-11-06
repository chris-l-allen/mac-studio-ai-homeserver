---
layout: default
title: DDR
---

# DDR (folded into this repo)

The HomeDDR project now lives here under `services/ddr/`. It shares the same box
as the network services and inference.

## Contents

| Path | What |
|---|---|
| `services/ddr/homeserver/server.py` | dependency-free static server (songs + media) |
| `services/ddr/scripts/serve.sh` | run the HomeServer |
| `services/ddr/scripts/install-outfox.sh` | guided Project OutFox install |
| `services/ddr/scripts/link-songpacks.sh` | symlink packs into OutFox |
| `services/ddr/songpacks/` | StepMania/OutFox packs (gitignored content) |
| `services/ddr/media/` | karaoke/audio (gitignored content) |
| `docs/ddr-setup.md` | OutFox + pad + charts (from the old repo) |
| `docs/ddr-homeserver.md` | HomeServer usage (from the old repo) |

## Run

```bash
cd ~/mac-studio-ai-homeserver/services/ddr
./scripts/serve.sh                       # http://127.0.0.1:8787
HOMEDDR_HOST=0.0.0.0 ./scripts/serve.sh  # expose on the LAN
```

Published at **https://ddr.allen** via Caddy. Sourced content lives in
`services/ddr/songpacks/` and `services/ddr/media/` (gitignored); the migration
tarball carries both onto Rocinante. See `services/ddr/SOURCES.md`.

## DDR engine

Project OutFox runs on this same box (the owner wants the DDR station on the
server). The **Mermaid** theme + palette-arrow noteskin live in
`services/ddr/outfox/`; install them and link the song library with:

```bash
OUTFOX_ROOT=/Applications/OutFox ./scripts/migrate/outfox-setup.sh
```

The old repo's `HANDOFF.md` is the historical record for pad selection and the
bridge plan.
