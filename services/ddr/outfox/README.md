# Mermaid theme + palette arrows

Custom OutFox skin for Rocinante. Based on OutFox's **Alpha V: Dance** theme and the
**default** dance noteskin (OutFox: Apache-2.0; graphics CC BY-SA 4.0, Team Rizu).
Keep the included `LICENSE.md` files.

## Install

Copy into OutFox's `Appearance/` folder:

```
Appearance/Themes/mermaid
Appearance/NoteSkins/dance/mermaid
```

Then in OutFox:
- **Options → Theme → Mermaid**
- **Options → Noteskin → Mermaid** (the theme also defaults to `mermaid`)

Existing song backgrounds/banners/jackets are untouched.

## What it changes

| Piece | Change |
|---|---|
| Player UI colours | pink + aqua (`Scripts/Main.lua`) |
| Notes | **palette arrows**, 8 quantisation colours |
| Receptor | pink/aqua ring |
| Loading / init | mermaid background with Hannah's photos |
| Fail screen | pastel-pink background, nautical *Pirata One* title, Hannah's video |
| Song-reload screen | same mermaid background |

## Art & credits

- **Anchors:** removed (superseded by palette arrows)
- **Title font:** *Pirata One* — SIL Open Font License (`fonts/`)
- **Medallion:** Rawpixel CC0 mermaid illustration (`art-candidates/rawpixel-207.jpg`)
- **Framed portrait:** *The Little Mermaid* — Elena Ringo, **CC BY 4.0**
  <https://commons.wikimedia.org/wiki/File:The_Little_Mermaid_-_Painting_by_Elena_Ringo.jpg>
- **Photos + video:** Hannah's 2026 media are kept **local only** (not committed)

## Rebuild the art

```bash
cd services/ddr/outfox
python3 build-noteskin.py        # palette arrows + receptor
python3 build-failscreen.py      # fail background, title, trimmed video
python3 build-loading-photos.py  # loading screen with Hannah's photos
python3 build-loading.py         # mermaid-only loading screen
```

Requires macOS `qlmanage`, `ffmpeg`, and `sips`.
