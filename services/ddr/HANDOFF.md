# HANDOFF — HomeDDR + HomeServer

> Read this file first in any new session. It is the single source of truth for
> project state, decisions, and the next actions. Keep it current as work lands.

**Updated:** 2026-11-05
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
