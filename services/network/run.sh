#!/bin/bash
# Run the Home Network Portal.
#   ./run.sh         -> web on https://0.0.0.0:8443, DNS on 5353 (no root)
#   sudo ./run.sh    -> DNS on 53 (recommended so devices can use it without config)
cd "$(dirname "$0")" || exit 1
exec python3 server.py "$@"
