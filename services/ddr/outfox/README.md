# Mermaid theme + Anchor noteskin

Custom OutFox skin for Rocinante. Based on OutFox's **Alpha V: Dance** theme and the
**default** dance noteskin (OutFox: Apache-2.0; graphics CC BY-SA 4.0, Team Rizu).
Keep the included `LICENSE.md` files.

## Install

Copy into OutFox's `Appearance/` folder:

```
Appearance/Themes/mermaid
Appearance/NoteSkins/dance/anchor
```

Then in OutFox:
- **Options → Theme → Mermaid**
- **Options → Noteskin → Anchor** (the theme also defaults to `anchor`)

Existing song backgrounds/banners/jackets are untouched.

## What it changes

| Piece | Change |
|---|---|
| Player UI colours | pink + aqua (`Scripts/Main.lua`) |
| Notes | **vintage-metal anchors**, 8 metal tints (gold, bronze, silver, copper, patina, rose, gunmetal, pearl) |
| Receptor | metal ring with patina/teal glow |
| Loading / init | mermaid background with Hannah's photos (`Graphics/Mermaid Loading.png`) |
| Song-reload screen | same mermaid background |

The loading/init background is wired through
`BGAnimations/ScreenInit background/mermaid.lua` and
`BGAnimations/ScreenReloadSongs background/mermaid.lua`.

## Art

- **Anchors:** original SVG art (metal gradients, bevels, shadow)
- **Medallion:** Rawpixel CC0 mermaid illustration (`art-candidates/rawpixel-207.jpg`)
- **Framed portrait:** *The Little Mermaid* — Elena Ringo, **CC BY 4.0**
  <https://commons.wikimedia.org/wiki/File:The_Little_Mermaid_-_Painting_by_Elena_Ringo.jpg>
- **Photos:** Hannah's 2026 photos are kept **local only** (not committed).

## Rebuild the art

```bash
cd services/ddr/outfox
python3 build-anchor.py          # anchor noteskin
python3 build-loading.py         # mermaid-only loading screen
python3 build-loading-photos.py  # loading screen with Hannah's photos
```

Requires macOS `qlmanage`, `ffmpeg`, and `sips`.
