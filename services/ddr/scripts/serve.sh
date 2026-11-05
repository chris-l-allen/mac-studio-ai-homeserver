#!/usr/bin/env bash
# Run the HomeServer from the repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

exec python3 homeserver/server.py
