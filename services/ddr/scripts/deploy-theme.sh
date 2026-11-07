#!/bin/sh
# Deploy the mermaid-kids theme from this repo to Rocinante and restart OutFox.
set -eu
HOST="callen@10.0.0.54"
KEY="$HOME/.ssh/id_rsa.tmp"
SRC="$HOME/mac-studio-ai-homeserver/services/ddr/outfox/Appearance/Themes/mermaid-kids"
DST="/Applications/OutFox/Appearance/Themes/mermaid-kids"

rsync -az --delete -e "ssh -i $KEY" "$SRC/" "$HOST:$DST/"
ssh -i "$KEY" "$HOST" 'killall -9 OutFox 2>/dev/null || true; sleep 2; open "$HOME/Desktop/DDR.app"; echo restarted'
