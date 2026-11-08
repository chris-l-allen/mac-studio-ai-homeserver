# HANDOFF — 2026-11-07 — "K-Pop Demon Hunters / Baby Shark / Alvin not visible in OutFox"

**Status: BLOCKED (incomplete). The 3 new packs are installed, linked, and have assets +
`.sm` charts present, but we have NOT yet confirmed a clean scan of them by the running
game. Do NOT assume done.**

> NOTE (added this session): An earlier "active summary" in this thread was partly stale.
> It claimed `ingest_song.py` was updated/active in `services/ddr/scripts/`. It actually
> lives in the **skill** dir `skills/ddr-song-ingest/scripts/` (committed, clean in git).
> The 8 KPDH song dirs were already ingested on Nov 7 10:49 (full assets + `.sm` + `.ssc`).
> See "Ingestion script" section below.

---

## TL;DR — what's true right now (FACT unless marked)

- The 3 target packs are **installed AND symlinked into the dir OutFox scans**, and all
  symlinks **resolve to real `.sm` files** (verified with a script). ✔
- The 8 KPDH song dirs each have the expected asset set (`-banner/-bg/-cover/-cd.png`,
  `.ogg`, `.sm`, `.ssc`) — verified by `ls`.
- OutFox is **NOT currently running** (`ps aux | grep -i outfox` → nothing). No OutFox log
  has been written in the last 60 min.
- The **last real game log session** is `00:19:53–00:43:25` — it scanned ONLY the old songs
  (`Kids Easy/…`, `Hannah's Picks/…`). It **predates** our 07:06 local fix.
- So: we have **no clean observation** of the game scanning the new packs. The single most
  important next step is to **launch OutFox and tail the newest MainLog** for the 3 pack names.

**SELF-CORRECTION (important):** Earlier I reported "user restarted OutFox at 07:11:37."
That was **wrong** — `pgrep -f OutFox.app` was matching my own `bash -c` command (which
contained the string "OutFox.app"). The 07:11:37 timestamp was my grep process, not the app.
Treat any "already restarted" claim from this session as **unverified**.

---

## The root problem I found (two copies of the repo)

`/Users/callen/mac-studio-ai-homeserver/` exists in **two places**:

1. **LOCAL** — a real git checkout on this Mac (`origin chris-l-allen/mac-studio-ai-homeserver`).
   **This is the copy the running OutFox reads.**
2. **ON `.54`** (ssh alias `rosinate` = 10.0.0.54 = hypometer.allen) — a separate working copy.

Last session I installed the 3 packs on **`.54`** only. The running OutFox reads the
**LOCAL** `Songs/` → **LOCAL** `songpacks/`, so the new packs were invisible. Fix this session:
copied the 3 packs from `.54` → local `songpacks/`, and added the 3 missing symlinks.

---

## What was done THIS session (all verified)

1. Copied 3 packs from `.54` to LOCAL `songpacks/` via `tar cf - … | tar xf -`:
   - `K-Pop Demon Hunters` (29 MB, 15 charts, 8 songs — Golden Beginner+Easy, etc.)
   - `Highflyer's Rhythmic Garbage` (79 MB, 26 charts — Baby Shark Easy, etc.)
   - `Torukine` (61 MB, 24 charts — Alvin and the chipmunks Easy, etc.)
   - Local `songpacks/` now == `.54` `songpacks/` (8 packs).
2. Added 3 symlinks into `/Users/callen/Applications/OutFox/Songs/`:
   - `K-Pop Demon Hunters -> /Users/callen/mac-studio-ai-homeserver/services/ddr/songpacks/K-Pop Demon Hunters`
   - `Highflyer's Rhythmic Garbage -> …/Highflyer's Rhythmic Garbage`
   - `Torukine -> …/Torukine`
   - `Songs/` now has 8 links: Hannah's Picks, Highflyer's Rhythmic Garbage, K-Pop Demon
     Hunters, Kids Easy, secret-eggs, Stepmania Pop Hits Collection, Torukine.
3. **Verified all 8 resolve** (symlink → real dir → charts):
   ```
   ok      Hannah's Picks                 1 charts
   ok      Highflyer's Rhythmic Garbage   26 charts
   ok      K-Pop Demon Hunters            15 charts
   ok      Kids Easy                      19 charts
   ok      Stepmania Pop Hits Collection  88 charts
   ok      Torukine                       24 charts
   ok      secret-eggs                    1 charts
   ```
4. Ruled out a song filter/blacklist as the cause (all minimal/empty):
   - `Data/DefaultSongPreferences.ini` → `[Settings]` only, `SongCenter1Player=None`,
     `SongMinTNSToHideNotes=Invalid`, no noteskin.
   - `Data/NamesBlacklist.txt` → just `#P1#` / `#P2#`.
   - `Data/UserPrefs` → a directory (not the blocking file).
5. Confirmed via the 00:19 MainLog that the app scans `/Songs/<Pack>/<Artist - Title>` paths
   (e.g. `Song::LoadFromSongDir(/Songs/Kids Easy/Disney - A Dream Is a Wish Your Heart Makes)`).
   So the scan root is `/Users/callen/Applications/OutFox/Songs/` — exactly where our links are.
6. **Located `ingest_song.py`** (the active summary had it in the wrong dir):
   - Real path: `~/mac-studio-ai-homeserver/skills/ddr-song-ingest/scripts/ingest_song.py`
     (13,846 bytes, committed, clean in git).
   - Sibling files in the skill dir: `SKILL.md`, `ARCHITECTURE.md`, `purchase_song.py`.
   - It is **NOT** in `services/ddr/scripts/` (that dir has `build-player.py`, which
     `ingest_song.py` likely calls for local target).

### Minor non-issues I checked
- `pack.ini`: `K-Pop Demon Hunters/` HAS one; the other 2 new packs and the OLD visible packs
  do NOT. Old visible packs work without it, so unlikely the blocker. (Low priority.)
- `~/Library/Application Support/Project OutFox/Songs/` exists but is **empty** — not the scan dir.

---

## NEXT STEPS (in order)

1. **Launch OutFox** (open the app at `/Users/callen/Applications/OutFox/OutFox.app`).
2. **Tail the newest MainLog** while it scans:
   ```
   ls -t "/Users/callen/Library/Logs/Project OutFox/"*.log | head -1   # newest log
   # then:
   grep -iE "K-Pop Demon Hunters|Baby Shark|Torukine|Alvin" <newest MainLog>
   ```
3. **Branch on the result:**
   - **If the log shows `LoadFromSongDir(/Songs/K-Pop Demon Hunters/…)` etc.** → the game
     loaded them. If the user STILL doesn't see them → it's a **theme / search / filter /
     menu** issue (e.g. theme hiding non-DanceDanceRevision songs, or the select screen
     grouped by pack and the user is looking under a different name). Ask the user WHERE they
     expect the songs (which menu / pack name) and check `Appearance/Themes/…/Mermaid Kids`.
   - **If the log does NOT show them** → scan problem. Re-verify the symlinks, check the app
     for a song-count / "songs not found" at startup, and look at the ThemeLua log too.
4. **Confirm with the user** (Hannah's machine context): the 3 songs appear **under their own
   pack names** (`K-Pop Demon Hunters`, `Highflyer's Rhythmic Garbage`, `Torukine`), NOT under
   `Kids Easy`. If the user wants them grouped with the Disney songs, move the 3 target songs
   into `Kids Easy/` as curated symlinks (see `scripts/build-kids-easy.py` / `curate.py`).

---

## Ingestion script (reconciled this session)

- **Real location**: `~/mac-studio-ai-homeserver/skills/ddr-song-ingest/scripts/ingest_song.py`
- **Companion files** in the same skill dir: `SKILL.md`, `ARCHITECTURE.md`, `purchase_song.py`
- **Asset contract it emits** (per the active summary):
  - `<prefix>-banner.png` (1024×400)
  - `<prefix>-bg.png` (1920×1080)
  - `<prefix>-cover.png` (300×300)
  - `<prefix>-cd.png` (612×400)
  - `#DISCIMAGE` empty.
- **CLI flags** (per the active summary): `--prefix`, `--target`, `--remote` (`local` is default).
- **Local deploy path** (default `--target local`):
  `~/mac-studio-ai-homeserver/services/ddr/songpacks/<Pack>/<Artist - Title>/`
- **Remote deploy path** (`--remote`): target `callen@10.0.0.54`, root
  `/Users/callen/mac-studio-ai-homeserver/services/ddr/songpacks`. Method: `tar | ssh` (not `scp`).
- The 8 KPDH song dirs already contain the expected asset set + `.sm` + `.ssc` (timestamps
  Nov 7 10:49), consistent with a prior local ingest run.

> TODO: verify the CLI flags / asset contract above against the actual `ingest_song.py`
> source — the active summary's description was not re-read against the file this session.

---

## Key paths

| What | Where |
|---|---|
| Running OutFox app | `/Users/callen/Applications/OutFox/OutFox.app` |
| **Song scan dir (symlinks)** | `/Users/callen/Applications/OutFox/Songs/` |
| **LOCAL songpacks (what's read)** | `/Users/callen/mac-studio-ai-homeserver/services/ddr/songpacks/` |
| `.54` songpacks (mirror, via `ssh rosinate`) | `/Users/callen/mac-studio-ai-homeserver/services/ddr/songpacks/` (same path, different box) |
| **Ingest skill (script + docs)** | `/Users/callen/mac-studio-ai-homeserver/skills/ddr-song-ingest/` |
| Game logs | `/Users/callen/Library/Logs/Project OutFox/` (`…MainLog.<date>--<hh.mm.ss>.log`) |
| Song config | `/Users/callen/Applications/OutFox/Data/DefaultSongPreferences.ini`, `NamesBlacklist.txt` |
| Content index | `/Users/callen/workspace/ddr-content-index.md` |
| Linking script (note: it looks at `~/Library/Application Support/…` dirs, NOT `/Users/callen/Applications/OutFox/Songs`) | `services/ddr/scripts/link-songpacks.sh` |
| Kids curation scripts | `services/ddr/scripts/build-kids-easy.py`, `services/ddr/scripts/curate.py` |
| Local build helper (called by ingest for `--target local`) | `services/ddr/scripts/build-player.py` |

## Notes / gotchas for next time
- **Two machines, same path** — always confirm which copy OutFox actually reads. The running
  app reads the **LOCAL** checkout. `ssh rosinate` = `.54` is a *separate* working copy.
- **`ingest_song.py` lives in the skill dir**, not `services/ddr/scripts/`. Don't confuse it
  with `build-player.py`. If you need the ingestion entrypoint, look under
  `skills/ddr-song-ingest/scripts/`.
- `pgrep -f OutFox.app` can match your own shell command if the pattern is in it — use
  `pgrep -x OutFox` or `ps aux | grep 'OutFox.app/Contents/MacOS/OutFox' | grep -v grep`.
- The `Scripts/` + `Data/` + `Songs/` + `Appearance/` layout under
  `/Users/callen/Applications/OutFox/` is the live game dir (not `~/Library/Application Support`).
- `link-songpacks.sh` candidate dirs do NOT include `/Users/callen/Applications/OutFox/Songs` —
  so the links were added by hand. Fine for now; consider updating the script.
- `ddr-content-index.md` still labels the 3 packs "INSTALLED ON ROSINATE" — they're now on
  **both** `.54` and local. Minor doc tidy.
- Disk: local volume ~19 GB free.

## Sources (from ddr-content-index.md)
- K-Pop Demon Hunters → SMO pack 8936
- Baby Shark → Highflyer's Rhythmic Garbage, SMO pack 6857
- Alvin and the Chipmunks Theme → Torukine, SMO pack 8374
- Not yet sourced: Cocomelon, Danny Go!, Little Big, Oliver Tree.
