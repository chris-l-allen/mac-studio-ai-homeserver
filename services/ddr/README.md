# DDR HomeServer

Folded in from `chris-l-allen/home-ddr`. Serves the song pack + media library on
the LAN and runs alongside Project OutFox on the same box.

```bash
./scripts/serve.sh                       # http://127.0.0.1:8787
HOMEDDR_HOST=0.0.0.0 ./scripts/serve.sh  # expose on the LAN
```

Published at `https://ddr.allen` via Caddy. Content dirs (`songpacks/`, `media/`)
are gitignored; copy them from the old `~/home-ddr` during migration.

See [`docs/ddr.md`](../../docs/ddr.md), plus the original
[`ddr-setup.md`](../../docs/ddr-setup.md) and
[`ddr-homeserver.md`](../../docs/ddr-homeserver.md).
