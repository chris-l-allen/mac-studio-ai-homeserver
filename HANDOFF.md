# HANDOFF — Rocinante home server + DDR

**Updated:** 2026-11-05
**Owner:** callen
**Repo:** `~/mac-studio-ai-homeserver` (branch `main`)
**Box:** **Rocinante** — new Apple Silicon Mac; arriving; SSH access pending.

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

## Where we are (2026-11-05)

- Hardware bought; arrival/SSH pending.
- **Deployment bundle complete:** `~/Desktop/Rocinante-Deploy/`.
- **DDR library:** 80 songs (Disney Channel 6, Disney Grooves 21, Pop Hits 53),
  renamed to **`Artist - Title`**.
- **OutFox:** Mermaid theme, palette-arrow noteskin, photo loading screen, pastel
  fail screen with video.
- **Web player:** dynamic `/player.html` + `/api/tracks`, with HTTP Range seeking.
- **New skill:** `ddr-song-ingest` (global + repo mirror).
- The old Mac is still running all 7 home services (no downtime).

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

Verified: CA root key + Gmail token + songpacks + photo/video in the tarball; all
migration scripts pass `bash -n`; plists pass `plutil`; Caddy validates; `ddr.allen`
and `llm.allen` certs verify OK.

---

## Deploy sequence

1. Copy the bundle to Rocinante; install Xcode CLT + Homebrew + `python3 node caddy ollama git`.
2. Clone the repo; unpack the bundle (`README.md` in the bundle has exact commands).
3. Install OutFox, then `OUTFOX_ROOT=/Applications/OutFox ./scripts/migrate/outfox-setup.sh`
   (copies theme/noteskin, swaps in the photo loading screen, installs `fail.mp4`,
   links song packs).
4. `./scripts/pull-models.sh` (Qwen 3.8 27B Q6, ~22 GB).
5. `./scripts/migrate/copy-certs.sh` (re-issue if the IP changed).
6. Choose the IP: same-IP swap (`10.0.0.11`) or a new IP → update
   `services/network/data/dns.json`, Caddy `LAN_IP`, poker `PUBLIC_URL`, router DNS.
7. `./scripts/migrate/install-services.sh`.
8. Gmail: re-auth (`bash ~/gmail-events/fix-auth.sh`) and run `node classify-test.js`.
9. Verify all `.allen` hosts, Ollama, Gmail, DDR, OutFox; reboot test.
10. Cutover; keep the old Mac for rollback.

**Interactive:** Xcode/Homebrew (sudo/GUI), Google sign-in, selecting the theme in
OutFox. Automatable via `scripts/migrate/deploy-remote.sh` once SSH is on.

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

**Reload opencode to load it.** Canonical install:
`~/.config/opencode/skills/ddr-song-ingest/`; repo mirror at `skills/ddr-song-ingest/`.

It takes a purchased, DRM-free audio file and produces a ready OutFox folder:
`audio.ogg` (native vorbis), `<Title>.ssc` (Beginner/Easy/Medium), `jacket.png`,
`banner.png`, blurred `bg.png`. BPM/offset auto-detect with `--bpm`/`--offset`
overrides and a BPM cache.

```bash
python3 ~/.config/opencode/skills/ddr-song-ingest/scripts/ingest_song.py \
  --file ~/Music/track.m4a --title "Dumb Ways to Die" \
  --artist "Tangerine Kitty" --pack "Hannah's Picks"
```

Tested on a library track: detector **89.29 BPM vs 90** (low-confidence flag),
OGG output, art, 3 charts; dynamic player went **80 → 81 → 80**. `.m4p` (DRM) is
rejected. Auto-charts are playable starting points; refine in OutFox's editor.

---

## Privacy / security

- Hannah's photos/video are **local only** (gitignored; in the bundle).
- The migration tarball is **unencrypted** — move directly, then shred.
- The old DeepSeek key was removed from the live plist and `.env`; rotate it if not
  already revoked.
- The photo loading image was force-pushed out of the branch after a brief commit;
  GitHub may still cache the old commit — contact Support to purge if needed.
- No secrets in git; `services/network/data/` is gitignored.

---

## Open items / next actions

1. Enable SSH; run the deploy (see above).
2. Pull the 27B model; verify `/v1`.
3. Re-auth Gmail; confirm local classification.
4. Install OutFox theme/noteskin; test loading, fail video, and a song.
5. Cutover IP/DNS; reboot test; keep rollback.
6. Reload opencode and run `ddr-song-ingest` on a purchased track.
7. Optional: tint long-note holds, add more songs, album art for purchased tracks.

---

## Facts / versions

- Old Mac: Intel, macOS **26.5.2**, LAN **10.0.0.11**, hostname `callen-HGJJR31JW9`.
- Python **3.14.6**; ffmpeg **9.0.1** (native `vorbis`, no `drawtext`).
- OutFox **0.5.0 pre043** (DMG saved).
- 7 home services live on the old Mac.

## Resume prompt

> Read `HANDOFF.md`. The box is Rocinante; SSH may be on. Continue with the deploy
> sequence, then verify. The `ddr-song-ingest` skill is ready after an opencode reload.
