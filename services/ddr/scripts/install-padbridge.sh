#!/bin/sh
# Install padbridge (HID -> keyboard bridge) as a user LaunchAgent.
#
# Why the SSH loop: a LaunchAgent-launched process is denied
# kTCCServicePostEvent on this Mac, while anything run through sshd inherits
# sshd-keygen-wrapper's PostEvent/Accessibility grants. The LaunchAgent keeps a
# localhost SSH session running the bridge, so it starts at login and survives
# reboot.
#
# Run as the desktop user on the target Mac (Rocinante), not as root.

set -eu

BIN_DIR="$HOME/bin"
LA_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs"
KEY="$HOME/.ssh/padbridge_ed25519"
LABEL="com.callen.padbridge"
SRC="$(cd "$(dirname "$0")" && pwd)/padbridge.c"

mkdir -p "$BIN_DIR" "$LA_DIR" "$LOG_DIR" "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

clang -framework IOKit -framework CoreFoundation \
      -framework ApplicationServices -o "$BIN_DIR/padbridge" "$SRC"
chmod +x "$BIN_DIR/padbridge"

if [ ! -f "$KEY" ]; then
    ssh-keygen -t ed25519 -N "" -f "$KEY" -q
fi
chmod 600 "$KEY"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
grep -qxF "$(cat "$KEY.pub")" "$HOME/.ssh/authorized_keys" \
    || cat "$KEY.pub" >> "$HOME/.ssh/authorized_keys"

cat > "$LA_DIR/$LABEL.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$LABEL</string>
<key>ProgramArguments</key><array>
<string>/usr/bin/ssh</string>
<string>-i</string><string>$KEY</string>
<string>-o</string><string>BatchMode=yes</string>
<string>-o</string><string>StrictHostKeyChecking=no</string>
<string>-o</string><string>UserKnownHostsFile=/dev/null</string>
<string>-o</string><string>ServerAliveInterval=5</string>
<string>-o</string><string>ServerAliveCountMax=2</string>
<string>$(id -un)@127.0.0.1</string>
<string>$BIN_DIR/padbridge</string>
</array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
<key>StandardOutPath</key><string>$LOG_DIR/padbridge.log</string>
<key>StandardErrorPath</key><string>$LOG_DIR/padbridge.log</string>
</dict></plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LA_DIR/$LABEL.plist"
echo "installed $LABEL; log: $LOG_DIR/padbridge.log"
