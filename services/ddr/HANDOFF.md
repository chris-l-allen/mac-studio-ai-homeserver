# HANDOFF — HomeDDR + HomeServer

> Read this file first in any new session. It is the single source of truth for
> project state, decisions, and the next actions. Keep it current as work lands.

**Updated:** 2026-11-07
**Owner:** callen
**Repo:** `/Users/callen/home-ddr` (local git; remote optional)

---

## 1. Mission

Build a kid-friendly DDR/rhythm station for a **5-year-old girl** who loves
**dancing, singing, Alvin and the Chipmunks**, plus a tiny **HomeServer** that
publishes the song/media library on the home LAN. No console, no subscriptions.

Budget: the original **~$50–75 CAD** gift target is obsolete. With the $929 mini
gone, recommended phase 1 (16/512 mini + bridge pad) ≈ **$1,379–1,414 CAD**; phase
2 (L-TEK Core) ≈ **$600–665**; total ≈ **$1,979–2,079 CAD**. The 16/256 mini
alternative totals ≈ **$1,832–1,932** (see §7.1). No purchases made; budget not yet
approved.

---

## 2. Current state (verified 2026-11-05)

- **FACT** Repo scaffolded: README, HANDOFF, AGENTS, docs, HomeServer, scripts,
  launchd plist. Nothing installed on the Mac yet.
- **FACT** Host Mac: Intel `x86_64`, macOS `26.5.2`, 16 GB RAM.
- **FACT** Available tools: Python `3.14.6`, Node `25.5.0`, git, `gh` (logged in as
  `chris-l-allen`, repo scope), Homebrew.
- **FACT** No Project OutFox / StepMania in `/Applications`.
- **FACT** OutFox site lists macOS builds (Universal DMG, Intel + Apple Silicon),
  dance-pad support, `.sm`/`.ssc` loading. Latest dev **0.5.0 Final Alpha
  (2025-09-07)**; legacy **0.4.19 LTS** flagged outdated.
- **FACT** (2026-11-05) Owner **declined** installing OutFox on the current Intel
  family Mac. The DDR engine is to run on a dedicated **HomeServer box** — a
  refurbished **Mac Studio or Mac mini** — which has **not been purchased yet**.
- **INFERENCE** OutFox will run on the eventual Mac Studio/mini; verify the build
  architecture and OS version on that box at install time.
- **GUESS** OutFox works on macOS `26.5.2` — untested here. The future box may
  ship with a different macOS version; re-verify there.
- **FACT** Per owner (2026-11-05), HomeServer is verified to run on this Mac.
- **FACT** Repo is now **public** (2026-11-05), required for free GitHub Pages.
  A scan found no secrets, emails, or addresses before the switch.
- **FACT** Rendered docs site is live: <https://chris-l-allen.github.io/home-ddr/>.
  Pages build status `built`; `/`, `/ddr-setup.html`, and `/homeserver.html` all
  returned HTTP 200 with rendered HTML (verified 2026-11-05).
- **FACT** (2026-11-05) Owner changed the acquisition plan: buy a **cheap local
  soft pad as a bridge now**; do **not** order the L-TEK Core until the mini,
  OutFox, bridge pad, and HomeServer all test positive. The project concludes when
  the **final L-TEK Core arrives**.

---

## 3. Decisions made

| # | Decision | Rationale |
|---|---|---|
| 1 | Use **Project OutFox**, not official DDR | Official DDR isn't on macOS; OutFox is free, cross-platform, supports pads |
| 2 | Final pad: **metal L-TEK Core** (owner choice, 2026-11-05) | Durable arcade feel; CAD 389 goods + ~$64 import, ships from Poland. **Deferred until bridge tests pass** |
| 3 | Build HomeServer on **Python stdlib** | Zero dependencies; runs anywhere; trivial to maintain |
| 4 | Keep song packs/media **gitignored** | Large binaries; share via LAN or object storage instead |
| 5 | Follow existing homelab doc style | Consistency with `mac-studio-ai-homeserver` |
| 6 | Run OutFox on a **dedicated HomeServer box** (refurbished Mac Studio/mini), **not** the current family Mac (owner, 2026-11-05) | Owner's call; keeps the DDR station on the server. Hardware not yet bought |
| 7 | **Buy now (pending approval):** refurb **Mac mini M4 16/512 ($1,189 CAD)**, or **16/256 ($1,059)** to minimize spend, + **cheap local soft pad**; ship to **Toronto, ON**. L-TEK Core deferred | $929 unit sold out; 16/512 doubles storage for $130. No $600 pad commitment until tests pass. Street address and full postal code kept out of the repo |
| 8 | **Bridge now, L-TEK later:** complete setup and positive tests on a cheap soft pad, then order the **L-TEK Core**; project concludes when the final pad arrives (owner, 2026-11-05) | Avoids committing to the expensive pad before the rig is proven; keeps a Sunday bridge achievable |

---

## 4. Open questions

1. **Hardware** — which refurbished box: **Mac mini** (cheaper, low power) or
   **Mac Studio** (more headroom)? What budget, and Intel vs Apple Silicon?
   OutFox's macOS build is Universal, so either arch works in principle.
   **Recommendation (INFERENCE, not tested):** with the $929 unit gone, the refurb
   **Mac mini M4 16GB/512GB at $1,189 CAD** is the best value; the **16GB/256GB at
   $1,059** is the budget alternative. The $2,729 Mac Studio is overkill for this
   workload. 256GB may need an external SSD later for a big song/media library.
2. **Custom charts** — do we author Alvin & the Chipmunks charts (hours of manual
   work) or just use existing kid packs?
3. **Two pads** — single-player now, second pad later?
4. **Bridge pad** — which cheap local pad/store: Amazon next-day (~$32–60) or a
   Canada Computers/Best Buy pickup? Target **$30–60 CAD**.
5. **If the mini is late** — may we temporarily install OutFox on the current Mac
   to hit the bridge deadline? Owner previously declined this; needs a fresh OK.
6. **Reverse proxy** — publish HomeServer via the existing Caddy stack or keep it
   standalone on `:8787`?

---

## 5. Next actions (ordered)

1. **Buy phase 1 (awaiting explicit go-ahead):** refurb **Mac mini M4 16/512
   ($1,189 CAD)** — or **16/256 ($1,059)** to minimize — + a **cheap local soft
   pad** (~$32–60 + tax). **Do not order the L-TEK yet.**
2. On the mini: `./scripts/install-outfox.sh` → install OutFox, launch once;
   confirm the Universal build runs on that macOS version.
3. `./scripts/link-songpacks.sh`; drop 2–3 kid packs into `songpacks/`.
4. Test the bridge pad: all four arrows register and a 1–3 foot chart is playable.
5. Start HomeServer (`./scripts/serve.sh`) and load it from a phone on the LAN.
6. **Only if steps 2–5 pass:** order the **L-TEK Core** (CAD 389 goods + ~$64
   Ontario import + cart-quoted shipping).
7. When the L-TEK arrives: repeat the arrow/chart test. **Project concludes when
   the final pad is delivered and verified.**
8. Decide on custom Alvin charts; if yes, chart a short pack.
9. Add to `mac-studio-ai-homeserver` Caddy routing (future).

> **Contingency:** if the mini is late, temporarily install OutFox on the current
> Mac to keep the Sunday bridge alive — requires a fresh owner OK (previously
> declined).

---

## 6. Key commands

```bash
cd /Users/callen/home-ddr

./scripts/serve.sh                     # HomeServer on 127.0.0.1:8787
HOMEDDR_HOST=0.0.0.0 ./scripts/serve.sh  # expose to LAN
./scripts/install-outfox.sh            # guided OutFox install
./scripts/link-songpacks.sh            # share song library with OutFox
```

---

## 7. Candidate purchases (prices checked 2026-11-05)

| Item | Price (CAD) | Link |
|---|---|---|
| **L-TEK Core (final pad — deferred)** | CAD 389 regular (240€ page) | https://www.iamats.com/shop/dance-mat-ltek-core/ |
| L-TEK Core via US reseller | $639 CAD (sold out) | https://ddrpad.com/en-ca/products/l-tek-core-dance-pad |
| VTech Kidi Superstar Jr. karaoke | $59.99 | https://www.amazon.ca/dp/B0BS2SCS2W |
| VTech Sing It Out karaoke mic | $46.96 | https://www.amazon.ca/dp/B09MVV6V5P |

> **Bridge first (owner, 2026-11-05):** buy one of the cheap soft pads below **now**
> as a temporary test pad. Do **not** order the L-TEK until the mini, OutFox,
> bridge pad, and HomeServer all test positive. The project concludes when the
> final L-TEK Core arrives.

| Bridge-pad options (buy now) | Price (CAD) | Link |
|---|---|---|
| OSTENT USB StepMania dance mat | $31.99 | https://www.amazon.ca/dp/B00FJ2KTXC |
| Domary USB dance pad | $38.60 | https://www.amazon.ca/dp/B0H8YNZ3Q9 |
| CVERY USB dance pad | $52.22 | https://www.amazon.ca/dp/B08DHZFHDX |

> Review counts were not readable by the scraper at research time; these are ranked
> by star rating + brand, not verified review volume. Re-check before buying.

### 7.1 Hardware research (2026-11-05)

**Apple Certified Refurbished (apple.com/ca, CAD, fetched 2026-11-05):**

**Re-checked 2026-11-05 after the $929 unit sold:**

| Item | Price | Status |
|---|---|---|
| Mac mini M4, 10-core CPU/GPU, **16GB / 256GB**, Gigabit | $929 (was $1,099) | **GONE** — no longer listed on the mini page |
| Mac mini M4, 10-core, **16GB / 256GB**, 10Gb Ethernet | **$1,059** | In stock ("Add to Bag"); specs verified |
| Mac mini M4, 10-core, **16GB / 512GB**, Gigabit | **$1,189** | In stock; specs verified; **recommended** |
| Mac mini M4, 10-core, **24GB / 512GB**, Gigabit | $1,439 | In stock; specs verified |
| Mac mini M4 Pro, 12-core CPU/16-core GPU, Gigabit | $1,949 | In stock; RAM/storage not verified |
| Mac Studio M4 Max, 14-core CPU/32-core GPU | $2,729 | In stock; RAM/storage not verified |

Refurb stock is limited and changes often. The $929 price still appears on a stale
Studio-page tile but **not** on the mini page — treat it as unavailable.

**L-TEK / iAmats (official, Poland; CAD prices are the vendor's own Canada reference):**

| Model | Price | Notes |
|---|---|---|
| **Core** | **CAD 389 regular** (240€ on product page) | 4 arrows, PRO panels, USB; **recommended** |
| Prime | CAD 486 regular (300€) | Illuminated Start/Select, switchable profiles |
| PRO X | from 279€ | All 9 panels printed |
| Core + Handbar | from 461€ | Bar is for advanced play; not needed for a 5-year-old |
| Handbar PRO alone | from 340€ | — |

- **FACT:** iAmats' own Canada guidance (verified 2026-09-13) lists the **Core at
  CAD 389** and Prime at CAD 486. Ships from Poland; 8–12 working days dispatch,
  then up to ~5 days courier. 2-year warranty, 14-day returns.
- **FACT:** official product page says the LTEK Edition software download is
  Windows-only, but the pad is plain USB and works with OutFox on macOS; verify
  with the actual unit.
- **FACT (Canada duty):** these pads classify under **9504.50.00.80**, where both
  MFN and CEUT rates are **Free** — **0% duty**, no CETA paperwork needed.
- **FACT (Ontario tax):** HST is **13%** on the goods' customs value. Qualifying
  international transport is excluded from that tax base (this corrects my earlier
  note that said "goods + shipping").
- **FACT (UPS fees):** disbursement is the greater of **3.7%** of advanced
  duties/taxes or **CAD 12**, plus 13% tax on that fee.
- **FACT (worked Core import estimate):** HST CAD 389 × 13% = **$50.57**;
  disbursement hits the **$12** minimum; tax on the fee **$1.56** →
  **≈ $64.13 CAD import payment** if paid online before delivery (add ~$6 ICOD if
  paid at the door).
- **FACT (shipping):** Canadian rates are weight-based and shown only in the cart.
  The US reference for one 18 kg pad is USD 151 (≈ CAD 210); **Canada differs**, so
  no Canadian shipping figure is quoted here.

**DDRPad.com (US reseller, en-ca storefront in CAD, fetched 2026-11-05):**

| Item | Price | Stock |
|---|---|---|
| L-TEK Core | $639 CAD | **Sold out** |
| L-TEK Prime + Bar | $1,335 CAD (sale; reg. $1,363) | 1 (USB + PS adapter) |

- Ships from Athens, Ohio; worldwide shipping; import taxes/duties may apply;
  30-day returns; shipping at checkout.
- The **$1,335** line is DDRPad's **Prime pad + steel Handbar** bundle (USB + PS
  adapter variant) — a premium, advanced-play package, **not** the Core. The bar
  is unnecessary for a 5-year-old; ignore this line for the project.

**Recommendation (INFERENCE / GUESS, no purchase made):**

- **Mac mini M4 16/512 @ $1,189 CAD — recommended now.** The $929 unit sold;
  $1,189 doubles the SSD over the $1,059 16/256 for $130, which is cheaper than
  adding an external SSD later. INFERENCE: 16GB RAM is plenty for OutFox + a static
  server. Choose **$1,059 16/256** only if minimizing spend; pick **$1,439 24/512**
  or the **$2,729 Studio** only for unrelated heavier workloads.
- **Bridge pad now** — one cheap soft pad (~$32–60 + tax) to prove the setup and
  survive the Sunday deadline. It is temporary, not the gift pad.
- **L-TEK Core later** — order only after the bridge tests pass. Goods + import
  ≈ **$453 CAD**; shipping is the open variable. A **GUESS** of ~$150–210
  shipping puts the Core at **~$600–665 CAD landed** — re-quote in the cart.

**Shipping destination (owner, 2026-11-05): Toronto, Ontario, Canada.** The full
postal code was derived and used only for the shipping estimate; it is deliberately
**not recorded** in the repo. Only the FSA **M6H** is stored, and the street
address is excluded.

**Phase 1 budget (now, GUESS):**
- 16/512 mini: $1,189 + 13% HST = **$1,343.57**; + bridge pad $35–70 →
  **≈ $1,379–1,414 CAD**.
- 16/256 mini: $1,059 + HST = **$1,196.67**; + bridge pad → **≈ $1,232–1,267**.
**Phase 2 budget (after tests pass):** L-TEK Core landed ≈ $600–665.
**Project totals:** 16/512 ≈ **$1,979–2,079**; 16/256 ≈ **$1,832–1,932**.
Re-quote both carts before buying; Apple's price excludes HST.

**Documented recommendation:** buy the **Mac mini M4 16/512 ($1,189 CAD)** and a
**cheap local soft pad now**. Order the **L-TEK Core (CAD 389)** only after the
mini, OutFox, bridge pad, and HomeServer tests pass. Pending explicit purchase
approval; nothing has been ordered.

---

## 8. Files of record

- `README.md` — what/why/architecture/layout/roadmap.
- `docs/ddr-setup.md` — OutFox, pad, kid difficulty, custom songs.
- `docs/homeserver.md` — server usage + LAN security notes.
- `docs/index.md` + `docs/_config.yml` — GitHub Pages landing page and config.
- `homeserver/server.py` — the server.
- `PROMO-IMAGES-KPDH-2026-11-07.md` — K-Pop Demon Hunters promo image
  replacement manifest (track → image mapping, sources, edits).
- `SOURCES.md` / `CURATION.md` — music library manifest / curation record.
- `scripts/*` — install/serve/link helpers.
- `launchd/com.local.homeddr.plist` — persistence.

---

## 9. Resume prompt

Paste this into a fresh terminal/session to continue:

```
Resume the HomeDDR + HomeServer project.

Repo: /Users/callen/home-ddr
Start by reading HANDOFF.md, then README.md and AGENTS.md.

Mission: a kid-friendly DDR/rhythm station on a family Mac (Project OutFox +
USB dance pad) for a 5-year-old girl who loves dancing, singing, and Alvin and
the Chipmunks, plus a tiny LAN HomeServer that publishes the song packs and
media.

Current state: repo scaffolded; docs live on GitHub Pages. OutFox is NOT to be
installed on the current Intel family Mac; owner wants it on a dedicated HomeServer
box (refurbished Mac mini recommended) that has not been purchased yet. Plan:
**bridge with a cheap local soft pad now**, test everything, then order the metal
L-TEK Core. The project concludes when the final L-TEK pad arrives. Current Mac:
Intel x86_64, macOS 26.5.2, 16 GB, Python 3.14.6, Node 25.5.0, git, gh, Homebrew.

Do next, in order:
1. Confirm budget/go-ahead: refurb Mac mini M4 16/512 ($1,189 CAD; 16/256 $1,059
   alternative) + a cheap local soft pad ($32-60). Do NOT order the L-TEK yet. No
   purchase without explicit OK.
2. Install Project OutFox on the mini (Universal DMG); verify it launches.
3. Test the bridge pad: all four arrows register; play a 1-3 foot chart.
4. Load 2-3 kid-friendly song packs via scripts/link-songpacks.sh.
5. Start HomeServer and confirm it loads from a phone on the LAN.
6. Only if tests pass: order the L-TEK Core (CAD 389 + ~$64 import + shipping).
7. Project concludes when the final L-TEK pad arrives and passes the same test.

Rules: follow the evidence discipline in AGENTS.md — label FACT / INFERENCE /
GUESS, never claim something works until tested here, and ask before installing
system software or buying anything. Keep HANDOFF.md updated as you go.
```

---

## 10. Changelog

- **2026-11-05** — Repo scaffolded: README, HANDOFF, AGENTS, docs, HomeServer,
  scripts, launchd plist. Git initialized.
- **2026-11-05** — Doc cleanup; recorded owner's need for a refurbished Mac Studio
  or Mac mini (separate).
- **2026-11-05** — Owner chose a **metal L-TEK** pad and **declined** installing
  OutFox on the current Mac; DDR engine moves to the future HomeServer box.
  OutFox install and pad tests are now blocked on hardware purchase.
- **2026-11-05** — Added hardware research (§7.1): refurb Mac mini M4 16/256 at
  $929 CAD recommended; L-TEK Core at CAD 389 recommended. Nothing purchased.
- **2026-11-05** — Documented the recommendation as decision #7; shipping region
  Ontario, Canada (street address excluded from repo). Awaiting purchase approval.
- **2026-11-05** — Made the repo public and enabled GitHub Pages from `docs/`.
  Live at <https://chris-l-allen.github.io/home-ddr/>; build `built` and all pages
  verified HTTP 200 with rendered HTML.
- **2026-11-05** — Owner set the **bridge plan**: buy a cheap local soft pad now,
  prove the rig, then order the L-TEK Core. Project concludes when the final pad
  arrives. Updated decisions, actions, budgets, docs, and resume prompt.
- **2026-11-05** — The $929 refurb mini sold out. Re-checked stock: **16/512 at
  $1,189** now recommended, **16/256 at $1,059** budget alternative; totals updated.
- **2026-11-07** — Replaced K-Pop Demon Hunters promo art: all 8 tracks now have
  per-track 1024×400 banners, 1920×1080 backgrounds, 612×400 CD-title cards, and
  raw single-cover jackets (built from official Wikipedia/Apple Music artwork via
  Pillow). 15 chart files (`#BANNER`/`#BACKGROUND`/`#JACKET`/`#CDTITLE`) and the
  pack banner repointed. Manifest: `PROMO-IMAGES-KPDH-2026-11-07.md`. Old
  `bg.png`/`cd.png`/`*-bn(2).png` kept for rollback. UNVERIFIED in a live OutFox
  render. NOTE: done in the LOCAL checkout (what running OutFox reads); the `.54`
  (`ssh rosinate`) copy still has the old art — sync if that box matters.
- **2026-11-07** — Theme pass for the kid setup (LOCAL checkout + local install
  only; NOT pushed to `.54` yet — owner reviewing). Changes:
  - `mermaid/BGAnimations/ScreenTitleMenuHome underlay.lua`: hide the top-left
    game-mode dropdown/connect box (`t[#t+1] = leftPaneArea` commented out).
  - `mermaid/Modules/UI/UI.MainMenu.lua`: "Play Now" goes straight to
    `ScreenSelectMusic` as guest (skips `ScreenSelectProfile`).
  - `mermaid-kids/BGAnimations/ScreenSelectMusic background.lua`: wheel preferred
    group switched `Kids Easy` → `K-Pop Demon Hunters` (fixes the empty wheel).
  - `mermaid-kids/Other/SongManager K-Pop Demon Hunters.txt`: REQUIRED companion
    for the new preferred group — the engine looks up `Other/SongManager <group>`.
    Without it, opening SelectMusic throws `Theme element ... could not be found`
    and OutFox exits (observed/fixed 2026-11-07).
  - `mermaid/Scripts/Main.lua` + `metrics.ini`: added `Branch.AfterGameplay`
    (returns `ScreenGameOver` when `AllFailed`, else `ScreenEvaluationNormal`)
    and set `[ScreenGameplay] NextScreen=Branch.AfterGameplay()`; kids
    `[ScreenGameOver] NextScreen="ScreenSelectMusic"` so the fail video plays then
    returns to the wheel. Failure routing UNVERIFIED (needs a live fail test).
  - K-Pop backgrounds regenerated: sharp cover panel on a soft ambient instead of
    the 28px blur (`/tmp/gen_bg.py`); originals backed up to
    `services/ddr/archive/kpdh-bg-orig/`.
  - Verified locally: theme loads, 8 songs found, dropdown gone. Wheel/guest/fail
    flow need an owner play-test. "PROFILES" menu button left in place.
- **2026-11-07** — Guest mode, no profile system (owner requirement). Fixed the
  *actual* Play Now source (`ScreenTitleMenuHome underlay.lua` `profileOrTutorial`
  now returns `"ScreenSelectMusic"`), and hid the profile UI: song-select profile
  bar / score graph / preview notefield (`Modules/Wheel/Objects/{PlayerArea,
  ChartInfo,Notefield}.lua` return empty), evaluation profile bar (same module),
  and the in-game avatar (`ScreenGameplay underlay/layered/profileArea.lua`).
  Verified: `TitleMenuHome -> ScreenSelectMusic` directly (no profile screen),
  the dark profile panel on song select is gone, K-pop wheel still lists 8 songs.
  Still present: main-menu "Profiles" button (hide needs a grid-skip adjustment)
  and the song-select "Hannah" collage background (theme art, not profile data).
- **2026-11-07** — CORRECTION: the "dark box in the top-left" was on the
  **gameplay** screen, not song select. Cause (verified with flat-gray song
  backgrounds): `mermaid-kids/BGAnimations/ScreenGameplay underlay.lua` drew its
  35% dim with `zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)` on a quad anchored at (0,0),
  so only the top-left quadrant darkened. Fixed to `FullScreen()` (uniform dim).
  Post-fix flat-gray test is uniform (~59) with no quadrant darkening. The earlier
  "song-select dark box gone" claim was **wrong** — that screen was a different
  screen; the song-select profile panels do not draw this box.
- **2026-11-07** — Owner wants **no gameplay dim** and the full HUD. Removed
  `mermaid-kids/BGAnimations/ScreenGameplay underlay.lua` entirely (archived to
  `archive/theme-review-baks/ScreenGameplay underlay.lua.guest`). Note: an
  **empty** file of that name still shadows the base HUD (score/lifebar/stage/
  timer disappear); deleting it loads `mermaid/BGAnimations/ScreenGameplay
  underlay/default.lua` — full HUD, no kids dim box. Flat-gray test suggested a
  residual ~0.7 factor; no hard box, possibly capture color-profile — unverified.
- **2026-11-07** — PUSHED to `.54` (`rosinate`) per owner: rsynced `mermaid` +
  `mermaid-kids` themes (`--delete`; only the kids `ScreenGameplay underlay.lua`
  was removed) and the 8 `K-Pop Demon Hunters/*/*-bg.png` (local/remote md5 match:
  `f29d1b2f…` for Your Idol). Restarted via `~/Desktop/DDR.app`. Verified remote:
  underlay gone, `ScreenTitleMenuHome underlay` returns `ScreenSelectMusic`,
  `SongManager K-Pop Demon Hunters.txt` present. Could not screencapture `.54`
  over SSH ("could not create image from display"). Fail-video path still
  UNVERIFIED on `.54`.
- **2026-11-07** — Guest-only system (LOCAL, verified): removed the "Profiles" and
  "Fitness" main-menu buttons (`UI.MainMenu.lua` `buttonInfo` + `ScreenTitleMenuHome
  underlay.lua` `MenuList`); attract/join buttons and the free-play join now go to
  `ScreenSelectMusic` (`_Attract PlayerButtons.lua`, `ScreenTitleMenuJoin
  underlay.lua`); removed "Change Profile" from the song-select options
  (`Modules/Menus/SelectMusicOptions.lua`). Verified locally: menu shows Play Now /
  Settings / Editor / Jukebox / Quit only; log `ScreenTitleMenuHome ->
  ScreenSelectMusic` (no `ScreenSelectProfile`); K-pop wheel loads; no exceptions.
  NOT pushed to `.54` yet; `.54` `DefaultLocalProfileIDP1` still to clear.
- **2026-11-07** — FAIL-CRASH FIX (pushed to `.54`): on fail the kids
  `[ScreenGameOver] NextScreen="ScreenSelectMusic"` sent the game to song select
  with **0 joined players** → FATAL "No compatible styles for dance with 0
  players" (SIGABRT, app exits). Removed the kids `[ScreenGameOver]` override so
  the base applies: `ScreenGameOver` (fail.mp4, 6.79s) → 8s timer → `NextScreen=
  "ScreenInit"` → `Branch.AfterInit()` → `Branch.TitleMenu()` → `ScreenTitleMenuHome`
  (back to start). Pushed `mermaid-kids/metrics.ini` to `.54` and restarted;
  verified base `NextScreen="ScreenInit"`, `TimerSeconds=8`, no kids override.
  Runtime fail not reproduced locally (Beginner forgiving at 86 misses) — owner to
  confirm on `.54`.
- **2026-11-07** — Fail page simplified (owner: "just the video and the reset"):
  `ScreenGameOver` now uses `Class="ScreenWithMenuElements"` (was `ScreenEnding`
  → `ScreenAttract`, which drew the engine's Continue/Screenshot menu), with
  header/footer/help/back hidden and `ResetGameState=true`. The underlay fires
  `SCREENMAN:SetNewScreen("ScreenTitleMenuHome")` after 7s, so fail → fail.mp4
  (~6.8s) → title (back to start), no menu. Verified locally: log
  `ScreenGameOver → ScreenTitleMenuHome` after ~7s, video shown, no buttons.
  Pushed `mermaid` + `mermaid-kids` themes to `.54` (also carries the guest-only
  menu changes) and restarted; verified Class, auto-reset call, no kids override,
  no `ScreenOptionsManageProfiles` in the main menu.
- **2026-11-07** — "Song ends right away / weird circle screen" fix: the engine's
  hold-Start give-up (`[ScreenGameplay] StartGivesUp=true`, `GiveUpSeconds=2.5`)
  plus the base gameplay HUD's `UI.HoldClickArea` (mouse-hold give-up, exposed
  when the kids underlay was removed) posted `SM_NotesEnded` (`m_gave_up=1`) →
  `ScreenEvaluationNormal` (the "circle" result page), not the fail video. Fix:
  `[ScreenGameplay] StartGivesUp=false` and `allowTouch=false` in
  `ScreenGameplay underlay/default.lua`. Pause-menu Give Up still works. Verified
  locally (song starts `ScreenGameplay` and keeps playing, no give-up); pushed to
  `.54` and restarted. NOTE: a running OutFox keeps old metrics in memory — always
  restart after metric edits.
- **2026-11-07** — Miss-fail now actually works: added a watcher in
  `ScreenGameplay underlay/default.lua` (`LifeChangedMessage` →
  `LifeMeter:GetLife() <= 0.01` → `SCREENMAN:SetNewScreen("ScreenGameOver")`).
  Verified in the theme log: `mermaid LifeSetting P1 = LifeType_Bar`, then
  `mermaid life empty -> fail` → `ScreenGameOver`. Drain `LifePercentChangeMiss=
  -0.010` (~100 missed notes to empty the bar, 8× more forgiving than the -0.08
  default). Hold-Select give-up (`StartGivesUp=true`, `GiveUpSeconds=3`) and
  `Branch.AfterGameplay` (incomplete → `ScreenGameOver`) both route to the fail
  video → home. Deployed to `.54` and restarted. **KEY LESSON: the owner plays on
  `.54` (Rocinante); deploy there, not just the local laptop install.**
- **2026-11-07** — Miss-fail calibrated to **30**: the per-miss drains live in
  `[LifeMeterBar]` (starts at `InitialValue=0.5`), **not** `[Gameplay]` — that's
  why all earlier drain edits did nothing (the theme used the `_fallback`
  `LifePercentChangeMiss=-0.080`, i.e. ~6 misses). Fix: theme `[LifeMeterBar]`
  `LifePercentChangeMiss=-0.0167` (others scaled) → bar empties after ~30 misses.
  Also `applyPartyOptions` now calls
  `GetPlayerOptions("ModsLevel_Preferred"):FailSetting("FailType_Immediate")` (the
  old `po.NoFail=false` was an invalid no-op), and the life watcher
  (`LifeMeter:GetLife() <= 0.01` → `SCREENMAN:SetNewScreen("ScreenGameOver")`)
  routes to the fail video. Verified trace: `mermaid life empty -> fail,
  misses=30` → `ScreenGameOver`.
- **2026-11-07** — Hi-res art upgrade for existing tracks (official covers from
  the internet, no AI generation). Sourced 40 covers via the iTunes/Apple Music
  catalog (1400–3000 px) into `services/ddr/media/<slug>/`; staged clean
  scale_crop art (banner 1024×400, bg 1920×1080, jacket 1024, cd 612×400) and
  replaced the low-res art **in place, using each song's referenced filenames**,
  for the 15 tracks already in the library: Baby Shark, The Fox, Dumb Ways to
  Die, Chandelier, Gangnam Style, Uptown Funk!, Call Me Maybe, Can't Stop The
  Feeling, Shake It Off, Roar, Good Time, Let It Go, Shut Up and Dance, Counting
  Stars, Cheerleader. Baby Shark / The Fox `.sm` refs set explicitly and a
  `Baby Shark-bg.png` symlink added under `Kids Easy`.
  Repo `songpacks/` on `.54` is the master; `Songs/<pack>` is a **symlink** to
  it (all packs except `Outfox`). **CRITICAL LESSON: never use
  `rsync --backup-dir` here — macOS `rsync` is openrsync and it deleted the
  real-dir `Songs/` copies (Stepmania 54→12, all ogg).** Recovered because the
  repo was intact: re-pointed Hannah's / Highflyer's / Stepmania `Songs/` entries
  as symlinks to the repo. Ship files with `tar | ssh` (also safe for spaces and
  `()` in names), not rsync. Art backups: `~/ddr-art-backups/` on `.54`.
- **2026-11-07** — Kid wheel now surfaces the upgraded tracks. Added a curated
  `Other/SongManager Kids Pop.txt` category (the 15 tracks + `K-Pop Demon
  Hunters/*`) and set `SetPreferredSongs("Kids Pop")` in
  `mermaid-kids/BGAnimations/ScreenSelectMusic background.lua` (random pick pool =
  K-Pop + Kids Easy). Also added hi-res `#JACKET` (1024²) to the 7 of 15 that
  lacked one (Baby Shark, The Fox, Gangnam Style, Call Me Maybe, Shake It Off,
  Shut Up and Dance, Counting Stars). Verified via ThemeLua log:
  `KIDSPOP wheel items=15` and K-Pop banners still load. NOTE:
  `~/Library/Logs/Project OutFox/` (`ProjectOutfox.Crash.*`) is written every
  run — tiny/0-byte entries are sink placeholders, not real crashes.
- **2026-11-07** — Fixed the "Kids Pop" wheel (15 didn't show; only K-Pop did).
  Cause (verified in StepMania `SongManager::UpdatePreferredSort` + `Song::Matches`):
  in `Other/SongManager <name>.txt`, a line ending in `/*` adds a whole **group**,
  but any other line goes to `FindSong(line)` → splits `Group/Song` and matches
  the **song folder name** case-insensitively (NOT a glob). My earlier
  `Group/Song*` lines therefore matched nothing; only `K-Pop Demon Hunters/*`
  worked. Fix: list exact `Group/FolderName` lines with **no `*`** (e.g.
  `Stepmania Pop Hits Collection/Shake it off 2`), keep the group line as
  `K-Pop Demon Hunters/*`. `SetPreferredSongs("Kids Pop")` loads
  `{theme}/Other/SongManager Kids Pop.txt`.
- **2026-11-08 — HANDOFF (state as left, branch `feature/two-player`)**

  **Deployed target:** `.54` (rosinate), OutFox launched with `--theme=mermaid-kids`.
  Theme at `/Applications/OutFox/Appearance/Themes/mermaid{,-kids}`. Deploy with
  `tar -C <srcdir> -cf - . | ssh rosinate 'tar -C <dstdir> -xf -'` — **never** rsync
  here (macOS openrsync + `--backup-dir` deleted files previously).

  **Verified working (1P + 2P):**
  - First page is a 1P/2P chooser (`ScreenSelectPlayers`, pad-driven). 1P → song
    select → play. 2P → joins P1+P2, versus **split view** (two note fields, two
    life bars).
  - P2 keyboard works: **W A S D + Space** (Start), Esc (back); P1 = pad
    (arrows + Enter). Keymap at `~/Library/Preferences/Project Out Fox/Keymaps.ini`.
  - Combined result: `ScreenWin` if ≥1 enabled player reaches the song end, else
    `ScreenGameOver`; per-player **OUT** indicator when a life bar empties;
    `FailType_ImmediateContinue` so one player can fail while the other continues.
  - Kids Pop wheel (`Other/SongManager Kids Pop.txt`): K-Pop (8) + the original
    Kids Easy/Stepmania set + 16 female-pop tracks (Bad Blood, Wildest Dreams,
    Blank Space, Style, Chained To The Rhythm, Applause, Bad Romance, Problem,
    Symphony, Rather Be, The Greatest, I Really Like You, Cool Kids, All About
    That Bass, Stronger, A Thousand Miles) — all with hi-res art.

  **Known issues / open:**
  - Per-song **difficulty selection (Left/Right on the wheel) does nothing** — has
    never worked in this theme. A `forceEasiest` handler in
    `ScreenSelectMusic background.lua`/`overlay.lua` currently defaults each song
    to Beginner; an attempted Left/Right cycling input callback did not take.
    Root cause not yet established (do not assume cache).
  - **Crab Rave**: originally added by a non-standard generator (SM-style
    `#NOTES`, **no measure commas** → 0 charts → hidden from the wheel). Re-added
    via the real `ddr-song-ingest` skill as
    `StarrySergal's Flamin Hot Munchies/Noisestorm - Crab Rave` (valid `.ssc`,
    generated art); old `Crab Rave - [StarrySergal]` folder removed and the
    `StarrySergal's Flamin Hot Munchies` pack symlinked into
    `/Applications/OutFox/Songs/`. Its on-screen appearance still needs a visual
    review/polish.
  - Temporary debug `Trace("CRAB …")` logging remains in
    `ScreenSelectPlayers underlay/default.lua` and `ScreenSelectMusic background.lua`
    — remove.
  - During troubleshooting, `~/Library/Caches/Project Out Fox/song.db` and
    `Image.db` were deleted and are rebuilt by OutFox. This is **not** part of the
    normal "add a song" flow and should not be needed.

  **Normal "add a song" pipeline (what to use next time):**
  1. `python3 ~/.config/opencode/skills/ddr-song-ingest/scripts/ingest_song.py
     --file <audio> --title "<T>" --artist "<A>" --pack "<Pack>" --art <cover> --no-player`
     → creates `songpacks/<Pack>/<Artist> - <Title>/` with a valid `.ssc`
     (`#NOTEDATA` + measure commas), art, audio.
  2. Append `Pack/FolderName` (exact folder, no glob) to
     `Other/SongManager Kids Pop.txt`.
  3. Ship the folder + the SongManager file to `.54` via `tar | ssh`; restart
     OutFox. Do not clear caches.

  **Other notes:** logs at `~/Library/Logs/Project Out Fox/`
  (`ProjectOutfox.MainLog.*`, `-mermaid-kids.ThemeLua.*`); caches at
  `~/Library/Caches/Project Out Fox/`; prefs/keymaps at
  `~/Library/Preferences/Project Out Fox/`. `songpacks/` and `media/` are
  gitignored (art not committed).
