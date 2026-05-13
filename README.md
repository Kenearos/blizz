# Blizz

**A reference implementation for a modern WoW addon — built ground-up for the Midnight 12.0 era.**

Blizz is a tank-focused UI addon for Protection Warriors in Mythic+, but the *interesting* part is the **architecture and engineering practices** for surviving Blizzard's 2026 addon prune. If you're starting (or migrating) an addon for WoW Midnight 12.0+ and looking for a worked-out example, this repository is for you.

---

## What this repository documents

Building an addon in Midnight 12.0 is not what it was in Dragonflight. Blizzard restricted combat data access, removed long-standing globals, and introduced Secret Values that throw silent errors. Most existing tutorials, examples, and YouTube videos predate this. **This repo collects every workaround we found, with working code.**

The interesting topics:

| Topic | Where to read it |
|---|---|
| What Midnight 12.0 broke and what replaces it | [`docs/cookbook/01-midnight-12.0-changes.md`](docs/cookbook/01-midnight-12.0-changes.md) |
| Standalone addon architecture (no runtime deps) | [`docs/cookbook/02-architecture.md`](docs/cookbook/02-architecture.md) |
| Headless Lua testing for WoW addons | [`docs/cookbook/03-testing-toolchain.md`](docs/cookbook/03-testing-toolchain.md) |
| Design specification (Tank UI for Prot Warri M+) | [`docs/superpowers/specs/2026-05-13-blizz-tank-ui-design.md`](docs/superpowers/specs/2026-05-13-blizz-tank-ui-design.md) |

The addon itself works and is playable; the docs are the long-term value.

---

## Quickstart (try Blizz in your WoW client)

Linux (Steam Deck, Lutris, native Wine):

```bash
git clone https://github.com/<your-fork>/blizz.git
cd blizz
./scripts/install.sh
# in WoW:
# /reload
# /blizz status
```

Windows/macOS: copy or symlink the repo to `World of Warcraft/_retail_/Interface/AddOns/Blizz`.

Run the headless test suite:

```bash
luajit tests/run.lua
# → 20 passed, 0 failed
```

---

## What's actually in the addon

Nine modules, each ~50-120 lines of focused Lua:

```
modules/mitigation       Shield Block + Ignore Pain display
modules/cooldowns        8-icon defensive CD bar with state inversion
modules/threat           Threat status pill + lost-aggro alert
modules/reflect          Pulsing alert on reflectable nameplate casts
modules/mplus_frame      M+ timer + forces + +2/+3 thresholds + deaths
modules/affix_s1         Bargain spawn tracker (NPC-ID based)
modules/nameplates       NPC classification + themed overlays
modules/kickrota         Interrupt CD tracker + next-kicker suggester
modules/party_cds        Top external defensives tracker
```

Six data files (some auto-imported from MDT):

```
data/spells_prot_warrior.lua   Spell IDs for Prot Warri
data/reflect_spells.lua        Reflectable mob casts (30 candidates from MDT)
data/affixes_s1.lua            Bargain affix definitions (template)
data/npcs_midnight_s1.lua      202 NPCs classified, imported from MDT
data/party_interrupts.lua      Class → interrupt spell mapping
data/party_cds.lua             Top-10 external defensives
```

Core engineering layer (the bit you might want to reuse):

```
core/eventbus.lua    Pub/sub bus with pcall error containment
core/wowevents.lua   WoW frame events → EventBus bridge with ref-counting
core/secrets.lua     Midnight 12.0 Secret Values defense layer
core/cooldowns.lua   C_Spell.GetSpellCooldown wrapper with secret-safe reads
core/unitstate.lua   UnitHealth/Absorb/Threat/Range wrappers
core/combatlog.lua   CLEU parser scaffolding (disabled in prod — see cookbook)
```

UI toolkit (no Ace3, no oUF, fully standalone):

```
ui/theme.lua             v6 Cyan Cyber Tactical token palette
ui/widgets/frame.lua     Themed Frame with tech-corner brackets and 4 states
ui/widgets/text.lua      Themed FontString with 5 style profiles
ui/widgets/icon.lua      Spell icon with ready/cd color-inversion states
ui/widgets/bar.lua       Status bar with value clamping
ui/widgets/alert.lua     Pulsing alert widget for Reflect-style warnings
```

---

## Why does this exist?

WoW Midnight 12.0 (live since 2026-03-02) brought the most aggressive addon API cull since Cataclysm. Combat-data addons broke en masse. Half-finished migrations, broken popups ("AddOn 'X' has been blocked from an action only available to the Blizzard UI"), Secret Values throwing silent errors — the addon ecosystem is rebuilding from scratch.

Existing learning resources are mostly stale:

- The classic `JuanjoSalvador/awesome-wow` list links eingestellte editors and predates Midnight by years
- Reddit "intro to WoW addons" tutorials are from 2012-2014, before Ace3 was rewritten and before C_Spell existed
- BigWigs/Cell/WeakAuras/Plater have figured out the workarounds, but they're embedded in 50k-line codebases that are hard to extract patterns from

Blizz is **small, complete, and documented**. Read the source. Read the cookbook. Steal what works.

---

## Status

- **Version:** 0.1.1 MVP
- **Tested against:** WoW Midnight 12.0.5 (Lutris/Battle.net on Steam Deck)
- **Test suite:** 20 test files, all green via LuaJIT 2.1 headless
- **Lint:** stylua-clean (tabs, 100-col, double-quote)
- **Type-check:** lua-language-server with WoW annotations
- **License:** MIT

---

## Contributing

The most valuable contributions right now:

1. **Affix-S1 NPC IDs** — `data/affixes_s1.lua` is a starter template; populate as you encounter Bargain spawns in-game
2. **Reflect-spell verification** — the 30 candidates in `data/reflect_spells.lua` are MDT-magic-flag-derived and noisy; in-game testing trims false positives
3. **Reference-quality testing** — `tests/test_*.lua` files demonstrate the testing pattern; new modules should follow it
4. **Cookbook expansion** — the `docs/cookbook/` is intentionally minimal at v0.1; recipe-style docs for module patterns are welcome

---

## Acknowledgements

- [MDT (Mythic Dungeon Tools)](https://github.com/Nnoggie/MythicDungeonTools) — NPC database we import from
- [BigWigs](https://github.com/BigWigsMods/BigWigs) — boss timer reference
- [Cell PR #457](https://github.com/enderneko/Cell/pull/457) — Midnight 12.0 secret-values migration patterns
- [warcraft.wiki.gg](https://warcraft.wiki.gg) — the only up-to-date WoW API reference

Built with [Claude Code](https://claude.com/claude-code) using the GSD planning workflow.
