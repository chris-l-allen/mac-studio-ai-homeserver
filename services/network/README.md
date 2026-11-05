# Network service — portal, DNS, private CA

Folded in from `chris-l-allen/homenetwork`. This is the `.allen` control plane:

- DNS server for zone `allen` (records + reservations), forwarding everything else.
- Private CA (root + intermediate) and per-host cert issuance.
- Device enrollment (`/setup`, `/install.sh`, `.mobileconfig`).
- Dashboard + JSON API (`/api/dns`, `/api/reservations`, `/api/certs/issue`).

## Run

```bash
./run.sh          # web on https://0.0.0.0:8443, DNS on :5353 (no root)
sudo ./run.sh     # DNS on :53
```

Or install `launchd/local.home-network.portal.plist`.

## Data

`./data/` holds the CA keys, issued certs, `dns.json`, `reservations.json`, and
`state.json` (password hash). It is **gitignored**. Move it intact during
migration; never commit it.

See [`docs/network.md`](../../docs/network.md).
