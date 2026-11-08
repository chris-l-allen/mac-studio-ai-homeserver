# Changelog — HomeDDR Kids Station

## v1.0.4 — 2026-11-08

Per-song difficulty is back, controlled with **Up/Down on the song screen**;
**Start** launches. No keymap changes, so the pad stays fixed.

### Added
- On the song screen the pad's Up/Down change the difficulty (Up = harder,
  Down = easier, wrapping Beginner → Easy → Medium → Hard → Challenge). The
  on-screen label updates live, and the hint reads `Up/Down: Difficulty  Start: Play`.
- This works because the song screen delivers the pad's Up/Down to a theme input
  callback (`button=Up/Down`), while gameplay still uses Up/Down as the
  gameplay directions — the callback only exists on `ScreenSelectMusic`.

### Why this is safe
- The keymap is still directions-only (P1 arrows, P2 W/A/S/D; menus unbound).
  No duplicate direction/menu bindings, so OutFox cannot drop the gameplay
  arrows.

### Verified
- Local and `.54`: Up → Easy, Up → Medium, Down → Easy, Enter → `ScreenGameplay`.
- `scripts/run-tests.sh` 13/13; `scripts/test-kids-random.sh` PASS.

## v1.0.3 — 2026-11-08

Fixes the **"pad only half works"** regression (menus worked, gameplay arrows did not).

### Fixed
- **Root cause (FACT):** v1.0.2 bound the pad's arrows to BOTH the gameplay
  directions and the menu buttons. OutFox does not reliably honour the direction
  side of a duplicate binding — it drops it — so the pad navigated menus but the
  four gameplay arrows did not all work. The keymap is now **directions only**
  again (P1 arrows; P2 W/A/S/D), menu buttons unbound.
- Removed the `chflags uchg` lock (a hack). The keymap is writable again; with no
  duplicates there is nothing for OutFox to normalize away. Verified the four
  directions and P2 bindings survive a clean quit.
- **2P selection:** the 1P/2P screen now reacts to *which player* pressed Start —
  P2 pressing SPACE joins 2 players, P1 ENTER starts 1 player. Verified
  `Players joined: P1, P2` on local and `.54`. (Arrows can't drive this screen
  because the base screen consumes them before Lua callbacks.)
- Synced the stale `.54` source checkout (`~/mac-studio-ai-homeserver` there is
  not a git repo) with this release's files.

### Deferred
- Per-song difficulty (Left/Right) is off again: it requires binding arrows to
  the menu buttons too, which is exactly what breaks gameplay arrows. A
  conflict-free control (e.g., spare pad buttons mapped to MenuLeft/Right) is
  the next safe design. Songs default to Beginner.

### Tests
- `scripts/run-tests.sh` — 13 unit tests (keymap has no direction/menu overlap,
  padbridge emits only arrows+Enter).
- `scripts/test-kids-random.sh` — random first song end-to-end.
- (Difficulty test removed while the feature is deferred.)

## v1.0.2 — 2026-11-08

Brings back per-song difficulty, safely, and restores 2P selection.

### Added
- **Per-song difficulty** with Left/Right again: Beginner → Easy → Medium →
  Hard → Challenge (wraps). Works for **1P and 2P**; the on-screen label updates.
  Verified end-to-end (`ChangeSteps(0, ±1)` and `ChangeSteps(1, ±1)`).
- `scripts/test-kids-difficulty.sh` — integration test for 1P and 2P difficulty.

### Fixed / how
- The pad's arrows must be both gameplay directions and `MenuLeft/Right` for
  difficulty, but OutFox clears one side of a duplicate binding when it rewrites
  `Keymaps.ini` on exit (what broke the pad in v1.0.0). The keymap is now made
  **immutable** (`chflags uchg`) after writing, so OutFox's exit-time rename
  fails (it only logs a warning) and the duplicate bindings survive. Verified
  across a clean Cmd+Q and relaunch.
- The 1P/2P chooser responds to Left/Right again (`MenuLeft/Right` are bound
  under the locked keymap), so 2P is selectable.

### Changed
- The on-screen hint no longer claims Up/Down song browsing (wheel Up/Down
  still does not move the wheel; tracked separately).
- To edit the keymap, use `scripts/fix-keymap.py` (it unlocks, writes, relocks)
  or run `chflags nouchg` first.

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
