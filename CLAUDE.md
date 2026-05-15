# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Blizz is a standalone WoW UI addon (tank-focused, Prot Warrior M+) targeting the **Midnight 12.0** client. Runtime is LuaJIT 2.1 / Lua 5.1 semantics — *not* standard Lua 5.3+. No Ace3, no oUF, no runtime dependencies.

Long-form docs live in `docs/cookbook/` (architecture, Midnight 12.0 API changes, testing) and `README.md`. Read `docs/cookbook/02-architecture.md` before making non-trivial structural changes.

## Common commands

```bash
# Full test suite (headless, ~130ms)
luajit tests/run.lua

# Single test file
luajit -e 'package.path="./?.lua;./?/init.lua;"..package.path; require("tests.test_eventbus")'

# Format (must be clean before commit)
stylua .
stylua --check .

# Install / symlink into the WoW AddOns folder
./scripts/install.sh                       # autodetect common Linux paths
./scripts/install.sh /path/to/Interface/AddOns   # explicit
```

In-game after edits: `/reload`, then `/blizz status` (other slash subcommands: `errors`, `modules`, `disable <id>`, `enable <id>`, `capture <bargain>`). There is no build step — files are loaded directly by WoW per the TOC.

## Architecture

Bootstrap flow (see `Blizz.lua`):

1. TOC loads files top-to-bottom. `core/*` → `config/savedvars.lua` → `data/*` → `ui/*` → `Blizz.lua` → `modules/*/init.lua`.
2. Each module file ends with `addon.registerModule(self)`. Registration subscribes the module's `onEvent` to the internal EventBus for each entry in `self.events`, and ref-counts a `frame:RegisterEvent` via `core/wowevents.lua`.
3. The bridge frame (`BlizzEventBridge`) waits for WoW's `PLAYER_LOGIN`. On fire, `addon:bootstrap()` runs `SavedVars:load()` (with version migration), then `pcall`s each module's `init` so one bad module cannot break the others.
4. WoW frame events are dispatched into `core/eventbus.lua`, which `pcall`s every subscriber and pushes errors into a 50-entry ring buffer at `addon.errors` (visible via `/blizz errors`).

Module contract — every `modules/*/init.lua` follows this shape:

```lua
local _, addon = ...
if not addon then addon = _G.Blizz or {}; _G.Blizz = addon end  -- dual-load: WoW TOC + headless require

local Mod = {
  id = "mitigation",                              -- unique key (also used for disable/positions)
  events = { "SPELL_UPDATE_COOLDOWN", "UNIT_AURA" },
  init = function(self) ... end,                  -- frames + state, called once after PLAYER_LOGIN
  onEvent = function(self, event, ...) ... end,
}
addon.registerModule(Mod)
return Mod
```

Combat-API reads (`UnitHealth`, `C_Spell.GetSpellCooldown`, …) go through `core/unitstate.lua` / `core/cooldowns.lua` which wrap calls in `pcall` and check `issecretvalue()` via `core/secrets.lua`. Don't call those WoW APIs directly from modules — Midnight 12.0 returns secret values that silently break arithmetic.

UI goes through `ui/widgets/*` (Frame, Text, Icon, Bar, Alert) with theme tokens from `ui/theme.lua`. State changes are method calls (`frame:setReady() / :setCD() / :setAlert() / :setDefault()`) — never raw `:SetBackdropColor`. This is what makes the widgets re-skinnable and what makes tests assert `frame:getState() == "ready"` instead of inspecting colors.

Position persistence: in `init()`, after creating your frame, call `addon.restorePosition(frame, self.id, default_anchor, default_x, default_y)`. It loads from `BlizzDB.profiles[active].positions[id]` if present, otherwise the default, and enables drag-to-move that writes back via `SavedVars:setPosition`.

SavedVars schema (`config/savedvars.lua`) has a version field and a `migrators` table keyed by old version. To change the schema: bump `CURRENT_VERSION`, add a migrator from `[v-1]` to `v`.

## Adding a new module / file (load-order rules)

1. Create `modules/<name>/init.lua` using the module contract above.
2. **Append it to `Blizz.toc` in load order** — modules go *after* `Blizz.lua`; anything they `require` (core/data/ui) must appear *before* `Blizz.lua`. Files not listed in the TOC are silently ignored by WoW.
3. If the file declares a new global (e.g. another `SLASH_*` constant or addon-wide table), add it to `diagnostics.globals` in `.luarc.json` so lua-language-server doesn't flag it.
4. Add `tests/test_<name>.lua`. The runner discovers `tests/test_*.lua` automatically.

## Testing

`tests/mocks/wow_api.lua` stubs the WoW global surface (CreateFrame, UnitHealth, GetTime, C_Spell.*, CLEU listener, …) and exposes `MockSet*` / `MockFire*` helpers for tests to drive state and fire events. The mock uses a catch-all `__index` that returns no-op functions for any `Set*`/`Get*` method you forgot — so missing stubs won't crash tests, they'll just silently do nothing.

When a module starts calling a WoW API not yet mocked:
1. Add the stub in `tests/mocks/wow_api.lua` (and a `MockSetX` control helper if state-bearing).
2. Add the helper name to `diagnostics.globals` in `.luarc.json`.

`tests/run.lua` clears `_G.Blizz` and `package.loaded[...]` between test files so each runs in a fresh scope. Plain `assert()` is the only test API — no busted/luaunit. Print `"✓ <description>"` lines on pass.

## Stolperfallen (gotchas)

- **TOC `## Interface: 120005`** must match the live client major. Bump on patch days or the addon shows "Out of Date" and won't load.
- **LuaJIT 5.1 only.** No `//` integer division, no native `&|~` bitwise ops (use `bit.band/bor/bxor/lshift/rshift`), no Lua 5.2+ `goto`-continue idioms, no `<const>` attributes.
- **Don't bypass the EventBus** by calling `frame:SetScript("OnEvent", ...)` in module code — you lose pcall containment and the diag tracer. Use the `events = { ... }` + `onEvent` contract.
- **Don't read combat APIs directly** — go through `core/unitstate.lua` / `core/cooldowns.lua`. Midnight 12.0 Secret Values otherwise contaminate arithmetic with silent errors. See `docs/cookbook/01-midnight-12.0-changes.md`.
- **`/blizz disable <id>` requires `/reload`** to take effect (disabled-set is read once during bootstrap).
- The `BlizzActionDiag` frame in `Blizz.lua` captures `ADDON_ACTION_BLOCKED`/`ADDON_ACTION_FORBIDDEN` with debugstack — leave it on while debugging Midnight blocked-action popups.
