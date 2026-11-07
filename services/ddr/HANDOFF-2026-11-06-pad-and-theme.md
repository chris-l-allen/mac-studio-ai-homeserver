# HANDOFF — DDR pad + Mermaid theme (2026-11-06)

**Status:** Theme/opening screen fixed. Rocinante deployed. Dance pad **working**
via a HID→keyboard bridge that bypasses OutFox's macOS joystick layer. See
"The pad — resolved" below.

**Owner:** callen
**Daughter pickup:** the owner had to leave to pick up his daughter. Do not ask him
to press/test the pad again unless he offers. Use the game's Test Input or a HID
monitor that labels every panel.

---

## The pad — resolved

FACT (verified):
- Pad is `0x0079:0x0011` "USB Gamepad", bcdDevice `0x0106` (the OSTENT mat).
  It reports 14 buttons, 0 axes, 0 hats.
- The OS delivers pad button events to a normal user process. A user-level
  `IOHIDManager` captured usages 1–4 when the arrow panels were pressed.
- OutFox's legacy joystick subsystem enumerates the pad ("buttons: 14") but
  receives **no button events**. The SDL GameController path also does not drive
  gameplay for this pad.
- A `CGEventPost` keyboard event from an SSH session **does** reach OutFox
  (verified: sending Return pushed a new screen in the game log).
- LaunchAgent-launched processes are denied key injection: the TCC database
  contains `/private/tmp/postkey | kTCCServicePostEvent | 0`. The
  `sshd-keygen-wrapper` binary has PostEvent and Accessibility granted, so
  children launched through SSH can inject keys.

FIX (working, verified by the owner playing): `padbridge` reads the pad via
`IOHIDManager` and posts keyboard events, bypassing OutFox's input layer. The
OutFox keymap binds the keyboard keys instead of joystick buttons. A LaunchAgent
keeps a localhost SSH session running the bridge, so it inherits sshd's TCC
grants and starts at login.

### Button map

Panels (verified live, ordered presses):
- usage 1 = Up, 2 = Down, 3 = Left, 4 = Right

Extras (Start/Back from the SDL2 Gamepad Tool mapping for this pad in
[OutFox issue #716](https://github.com/TeamRizu/OutFox/issues/716):
`back:b8,start:b9,dpup:b2,dpdown:b1,dpleft:b0,dpright:b3`; 5–8 and 11–14 are
best-effort guesses):
- usage 5 = `/` (Select), 6 = F1 (Coin), 7 = Scroll Lock (Operator)
- usage 8 = Enter (Start alt), 9 = Escape (Back), 10 = Enter (Start)
- usage 11–14 = F2–F5 (spare)

### Files / commands

On Rocinante, user `callen`:
- `~/bin/padbridge` — compiled bridge
- `~/Library/LaunchAgents/com.callen.padbridge.plist` — login service
- `~/Library/Logs/padbridge.log` — open result plus every press (`usage=N value=0/1 key=K`)
- `~/.ssh/padbridge_ed25519{,.pub}` — localhost key for the SSH loop
- Repo source: `services/ddr/scripts/padbridge.c`,
  `services/ddr/scripts/install-padbridge.sh`

Keymap: `~/Library/Preferences/Project OutFox/Keymaps.ini` now uses keyboard
bindings for P1: `1_Up=Key_up`, `1_Down=Key_down`, `1_Left=Key_left`,
`1_Right=Key_right`, `1_Start=Key_enter`, `1_Back=Key_escape`,
`1_Select=Key_/`, `1_Coin=Key_F1`, `1_Operator=Key_scroll lock`.

Revert / remove:
```sh
launchctl bootout gui/$(id -u)/com.callen.padbridge
rm ~/Library/LaunchAgents/com.callen.padbridge.plist \
   ~/bin/padbridge ~/Library/Logs/padbridge.log
# remove the padbridge_ed25519 line from ~/.ssh/authorized_keys
```

Notes:
- OutFox was restarted with legacy joystick mapping off
  (`InputUseOldJoystickMapping=0`) during diagnosis. The bridge works either way;
  restore to `1` only if reverting to native joystick.
- The old root daemon `com.callen.dancepad` is still installed but is inert
  (blocked by TCC). Remove with sudo:
  `sudo launchctl bootout system/com.callen.dancepad`
  `sudo rm /Library/LaunchDaemons/com.callen.dancepad.plist /usr/local/bin/dancepad`
- To remap a physical button: press it once, read `usage=N` from the log, change
  `kmap[]` in `padbridge.c`, and reinstall.

---

---

## Rocinante (deployment) — done and verified

- SSH `callen@10.0.0.54`; key `~/.ssh/id_rsa.tmp`.
- macOS 27.0, Apple Silicon, 36 GB RAM; IP pinned static on Wi-Fi.
- 7 services as **boot-time LaunchDaemons**; verified after cold reboot with no login.
- FileVault **off**, `pmset autorestart 1 sleep 0`.
- `.allen` hosts all 200: homenetwork, poker, hypometer, hockey, ddr, llm.
- Portal DNS + CA + certs + enrollment; split-DNS profile
  `http://10.0.0.54/dns-profile.mobileconfig`; macOS `/etc/resolver/allen` = 10.0.0.54.
- Qwen 27B `hf.co/unsloth/Qwen3.8-27B-GGUF:Q6_K`; `/v1` works.
- Gmail classifier uses the local 27B (`method: llm`, 0.98).
- DDR web player: 81 tracks / 4 packs; `https://ddr.allen/`.

---

## Mermaid theme — fixed this session (repo mirrored)

- Opening/loading photo was anchored at origin (`center()`); now
  `xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH,SCREEN_HEIGHT)`.
  **Owner confirmed the opening screen works.**
- Duplicate `Mermaid Loading.local.png` removed; `outfox-setup.sh` now deletes it
  after copying (`Mermaid Loading.png` keeps the photo). ThemeManager dupe gone.
- Fail video works (owner confirmed); `ScreenGameOver` timer 8 s; paths use
  `THEME:GetPathG`.
- Removed fallback Train/Dreamcast intro overlay on `ScreenNewInit` (photo visible).
- Noteskin: `_circle` note glows and `_rflash` receptor flash removed.
- Gameplay HUD/legend hidden: `ScreenTitleMenuJoin/Home` use the photo background;
  `ScreenGameplay underlay/Normal.lua` returns an empty ActorFrame.
- `stage Demo.png` added as a blank placeholder (copied `stage event.png`) to stop
  the MissingThemeElement dialog.
- Theme source: `services/ddr/outfox/Appearance/Themes/mermaid/` and
  `.../NoteSkins/dance/mermaid/`.
- Noteskin white backgrounds removed: `_arrow 1x8 (doubleres).png` and
  `_receptor (doubleres).png` now have transparent backgrounds (arrow sheet
  flood-filled so the white lift arrow survives; receptor interior cleared).
  **Do not leave `.bak` files inside the noteskin folder** — OutFox treats them
  as extra matches and throws `references a file ... which has multiple matches`.
- The visible arrow/receptor art occupied only ~45×42 / 51×51 of its 128px frame.
  It is now scaled/centered to fill the frame (premultiplied alpha), so the
  in-game arrows and target are ~2.5× larger. `Image.db` was cleared.

## Kids Easy pack (2026-11-06)

- `scripts/build-kids-easy.py` builds `songpacks/Kids Easy/`: 19 songs (Disney
  meter-1 + Dumb Ways to Die), each filtered to the dance-single **Beginner**
  chart only, with relative symlinks to the original media. `kidsify_note_lines`
  converts hold/roll heads to taps and drops tails/mines/jumps, so the Kids Easy
  copy is pure taps (no holds/rolls/jumps).
- Selection is by `#TITLE`, not folder name (Rocinante and the Mac Studio copy
  use different folder names for the Disney Channel pack).
- Deployed to Rocinante; `/Applications/OutFox/Songs/Kids Easy` symlinks to the
  repo pack. After rebuilding, delete
  `~/Library/Caches/Project OutFox/song.db` and restart OutFox to refresh.

## Mermaid Kids theme / Kids DDR launcher (2026-11-06)

- New `Appearance/Themes/mermaid-kids/` theme with `FallbackTheme=mermaid`, so
  it inherits the Mermaid photo, mermaid noteskin, hidden gameplay HUD, fail
  video, game-over timer, etc.
- Flow is stripped down: `[ScreenNewInit] NextScreen=Branch.TitleMenu()` and
  `Branch.AfterInit` skip **KnownBugs**; `[ScreenProfileLoad] NextScreen=
  "ScreenSelectMusic"` and `Branch.AfterProfileLoad` skip the Play Mode screen.
  `Branch.AfterProfileSave` returns `"ScreenSelectMusic"`, so a song always
  returns to the wheel (even on fail / the last stage).
- Song select uses the classic `_fallback` `ScreenSelectMusic` wheel, locked to
  the `Kids Easy` group: `Other/SongManager Kids Easy.txt` (`Kids Easy/*`) plus
  `SONGMAN:SetPreferredSongs("Kids Easy")` and
  `MusicWheel:ChangeSort("SortOrder_Preferred")` in
  `BGAnimations/ScreenSelectMusic background.lua`.
- That same file draws `Mermaid Loading.png` at ~0.35 alpha behind the wheel and
  sets the `musicWheelItemColor` / `sectionWheelItemColor*` env colors. The wheel
  uses the default theme's `MusicWheelItem *` and `MusicWheel highlight.lua`
  assets, with teal fallback colors; `[MusicWheel]` hides Roulette/Random/Portal
  and enables the highlight (`HighlightOnCommand`).
- Wheel navigation: `PreviousSongButton="MenuUp"`, `NextSongButton="MenuDown"`
  (pad up/down moves songs); group/difficulty buttons are on left/right and are
  effectively inactive with the single Kids Easy group.
- `[ScreenSelectMusic] NextScreen="ScreenGameplay"` skips Player Options.
- `[GameState] AllowLateJoin=0`; `Preferences.ini Center1Player=1` centers the
  single player and removes the empty second side.
- `~/Desktop/Kids DDR.app` launches `--theme=mermaid-kids`; its script force-
  kills any existing OutFox first (`pkill -9 -x OutFox`).
- `Customs -> ../mermaid/Customs` symlink is required so the menu background
  manager finds `Customs/MenuBackgrounds`.
- `[Game-dance] Theme` is currently `mermaid-kids`, so the normal OutFox icon
  also opens the Kids theme. To get the original mermaid Lua wheel back, set
  `[Game-dance] Theme=mermaid` or pick mermaid in Options → Theme.
- Verified: `Theme: mermaid-kids`; NewInit → TitleMenuHome (no KnownBugs);
  ProfileLoad → ScreenSelectMusic (no Play Mode); wheel on `Kids Easy`;
  `ScreenGameplay` directly; noteskin `cache mermaid`; no `Error playing command
  / diffuse` wheel errors; `Center1Player=1`.

## Dumb Ways to Die chart (2026-11-06)

- The paid original is `~/Media/Music/Tangerine Kitty/Dumb Ways to Die -
  Single/01 Dumb Ways to Die.m4a`; the game's `audio.ogg` is the same master
  (180.07 s vs 180.02 s, envelope lag 0 s). No public simfile exists (GitHub
  code search, Zenius-I-Vanisher official/user search, StepMania/Reddit, Bing/
  DDG); the paid file is the audio.
- Better method: **phr00t/AutoStepper v1.7** (Java, 137★). The paid m4a was
  converted to a tagged 320k mp3 and processed with
  `java -jar AutoStepper.jar input=... output=... duration=180`. It detected
  128 BPM / offset −0.263561 and generated 5 dance-single difficulties. The
  **Beginner** chart was imported into the song's `.ssc` (`#CREDIT:AutoStepper
  by phr00t.com`, `#OFFSET:-0.26356104`, `#BPMS:0.000=128.000`). AutoStepper is
  non-commercial with attribution.
- The Kids Easy copy is built from the same source by
  `scripts/build-kids-easy.py`; `kidsify_note_lines` turns hold/roll heads into
  taps, drops tails/mines/jumps. Current Kids Easy Dumb Ways: **200 pure taps**,
  no holds/rolls/jumps.
- `scripts/chart-dumb-ways.py` (the earlier hand-authored energy/pattern chart)
  is superseded and not used.
- If the AutoStepper beat phase feels early/late, adjust the `.ssc #OFFSET` in
  ~10 ms steps, or rerun AutoStepper with `tap=true` and tap 30 beats.

## Mermaid Kids wheel + pop folder (2026-11-06)

- Both `DDR.app` and `Kids DDR.app` use `mermaid-kids`: the working classic
  wheel with exactly two items, `Kids Easy` and `pop`, plus the Mermaid noteskin.
  No KnownBugs, no Play Mode.
- `Other/SongManager Kids Easy.txt` has two sections: `Kids Easy` and `pop`
  (`Stepmania Pop Hits Collection/*`). The `pop` folder holds the pop songs and
  the in-game secret `nothing to see here` (symlink in the Pop Hits pack).
- `BGAnimations/ScreenSelectMusic background.lua` sets the preferred wheel and
  picks a random song on entry only from `Kids Easy` + `pop`
  (`SONGMAN:GetSongsInGroup`, excluding `nothing to see here`), so the wheel
  cannot go empty when a song outside the preferred sort is selected.
- `Graphics/MusicWheelItem Song NormalPart.lua` draws the song title plus the
  current difficulty on each row; `BGAnimations/ScreenSelectMusic overlay.lua`
  shows the controls. `ToEnumShortString` is used directly because the Kids
  theme has no `Difficulty` language strings.
- The `ScreenGameplay background.lua` override was removed: it replaced the
  mermaid background video. Gameplay/failure video plays again.
- Prefs: `LifeDifficultyScale=0.000000`, `DefaultDifficulty=Easy`.
- Padbridge: only arrows (1-4), Enter/Start (8/10), and Esc/Back (9) are mapped;
  all other usages are inert. F1-F5/Scroll Lock/`/` mappings were removed
  (macOS F3/F4 opened Mission Control/Launchpad). Device removal exits so
  launchd reopens the pad on replug.
- Added `scripts/deploy-theme.sh`, `smoke-test.sh`, `backup-profile.sh`,
  `padbridge-status.sh`, `padbridge-logrotate.sh`.
- The overbuilt `mermaid-classic` full-library theme was deleted, removing the
  text doubling, Most Played/shortcuts, and buggy full-library wheel.
- Noteskin arrows/receptor are vector SVGs; the old PNGs are in
  `archive/noteskin-backups/`.
- Crash fix: OutFox aborts in `ScreenOptionsManageProfiles`
  (`GetLocalProfileIndexWithFocus`, SIGABRT) when there are no local profiles.
  A local `callen` profile was created under
  `~/Library/Preferences/Project OutFox/LocalProfiles/callen/` from the machine
  profile with `DisplayName=callen`; the game now loads
  `/Save/LocalProfiles/callen/`.
- Web-player secret was reverted; the secret is in-game only.

## Local mirror + verified theme (2026-11-06)

- Local OutFox at `~/Applications/OutFox` (copied from Rocinante; `Songs` is a
  subset symlinked to the repo). Config mirrored to
  `~/Library/Preferences/Project OutFox`.
- Local screen capture works. End-to-end verified:
  `ScreenNewInit` -> Enter -> title -> Enter -> profile -> `ScreenSelectMusic`.
- Local SelectMusic capture confirms song titles, per-row difficulty, and the
  controls legend. Gameplay capture confirms the mermaid background video plays.
- Folder counts hidden with `SectionCountX/Y=-9999` and
  `SectionCountOnCommand=visible,false;x,-9999;y,-9999`.
- Published to Rocinante with `deploy-theme.sh`; `smoke-test.sh` PASS
  (theme=mermaid-kids, no empty wheel/crash).
- Pad footer: green = Select/Join (Return), red = Exit.

## Still unrealized

- Full pad button map beyond the best-effort table; the extra buttons still need
  physical labels (press one, read `usage=N` from `padbridge.log`).
- `hockey.allen` still aliases the hypometer, **not** Jacob's house league
  (the house-league app was never found; not deployed).
- Mermaid theme is a **26/45** port (TODO.md): pre-menu removal, system options,
  style selection, failure transition, Sudden+/Hidden+, full evaluation.
- `stage Demo` is a blank placeholder, not a proper "STAGE DEMO" card.
- Router cannot advertise custom DHCP DNS; DNS is per-device via the split profile.
- Old Mac still runs the 7 services for rollback.

---

## Close-out

The pad failure was not a button-map problem. OutFox on this macOS enumerates
the pad but receives no button events; the OS delivers them fine to a
user process. The working fix is the `padbridge` HID→keyboard bridge above,
installed as `com.callen.padbridge`. The old root `dancepad` daemon is obsolete
and inert.
