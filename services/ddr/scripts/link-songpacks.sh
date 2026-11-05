#!/usr/bin/env bash
# Symlink shared song packs into OutFox's Songs folder (best effort).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/songpacks"

# Common user-data locations; OutFox may use either depending on version.
CANDIDATES=(
  "$HOME/Library/Application Support/Project OutFox/Songs"
  "$HOME/Library/Application Support/OutFox/Songs"
  "$HOME/Library/Application Support/StepMania 5/Songs"
  "/Applications/Project OutFox.app/Contents/Resources/Songs"
)

DEST=""
for c in "${CANDIDATES[@]}"; do
  if [ -d "$c" ]; then DEST="$c"; break; fi
done

if [ -z "$DEST" ]; then
  echo "No OutFox/StepMania Songs folder found."
  echo "Install OutFox first (scripts/install-outfox.sh), launch it once, then re-run."
  echo "Checked:"
  printf '  %s\n' "${CANDIDATES[@]}"
  exit 1
fi

echo "Linking packs from: $SRC"
echo "                 to: $DEST"

shopt -s nullglob
linked=0
for pack in "$SRC"/*/; do
  name="$(basename "$pack")"
  target="$DEST/$name"
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "  skip (exists): $name"
    continue
  fi
  ln -s "$pack" "$target"
  echo "  linked: $name"
  linked=$((linked + 1))
done

if [ "$linked" -eq 0 ]; then
  echo "No packs to link. Add .sm/.ssc packs under songpacks/ first."
fi
