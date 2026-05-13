# Tank meta & community signals — Midnight 12.0.5

A snapshot of the WoW Mythic+ tank ecosystem in May 2026, three months after Midnight's launch and the "Addon Apocalypse." If you're building a tank addon and need to know what the community runs, where the pain is, and which gaps are unfilled — start here.

This chapter is data-driven, not opinion. Every claim has a source.

## What the top tanks actually run

Compiled from public UI packs, Wago profiles, Twitch overlay analysis, and creator blogs (Quazii, Naowh, Dorki, Petko, YoDa, Causese), Q1-Q2 2026:

| Creator | UI base | Nameplates | Cooldown display | WeakAuras |
|---|---|---|---|---|
| **Quazii** | ElvUI + non-ElvUI variants (QUI Installer) | **Plater & Platynator both shipped** | Blizzard CDM + class WAs | Class-specific WA bundles per spec |
| **Naowh** | ElvUI + ElvUI_WindTools | Plater | Blizzard CDM + AyijeCDM | **No WAs in pack** — deliberate choice |
| **Dorki** | Unhalted Unit Frames + Platynator + ArcUI | **Platynator** (Plater out) | Blizzard CDM | Class Reminders + TargetedSpells |
| **Petko** | Custom ElvUI setup | Plater w/ Season 1 Important Mobs profile | OmniCD + MDT-centric | Class WAs from Wago + Dungeon packs |
| **YoDa** | UI pack (uipacks.wago.io) | Plater (YoDa profile, multi-versioned) | WA + CDM hybrid | M+ dungeon auras + Morning's M+ Timer edits |
| **Causese** | n/a — not a UI personality | n/a | n/a | **WA dungeon-mechanic packs** (the de-facto standard since Castle Nathria) |

Two patterns dominate:

- **Cooldown Manager (CDM) is winning over WeakAuras for personal CD tracking.** Blizzard's native Cooldown Manager + AyijeCDM (388k+ downloads) replaced what used to be Hekili and WA cooldown bars. Naowh's pack ships zero WAs and just uses CDM. Method's own Prot Warrior guide on method.gg gives two CDM imports and no WA list.
- **Plater vs Platynator is a real schism.** Plater still works for static coloring but its dynamic-scripting features were gutted by the 12.0 API lockdown. Platynator (by plusmouse, author of Auctionator/Baganator) was built for the new API and is gaining share — Dorki migrated fully, Naowh uses Plater still, Quazii ships both.

## The consensus stack — what shows up in 90% of guides

Across Wowhead, Icy-Veins, Maxroll, Murlok.io, Method.gg, Raider.io, and ConquestCapped:

**Core six (every tank runs these):**
1. **BigWigs + LittleWigs** — boss/dungeon timers (DBM equivalent; BigWigs lighter)
2. **Plater** *or* **Platynator** — threat colors, kick-target highlighting, NPC classification
3. **OmniCD** (v2.8.32, Feb 2026) — party kicks/defensives/externals
4. **Method Raid Tools (MRT)** — notes, CD assignments, big-pull markers
5. **Details!** — works but partially restricted; uses server-side damage API
6. **MPlusTimer** / **MythicPlusTimer** — M+ timer with death penalty + forces

**Tank-specific adds:**
7. **MythicPlusCount-Midnight** — forces % on each nameplate (189k DL)
8. **MiniCC** — all-in-one CC/Defensive/Kick tracker (2.3M+ DL, viral)
9. **NSRT (Northern Sky Raid Tools)** — WA-pack replacement, 5.9M+ DL
10. **MidnightSimpleAuras** — personal cooldowns, WA look without Secret-Values pain
11. **MDT** — out-of-combat route planning (v4.4.0.5+)
12. **BetterCooldownManager** — Blizzard CDM skin
13. **ElvUI** (optional) or **MidnightUI** (newer, tank profile)

## Addons that died in the prune

| Addon | Status | Why |
|---|---|---|
| **Hekili** | Officially sunset Jan 2026 | APL simulation needs combat API access. Author retired the project. |
| **WeakAuras** (combat) | Team officially ended combat-feature support | Stanzilla in PCGamesN interview: "We just don't see Blizzard reversing these core restrictions." Cosmetic use remains. |
| **Threat Plates** | Dead | Maintainer never updated |
| **GTFO** | Dead | CLEU access required |
| **MoveAnything / MoveIt** | Obsolete | Blizzard Edit Mode |
| **TipTac, ErrorFilter, Opie, Greenwall, TLDR Missions** | Dead | Maintainers exited or API broke them |
| **Healbot debuff tracking** | Heavily restricted | Aura data is now Secret Values |
| **Shield Maid** (Prot Warri mitigation tracker) | Stuck at 11.2.0 | Last update August 2025. **This is a clear opening for Blizz.** |

The Shield Maid gap is the single best opportunity in the Prot Warri space right now: it was the canonical Shield Block + Ignore Pain visualizer, and nobody has stepped in to maintain it for Midnight.

## What's new since the prune

Addons created or significantly rewritten Jan-May 2026:

| Addon | Purpose | Downloads |
|---|---|---|
| **Platynator** | Plater-successor for the new API | growing share |
| **AyijeCDM** | Customization layer on Blizzard's CDM | 388k+ |
| **NSRT** | Replaces WA cosmetic/reminder use cases | 5.9M+ |
| **MPlusTimer** (standalone) | Was a WA, now an addon to escape Secret Values | 711k+ |
| **MythicPlusCount-Midnight** | Forces % on nameplates | 189k+ |
| **MiniCC** | CC/Defensive/Kick all-in-one | 2.3M+ |
| **MidnightSimpleAuras** | Personal CDs WA-style without WA's combat restrictions | active |
| **HekiLight / Blizzkili / Knickili** | Built on `C_AssistedCombat` to fill Hekili's gap | nascent |
| **TargetedSpells** | Incoming-spell warnings (used in Dorki's pack) | 735k+ |
| **CoTankAuras** | Tank-shared auras for raid co-tanking | active |
| **Viserio Cooldowns** | Web + NSRT integration for raid CD planning | active |
| **NaowhQOL** | QoL bundle from the Naowh setup | active |

The pattern: **a wave of small, focused, single-purpose addons** has replaced the WeakAuras-as-everything era. Each does one thing in the new API constraints.

## Community pain points (May 2026)

These are the gaps the community is most vocal about — distilled from Blizzard forum threads, Wowhead news comments, the PCGamesN/Stanzilla interview, and recent CurseForge top-rated comments:

### 1. "Combat state is a black box"

The biggest single frustration. WAs that read aura stacks, predicted defensive windows, or watched specific enemy casts now return Secret Values and can't be used in conditions. Petko on Stanzilla's interview: *"Combat events are in a black box; addons can change the size or shape of the box… but what they can't do is look inside the box."*

The community wants: **defensive suggestions like "press Shield Wall now" without needing combat-API access** — i.e. statically curated per-encounter tank-buster databases.

### 2. "Affix UX for Bargain is terrible"

Voidbound, Pulsar, Devour, Ascendant + Lindormi's Guidance = five mechanics with no dedicated tracker. Forum threads US-2227538 and EU-612425 both complain. The closest is Zytech's all-affix WA, which isn't tank-focused.

The community wants: **a Bargain-variant-aware HUD with sub-modes per week** showing only the current week's mechanic with tank-relevant action prompts.

### 3. "Threat awareness died with Plater dynamic scripting"

Threat Plates is dead. Plater's threat coloring still works but the dynamic logic addons used (e.g. "warn me when I'm about to lose this mob in 2s") is gone.

The community wants: **a simple "you're about to lose this mob" alert that doesn't require Plater configuration.**

### 4. "Configuration overhead is absurd"

Pre-12.0: one WA import string and you had a full tank UI. Post-12.0: NSRT + MRT + OmniCD + Plater + MidnightSimpleAuras + BetterCDM + 6 more = **5+ separate configs, often with conflicting keybinds and overlapping displays**.

The community wants: **"tank stack one-click setup"** — a single addon (or pack) with sensible defaults across all these concerns, spec-aware.

### 5. "Rotation helper on a single button isn't enough for high keys"

Blizzard's `C_AssistedCombat` gives one suggested next-button. HekiLight/Blizzkili/Knickili are UI skins on that one button. Community consensus (EU forum 602434, US 2212381): *"Removing Hekili without a real replacement was a mistake."*

For tanks specifically: **threat-priority suggestions during multi-pulls** and **rage-budgeting hints** (don't burn rage on Ignore Pain right before a Shield Slam window).

## Where Blizz fits

Mapping the pain points to Blizz's modules:

| Pain | Blizz position | Status |
|---|---|---|
| Tank-buster database for "press defensive now" | Could be a new module reading static `data/tankbusters_s1.lua` | Not yet built |
| Bargain-variant-aware HUD | `modules/affix_s1` is the scaffold, `data/affixes_s1.lua` is the placeholder | Skeleton exists, data empty |
| Threat-loss predictor on nameplates | `modules/nameplates` + `modules/threat` cover the surface | Built, can add prediction logic |
| One-click tank stack | Already 9 modules in one addon | Done — Blizz IS the one-click setup |
| Rage budgeting / pull planner | New module candidate | Not yet considered |

The honest assessment: **the consensus stack the community runs is 5-13 addons**. Blizz is one addon doing the work of roughly half that stack (mitigation + cooldowns + threat + reflect + mplus_frame + affix + nameplates + kickrota + party_cds). The remaining half (BigWigs, MDT, OmniCD as data sources) we leave to specialized addons because their data scope is too large to maintain in-house.

## The opening that nobody has filled

If you wrote a single sentence describing the ideal addon for Prot Warriors in M+ Midnight 12.0.5, it would be: **"A maintained, free, Midnight-native, all-in-one Prot Warrior tank UI suite with curated per-encounter and per-affix data."**

This doesn't exist. Luxthos is TWW-stale and generic. Kira is premium and not Warrior-focused. Shield Maid is dead. The remaining options are 8-12 separate WAs you piece together yourself.

That's the gap Blizz is built into. Whether it ends up filling it depends on data curation (the affix and tank-buster databases are work) and whether the community discovers it.

## Sources

- [BlizzardWatch — Addon Apocalypse coverage](https://blizzardwatch.com/2026/01/13/addon-apocalypse-midnight/)
- [PCGamesN — Midnight WeakAuras Stanzilla interview](https://www.pcgamesn.com/world-of-warcraft/midnight-weakauras-interview-stanzilla)
- [Patreon — Team WeakAuras Midnight statement](https://www.patreon.com/posts/midnight-144610594)
- [Quazii blog — Midnight Plater/Platynator profile](https://quazii.com/midnight-plater-platynator-profile/)
- [Naowh UI pack](https://uipacks.wago.io/pack/naowhui)
- [Dorki UI pack v67](https://uipacks.wago.io/pack/dorkiui)
- [Method.gg Prot Warri interface guide](https://www.method.gg/guides/protection-warrior/interface-and-macros)
- [Petko Plater profile](https://wago.io/ZgVKZOHFv) | [S1 Important Mobs](https://wago.io/LRC6p0kRO)
- [Wowhead — MPlusTimer standalone news](https://www.wowhead.com/news/former-m-timer-weakaura-receives-standalone-addon-for-midnight-mplustimer-379922)
- [Wowhead — Northern Sky Raid Tools](https://www.wowhead.com/news/raid-planning-made-easy-with-northern-sky-raid-tools-379984)
- [Icy Veins — Petko Advanced M+ UI Setup](https://www.icy-veins.com/wow/advanced-mythic-ui-setup-guide)
- [Murlok.io — Prot Warri M+ data](https://murlok.io/warrior/protection/m+)
- [Hekili sunset announcement](https://x.com/hekili808/status/1973479282006696123)
- US Blizzard Forums threads: 2234377, 2214572, 2296045, 2176326, 2212381, 2180382, 2227538
- EU Blizzard Forums thread: 602434
