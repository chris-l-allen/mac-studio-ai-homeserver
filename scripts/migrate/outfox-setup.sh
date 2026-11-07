#!/usr/bin/env bash
# Install the Mermaid theme + noteskin and link the song library into OutFox.
# Run on Rocinante after OutFox is installed.
#
#   OUTFOX_ROOT=/Applications/OutFox ./scripts/migrate/outfox-setup.sh
#
# Defaults to /Applications/OutFox, then ~/OutFox. Expects an `Appearance/`
# folder next to OutFox.app (as shipped in the DMG).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/services/ddr/outfox"
GFX_SRC="$SRC/Appearance/Themes/mermaid/Graphics"

pick_root() {
  if [ -n "${OUTFOX_ROOT:-}" ]; then echo "$OUTFOX_ROOT"; return; fi
  for d in /Applications/OutFox "$HOME/OutFox" /Applications/OutFox.app/Contents/Resources; do
    if [ -d "$d/Appearance" ]; then echo "$d"; return; fi
  done
}
ROOT="$(pick_root || true)"
if [ -z "$ROOT" ] || [ ! -d "$ROOT/Appearance" ]; then
  echo "OutFox Appearance folder not found. Set OUTFOX_ROOT to the folder that contains Appearance/." >&2
  exit 1
fi

mkdir -p "$ROOT/Appearance/Themes" "$ROOT/Appearance/NoteSkins/dance" "$ROOT/Songs"

# theme + noteskin
rm -rf "$ROOT/Appearance/Themes/mermaid" "$ROOT/Appearance/NoteSkins/dance/mermaid"
cp -R "$SRC/Appearance/Themes/mermaid" "$ROOT/Appearance/Themes/"
cp -R "$SRC/Appearance/NoteSkins/dance/mermaid" "$ROOT/Appearance/NoteSkins/dance/"

# local-only photo loading screen (replaces the committed mermaid-only one)
if [ -f "$GFX_SRC/Mermaid Loading.local.png" ]; then
  cp "$GFX_SRC/Mermaid Loading.local.png" "$ROOT/Appearance/Themes/mermaid/Graphics/Mermaid Loading.png"
  rm -f "$ROOT/Appearance/Themes/mermaid/Graphics/Mermaid Loading.local.png"
  echo "installed photo loading screen"
else
  echo "no local photo loading screen found; using mermaid-only version"
fi

# local-only fail video
if [ -f "$GFX_SRC/fail.mp4" ]; then
  cp "$GFX_SRC/fail.mp4" "$ROOT/Appearance/Themes/mermaid/Graphics/fail.mp4"
  echo "installed fail-screen video"
fi

# song packs (symlink so updates are shared)
for d in "$REPO/services/ddr/songpacks"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  if [ ! -e "$ROOT/Songs/$name" ]; then
    ln -s "$d" "$ROOT/Songs/$name"
    echo "linked song pack: $name"
  fi
done

echo
echo "Done. In OutFox: Options -> Theme -> Mermaid; Noteskin -> Mermaid."
echo "Then play a song, fail it, and confirm the video/loading screen."
