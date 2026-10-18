#!/usr/bin/env bash
#
# Pull the models used by this server.
# Requires Ollama (https://ollama.com) with Hugging Face pull support.
#
set -euo pipefail

# Q6_K is the quality/size sweet spot on 36 GB unified memory (~22 GB).
# On a 24 GB GPU, use Q4_K_M instead.
MODEL="${MODEL:-hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K}"

echo "==> Pulling ${MODEL}"
ollama pull "${MODEL}"

echo
echo "==> Installed models:"
ollama list

echo
echo "Done. Serve the API with ./scripts/serve-ollama.sh (or the launchd plist)."
