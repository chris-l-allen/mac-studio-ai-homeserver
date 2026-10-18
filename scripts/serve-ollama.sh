#!/usr/bin/env bash
#
# Run the Ollama API server in the foreground (for testing).
# For a persistent service, use launchd/com.local.ollama.plist instead.
#
set -euo pipefail

# Reachable from the LAN and from Docker via host.docker.internal.
export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
# Keep the model resident: this is a server, not a one-shot chat.
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:--1}"
# Tune to your RAM headroom. 32768 is a comfortable default for 27B + services.
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-32768}"

exec ollama serve
