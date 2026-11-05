---
layout: default
title: Objectives — Rocinante
---

# Objectives — Rocinante

**Server name:** **Rocinante** (macOS Computer Name / LocalHostName `Rocinante`; optional LAN alias `rocinante.allen`).
**Status:** agreed 2026-11-05 — implementation underway. This file is the source of truth for scope.

---

## A. Core mission (must-have)

1. **Rocinante is the server; the old Mac is a client.** The current Mac is the
   owner's personal laptop. It and every other device become **consumers** of
   services on Rocinante. After cutover the laptop runs no server roles.
2. **Host every `.allen` page and network service.** DNS for `allen`, private CA +
   device enrollment, Caddy, and the pages: `homenetwork`, `poker`, `hypometer`,
   `ddr`, `llm`.
3. **Local inference for sensitive work.** Qwen 3.8 27B behind an OpenAI-compatible
   API; Gmail processing and all other sensitive inference use it; no cloud calls.
4. **DDR station on the same box.** Project OutFox + the song/media library,
   published at `ddr.allen`.
5. **Clean migration with rollback.** Code + data + secrets copied intact, minimal
   downtime, the laptop untouched as a rollback path until Rocinante passes
   verification.

## B. Operational

6. **Survive reboot.** Every service is a launchd unit — auto-start, auto-restart.
7. **Observable.** Health endpoints plus one monitor/dashboard.
8. **Backed up.** Config, CA, certs, DNS/state, OAuth tokens, and media; models can
   be re-pulled.
9. **Secret hygiene.** No plaintext keys in plists or git; the old DeepSeek key
   revoked; `data/` stays ignored.
10. **Reproducible and documented.** One merged repo, migration runbook, and a
    rebuild-from-scratch path.

## C. Principles / constraints

11. **LAN-only, no public exposure.** No port-forwarding; devices trust the private CA.
12. **Quiet, low power, 24/7.** Silent, roughly 10–20 W idle, on a shelf.
13. **Value-conscious.** No buying storage, ethernet, or capacity we won't use.
14. **Sensitive data never leaves the house.**

## D. Non-goals

- Public web hosting, model training/fine-tuning, frontier MoE models (400B+),
  gaming, and rewriting the poker/hypometer apps (hosted, not rebuilt).

## E. Done when

- Every `.allen` host returns 200 over HTTPS from a LAN client.
- `llm.allen/v1` answers and the Gmail daemon classifies a real email with **zero**
  cloud calls.
- `ddr.allen` serves the library and OutFox runs on Rocinante.
- Reboot test passes: all services return without help.
- The laptop can be powered off and rollback has been rehearsed.
- No secrets in git; the exposed key is revoked.

## Assumptions / open items

- **Box config:** M5 Max, 36 GB (from the Amazon listing) — confirm.
- **All on one box:** network + `.allen` pages + DDR + inference.
- **LAN-only:** no internet-facing pages.
- **Model/quant:** Qwen 3.8 27B at Q6 (~22 GB).
- **Laptop's role:** consumer only; kept as cold spare/rollback.
- **Backups:** target and frequency TBD.
- **Monitoring:** Uptime Kuma vs. simple health checks TBD.
- **Remote access:** Tailscale/WireGuard in scope or strictly in-house TBD.

## Revision log

- **2026-11-05:** A.1 revised — the old Mac is the personal laptop and becomes a
  consumer of Rocinante's services; the new server is named **Rocinante**.
