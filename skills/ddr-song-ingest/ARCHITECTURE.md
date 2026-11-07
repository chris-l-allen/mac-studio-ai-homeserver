# Architecture — ddr-song-ingest

## Goal

One command from a purchased audio file to a playable OutFox song, with no manual
audio editing and no missing metadata/art.

## Pipeline

```
purchase (.m4a) ─► probe ─► audio.ogg ─► artwork ─► tempo/offset ─► .ssc ─► folder ─► verify
                              │           │            │
                              │           │            └─ cache BPM per artist|title
                              │           └─ embedded cover → jacket / banner / bg
                              └─ loudnorm (optional)
```

## Why these choices

- **OGG Vorbis** — universally supported by StepMania/OutFox and compresses well.
  MP3 is the fallback.
- **Charts generated locally** — a 5-year-old only needs Beginner/Easy; the
  generator emits half/quarter/eighth-note patterns with no jumps that require
  crossover skill. The user can refine in OutFox’s editor.
- **Tempo detection without dependencies** — aubio is ideal but was unavailable on
  this Mac (Homebrew build hung on a GNU mirror). The script uses a small
  onset-envelope + autocorrelation detector on an 8 kHz mono decode. It is
  approximate; `--bpm`/`--offset` overrides are first-class, and low confidence is
  reported.
- **BPM cache** — re-ingesting the same track (or fixing a chart) reuses the
  previously confirmed BPM.
- **Artwork** — embedded cover art is extracted at full quality, then derived to
  jacket/banner/background. Missing art gets a pink/teal placeholder with the
  nautical title font when available.

## Module boundaries

| Unit | Responsibility |
|---|---|
| `ffprobe` wrapper | duration, tags, stream/cover detection |
| `detect_tempo` | decode → onset → autocorrelation → (bpm, offset, confidence) |
| `placeholder_cover` | SVG → qlmanage → PNG |
| `scale_crop` | ffmpeg cover derivatives |
| `make_ssc` / `chart_block` | simfile header + generated charts |
| `main` | orchestration, validation, player refresh |

## Validation gates

- input exists and is not `.m4p`
- output audio probes successfully
- all four art/audio files exist
- `.ssc` contains `#TITLE`, `#ARTIST`, `#MUSIC`, `#BPMS`, `#NOTES`

## Extension points

- swap the tempo detector for `aubio`/`librosa` when available
- add a `--chartpack` to use curated charts
- add album-art fetch from the store
- purchase automation is a hand-off (search → open store page → user confirms);
  no store offers a scriptable charge API
- emit a course (`Songs`/`Courses`) entry for a “new songs” playlist
