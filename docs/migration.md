---
layout: default
title: Migration runbook
---

# Migration runbook — old Mac → Mac Studio (arriving tomorrow)

Goal: move **all `.allen` pages + network services + local inference** off the
current Mac (`callen-HGJJR31JW9`, LAN `10.0.0.11`) and onto **Rocinante**,
with zero data loss and a rollback path.

Everything here is **prepared, not executed**. The old Mac keeps running until
the cutover step.

---

## 0. What is moving

| Piece | Lives now | Moves to (merged repo / host) | Secret? |
|---|---|---|---|
| Portal + DNS + private CA | `~/home-network` | `services/network/` + `services/network/data/` | **Yes** |
| `.allen` Caddy routes | `~/home-network/Caddyfile` | `caddy/Caddyfile` | No |
| Poker game | `~/workspace/poker-game` | unchanged path (own repo) | No |
| Hypometer | `~/leafs-hypometer` | unchanged path | Certs |
| DDR HomeServer + media | `~/home-ddr` | `services/ddr/` | Media |
| Gmail daemon | `~/gmail-events` | unchanged path | **Yes** (OAuth) |
| Ollama + Qwen 27B | `~/mac-studio-ai-homeserver` | same repo | No |
| Watchlist poller | this repo | same repo | No |

**FACT (verified on the old Mac):** services currently bound: portal `UDP :53`,
`TCP :8443`; Caddy `:80/:443`; poker `:8080`; Ollama `127.0.0.1:11434`.
**FACT:** `~/home-network/data` holds the CA root/intermediate keys, issued certs,
`dns.json`, `reservations.json`, `state.json`, `cert_index.json`.

---

## 1. Before the box arrives (old Mac)

```bash
cd ~/mac-studio-ai-homeserver
./scripts/migrate/inventory.sh          # list what must move
./scripts/migrate/package-data.sh       # bundle secrets+media to ~/Desktop
```

Notes:
- The tarball contains **private keys and OAuth tokens**. AirDrop/SSH it; do not
  email it, do not commit it. Shred it after unpacking.
- `poker-game` and `gmail-events` can be re-cloned/re-copied; the irreplaceable
  bits are the `data/` dirs and OAuth files.
- **Rotate the DeepSeek key** currently sitting in
  `~/Library/LaunchAgents/com.gmail-events.daemon.plist` (plaintext) once Gmail
  is on local inference. The merged plist contains no key.

---

## 2. Prepare Rocinante

1. Create the user (`callen` assumed; the install script rewrites paths if not).
2. Install tools:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install python3 node caddy ollama
   ```

3. Put the repo in place:

   ```bash
   # clone or copy the merged repo
   git clone https://github.com/chris-l-allen/mac-studio-ai-homeserver.git ~/mac-studio-ai-homeserver
   ```

4. Unpack runtime data into the merged layout:

   ```bash
   cd ~/mac-studio-ai-homeserver
   # from the tarball created in §1
   mkdir -p services/network services/ddr
   tar -xzf ~/Desktop/homelab-migration-*.tar.gz -C "$HOME"
   rsync -a ~/home-network/data/  services/network/data/
   rsync -a ~/home-ddr/songpacks/ services/ddr/songpacks/
   rsync -a ~/home-ddr/media/     services/ddr/media/
   # gmail-events and leafs-hypometer stay at ~/gmail-events and ~/leafs-hypometer
   ```

5. Pull the model (≈22 GB, one-time):

   ```bash
   ./scripts/pull-models.sh        # hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K
   ```

6. Set the server's LAN address. Either:
   - **Same-IP swap (simplest):** after stopping the old services, give the
     Studio `10.0.0.11`; DNS, certs, and `PUBLIC_URL` need no changes.
   - **New IP (test in parallel):** give it e.g. `10.0.0.12`, then update
     `services/network/data/dns.json` records, the Caddy plist `LAN_IP`, the poker
     plist `PUBLIC_URL`, and the router's DNS to `10.0.0.12`.

---

## 3. Certs for the `.allen` hosts

Existing certs for `poker`, `homenetwork`, `hypometer` are in the copied `data/`.
The merged stack adds **`ddr.allen`** and **`llm.allen`**.

1. Start the portal alone first (needed to issue certs):

   ```bash
   cd ~/mac-studio-ai-homeserver
   python3 services/network/server.py
   ```

2. Open `https://<server-ip>:8443` (or `https://homenetwork.allen`), log in, and
   issue certs for `ddr.allen` and `llm.allen` (SANs: the `.allen` name + the
   server IP). Re-issue the others if their SAN IP is stale (`10.0.0.106` is
   still on the old certs).

3. Copy the newest leaf certs into the Caddy directory:

   ```bash
   ./scripts/migrate/copy-certs.sh
   ```

---

## 4. Start the services

```bash
cd ~/mac-studio-ai-homeserver
DRY_RUN=1 ./scripts/migrate/install-services.sh   # preview
./scripts/migrate/install-services.sh             # install + load
```

This loads:

| Label | Service | Port |
|---|---|---|
| `com.local.ollama` | Qwen 27B inference | `0.0.0.0:11434` |
| `local.home-network.portal` | DNS + CA + portal | `:53`, `:8443`, `:8081` |
| `local.home-network.caddy` | reverse proxy | `:80`, `:443` |
| `com.local.homeddr` | DDR library | `:8787` |
| `com.callen.holdem.agent` | poker | `:8080` |
| `local.hypometer.server` | hypometer | `:8899` |
| `com.gmail-events.daemon` | Gmail → Calendar (local LLM) | — |

> DNS on `:53` needs permission to bind a privileged port. If the portal log says
> it fell back to `5353`, run the portal as a LaunchDaemon or with the same
> privilege the old Mac uses.

---

## 5. Point Gmail at local inference

The daemon already supports it (`config.js`: `LLM_PROVIDER=ollama`). The merged
plist sets:

```
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://127.0.0.1:11434/v1
OLLAMA_MODEL=hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K
```

Verify the classifier before trusting it:

```bash
cd ~/gmail-events
node classify-test.js
```

Test the raw endpoint:

```bash
curl -s http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K",
       "messages":[{"role":"user","content":"Reply with the word: ready"}],
       "chat_template_kwargs":{"enable_thinking":false}}' | jq .
```

If the 27B model rejects `response_format: json_object`, add an Ollama-compatible
JSON hint in `classifier.js` (or keep the rule-based fallback).

---

## 6. Cutover

1. **Freeze the old Mac:** stop the services so the IP/ports are free.

   ```bash
   for l in local.home-network.caddy local.home-network.portal com.callen.holdem.agent; do
     launchctl unload ~/Library/LaunchAgents/$l.plist
   done
   ```

2. Point the **Rogers router's DNS** at the new server (if you changed the IP).
   The gateway is cloud-managed; only the DNS setting may stick — verify.
3. Re-run the verification below on the new box.
4. Keep the old Mac's data untouched for at least a week (rollback).

---

## 7. Verification (must all pass)

```bash
curl -sk https://homenetwork.allen/ | head           # portal
curl -sk https://poker.allen/ | head                 # poker
curl -sk https://hypometer.allen/ | head             # hypometer
curl -sk https://ddr.allen/health                    # {"status":"ok",...}
curl -s  http://127.0.0.1:11434/api/tags | jq        # qwen model present
curl -sk https://llm.allen/v1/models | jq            # OpenAI-compatible
```

From a phone on the LAN: open `https://ddr.allen/` and play a song; open
`https://homenetwork.allen/` and issue a test cert.

---

## 8. Rollback

If anything fails: re-load the old Mac's launchd units, point the router DNS back
at `10.0.0.11`, and leave Rocinante running only Ollama (harmless). The laptop's
repo and `data/` were never modified.
