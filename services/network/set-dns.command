#!/bin/bash
# Route only *.allen to the home server. All other DNS is left untouched, so
# internet access keeps working if the home server is offline.
PRIMARY="10.0.0.54"
RESOLVER="/etc/resolver/allen"

if [ "$(id -u)" != "0" ]; then
  osascript -e "do shell script \"$0\" with administrator privileges"
  exit $?
fi

mkdir -p /etc/resolver
printf "nameserver %s\n" "$PRIMARY" > "$RESOLVER"
chmod 644 "$RESOLVER"
echo "wrote $RESOLVER -> $PRIMARY"

dscacheutil -flushcache
killall -HUP mDNSResponder 2>/dev/null
echo
echo "Active .allen resolver:"
scutil --dns | grep -A2 "domain   : allen" | head -4
