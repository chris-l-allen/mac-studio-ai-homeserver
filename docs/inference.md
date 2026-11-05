---
layout: default
title: Local inference
---

# Local inference — Qwen 3.8 27B

The server exposes an OpenAI-compatible endpoint so internal apps can do
**sensitive inference without sending data to a cloud provider**.

## Runtime

- **Ollama, native** (not Docker — containers on macOS have no Metal GPU).
- Model: `hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K` (≈22 GB, fits 36 GB unified).
- API: `http://0.0.0.0:11434/v1` (OpenAI-compatible).
- Published on the LAN at `https://llm.allen/v1` through Caddy.

## Start / keep running

```bash
./scripts/pull-models.sh          # one-time
./scripts/serve-ollama.sh         # foreground test
# production: launchd/com.local.ollama.plist
```

Environment (see the plist):

```
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_KEEP_ALIVE=-1              # model stays resident
OLLAMA_CONTEXT_LENGTH=32768
```

## Client example

```python
from openai import OpenAI

client = OpenAI(base_url="http://llm.allen/v1", api_key="not-needed",
                # or http://<server-ip>:11434/v1
                )

resp = client.chat.completions.create(
    model="hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K",
    messages=[{"role": "user", "content": "Summarize this email..."}],
    extra_body={"chat_template_kwargs": {"enable_thinking": False}},
)
```

## Gmail email processing

`~/gmail-events` already supports local inference. The merged launchd plist
(`launchd/com.gmail-events.daemon.plist`) sets:

```
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://127.0.0.1:11434/v1
OLLAMA_MODEL=hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K
```

and contains **no API key**. Remove the old DeepSeek key from the existing plist
and rotate it. Test with `node classify-test.js` before trusting the daemon.

> Risk: `classifier.js` sends `response_format: {"type":"json_object"}`. If the
> 27B model or Ollama rejects it, fall back to the rule-based classifier or use
> Ollama's `format: "json"` parameter.
