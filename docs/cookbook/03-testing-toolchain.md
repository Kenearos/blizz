# Testing & toolchain setup

Most WoW addons have no automated tests. The dominant testing strategy is "I logged in and it didn't error." This works until it doesn't — usually right when Blizzard ships a patch.

Blizz uses headless Lua testing with hand-mocked WoW globals. The full test suite runs in under a second from the command line, doesn't require WoW to be installed, and catches the kind of regression that takes hours to find via `/reload` + manual play.

## The stack

| Tool | Role | Required? |
|---|---|---|
| **LuaJIT 2.1** | Test runner that matches WoW's Lua 5.1 runtime + `bit` library | Yes — LuaJIT, not Lua 5.4 |
| **stylua** | Formatter | Yes |
| **lua-language-server** | IDE intelligence + type-checking | Recommended |
| **WoW API annotations** | LLS workspace library for autocomplete | Recommended |
| **No external test framework** | We use plain `assert()` + a small `tests/run.lua` | Intentional |

The decision to skip `busted` and `luaunit` is deliberate. Plain assert + a self-rolled runner is 70 lines total and has no LuaRocks dependency. The cost is fewer features (no spy/stub built-in, no BDD syntax); the benefit is a single-file dependency that runs from any Lua interpreter.

## Why LuaJIT specifically

WoW's runtime is LuaJIT 2.0/2.1 with Lua 5.1 semantics. If you write tests against Lua 5.4 (or even 5.3), you'll occasionally hit syntax that WoW's runtime doesn't accept:

- No integer division `//`
- No bitwise operators `&` `|` `~` (use the `bit` library instead)
- No goto-continue idiom in some 5.1 compilers
- Different `os.time` behavior
- No `goto` label scoping changes from 5.2+

Running tests with `luajit` (2.1) avoids all of these surprises. If your test passes locally, it almost certainly works in WoW.

Install (Arch / Steam Deck):

```bash
pacman -S luajit
luajit -v
# → LuaJIT 2.1.x ... Lua 5.1
```

## The runner: `tests/run.lua`

The runner discovers `tests/test_*.lua` files, runs each in a fresh `_G.Blizz` scope, and prints a summary:

```lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function list_test_files()
    local files = {}
    local p = io.popen("ls tests/test_*.lua 2>/dev/null")
    if p then
        for line in p:lines() do
            local name = line:gsub("^tests/", ""):gsub("%.lua$", "")
            table.insert(files, "tests." .. name)
        end
        p:close()
    end
    table.sort(files)
    return files
end

local files = list_test_files()
local passed, failed = 0, 0

for _, modname in ipairs(files) do
    -- fresh state per test file: clear globals + cached modules
    _G.Blizz = nil
    for k in pairs(package.loaded) do
        if k:match("^core%.") or k:match("^ui%.") or k:match("^config%.")
                or k:match("^modules%.") or k:match("^data%.")
                or k == modname or k == "tests.mocks.wow_api" or k == "Blizz" then
            package.loaded[k] = nil
        end
    end

    io.write(string.format("\n=== %s ===\n", modname))
    local ok, err = pcall(require, modname)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("✗ FAIL:", err)
    end
end

print(string.format("\n--- %d passed, %d failed ---", passed, failed))
if failed > 0 then os.exit(1) end
```

Run with `luajit tests/run.lua` — output looks like:

```
=== tests.test_eventbus ===
✓ subscribe/dispatch works
✓ multi-subscriber works
✓ pcall containment works
✓ unsubscribe by token works
✓ args passthrough works
...
--- 20 passed, 0 failed ---
```

A test file looks like:

```lua
-- tests/test_eventbus.lua
require("tests.mocks.wow_api")
local EventBus = require("core.eventbus")

local count = 0
EventBus:subscribe("PLAYER_LOGIN", function() count = count + 1 end)
EventBus:dispatch("PLAYER_LOGIN")
EventBus:dispatch("PLAYER_LOGIN")
assert(count == 2, "subscriber should fire on each dispatch")
print("✓ subscribe/dispatch works")
```

That's it. No `describe`/`it` blocks, no test discovery beyond filename. The `assert` either passes silently or throws; print on pass for visibility.

## The mock layer: `tests/mocks/wow_api.lua`

This is where you stub the WoW API so module code can run outside WoW. The structure:

```lua
local Mock = {
    units = {},        -- [unit] = { health, maxHealth, absorb, ... }
    cooldowns = {},    -- [spellID] = { start, duration, charges, ... }
    cleu_listener = nil,
    time = 1000,
    frames = {},       -- tracks created frames for event broadcast
    mythicplus = { active = false, mapID = 0, timeLimit = 1800 },
    forces = { total = 100, current = 0 },
}

local function make_frame(frameType, name, parent)
    local f = {
        __type = frameType, __name = name, __parent = parent,
        __events = {}, __scripts = {}, __points = {}, __size = { 0, 0 },
        __shown = true,
    }
    function f:SetSize(w, h) self.__size = { w, h } end
    function f:SetPoint(...) table.insert(self.__points, { ... }) end
    function f:RegisterEvent(ev) self.__events[ev] = true end
    function f:SetScript(name, fn) self.__scripts[name] = fn end
    function f:Show() self.__shown = true end
    function f:Hide() self.__shown = false end
    function f:IsShown() return self.__shown end
    function f:SetBackdropColor(_, _, _, _) end
    function f:CreateTexture(_, _) return make_frame("Texture") end
    function f:CreateFontString(_, _, _) return make_frame("FontString") end
    -- ... catch-all for the long tail:
    setmetatable(f, { __index = function(_, k)
        if type(k) == "string" and (k:match("^Set") or k:match("^Get")) then
            return function() end
        end
        return nil
    end })
    table.insert(Mock.frames, f)
    return f
end

_G.UIParent = make_frame("Frame", "UIParent")
_G.CreateFrame = function(frameType, name, parent, template)
    return make_frame(frameType, name, parent, template)
end
_G.GetTime = function() return Mock.time end
_G.UnitHealth = function(unit) return (Mock.units[unit] or {}).health or 0 end
-- ... etc.

-- Mock control API for tests:
function MockSetUnit(unit, props) Mock.units[unit] = props end
function MockSetCooldown(spellID, start, duration) ... end
function MockSetTime(t) Mock.time = t end
function MockFireFrameEvent(eventName, ...) ... end  -- simulate a WoW event
```

The pattern:
1. Each Mock-controlled value lives in the `Mock` table
2. `_G.UnitFoo` reads from `Mock.units[unit].foo`
3. `MockSetUnit("player", { health = 50000 })` lets tests set up state
4. The catch-all metatable returns no-ops for methods you forgot to stub — your tests won't crash when a module calls `frame:SetWidth(100)` even if you never added an explicit `SetWidth` stub

This is intentionally minimal. Cell, ElvUI, BigWigs all maintain mock layers an order of magnitude larger; ours covers exactly the API surface Blizz uses (~30 functions). When a module starts calling a new API, add a stub.

## Module pattern compatibility with tests

The module files use this load pattern:

```lua
local _, addon = ...
if not addon then
    addon = _G.Blizz or {}
    _G.Blizz = addon
end
```

The first line handles WoW's TOC load (which passes `addonName, addonTable` as varargs). The fallback `if not addon then` covers headless tests where the file is loaded via `require()` (which passes `("module_name",)` and `addon` is nil).

This dual-load pattern means **every module file works identically in WoW and in tests**. No conditional code, no separate test entry points.

## stylua

Config in `stylua.toml`:

```toml
column_width = 100
line_endings = "Unix"
indent_type = "Tabs"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
collapse_simple_statement = "Never"
```

Run on every new file before commit:

```bash
stylua path/to/file.lua && stylua --check path/to/file.lua
```

The `collapse_simple_statement = "Never"` is non-default. Without it, stylua collapses small `if cond then statement end` blocks onto one line, which makes diffs noisier and conflicts with the lua-language-server's understanding of branch coverage.

Install (Arch):
```bash
curl -fsSL -o stylua.zip https://github.com/JohnnyMorganz/StyLua/releases/download/v2.4.1/stylua-linux-x86_64.zip
unzip stylua.zip -d ~/.local/bin/
chmod +x ~/.local/bin/stylua
```

## lua-language-server

Config in `.luarc.json`:

```json
{
  "runtime.version": "Lua 5.1",
  "runtime.special": {
    "C_Timer.After": "setTimeout"
  },
  "workspace.library": [
    "/home/<user>/.local/share/wow-api/Annotations"
  ],
  "workspace.checkThirdParty": false,
  "diagnostics.globals": [
    "LibStub",
    "SLASH_BLIZZ1",
    "SlashCmdList",
    "BlizzDB",
    "MockSetUnit",
    "MockSetCooldown",
    "MockSetThreat",
    "MockSetTime",
    "MockSetCLEUListener",
    "MockFireCLEU",
    "MockFireFrameEvent",
    "MockSetMythicPlus",
    "MockSetForces",
    "MockSetTimer",
    "MockSetGroup",
    "MockSetUnitDead",
    "MockReset"
  ]
}
```

Key parts:
- `runtime.version` is `Lua 5.1` because WoW runs LuaJIT 5.1-compat semantics
- `workspace.library` points at a WoW-API-Annotations bundle (e.g. [Ketho/vscode-wow-api](https://github.com/Ketho/vscode-wow-api) emits these). LLS uses them for autocomplete and type-checking on WoW APIs
- `diagnostics.globals` declares globals LLS should ignore — slash commands, saved-variable global, and all `Mock*` test helpers

## TOC manifest

Load order matters in WoW. Files are concatenated and executed top-to-bottom. Reference dependencies must load first.

Blizz's `Blizz.toc` load order (excerpt):

```
## Interface: 120005
## Title: Blizz
## Version: 0.1.1
## SavedVariables: BlizzDB

# Theme (UI color/font tokens — depended on by widgets)
ui/theme.lua

# Core (event bus + API wrappers, no UI dependencies)
core/eventbus.lua
core/secrets.lua
core/cooldowns.lua
core/unitstate.lua
core/combatlog.lua
core/wowevents.lua

# Config (saved-vars)
config/savedvars.lua

# Static data (no dependencies)
data/spells_prot_warrior.lua
data/reflect_spells.lua
data/affixes_s1.lua
data/npcs_midnight_s1.lua
data/party_interrupts.lua
data/party_cds.lua

# Widget toolkit (depends on theme)
ui/widgets/frame.lua
ui/widgets/text.lua
ui/widgets/icon.lua
ui/widgets/bar.lua
ui/widgets/alert.lua

# Main entry (provides addon.registerModule)
Blizz.lua

# Modules (call addon.registerModule on load; depend on Blizz.lua being loaded)
modules/mitigation/init.lua
modules/cooldowns/init.lua
modules/threat/init.lua
modules/reflect/init.lua
modules/mplus_frame/init.lua
modules/affix_s1/init.lua
modules/nameplates/init.lua
modules/kickrota/init.lua
modules/party_cds/init.lua
```

The rule: anything `Blizz.lua` references via `addon.X` must load before `Blizz.lua`. Modules load *after* `Blizz.lua` because they call `addon.registerModule` at file end.

## Install workflow on Linux

Symlink the repo into the WoW AddOns folder:

```bash
./scripts/install.sh
# verifies all TOC-listed files exist
# creates symlink: <WoW>/Interface/AddOns/Blizz → /path/to/blizz
```

After any edit, in-game `/reload` picks up the changes immediately. No copy step needed.

## CI

Blizz doesn't currently run CI but is set up to. A minimal GitHub Actions job would be:

```yaml
name: tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install -y luajit
      - run: luajit tests/run.lua
      - run: curl -L https://github.com/JohnnyMorganz/StyLua/releases/download/v2.4.1/stylua-linux-x86_64.zip -o stylua.zip
      - run: unzip stylua.zip -d /tmp/
      - run: /tmp/stylua --check $(find . -name "*.lua" -not -path "./.claude/*")
```

20 tests run in 130ms. The lint sweep is sub-second.

## Mock-layer extension cookbook

When you write a module that needs a new WoW API, add a stub. The pattern:

```lua
-- in tests/mocks/wow_api.lua, alongside other unit stubs:
_G.UnitFoo = function(unit)
    return (Mock.units[unit] or {}).foo or 0
end

-- and a control helper:
function MockSetUnitFoo(unit, foo)
    Mock.units[unit] = Mock.units[unit] or {}
    Mock.units[unit].foo = foo
end
```

Then declare the mock helper in `.luarc.json`'s `diagnostics.globals` so LLS doesn't complain. Then your test:

```lua
MockSetUnitFoo("player", 42)
assert(UnitState:getFoo("player") == 42)
```

Three lines of mock code per API. Compounds slowly. After 6 months of development, our mock is 300 lines covering ~30 WoW APIs.

## What this stack doesn't give you

Honest accounting:

- **No coverage reports.** If you need line coverage, add `luacov` (LuaRocks dependency).
- **No spy/mock framework.** If you want `spy.on(module, "method")` syntax, switch to `busted`. The `setfenv`-per-test pattern in [Adirelle/wowmock](https://github.com/Adirelle/wowmock) is a middle-ground worth studying.
- **No async test support.** WoW's `C_Timer.After` is stubbed as a no-op; if your module relies on delayed execution, your tests will need explicit time-advance helpers (see `MockSetTime`).
- **No visual regression.** Anything UI-related is tested at the call-pattern level (e.g. "did `setReady()` change `__state` to `'ready'`?") — not pixel-perfect.

For Blizz's scope, this is enough. For an addon 10x larger, consider migrating to `busted` and adding coverage.

## Reading order if you want to copy this approach

1. Install `luajit` and `stylua`
2. Copy `tests/run.lua` as your runner
3. Copy `tests/mocks/wow_api.lua` and trim it to the APIs you actually call
4. Write your first module with the dual-load pattern (`local _, addon = ...`)
5. Write a test that `require()`s the module and asserts behavior
6. Run `luajit tests/run.lua` — verify it passes
7. Add stylua + LLS config
8. From here, each new module = a test file + an implementation file + a commit

You'll have a tighter feedback loop than 99% of WoW addons within a day.
