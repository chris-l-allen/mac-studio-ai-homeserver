#!/usr/bin/env bash
# Guided Project OutFox install.
# Opens the official downloads page; does not download or install silently.
set -euo pipefail

APP="/Applications/Project OutFox.app"

if [ -d "$APP" ]; then
  echo "OutFox already appears to be installed: $APP"
  echo "Launch it from /Applications or with: open \"$APP\""
  exit 0
fi

echo "Project OutFox is not installed in /Applications."
echo
echo "This script opens the official downloads page:"
echo "  https://projectoutfox.com/downloads"
echo
echo "Download the macOS build, then drag it to /Applications."
echo "If macOS blocks it, allow it in System Settings > Privacy & Security."
echo
read -r -p "Open the downloads page now? [y/N] " reply
case "$reply" in
  [yY]*) open "https://projectoutfox.com/downloads" ;;
  *) echo "Skipped. Visit the URL above when ready." ;;
esac
