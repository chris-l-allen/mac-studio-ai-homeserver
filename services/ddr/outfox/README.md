# Mermaid theme + Anchor noteskin

Custom OutFox skin for Rocinante. Based on OutFox's **Alpha V: Dance** theme and the
**default** dance noteskin (OutFox: Apache-2.0; graphics CC BY-SA 4.0, Team Rizu).
Keep the included `LICENSE.md` files with the theme/noteskin.

## Install

Copy these into OutFox's `Appearance/` folder (same level as `Themes/` and
`NoteSkins/`):

```
Appearance/Themes/mermaid
Appearance/NoteSkins/dance/anchor
```

Then in OutFox:
- **Options → Theme → Mermaid**
- **Options → Noteskin → Anchor**

Existing song backgrounds/banners/jackets are untouched.

## What it changes

| Piece | Change |
|---|---|
| Player UI colours | pink + aqua (`Scripts/Main.lua`) |
| Notes | anchor-shaped, 8 quantisation colours (`_arrow 1x8`) |
| Receptor | anchor ring (`_receptor`) |
| Loading / init | mermaid gradient + anchor (`Graphics/Mermaid Loading.png`) |
| Song-reload screen | same mermaid background |

The loading/init background is wired through
`BGAnimations/ScreenInit background/mermaid.lua` and
`BGAnimations/ScreenReloadSongs background/mermaid.lua`.

## Rebuild the art

```bash
cd services/ddr/outfox
python3 build-mermaid.py
```

Requires macOS `qlmanage`, `ffmpeg` (vstack), and `sips`. Photos/mermaid art can be
dropped in later; replace `Graphics/Mermaid Loading.png` or point the BGAnimations
at new images.
