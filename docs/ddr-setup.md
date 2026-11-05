---
layout: default
title: DDR setup
---

# HomeDDR — OutFox setup, pad, and kid-friendly charts

This doc covers running a DDR/rhythm station on the family Mac.

## 1. The engine: Project OutFox

- Free, open-source, cross-platform; a fork/continuation of StepMania.
- Supports dance pads, instruments, and standard StepMania `.sm` / `.ssc` song
  files.
- Official site: <https://projectoutfox.com/> · Downloads:
  <https://projectoutfox.com/downloads> · Wiki: <https://outfox.wiki/>

**FACT** (from the project site, 2026-11): the macOS release is a **Universal DMG**
(Intel + Apple Silicon); dance-pad support and `.sm`/`.ssc` import are listed
features.

**FACT** (owner, 2026-11-05): OutFox will run on a dedicated HomeServer box — a
refurbished **Mac Studio or Mac mini** — not on the current family Mac. That box is
not purchased yet, so installation is deferred.

**GUESS:** compatibility with the future box's macOS version is untested; verify at
install time.

### Install

Run this **on the eventual HomeServer box**, not the current family Mac:

```bash
./scripts/install-outfox.sh
```

The script opens the official downloads page; download the Universal macOS DMG and
drag the app to `/Applications`. macOS may block an unsigned app — use System
Settings → Privacy & Security → "Open Anyway" if prompted.

## 2. The pad

A USB dance pad presents as keyboard arrows, so no drivers are needed.

| Tier | Price (CAD) | Role |
|---|---|---|
| **Soft pad (bridge)** | $32–60 | **Buy now** to prove the rig; temporary, wears out |
| Foam pad | ~$100 | Optional middle ground |
| **Metal pad (L-TEK Core)** | CAD 389 goods + ~$64 Ontario import | **Final pad — deferred** until the bridge passes every test |

**Owner plan (2026-11-05): bridge now, upgrade later.** Buy a cheap local soft pad,
complete setup and test all four arrows plus a 1–3 foot chart, then order the L-TEK
Core. The project concludes when the final L-TEK pad arrives.

**Test:** open OutFox → Options → Input → Test Input; step on each arrow and confirm
the mapping. Repeat on the final L-TEK pad when it arrives.

## 3. Song packs

- Put `.sm`/`.ssc` packs in `songpacks/` (gitignored).
- `scripts/link-songpacks.sh` symlinks them into OutFox's `Songs/` folder.
- Prioritise packs with **low difficulties (1–3 foot)** for a 5-year-old.

## 4. Custom songs (Alvin and the Chipmunks)

OutFox loads community simfiles, so you *can* add custom charts for specific songs.
This is **manual work**: you need audio plus a chart (steps) matching the beat.
- Tools: the built-in OutFox editor, or external editors.
- Licensing: keep personal use in mind; don't redistribute copyrighted audio.

**INFERENCE:** well-known pop/chipmunk tracks may already have community charts;
search before authoring from scratch.

## 5. Kid mode

- Start on the easiest difficulties; turn off fail.
- Use a readable noteskin and a wide/distant **perspective** (the in-game camera
  angle — **not** a webcam) so the arrows are easy to see.
- Keep sessions short; DDR is physically tiring for small kids.
- Consider a second pad for co-op later.
