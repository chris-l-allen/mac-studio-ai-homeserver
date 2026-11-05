---
layout: default
title: HomeServer
---

# HomeServer — LAN media + song library

A tiny, dependency-free static server for the HomeDDR project.

## Run

```bash
./scripts/serve.sh                      # http://127.0.0.1:8787 (local only)
HOMEDDR_HOST=0.0.0.0 ./scripts/serve.sh # expose to the LAN
```

Or directly:

```bash
python3 homeserver/server.py
```

## Configuration

| Env var | Default | Meaning |
|---|---|---|
| `HOMEDDR_HOST` | `127.0.0.1` | Bind address (`0.0.0.0` for LAN) |
| `HOMEDDR_PORT` | `8787` | Port |
| `HOMEDDR_ROOT` | repo root | Content root |

## Endpoints

| Path | Purpose |
|---|---|
| `/` | Landing page listing packs and media |
| `/songs/` | Browse/download song packs |
| `/media/` | Browse/download karaoke/audio |
| `/health` | JSON health check |

## Persistence

`launchd/com.local.homeddr.plist` keeps the server running at login.

```bash
cp launchd/com.local.homeddr.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.local.homeddr.plist
```

## Security

This is a **LAN-only** file server with no authentication. Do not expose it to the
public internet. If remote access is needed, put it behind the homelab reverse
proxy or a VPN (e.g. Tailscale), not a port-forward.
