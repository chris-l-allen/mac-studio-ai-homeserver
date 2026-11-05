#!/bin/bash
PRIMARY="10.0.0.11"
SECONDARY="10.0.0.1"

if [ "$(id -u)" != "0" ]; then
  osascript -e "do shell script \"$0\" with administrator privileges"
  exit $?
fi

while IFS= read -r svc; do
  [ -z "$svc" ] && continue
  case "$svc" in \**) continue;; esac
  networksetup -setdnsservers "$svc" "$PRIMARY" "$SECONDARY"
  echo "set $svc -> $PRIMARY, $SECONDARY"
done < <(networksetup -listallnetworkservices | tail -n +2)

dscacheutil -flushcache
killall -HUP mDNSResponder 2>/dev/null
echo
echo "Active resolvers:"
scutil --dns | grep "nameserver\[" | head -4
