# Skill: ddr-song-ingest

Use when the user wants to add a purchased song to the DDR / OutFox library:
“ingest this song”, “add [song] to DDR”, “prepare this track for the pad”,
“purchase and prepare a song”, “make a chart for …”.

## What it does

Turns a purchased audio file into a ready OutFox song folder:

```
songpacks/<Pack>/<Artist> - <Title>/
  audio.ogg            # audio.mp3 if ffmpeg has no vorbis encoder
  <Title>.ssc          # Beginner + Easy + Medium charts
  jacket.png           # album art
  banner.png
  bg.png               # blurred/darkened gameplay background
```

It does **not** complete the charge itself. No store exposes a public
"purchase this track" API, so buying is a hand-off: the helper finds the exact
track, prints price and store URL, and opens the store page in Music. The
signed-in user confirms the charge (password/Touch ID), which the platform does
not allow scripts to do.

## Purchase assistance

`scripts/purchase_song.py` searches the iTunes Store, ranks exact title/artist
matches, and only lists tracks with a real store price (Apple Music streams have
none). Then:

```bash
python3 ~/.config/opencode/skills/ddr-song-ingest/scripts/purchase_song.py \
  --title "Dumb Ways to Die" --artist "Tangerine Kitty" \
  --list                                   # see matches + prices
  --open --wait 300 --ingest --pack "Hannah's Picks"   # open, wait, ingest
```

- `--open` opens the chosen track page in Music.
- `--wait SECONDS` polls the media folder for the purchased download.
- `--ingest` hands the found file to `ingest_song.py` automatically.
- `--file PATH` skips purchase and ingests an existing file.
- Already signed in? Check with `defaults read com.apple.iTunes | grep Store`.

Apple Music subscription downloads are `.m4p` (DRM) — the scripts reject them.
Buy the iTunes Store version (`.m4a`); embedded album art is used automatically.

## Command

```bash
python3 ~/.config/opencode/skills/ddr-song-ingest/scripts/ingest_song.py \
  --file "/path/to/Track.m4a" \
  --title "Dumb Ways to Die" \
  --artist "Tangerine Kitty" \
  --pack "Hannah's Picks"
```

Options:

| Flag | Meaning |
|---|---|
| `--bpm` / `--offset` | override auto-detection |
| `--art` | cover image (when the file has none) |
| `--genre` | chart genre (default Pop) |
| `--normalize` | loudness-normalize audio |
| `--dry-run` | show BPM/offset/output path only |
| `--no-player` | skip rewriting the player page (it’s dynamic; normally unnecessary) |
| `--force` | overwrite an existing song folder |

## BPM / offset

- Auto-detected from the audio (pure Python; no extra deps).
- If confidence is **low**, pass `--bpm` (and optionally `--offset`).
- Detected BPMs are cached in `~/.cache/ddr-song-ingest/bpm.json`.

## After ingest

- The web player is **dynamic** (`/api/tracks`): the new song appears on refresh, or
  within 30 s. No rebuild needed.
- OutFox: if the pack already exists in `Songs/`, it appears on next launch. If it’s
  a new pack, re-run `scripts/migrate/outfox-setup.sh` to link it.

## Charts

Generates safe beginner-friendly patterns:

- **Beginner** — half notes, 2 rows/measure
- **Easy** — quarter notes, 4 rows/measure
- **Medium** — eighth notes, 8 rows/measure

These are playable auto-charts; refine in OutFox’s editor for tricky songs.

## Sanity test

```bash
# use an existing library track as the source
SRC="$(find ~/mac-studio-ai-homeserver/services/ddr/songpacks -name '*.ogg' | head -1)"
python3 ~/.config/opencode/skills/ddr-song-ingest/scripts/ingest_song.py \
  --file "$SRC" --title "Pipeline Test" --artist "Test Artist" \
  --pack "Test Ingests" --no-player
```

Check the folder under `songpacks/Test Ingests/`, then delete that pack.

## Failure modes

- `.m4p` → DRM; buy the iTunes Store version.
- no embedded art and no `--art` → pink/teal placeholder cover.
- low-confidence BPM → pass `--bpm`.
- existing folder → use `--force` or pick another title.
