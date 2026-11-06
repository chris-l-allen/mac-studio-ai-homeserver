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

It does **not** download music. The user supplies a purchased, DRM-free file.

## Purchase step (manual)

- Buy the track in the **iTunes Store** (Music app) or another DRM-free store.
- Apple Music subscription downloads are `.m4p` (DRM) — the script rejects them.
- Save/purchase the file; embedded album art is used automatically.

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
