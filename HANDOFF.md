# HANDOFF — Rocinante home server + DDR

**Updated:** 2026-11-06
**Owner:** callen
**Repo:** `~/mac-studio-ai-homeserver` (branch `main`)
**Box:** **Rocinante** — Apple Silicon, macOS 27.0, **10.0.0.54** (`ssh callen@10.0.0.54`).

> Read this first in a new session. Deeper docs: `docs/objectives.md`,
> `docs/migration.md`, `docs/network.md`, `docs/inference.md`, `docs/ddr.md`.

---

## Mission

Rocinante is the one always-on box for the house:

1. **All `.allen` pages + network services** — DNS, private CA, Caddy, enrollment.
2. **Local inference** — Qwen 3.8 27B for Gmail and all sensitive inference.
3. **DDR / OutFox station** — song library, charts, custom theme.

The current Mac becomes a client. Nothing is public; `.allen` is LAN-only.

---

## Where we are (2026-11-06)

**Deployed and verified.** The old Mac still runs the 7 services at `10.0.0.11`
for rollback.

- **Box:** Apple Silicon, macOS 27.0 (26A425), 36 GB RAM, 386 GB free; hostname
  `Christophers-Mac-Studio.local`; **10.0.0.54** pinned on Wi-Fi (static).
- **IP caveat:** built-in Ethernet (`en0`, MAC `bc:89:c1:dd:03:86`) had no link, so
  Wi-Fi (`en1`) was pinned to the reserved `10.0.0.54`. If Ethernet is connected
  later, clear the static Wi-Fi address first to avoid a duplicate.
- **Services:** all 7 run as **boot-time LaunchDaemons** (`install-services.sh`);
  Caddy as root, the rest as `callen`. Verified after a cold reboot with **no user
  logged in**: SSH back in ~24 s, all services + model up.
- **Unattended boot:** FileVault **disabled** (required for unattended boot; the
  disk is no longer encrypted at rest), `pmset autorestart 1`, `sleep 0`.
- **Inference:** Qwen 27B Q6_K created locally (21 GB) after `ollama pull` failed
  with `Error: file does not exist`; `ollama list` shows
  `hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K`; `/v1/models` works.
- **Gmail:** classifier uses the local 27B. Fix: `/no_think` + `max_tokens: 1200`
  in `~/gmail-events/classifier.js`, and `OLLAMA_MODEL` in `~/gmail-events/.env`.
- **Certs:** re-issued with `IP:10.0.0.54` SAN; `copy-certs.sh` + Caddy reload.
- **DDR:** OutFox 0.5.0 installed at `/Applications/OutFox`; Mermaid theme/noteskin,
  photo loading screen, fail video; 4 packs linked, including `Hannah's Picks` /
  Dumb Ways to Die. `https://ddr.allen/` returns 200.
- **DNS:** the Rogers gateway **cannot** advertise custom DHCP DNS (no LAN DNS
  field; WAN DNS is ISP read-only). A split-DNS profile is served at
  `http://10.0.0.54/dns-profile.mobileconfig`: only `*.allen` -> `10.0.0.54`, all
  other DNS unchanged, so a Rocinante outage affects only `.allen`. macOS hosts
  with a stale `/etc/resolver/allen` must update it — `set-dns.command` now writes
  `10.0.0.54`.
- **Hosts:** `homenetwork`, `poker`, `hypometer`, `hockey` (alias → `8899`), `ddr`,
  and `llm` all resolve to `10.0.0.54`.

---

## Deployment bundle

`~/Desktop/Rocinante-Deploy/`

| File | Contents |
|---|---|
| `homelab-migration.tar.gz` | `home-network/data` (CA, certs, DNS, state), song packs, photo loading screen, `fail.mp4`, Gmail OAuth, hypometer data |
| `homelab-apps.tar.gz` | `~/gmail-events` (code + node_modules), `~/leafs-hypometer` |
| `poker-game-code.tar.gz` | poker source (no node_modules) |
| `OutFox-0.5.0-pre043.dmg` | DDR engine |
| `README.md` | morning runbook |
| `SHA256SUMS.txt` | checksums |

Verified: all four SHA256 checksums OK on the destination.

---

## Deploy sequence (as executed 2026-11-06)

1. SSH to `callen@10.0.0.54` (key installed with `ssh-copy-id -f`; the private key
   is `~/.ssh/id_rsa.tmp`).
2. Copy the bundle (`rsync`), verify `SHA256SUMS.txt`.
3. Fetch the repo with `curl` (git is a CLT stub until CLT is installed):
   `https://codeload.github.com/chris-l-allen/mac-studio-ai-homeserver/tar.gz/refs/heads/main`.
4. Unpack `homelab-apps.tar.gz` and `homelab-migration.tar.gz` into `$HOME`; poker
   into `~/workspace`; `rsync ~/home-network/data/` into
   `services/network/data/`.
5. Install CLT from the downloaded `CLTools_Executables.pkg` (`sudo installer
   -pkg ... -target /`); `softwareupdate` stalls on this box.
6. Install Homebrew from the `main` tarball into `/opt/homebrew` (the `master`
   tarball is retired); `brew install python node caddy ollama git ffmpeg`.
7. OutFox: copy the DMG's `OutFox/` to `/Applications/OutFox`; run
   `OUTFOX_ROOT=/Applications/OutFox ./scripts/migrate/outfox-setup.sh`; copy
   `Hannah's Picks` over and link it.
8. IP: set `10.0.0.54` in `dns.json`, `reservations.json`, Caddy `LAN_IP`, poker
   `PUBLIC_URL`; fix plists to `/opt/homebrew`; add `/opt/homebrew/bin/openssl` to
   the portal candidates.
9. `copy-certs.sh`; re-issue certs with `sans:["10.0.0.54"]` via the portal API.
10. `sudo ./scripts/migrate/install-services.sh` (LaunchDaemons, boot-time).
11. Model: `ollama pull` downloads the blobs but fails to write the manifest; create
    the model with `ollama create hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K` from the
    cached blob.
12. Gmail: `OLLAMA_MODEL` in `.env`; `/no_think` + `max_tokens: 1200` in
    `classifier.js`; run `node classify-test.js`.
13. `fdesetup disable` (unattended boot), `pmset -a autorestart 1 sleep 0`.
14. Reboot test with no user logged in; verify all services, `.allen` endpoints,
    `/v1/models`.

---

## DDR state

- Library: `services/ddr/songpacks/` (gitignored), 80 songs; `Artist - Title`.
- Theme: `services/ddr/outfox/Appearance/Themes/mermaid/`.
- Noteskin: `services/ddr/outfox/Appearance/NoteSkins/dance/mermaid/`.
- Player: `services/ddr/player.html` (dynamic; `scripts/build-player.py` writes it).
- HomeServer: `services/ddr/homeserver/server.py` — static + `/api/tracks` + Range.
- **Local-only assets:** `Mermaid Loading.local.png` (Hannah's photos) and
  `fail.mp4` are gitignored and packaged in the migration tarball.
- Watch: fail video is 6.8 s and looped — if `ScreenGameOver` advances sooner, trim
  or extend; long-note holds still use the default noteskin colors.

---

## Skill: `ddr-song-ingest`

Canonical install: `~/.config/opencode/skills/ddr-song-ingest/`; repo mirror at
`skills/ddr-song-ingest/`. See `SKILL.md` for the purchase hand-off and ingest.

- Purchase assist: `scripts/purchase_song.py` (iTunes Store search/open; the charge
  is confirmed by the signed-in user).
- Ingest: `scripts/ingest_song.py` (OGG, art, Beginner/Easy/Medium charts, BPM cache).
- `Dumb Ways to Die` (Tangerine Kitty) was purchased and ingested on 2026-11-06;
  SongBPM confirmed **128 BPM** (detector said 127.12 low-confidence).

---

## Privacy / security

- Hannah's photos/video are **local only** (gitignored; in the bundle).
- The migration tarball is **unencrypted** — move directly, then shred.
- **FileVault is OFF on Rocinante** (required for unattended boot). The disk is not
  encrypted at rest; physical access = data access.
- The old DeepSeek key was removed from the live plist and `.env`; rotate it if not
  already revoked.
- The photo loading image was force-pushed out of the branch after a brief commit;
  GitHub may still cache the old commit — contact Support to purge if needed.
- No secrets in git; `services/network/data/` is gitignored.

---

## Open items / next actions

1. **Client DNS:** install `http://10.0.0.54/dns-profile.mobileconfig` on Apple
   devices; on macOS also ensure `/etc/resolver/allen` is `10.0.0.54`
   (`set-dns.command`). Other devices: DNS `10.0.0.54` primary, `10.0.0.1` fallback.
2. **Cutover:** once every client uses the profile/command, the old Mac
   (`10.0.0.11`) is unused; stop its 7 services and keep it for rollback.
3. **Router:** the Rogers gateway cannot advertise custom DHCP DNS. Network-wide
   automatic DNS needs a bridge-mode gateway + a router that supports custom DHCP
   DNS (or a dedicated DHCP/DNS box).
4. **OutFox:** launch on Rocinante (login required for the GUI), select Mermaid,
   test a song + fail video. The app is not running headless.
5. **DDR songs:** ingest more via the skill; `Dumb Ways to Die` is in
   `Hannah's Picks`.
6. Optional: tint long-note holds; add more packs.

---

## Facts / versions

- Rocinante: Apple Silicon, macOS **27.0** (26A425), 36 GB RAM, LAN **10.0.0.54**
  (Wi-Fi static), hostname `Christophers-Mac-Studio.local`.
- Old Mac: Intel, macOS **26.5.2**, LAN **10.0.0.11**, hostname `callen-HGJJR31JW9`.
- Homebrew `/opt/homebrew`; Python **3.15.2**; Node **26.13.0**; Caddy **2.11.9**;
  Ollama **0.40.14**; ffmpeg **9.0.2**; OpenSSL **4.1.0**.
- OutFox **0.5.0 pre043**; model `hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K` (21 GB).

## Resume prompt

> Read `HANDOFF.md`. Rocinante is live at `10.0.0.54`; all 7 services are boot-time
> LaunchDaemons and survive a cold reboot with no login. Remaining: client DNS via
> the split-DNS profile, then cut over from the old Mac. The `ddr-song-ingest`
> skill is installed.
