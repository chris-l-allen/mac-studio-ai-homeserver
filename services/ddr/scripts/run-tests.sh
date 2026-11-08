#!/bin/sh
# Run the DDR unit tests (stdlib unittest; no dependencies).
set -eu
cd "$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -m unittest discover -s tests -v "$@"
