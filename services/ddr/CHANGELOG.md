# Changelog — HomeDDR Kids Station

## v1.0.0 — 2026-11-08

First tagged release of the kids DDR station.

### Added
- **Random first song** on the kids wheel (Kids Pop): the chosen song is
  committed and actually played, and the same song is not repeated on
  back-to-back visits.
- **Per-song difficulty selection** with Left/Right: Beginner → Easy → Medium →
  Hard → Challenge, wrapping around. The on-screen label updates.
- **Player 2 keyboard** uses W/A/S/D for all four directions (plus Space =
  Start, Esc = Back), and those keys also drive the wheel/difficulty menus.
- **Tests**
  - `scripts/run-tests.sh` — unit tests for the keymap contract and the
    padbridge safety map (Python stdlib, no dependencies).
  - `scripts/test-kids-random.sh` — end-to-end: random pick is the song played.
  - `scripts/test-kids-difficulty.sh` — end-to-end: 1P Left/Right and 2P A/D
    cycle difficulty.

### Fixed
- The wheel always played the first song: `MusicWheel:SelectSong()` only moves
  the cursor. The theme now sets the preferred song and re-applies the sort so
  the engine commits it.
- Left/Right did nothing: `ChangeStepsWithGameButtons` is disabled in
  `_fallback`, and the keymap bound `MenuLeft/Right` to Delete/PgDn instead of
  the pad's arrows. Both are fixed; the broken Lua input callback was removed.
- A pad button could drop focus to the macOS desktop: `padbridge` maps usage 9
  (Back) and every unlabelled button to inert. Regression test added.
- Removed stale `CRAB` debug tracing.

### Known issues
- Song-wheel Up/Down browsing still does not move the wheel (pre-existing and
  outside this release's scope). The random pick, difficulty and play flow do
  work. The on-screen hint still mentions Up/Down.
- Full owner play-through on `.54` (Rocinante) after the release is still
  recommended.

### Deployment
- Theme, metrics and keymap applied to the local install and to `.54`
  (Rocinante). Theme backups live in `~/ddr-theme-backups/` on each machine.
- Verify with: `./scripts/run-tests.sh`,
  `VISITS=4 ./scripts/test-kids-random.sh`,
  `./scripts/test-kids-difficulty.sh`.
