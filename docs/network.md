---
layout: default
title: Network & .allen
---

# Network services & the `.allen` zone

The server is the LAN's DNS authority, private CA, and reverse proxy. Nothing is
exposed to the public internet.

## Host map

| Host | Backend | Port | Service |
|---|---|---|---|
| `homenetwork.allen` | portal (HTTPS) | `8443` | DNS admin, CA, cert issuance, device enrollment, dashboard |
| `poker.allen` | poker game (HTTP) | `8080` | Moonbeam Hold'em |
| `hypometer.allen` | hypometer (HTTP) | `8899` | Leafs hypometer page |
| `hockey.allen` | hypometer (HTTP) | `8899` | alias for the Leafs hypometer |
| `ddr.allen` | DDR HomeServer (HTTP) | `8787` | song + media library |
| `llm.allen` | Ollama (HTTP) | `11434` | OpenAI-compatible inference |

Plain-HTTP bootstrap at `http://<LAN_IP>/` serves `/set-dns.command` and
`/dns-profile.mobileconfig` and proxies enrollment paths to the portal's `:8081`
listener.

## DNS

- Zone: `allen`, served by `services/network/server.py` on `:53` (falls back to
  `:5353` if the privileged bind fails).
- Records live in `services/network/data/dns.json`.
- Static reservations live in `services/network/data/reservations.json`
  (name → MAC → IP), because the Rogers gateway can't do DHCP reservations.
- Unknown names are forwarded to the gateway (`10.0.0.1`).

### Client DNS (split + fallback)

The Rogers gateway cannot advertise custom DHCP DNS, so clients opt in:

- **Apple devices:** install `http://<LAN_IP>/dns-profile.mobileconfig`. It routes
  only `*.allen` to Rocinante; all other DNS stays on the ISP, so an outage of
  Rocinante affects only `.allen`.
- **macOS:** `services/network/set-dns.command` writes `/etc/resolver/allen` with
  `nameserver 10.0.0.54` (same split behavior).
- **Other devices:** DNS `10.0.0.54` primary, `10.0.0.1` fallback.

## Private CA

- Root + intermediate: `services/network/data/ca/` (**never commit**).
- Issued leaf certs: `services/network/data/certs/<cn>_<stamp>/`.
- The Caddyfile reads `services/network/data/tls/<host>.crt|.key`.
- `scripts/migrate/copy-certs.sh` copies the newest issued cert into `data/tls/`.

## Security

- `services/network/data/` is gitignored (keys, certs, password hash).
- The portal password/state is in `data/state.json`.
- `llm.allen` is LAN-only; there is no auth in front of Ollama. Keep the `allen`
  DNS internal to the house, and do not port-forward.
