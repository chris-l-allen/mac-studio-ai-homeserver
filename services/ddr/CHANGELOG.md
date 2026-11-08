# Changelog — HomeDDR Kids Station

## v1.0.1 — 2026-11-08

Fixes a **pad regression introduced in v1.0.0**. v1.0.0 is superseded — do not
deploy it.

### Fixed
- **Pad Down/Left stopped working after a game restart.** v1.0.0 bound the pad's
  arrow keys to *both* the gameplay directions and the menu buttons. OutFox
  clears one side of a duplicate direction/menu binding when it rewrites
  `Keymaps.ini` on exit (verified: one instance, clean Cmd+Q → `1_Down=` and
  `1_Left=` emptied). The keymap now binds the arrows to the **directions only**,
  and P2 to W/A/S/D directions only. Verified the minimal keymap survives a
  clean quit.
- Restored the pad on `.54` (Rocinante) and confirmed OutFox runs with
  `Theme: mermaid-kids` and all four directions bound.

### Changed
- **P2 joins with SPACE on the song screen** (late join). The 1P/2P chooser
  defaults to 1P because the base screen consumes the pad's arrows before the
  chooser's Lua callback; P2 pressing Space on the song screen joins as P2
  (`Players joined: P1, P2` verified). The chooser shows a hint.
- **Per-song difficulty (Left/Right) is deferred.** The pad's Left/Right must
  stay gameplay directions, and OutFox both clears duplicate direction/menu
  bindings on exit and consumes the arrows before Lua input callbacks. Songs
  still default to Beginner. Next idea: a launch-time keymap self-heal or a
  dedicated difficulty button.

### Removed
- The failing/aspirational `test-kids-difficulty.sh` (difficulty is deferred).

### Kept from v1.0.0
- Random first song (committed and played, no immediate repeats).
- P2 keyboard W/A/S/D gameplay directions.
- Pad safety: only arrows + Enter are ever emitted; Back and all unlabelled
  buttons are inert.
- Unit tests (`scripts/run-tests.sh`, 11 tests) and the random integration test
  (`scripts/test-kids-random.sh`).

## v1.0.0 — 2026-11-08 — SUPERSEDED (broke the pad after restart)

Do not deploy. Introduced duplicate direction/menu key bindings that OutFox
clears on exit, leaving pad Down/Left unbound after a restart. Use v1.0.1.

Initial tagged release: random first song, difficulty Left/Right (later
deferred), P2 W/A/S/D, pad-safety test, changelog.
