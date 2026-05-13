# Architecture patterns

The point of this document is to describe the structural decisions that make Blizz testable, replaceable, and resistant to Blizzard's API churn. Most of the patterns here are *not* new; they're just rare in the WoW addon ecosystem because most addons grew organically from in-game scripting rather than software engineering.

## Decision 1: Standalone (no runtime dependencies)

**The rule:** the addon does not require any other addon to function. No Ace3 dependency, no oUF, no LibStub-fronted libraries at runtime. Nothing in `## Dependencies:` in the TOC.

**Why:**
- Every dependency is a point of breakage when Blizzard ships an API change
- Most addon users don't read documentation; if Blizz requires Ace3, half of them will install Blizz and not Ace3
- The relevant code for our scope is small enough to maintain in-tree

**What this looks like in practice:**
- `core/eventbus.lua` is 60 lines and replaces AceEvent-3.0's role for us
- `config/savedvars.lua` is 80 lines and replaces AceDB-3.0's role for us
- Widget rendering goes through `ui/widgets/*.lua`, no UIWidgetTemplate dependency
- `LibStub` would be embedded if needed but isn't currently used

**When this rule breaks down:**
- If you grow toward a feature-equivalent of Ace3 (profiles, options-UI), the cost of in-house replacement exceeds the dependency cost. At that point, embed LibStub + AceConfig directly.
- For things you can't realistically rebuild — boss timers, CDR-aware party-CD tracking — you don't fight it. You consume their **data** (e.g. import MDT's NPC database into a static file), not their **runtime**.

This is what we call the "hybrid+" approach: rebuild for what we can, statically import data for what we can't, and don't take a runtime dependency on either.

## Decision 2: Module pattern with explicit registration

Every functional unit of the addon is a module. A module is a Lua table with this contract:

```lua
local Module = {
    id = "mitigation",                         -- unique string identifier
    events = { "UNIT_AURA", "SPELL_UPDATE_COOLDOWN" },  -- WoW events to subscribe
    init = function(self) ... end,             -- one-time setup (frames, state)
    onEvent = function(self, event, ...) ... end,  -- event handler
}

addon.registerModule(Module)
return Module
```

Registration does two things:
1. Subscribes the module's `onEvent` to the internal EventBus for each event in `events`
2. Tells the WoWEvents bridge to register those events on the bridge frame (so WoW will deliver them)

The bootstrap loop runs `init()` on every registered module after `PLAYER_LOGIN`:

```lua
function addon:bootstrap()
    WoWEvents:init()
    SavedVars:load()
    local profile = SavedVars:getCurrentProfile() or {}
    local disabled = profile.disabled or {}
    for id, mod in pairs(self.modules) do
        if disabled[id] then
            DEFAULT_CHAT_FRAME:AddMessage("|cff999999[Blizz]|r module disabled: " .. id)
        elseif mod.init then
            local ok, err = pcall(mod.init, mod)
            if not ok then
                table.insert(addon.errors, { event = "init:" .. id, err = tostring(err) })
            end
        end
    end
end
```

Note the `pcall` around init — an exception in one module doesn't break the others.

**Why this pattern matters:**
- Modules can be enabled/disabled per profile (`/blizz disable nameplates`, `/reload`)
- Module init runs in pcall, so a Lua error in one doesn't cascade
- Adding a module = create file, add to TOC, call `addon.registerModule(self)`. Nothing else.
- Tests can require a module directly and dispatch events to it without booting the whole addon

## Decision 3: Internal EventBus with pcall containment

WoW's frame-event model has a quirk: if your `OnEvent` handler errors, the user sees a Blizzard error popup. If you have 9 modules all listening to the same event, one bad module breaks the others' execution if the error propagates.

The fix: an internal bus that swallows per-subscriber errors.

```lua
-- core/eventbus.lua
local EventBus = {
    __subscribers = {},  -- [eventName] = { [token] = callback }
    __errors = {},       -- ring buffer of last 50 errors
}

function EventBus:subscribe(event, callback)
    self.__subscribers[event] = self.__subscribers[event] or {}
    self.__nextToken = (self.__nextToken or 0) + 1
    self.__subscribers[event][self.__nextToken] = callback
    return { event = event, token = self.__nextToken }
end

function EventBus:dispatch(event, ...)
    local subs = self.__subscribers[event]
    if not subs then return end
    for _, cb in pairs(subs) do
        local ok, err = pcall(cb, ...)
        if not ok then
            table.insert(self.__errors, { event = event, err = tostring(err) })
        end
    end
end
```

WoW frame events are routed *into* this bus via a separate bridge.

## Decision 4: WoW event bridge as a ref-counted layer

Modules talk to the EventBus, not to WoW frames. This means:
- Tests can dispatch events without involving CreateFrame
- The bus is the canonical place to add logging/tracing/diagnostics
- A single frame (`BlizzEventBridge`) holds all RegisterEvent calls, ref-counted by event name

```lua
-- core/wowevents.lua
local WoWEvents = {
    frame = nil,
    refCount = {},  -- event → number of registrants
}

function WoWEvents:init()
    if self.frame then return end
    self.frame = CreateFrame("Frame", "BlizzEventBridge")
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if addon.EventBus then
            addon.EventBus:dispatch(event, ...)
        end
    end)
end

function WoWEvents:register(event)
    self.refCount[event] = (self.refCount[event] or 0) + 1
    if self.refCount[event] == 1 then
        self.frame:RegisterEvent(event)
    end
end

function WoWEvents:unregister(event)
    self.refCount[event] = self.refCount[event] - 1
    if self.refCount[event] <= 0 then
        self.refCount[event] = nil
        self.frame:UnregisterEvent(event)
    end
end
```

This means two modules both registering for `UNIT_HEALTH` only result in one `frame:RegisterEvent` call.

## Decision 5: Data as static Lua files

Every dataset Blizz consumes — NPC IDs, spell IDs, classifications, affix definitions — is a Lua file under `data/`. No runtime fetching. No database loading. No third-party addon dependency.

```
data/
├── spells_prot_warrior.lua    -- spell ID database, hand-maintained
├── reflect_spells.lua         -- reflectable mob casts, auto-imported from MDT
├── npcs_midnight_s1.lua       -- 202 NPC classifications, auto-imported from MDT
├── affixes_s1.lua             -- Bargain definitions, hand-maintained
├── party_interrupts.lua       -- class → interrupt spell mapping
└── party_cds.lua              -- top external defensives
```

Where the data comes from:

- **Hand-curated** (`spells_prot_warrior`, `party_interrupts`, `party_cds`, `affixes_s1`): small enough to maintain by reading Wowhead and patch notes
- **Auto-imported from open-source addons** (`npcs_midnight_s1`, `reflect_spells`): we run a Lua script that loads the source addon's data files, applies heuristics, and emits our format

The import scripts live in `scripts/` and are stable across patches. When Blizzard ships a new dungeon, re-run the import.

The contract: data files don't make API calls, don't trigger events, and load cleanly from a plain `require()`. This makes them straightforward to import in headless tests.

## Decision 6: Saved variables with explicit schema and migration

```lua
-- config/savedvars.lua
local CURRENT_VERSION = 1

local function default_profile()
    return {
        positions = {},        -- [moduleId] = {x, y, anchor, relativeAnchor}
        disabled = {},         -- [moduleId] = true
        hero_talent = "auto",
        theme_overrides = {},
        module_options = {
            mitigation = { show_charges = true, show_absorb_value = true },
            kickrota = { announce_to_party = false },
            nameplates = { override_default = false },
        },
    }
end

local migrators = {
    [0] = function(db)
        local fresh = default_db()
        for k, v in pairs(fresh) do
            if db[k] == nil then db[k] = v end
        end
        db.version = 1
        return db
    end,
}

function SavedVars:load()
    if _G.BlizzDB == nil or next(_G.BlizzDB) == nil then
        _G.BlizzDB = default_db()
        return _G.BlizzDB
    end
    local v = _G.BlizzDB.version or 0
    while v < CURRENT_VERSION do
        local mig = migrators[v]
        if not mig then break end
        _G.BlizzDB = mig(_G.BlizzDB)
        v = _G.BlizzDB.version
    end
    return _G.BlizzDB
end
```

The pattern is: bump `CURRENT_VERSION`, add a migrator from `[v-1]` to `v`, ship. Users running an older `BlizzDB` will be auto-migrated on login.

## Decision 7: Widget toolkit with state-based theming

Instead of every module hand-rolling its own `:SetBackdrop` / `:SetTextColor` calls, all UI goes through a small toolkit:

```lua
local Frame = require "ui.widgets.frame"

local f = Frame:new({ parent = UIParent, width = 100, height = 30 })
f:setReady()    -- cyan fill + dark text (visual cue: spell is up)
f:setCD()       -- dim grey border + dim text
f:setAlert()    -- pulsing red (visual cue: react now)
f:setDefault()  -- outline only (visual cue: at-rest)
```

States are defined by the theme (`ui/theme.lua` token table) and applied via four `apply_*` functions in the widget. Adding a new state = add a token entry + an apply function. Modules never touch raw `:SetBackdropColor` — they call `frame:setReady()`.

This means:
- Visual changes (re-skinning the addon) only touch `ui/theme.lua`
- Modules are visually consistent by construction
- Headless tests can assert `frame:getState() == "ready"` instead of inspecting raw color values

## Decision 8: Hardened against Midnight 12.0 secret values

Every read from a Combat API goes through `core/secrets.lua`. The pattern:

```lua
function UnitState:getHealth(unit)
    return Secrets:safeNumber(safe_unit_call(_G.UnitHealth, unit), 0)
end
```

`safe_unit_call` pcalls the API. `safeNumber` checks `issecretvalue()` and returns the default (0) if the value is secret. Arithmetic later in the module's display logic is safe.

The cost is one extra pcall and one extra issecretvalue check per read — measured in microseconds. The benefit is that your addon doesn't throw silent errors mid-pull when Blizzard's protection mode kicks in.

See [`01-midnight-12.0-changes.md`](01-midnight-12.0-changes.md) for the full rationale.

## File layout

```
Blizz.lua                 -- Main entry: registry, bootstrap, slash command, action tracer
Blizz.toc                 -- WoW manifest with load order
core/
  eventbus.lua            -- Pub/sub
  wowevents.lua           -- WoW frame-event bridge
  cooldowns.lua           -- C_Spell wrapper, secret-safe
  unitstate.lua           -- Unit API wrapper, secret-safe
  combatlog.lua           -- CLEU parser scaffold (disabled in prod)
  secrets.lua             -- Secret-value defense layer
config/
  savedvars.lua           -- BlizzDB + migration
data/
  spells_prot_warrior.lua, reflect_spells.lua, npcs_midnight_s1.lua,
  affixes_s1.lua, party_interrupts.lua, party_cds.lua
ui/
  theme.lua               -- v6 token palette
  widgets/
    frame.lua, text.lua, icon.lua, bar.lua, alert.lua
modules/
  mitigation/, cooldowns/, threat/, reflect/, mplus_frame/,
  affix_s1/, nameplates/, kickrota/, party_cds/
tests/
  run.lua                 -- Headless runner
  mocks/wow_api.lua       -- WoW global stubs for testing
  test_*.lua              -- Per-component tests
scripts/
  install.sh              -- Symlink to WoW AddOns folder
  import-mdt-npcs.lua     -- Auto-generate npcs_midnight_s1.lua from MDT
  import-mdt-reflect-candidates.lua  -- Same for reflect_spells
docs/
  superpowers/specs/      -- Design specifications
  superpowers/plans/      -- Implementation plans
  cookbook/               -- This documentation
```

## Why this matters in 2026

Every one of these decisions trades initial complexity for **resilience to Blizzard's API churn**. The major Midnight 12.0 changes — CLEU restriction, Secret Values, C_Spell namespace — required surgical changes to two files in Blizz, not a rewrite.

If you're starting an addon today, the question to ask before adding any pattern is: **"when Blizzard breaks something here, what's my blast radius?"** The patterns above answer that question deliberately.

## Reading order if you want to copy this approach

1. Start with `core/eventbus.lua` — it's small and self-contained
2. Add `core/wowevents.lua` as the bridge
3. Set up `tests/mocks/wow_api.lua` for one module's worth of API surface
4. Write `tests/run.lua` and verify a smoke test passes
5. Build your first module with the `{id, events, init, onEvent}` contract
6. Add `core/secrets.lua` when you start reading combat APIs
7. Add `config/savedvars.lua` when you need persistence

Each layer is one or two files. None of them require Ace3. All of them are testable headless.
