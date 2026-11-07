#!/bin/sh
# Back up the local profile. The Manage Profiles screen aborts if no local
# profile exists, so keep a copy we can restore.
set -eu
HOST="callen@10.0.0.54"
KEY="$HOME/.ssh/id_rsa.tmp"
DEST="$HOME/mac-studio-ai-homeserver/services/ddr/archive/profile-backups"
STAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$DEST"
rsync -az -e "ssh -i $KEY" \
  "$HOST:'Library/Preferences/Project OutFox/LocalProfiles/callen/'" \
  "$DEST/callen-$STAMP/"
echo "backed up to $DEST/callen-$STAMP"
