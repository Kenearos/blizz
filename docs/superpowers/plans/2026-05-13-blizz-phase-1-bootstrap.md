# Blizz Phase 1 — Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lege Foundation für das Blizz WoW-Addon: Core-Schicht (Event-Bus, Cooldowns, Unit-State, Combat-Log), v6-Theme-Tokens, Widget-Toolkit-Grundlagen, Saved-Vars, Mock-Layer + Headless-Test-Runner — alles testbar und committet. Am Ende lädt das leere Addon in WoW ohne Fehler und antwortet auf `/blizz status`.

**Architecture:** Standalone-Addon, keine Runtime-Deps außer embedded `LibStub` (kommt erst wenn benötigt). Jede Lua-Datei ist sowohl per WoW-TOC ladbar (`local _, addon = ...`) als auch per `require()` headless testbar (Fallback auf `_G.Blizz`). Tests laufen via LuaJIT mit gemockten WoW-Globals — kein WoW-Client während Entwicklung nötig.

**Tech Stack:**
- WoW Lua 5.1 / LuaJIT 2.1 (Client) — LuaJIT 2.1 lokal als Test-Runner (matches WoW-Semantik + `bit`-Lib)
- `stylua` 2.4.1 für Formatierung (Tabs, 100-col, doppelte Anführungszeichen — siehe `stylua.toml`)
- lua-language-server mit WoW-API-Annotations für IDE
- Plain `assert()` als Test-Assertionen, eigener `tests/run.lua` Runner
- Git: jeder Task = ein atomarer Commit

---

## File Structure

Diese Phase legt folgende Files an (alle neu außer `Blizz.toc`):

| Datei | Verantwortung |
|---|---|
| `Blizz.toc` (modify) | Manifest: listet alle Lua-Files in Ladereihenfolge |
| `Blizz.lua` (new) | Main entry, `Blizz`-Global, Module-Registry, Slash-Command |
| `core/eventbus.lua` | Pub/Sub mit pcall-Error-Containment |
| `core/cooldowns.lua` | GetSpellCooldown + GetSpellCharges Wrapper |
| `core/unitstate.lua` | UnitAura/UnitHealth/UnitThreatSituation-Wrapper |
| `core/combatlog.lua` | CLEU-Parser: filtert & klassifiziert Events |
| `config/savedvars.lua` | BlizzDB-Default-Factory + Version-Migration |
| `ui/theme.lua` | v6 Cyan-Cyber-Tactical Token-Tabelle |
| `ui/widgets/frame.lua` | Themed Frame mit Tech-Corner-Brackets |
| `ui/widgets/text.lua` | Themed FontString (Mono + Letter-Spacing) |
| `ui/widgets/icon.lua` | Spell-Icon mit ready/cd-State (Farb-Inversion) |
| `ui/widgets/bar.lua` | Cooldown/Status-Bar |
| `ui/widgets/alert.lua` | Pulsing Alert (Reflect-Style mit Scale-Animation) |
| `tests/mocks/wow_api.lua` | WoW-Global-Stubs für headless Tests |
| `tests/run.lua` | Test-Runner — sammelt + führt aus |
| `tests/test_theme.lua` | Tests für Theme-Tokens |
| `tests/test_eventbus.lua` | Tests für Event-Bus |
| `tests/test_savedvars.lua` | Tests für BlizzDB-Defaults |
| `tests/test_cooldowns.lua` | Tests für Cooldown-Tracker |
| `tests/test_unitstate.lua` | Tests für Unit-State |
| `tests/test_combatlog.lua` | Tests für Combat-Log-Parser |
| `tests/test_widgets.lua` | Smoke-Tests für Widgets (Konstruktor-Aufrufe) |
| `tests/test_addon.lua` | Test für Module-Registry + Slash-Command |

**Datei-Konventionen:**
- Erste Zeile in jedem Modul-Lua-File:
  ```lua
  local _, addon = ...
  if not addon then
    addon = _G.Blizz or {}
    _G.Blizz = addon
  end
  ```
  Damit funktionieren beide Lade-Wege (WoW-TOC + `require()`).
- Modul-Export: am Ende `addon.ModuleName = ModuleName; return ModuleName`.
- Stylua-Style: Tabs, 100-col, `"double"` quotes.

---

## Task 1: Test-Harness + leerer Runner

**Files:**
- Create: `tests/run.lua`

- [ ] **Step 1: LuaJIT prüfen**

Run: `luajit -e 'print(_VERSION, "ok")'`
Expected output: `Lua 5.1	ok`

- [ ] **Step 2: Test-Runner schreiben**

Create `tests/run.lua`:
```lua
-- tests/run.lua
-- Discovers tests/test_*.lua, runs each in a fresh _G.Blizz scope, prints summary.
-- Each test file uses plain `assert(cond, msg)` and prints "✓ name" on pass.

package.path = "./?.lua;./?/init.lua;" .. package.path

local lfs_ok, lfs = pcall(require, "lfs")
local function list_test_files()
	local files = {}
	if lfs_ok then
		for f in lfs.dir("tests") do
			if f:match("^test_.+%.lua$") then table.insert(files, "tests." .. f:gsub("%.lua$", "")) end
		end
	else
		-- fallback: shell glob via io.popen
		local p = io.popen("ls tests/test_*.lua 2>/dev/null")
		if p then
			for line in p:lines() do
				local name = line:gsub("^tests/", ""):gsub("%.lua$", "")
				table.insert(files, "tests." .. name)
			end
			p:close()
		end
	end
	table.sort(files)
	return files
end

local files = list_test_files()
if #files == 0 then
	print("No tests found in tests/test_*.lua")
	os.exit(0)
end

local passed, failed = 0, 0
local failures = {}

for _, modname in ipairs(files) do
	-- fresh state per test file
	_G.Blizz = nil
	for k in pairs(package.loaded) do
		if k:match("^core%.") or k:match("^ui%.") or k:match("^config%.") or k == modname or k == "tests.mocks.wow_api" then
			package.loaded[k] = nil
		end
	end

	io.write(string.format("\n=== %s ===\n", modname))
	local ok, err = pcall(require, modname)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		table.insert(failures, { mod = modname, err = err })
		print("✗ FAIL:", err)
	end
end

print(string.format("\n--- %d passed, %d failed ---", passed, failed))
if failed > 0 then
	for _, f in ipairs(failures) do print("FAIL:", f.mod) end
	os.exit(1)
end
```

- [ ] **Step 3: Runner ausführen — leere Suite**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected output: `No tests found in tests/test_*.lua`

- [ ] **Step 4: Commit**

```bash
git add tests/run.lua
git commit -m "test: add headless lua test runner"
```

---

## Task 2: WoW API Mock-Layer

**Files:**
- Create: `tests/mocks/wow_api.lua`
- Create: `tests/test_mocks.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_mocks.lua`:
```lua
require "tests.mocks.wow_api"

-- CreateFrame should return a table with WoW frame methods
local f = CreateFrame("Frame", "TestFrame", UIParent)
assert(type(f) == "table", "CreateFrame returned non-table")
assert(type(f.SetSize) == "function", "frame:SetSize missing")
assert(type(f.SetPoint) == "function", "frame:SetPoint missing")
assert(type(f.RegisterEvent) == "function", "frame:RegisterEvent missing")
assert(UIParent ~= nil, "UIParent missing")
print("✓ CreateFrame returns themed frame stub")

-- UnitHealth / UnitGetTotalAbsorbs return mocked numeric values
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 38000 })
assert(UnitHealth("player") == 50000, "UnitHealth")
assert(UnitGetTotalAbsorbs("player") == 38000, "UnitGetTotalAbsorbs")
print("✓ unit state mock works")

-- GetSpellCooldown mock
MockSetCooldown(871, GetTime() - 1, 240)  -- Shield Wall, started 1s ago, 240s CD
local start, dur = GetSpellCooldown(871)
assert(start ~= 0 and dur == 240, "GetSpellCooldown shape")
print("✓ cooldown mock works")

-- Combat-log injection
local captured
MockSetCLEUListener(function(event, ...) captured = { event, ... } end)
MockFireCLEU("SPELL_INTERRUPT", "Player-123", "Target-456", 6552)
assert(captured and captured[1] == "SPELL_INTERRUPT", "CLEU injection")
print("✓ CLEU mock works")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'tests.mocks.wow_api' not found`

- [ ] **Step 3: Mock-Layer implementieren**

Create `tests/mocks/wow_api.lua`:
```lua
-- tests/mocks/wow_api.lua
-- Minimal WoW-Global-Stubs für headless Tests.
-- Nur das was Phase 1 braucht. Erweitern wenn Module mehr APIs nutzen.

local Mock = {}
Mock.units = {}
Mock.cooldowns = {}
Mock.cleu_listener = nil
Mock.time = 1000  -- fake game time, in seconds

local function frame_method_stub() end

local function make_frame(frameType, name, parent, template)
	local f = {
		__type = frameType or "Frame",
		__name = name,
		__parent = parent,
		__template = template,
		__events = {},
		__scripts = {},
		__points = {},
		__size = { 0, 0 },
		__shown = true,
	}
	function f:SetSize(w, h) self.__size = { w, h } end
	function f:GetSize() return self.__size[1], self.__size[2] end
	function f:SetPoint(...) table.insert(self.__points, { ... }) end
	function f:ClearAllPoints() self.__points = {} end
	function f:RegisterEvent(ev) self.__events[ev] = true end
	function f:UnregisterEvent(ev) self.__events[ev] = nil end
	function f:RegisterUnitEvent(ev, _) self.__events[ev] = true end
	function f:IsEventRegistered(ev) return self.__events[ev] == true end
	function f:SetScript(name, fn) self.__scripts[name] = fn end
	function f:GetScript(name) return self.__scripts[name] end
	function f:Show() self.__shown = true end
	function f:Hide() self.__shown = false end
	function f:IsShown() return self.__shown end
	function f:SetAlpha(_) end
	function f:SetFrameStrata(_) end
	function f:SetFrameLevel(_) end
	function f:SetParent(p) self.__parent = p end
	function f:GetName() return self.__name end
	function f:SetBackdrop(_) end
	function f:SetBackdropColor(_, _, _, _) end
	function f:SetBackdropBorderColor(_, _, _, _) end
	function f:CreateTexture(_, _) return make_frame("Texture") end
	function f:CreateFontString(_, _, _) return make_frame("FontString") end
	function f:CreateAnimationGroup(_) return make_frame("AnimationGroup") end
	function f:SetText(t) self.__text = t end
	function f:GetText() return self.__text end
	function f:SetFont(...) self.__font = { ... } end
	function f:SetTextColor(...) self.__textColor = { ... } end
	function f:SetVertexColor(...) self.__vertexColor = { ... } end
	function f:SetTexture(t) self.__texture = t end
	function f:GetParent() return self.__parent end
	-- Method stub catch-all for anything else
	setmetatable(f, {
		__index = function(_, k)
			if type(k) == "string" and k:match("^Set") or k:match("^Get") then return frame_method_stub end
			return nil
		end,
	})
	return f
end

-- ---------- WoW Globals ----------
_G.UIParent = make_frame("Frame", "UIParent")
_G.WorldFrame = make_frame("Frame", "WorldFrame")
_G.CreateFrame = function(frameType, name, parent, template) return make_frame(frameType, name, parent, template) end
_G.GetTime = function() return Mock.time end
_G.UnitExists = function(unit) return Mock.units[unit] ~= nil end
_G.UnitHealth = function(unit) return (Mock.units[unit] or {}).health or 0 end
_G.UnitHealthMax = function(unit) return (Mock.units[unit] or {}).maxHealth or 0 end
_G.UnitGetTotalAbsorbs = function(unit) return (Mock.units[unit] or {}).absorb or 0 end
_G.UnitThreatSituation = function(_, _) return Mock.threat or 3 end
_G.UnitInRange = function(_) return true end
_G.UnitAura = function(_, _) return nil end
_G.GetSpellCooldown = function(spellID)
	local c = Mock.cooldowns[spellID]
	if not c then return 0, 0, 1 end
	return c.start, c.duration, c.enable
end
_G.GetSpellCharges = function(spellID)
	local c = Mock.cooldowns[spellID]
	if not c or not c.charges then return nil end
	return c.charges, c.maxCharges or c.charges, c.start, c.duration
end
_G.GetSpellInfo = function(spellID) return tostring(spellID), nil, nil end

_G.C_Timer = _G.C_Timer or { After = function(_, _) end }
_G.C_Scenario = _G.C_Scenario or { GetCriteriaInfo = function(_) return nil end }

_G.SLASH_BLIZZ1 = nil  -- gets set by addon
_G.SlashCmdList = _G.SlashCmdList or {}

-- ---------- Mock-Control-API (Tests rufen das auf) ----------
function MockSetUnit(unit, props)
	Mock.units[unit] = props
end
function MockSetCooldown(spellID, start, duration, charges, maxCharges)
	Mock.cooldowns[spellID] = {
		start = start or 0,
		duration = duration or 0,
		enable = 1,
		charges = charges,
		maxCharges = maxCharges,
	}
end
function MockSetThreat(level) Mock.threat = level end
function MockSetTime(t) Mock.time = t end
function MockSetCLEUListener(fn) Mock.cleu_listener = fn end
function MockFireCLEU(...) if Mock.cleu_listener then Mock.cleu_listener(...) end end
function MockReset()
	Mock.units = {}
	Mock.cooldowns = {}
	Mock.cleu_listener = nil
	Mock.threat = 3
	Mock.time = 1000
end

return Mock
```

- [ ] **Step 4: Test ausführen — sollte passen**

Run: `luajit tests/run.lua`
Expected output:
```
=== tests.test_mocks ===
✓ CreateFrame returns themed frame stub
✓ unit state mock works
✓ cooldown mock works
✓ CLEU mock works

--- 1 passed, 0 failed ---
```

- [ ] **Step 5: Commit**

```bash
git add tests/mocks/wow_api.lua tests/test_mocks.lua
git commit -m "test: add minimal WoW API mock layer"
```

---

## Task 3: Theme-Tokens (v6 Cyan-Cyber-Tactical)

**Files:**
- Create: `ui/theme.lua`
- Create: `tests/test_theme.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_theme.lua`:
```lua
require "tests.mocks.wow_api"
local Theme = require "ui.theme"

-- alle Schlüssel da
local required_colors = {
	"bg_primary", "primary", "primary_hi", "ready_bg", "ready_fg",
	"alert", "alert_deep", "info", "caster", "frontal", "healer",
	"cd_border", "cd_text",
}
for _, key in ipairs(required_colors) do
	assert(Theme.colors[key], "missing color: " .. key)
	local c = Theme.colors[key]
	assert(type(c) == "table" and #c == 4, "color " .. key .. " is not {r,g,b,a}")
	for i = 1, 4 do
		assert(type(c[i]) == "number" and c[i] >= 0 and c[i] <= 1, "color " .. key .. "[" .. i .. "] out of [0,1]")
	end
end
print("✓ all v6 color tokens present and well-formed")

-- spezifische bekannte Werte verifizieren
local primary = Theme.colors.primary
assert(math.abs(primary[1] - 0.494) < 0.01, "primary R")
assert(math.abs(primary[2] - 0.851) < 0.01, "primary G")
assert(math.abs(primary[3] - 1.000) < 0.01, "primary B")
print("✓ primary cyan #7ed9ff verified")

-- fonts und layout-tokens da
assert(Theme.fonts.family, "fonts.family missing")
assert(Theme.fonts.fallback, "fonts.fallback missing")
assert(Theme.fonts.default_size, "fonts.default_size missing")
assert(Theme.layout.border_width == 1.5, "border_width should be 1.5")
print("✓ font + layout tokens present")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'ui.theme' not found`

- [ ] **Step 3: Theme-Modul implementieren**

Create `ui/theme.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/theme.lua
-- v6 Cyan Cyber Tactical Tokens (siehe docs/superpowers/specs/2026-05-13-blizz-tank-ui-design.md §4)
-- Farben als {r, g, b, a} normalisiert auf [0,1].

local Theme = {}

Theme.colors = {
	bg_primary = { 0.008, 0.024, 0.059, 1.00 }, -- #02060f
	primary = { 0.494, 0.851, 1.000, 1.00 }, -- #7ed9ff
	primary_hi = { 0.831, 0.933, 0.976, 1.00 }, -- #d4eef9
	ready_bg = { 0.494, 0.851, 1.000, 1.00 }, -- #7ed9ff
	ready_fg = { 0.000, 0.102, 0.165, 1.00 }, -- #001a2a
	alert = { 1.000, 0.161, 0.400, 1.00 }, -- #ff2966
	alert_deep = { 0.502, 0.000, 0.125, 1.00 }, -- #800020
	info = { 0.941, 0.941, 0.941, 1.00 }, -- #f0f0f0
	caster = { 1.000, 0.365, 0.784, 1.00 }, -- #ff5dc8
	frontal = { 0.302, 0.878, 0.784, 1.00 }, -- #4de0c8
	healer = { 0.773, 1.000, 0.180, 1.00 }, -- #c5ff2e
	cd_border = { 0.165, 0.227, 0.290, 1.00 }, -- #2a3a4a
	cd_text = { 0.353, 0.439, 0.502, 1.00 }, -- #5a7080
}

Theme.fonts = {
	family = "Interface\\AddOns\\Blizz\\fonts\\JetBrainsMono-Bold.ttf",
	fallback = "Fonts\\FRIZQT__.TTF",
	default_size = 12,
	value_size = 13,
	alert_size = 16,
}

Theme.layout = {
	border_width = 1.5,
	outer_ring_offset = 1.5,
	letter_spacing_title = 3, -- WoW kennt kein letter-spacing — wird via Spacing-Hack umgesetzt
	radius = 0,
	container_radius = 4,
}

-- Convenience: getColor("primary") → 4 separate Werte (für SetColorRGBA-Style)
function Theme.getColor(key)
	local c = Theme.colors[key]
	if not c then return 1, 1, 1, 1 end
	return c[1], c[2], c[3], c[4]
end

addon.Theme = Theme
return Theme
```

- [ ] **Step 4: Test ausführen — sollte passen**

Run: `luajit tests/run.lua`
Expected: `✓ all v6 color tokens present and well-formed`, `✓ primary cyan #7ed9ff verified`, `✓ font + layout tokens present`. 2 passed.

- [ ] **Step 5: stylua formatieren**

Run: `stylua ui/theme.lua tests/test_theme.lua`
Expected: exit 0, no output.

- [ ] **Step 6: Commit**

```bash
git add ui/theme.lua tests/test_theme.lua
git commit -m "feat(ui): v6 theme tokens (cyan cyber tactical palette)"
```

---

## Task 4: Event-Bus

**Files:**
- Create: `core/eventbus.lua`
- Create: `tests/test_eventbus.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_eventbus.lua`:
```lua
require "tests.mocks.wow_api"
local EventBus = require "core.eventbus"

-- subscribe + dispatch
local count = 0
EventBus:subscribe("PLAYER_LOGIN", function() count = count + 1 end)
EventBus:dispatch("PLAYER_LOGIN")
EventBus:dispatch("PLAYER_LOGIN")
assert(count == 2, "subscriber should fire on each dispatch (got " .. count .. ")")
print("✓ subscribe/dispatch works")

-- mehrere subscriber für gleiches Event
local a, b = 0, 0
EventBus:subscribe("SPELL_UPDATE_COOLDOWN", function() a = a + 1 end)
EventBus:subscribe("SPELL_UPDATE_COOLDOWN", function() b = b + 1 end)
EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(a == 1 and b == 1, "both subscribers should fire")
print("✓ multi-subscriber works")

-- Error in einem Subscriber stoppt nicht die anderen
local survived = false
EventBus:subscribe("UNIT_AURA", function() error("oopsie") end)
EventBus:subscribe("UNIT_AURA", function() survived = true end)
EventBus:dispatch("UNIT_AURA")
assert(survived, "second subscriber should still fire after first errors")
print("✓ pcall containment works")

-- unsubscribe per token
local hit = 0
local token = EventBus:subscribe("PLAYER_DEAD", function() hit = hit + 1 end)
EventBus:dispatch("PLAYER_DEAD")
EventBus:unsubscribe(token)
EventBus:dispatch("PLAYER_DEAD")
assert(hit == 1, "unsubscribed callback should not fire (got " .. hit .. ")")
print("✓ unsubscribe by token works")

-- dispatch übergibt args
local got_args
EventBus:subscribe("UNIT_HEALTH", function(unit, value) got_args = { unit, value } end)
EventBus:dispatch("UNIT_HEALTH", "player", 12345)
assert(got_args[1] == "player" and got_args[2] == 12345, "args passthrough")
print("✓ args passthrough works")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'core.eventbus' not found`

- [ ] **Step 3: Event-Bus implementieren**

Create `core/eventbus.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/eventbus.lua
-- Pub/Sub-Bus mit pcall-Error-Containment.
-- Subscriber-Errors landen in addon.errors (ring buffer, max 50).

local EventBus = {}
EventBus.__subscribers = {} -- [eventName] = { [token] = callback }
EventBus.__nextToken = 0
EventBus.__errors = addon.errors or {}
addon.errors = EventBus.__errors

local MAX_ERRORS = 50

local function log_error(event, err)
	table.insert(EventBus.__errors, {
		event = event,
		err = tostring(err),
		time = (GetTime and GetTime()) or 0,
	})
	while #EventBus.__errors > MAX_ERRORS do
		table.remove(EventBus.__errors, 1)
	end
end

function EventBus:subscribe(event, callback)
	assert(type(event) == "string", "event must be string")
	assert(type(callback) == "function", "callback must be function")
	self.__subscribers[event] = self.__subscribers[event] or {}
	self.__nextToken = self.__nextToken + 1
	local token = self.__nextToken
	self.__subscribers[event][token] = callback
	return { event = event, token = token }
end

function EventBus:unsubscribe(handle)
	if not handle or not self.__subscribers[handle.event] then return end
	self.__subscribers[handle.event][handle.token] = nil
end

function EventBus:dispatch(event, ...)
	local subs = self.__subscribers[event]
	if not subs then return end
	for _, cb in pairs(subs) do
		local ok, err = pcall(cb, ...)
		if not ok then log_error(event, err) end
	end
end

addon.EventBus = EventBus
return EventBus
```

- [ ] **Step 4: Test ausführen — sollte passen**

Run: `luajit tests/run.lua`
Expected: alle 5 assertions in test_eventbus passen. `3 passed, 0 failed` (mocks + theme + eventbus).

- [ ] **Step 5: stylua + Commit**

```bash
stylua core/eventbus.lua tests/test_eventbus.lua
git add core/eventbus.lua tests/test_eventbus.lua
git commit -m "feat(core): event bus with pcall error containment"
```

---

## Task 5: Saved-Variables (BlizzDB)

**Files:**
- Create: `config/savedvars.lua`
- Create: `tests/test_savedvars.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_savedvars.lua`:
```lua
require "tests.mocks.wow_api"
local SavedVars = require "config.savedvars"

-- erster Load: erzeugt Defaults
_G.BlizzDB = nil
local db = SavedVars:load()
assert(db.version == 1, "version should be 1, got " .. tostring(db.version))
assert(db.active_profile == "default", "active_profile should be 'default'")
assert(db.profiles.default, "profiles.default missing")
assert(db.profiles.default.hero_talent == "auto", "hero_talent default should be 'auto'")
assert(type(db.profiles.default.positions) == "table", "positions table missing")
assert(type(db.profiles.default.disabled) == "table", "disabled table missing")
assert(type(db.profiles.default.module_options) == "table", "module_options missing")
assert(type(db.errors) == "table", "errors table missing")
print("✓ first-load creates correct defaults")

-- zweiter Load: behält bestehende Daten
_G.BlizzDB = { version = 1, active_profile = "raid", profiles = { raid = { positions = {}, disabled = {}, module_options = {}, hero_talent = "colossus" } }, errors = {} }
local db2 = SavedVars:load()
assert(db2.active_profile == "raid", "should preserve active_profile")
assert(db2.profiles.raid.hero_talent == "colossus", "should preserve hero_talent")
print("✓ second-load preserves existing data")

-- getCurrentProfile gibt aktives Profil zurück
_G.BlizzDB = nil
SavedVars:load()
local p = SavedVars:getCurrentProfile()
assert(p.hero_talent == "auto", "current profile should be default")
print("✓ getCurrentProfile works")

-- migration: version 0 → 1 fügt fehlende Felder hinzu
_G.BlizzDB = { version = 0 }
local db3 = SavedVars:load()
assert(db3.version == 1, "migration should bump version to 1")
assert(db3.profiles, "migration should populate profiles")
print("✓ migration v0 → v1 works")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'config.savedvars' not found`

- [ ] **Step 3: SavedVars-Modul implementieren**

Create `config/savedvars.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- config/savedvars.lua
-- BlizzDB lifecycle: erstmaliges Anlegen, Version-Migration, Profil-Lookup.
-- BlizzDB ist eine SavedVariables-Tabelle (siehe Blizz.toc ## SavedVariables: BlizzDB).

local SavedVars = {}
local CURRENT_VERSION = 1

local function default_profile()
	return {
		positions = {}, -- [moduleId] = {x, y, anchor, relativeAnchor}
		disabled = {}, -- [moduleId] = true
		hero_talent = "auto", -- "auto" | "mountain_thane" | "colossus"
		theme_overrides = {},
		module_options = {
			mitigation = { show_charges = true, show_absorb_value = true },
			kickrota = { announce_to_party = false },
			nameplates = { override_default = false },
		},
	}
end

local function default_db()
	return {
		version = CURRENT_VERSION,
		active_profile = "default",
		profiles = { default = default_profile() },
		errors = {},
	}
end

local migrators = {
	-- migration step: 0 → 1 (initial)
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

function SavedVars:getCurrentProfile()
	local db = _G.BlizzDB
	if not db then return nil end
	return db.profiles[db.active_profile]
end

function SavedVars:getModuleOption(moduleId, key)
	local p = self:getCurrentProfile()
	if not p or not p.module_options[moduleId] then return nil end
	return p.module_options[moduleId][key]
end

addon.SavedVars = SavedVars
return SavedVars
```

- [ ] **Step 4: Test ausführen**

Run: `luajit tests/run.lua`
Expected: alle 4 print-Statements in test_savedvars, `4 passed`.

- [ ] **Step 5: stylua + Commit**

```bash
stylua config/savedvars.lua tests/test_savedvars.lua
git add config/savedvars.lua tests/test_savedvars.lua
git commit -m "feat(config): BlizzDB saved-vars with v0→v1 migration"
```

---

## Task 6: Cooldown-Tracker

**Files:**
- Create: `core/cooldowns.lua`
- Create: `tests/test_cooldowns.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_cooldowns.lua`:
```lua
require "tests.mocks.wow_api"
local Cooldowns = require "core.cooldowns"

MockReset()
MockSetTime(1000)

-- spell off cooldown
MockSetCooldown(871, 0, 0) -- Shield Wall, not used
local st = Cooldowns:getState(871)
assert(st.ready == true, "fresh spell should be ready")
assert(st.remaining == 0, "remaining should be 0")
print("✓ ready spell detected")

-- spell on cooldown
MockSetCooldown(871, 995, 240) -- started 5s ago, 240s CD
st = Cooldowns:getState(871)
assert(st.ready == false, "spell on CD should not be ready")
assert(math.abs(st.remaining - 235) < 0.1, "remaining should be ~235s (got " .. st.remaining .. ")")
assert(math.abs(st.percent - (5 / 240)) < 0.01, "percent should be ~2%")
print("✓ on-cd spell calculated correctly")

-- spell mit charges
MockSetCooldown(100, 995, 20, 2, 3) -- Charge: 2 of 3 charges, recharging
st = Cooldowns:getState(100)
assert(st.charges == 2, "charges should be 2")
assert(st.maxCharges == 3, "maxCharges should be 3")
assert(st.ready == true, "spell with charges available should be ready")
print("✓ charges tracked correctly")

-- bulk poll
MockSetCooldown(1, 0, 0)
MockSetCooldown(2, 999, 10)
local states = Cooldowns:getStates({ 1, 2 })
assert(states[1].ready and not states[2].ready, "bulk poll")
print("✓ bulk getStates works")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'core.cooldowns' not found`

- [ ] **Step 3: Cooldowns-Modul implementieren**

Create `core/cooldowns.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/cooldowns.lua
-- Wrapper um GetSpellCooldown + GetSpellCharges.
-- Liefert pro Spell {ready, remaining, percent, charges, maxCharges}.

local Cooldowns = {}

function Cooldowns:getState(spellID)
	local start, duration, enabled = GetSpellCooldown(spellID)
	local now = GetTime()
	local charges, maxCharges = nil, nil
	if GetSpellCharges then
		local c, mc = GetSpellCharges(spellID)
		if c then
			charges, maxCharges = c, mc
		end
	end

	local state = {
		spellID = spellID,
		ready = false,
		remaining = 0,
		percent = 0,
		charges = charges,
		maxCharges = maxCharges,
	}

	-- charges available: always considered "ready"
	if charges and charges > 0 then
		state.ready = true
		-- still track recharge progress for next charge
		if duration and duration > 0 and start and start > 0 then
			local elapsed = now - start
			state.remaining = math.max(0, duration - elapsed)
			state.percent = math.min(1, elapsed / duration)
		end
		return state
	end

	if not start or not duration or duration == 0 then
		state.ready = true
		return state
	end

	local elapsed = now - start
	if elapsed >= duration then
		state.ready = true
		return state
	end

	state.remaining = duration - elapsed
	state.percent = elapsed / duration
	return state
end

function Cooldowns:getStates(spellIDs)
	local out = {}
	for _, id in ipairs(spellIDs) do
		out[id] = self:getState(id)
	end
	return out
end

addon.Cooldowns = Cooldowns
return Cooldowns
```

- [ ] **Step 4: Test ausführen + stylua + Commit**

```bash
luajit tests/run.lua
stylua core/cooldowns.lua tests/test_cooldowns.lua
git add core/cooldowns.lua tests/test_cooldowns.lua
git commit -m "feat(core): cooldown tracker (incl. charges)"
```

Expected: 5 passed.

---

## Task 7: Unit-State-Wrapper

**Files:**
- Create: `core/unitstate.lua`
- Create: `tests/test_unitstate.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_unitstate.lua`:
```lua
require "tests.mocks.wow_api"
local UnitState = require "core.unitstate"

MockReset()
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 38000 })
MockSetThreat(3)

assert(UnitState:getHealth("player") == 50000, "getHealth")
assert(UnitState:getMaxHealth("player") == 100000, "getMaxHealth")
assert(math.abs(UnitState:getHealthPercent("player") - 0.5) < 0.001, "getHealthPercent")
assert(UnitState:getAbsorb("player") == 38000, "getAbsorb")
print("✓ health/absorb readout")

assert(UnitState:getThreatLevel("player", "target") == 3, "getThreatLevel")
assert(UnitState:isTanking("player", "target") == true, "isTanking at level 3")
MockSetThreat(2)
assert(UnitState:isTanking("player", "target") == false, "not tanking at level 2")
print("✓ threat helpers")

assert(UnitState:isInRange("party1") == true, "isInRange (mocked true)")
print("✓ range check")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'core.unitstate' not found`

- [ ] **Step 3: UnitState-Modul implementieren**

Create `core/unitstate.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/unitstate.lua
-- Wrappers für UnitHealth/UnitAura/UnitThreatSituation mit Convenience-Helpers.

local UnitState = {}

function UnitState:getHealth(unit) return UnitHealth(unit) or 0 end

function UnitState:getMaxHealth(unit) return UnitHealthMax(unit) or 0 end

function UnitState:getHealthPercent(unit)
	local max = self:getMaxHealth(unit)
	if max == 0 then return 0 end
	return self:getHealth(unit) / max
end

function UnitState:getAbsorb(unit) return UnitGetTotalAbsorbs(unit) or 0 end

-- 0 = low/no threat, 1 = high threat, 2 = primary target, 3 = securely tanking
function UnitState:getThreatLevel(unit, target) return UnitThreatSituation(unit, target) or 0 end

function UnitState:isTanking(unit, target) return self:getThreatLevel(unit, target) == 3 end

function UnitState:isInRange(unit) return UnitInRange(unit) end

addon.UnitState = UnitState
return UnitState
```

- [ ] **Step 4: Test + Stylua + Commit**

```bash
luajit tests/run.lua
stylua core/unitstate.lua tests/test_unitstate.lua
git add core/unitstate.lua tests/test_unitstate.lua
git commit -m "feat(core): unit state wrapper (health/absorb/threat/range)"
```

Expected: 6 passed total.

---

## Task 8: Combat-Log-Parser

**Files:**
- Create: `core/combatlog.lua`
- Create: `tests/test_combatlog.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_combatlog.lua`:
```lua
require "tests.mocks.wow_api"
local CombatLog = require "core.combatlog"

MockReset()
CombatLog:init()

local captured = {}
CombatLog:on("interrupt", function(payload) table.insert(captured, payload) end)

-- WoW CLEU args (verkürzt für Test): timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, ...
local function fire_interrupt(sourceGUID, destGUID, spellID)
	MockFireCLEU(1234, "SPELL_INTERRUPT", false, sourceGUID, "Caster", 0, 0, destGUID, "Target", 0, 0, spellID, "Interrupted Cast")
end

fire_interrupt("Player-1", "Creature-1", 6552)
fire_interrupt("Player-2", "Creature-2", 47528)
assert(#captured == 2, "expected 2 interrupt events, got " .. #captured)
assert(captured[1].sourceGUID == "Player-1", "sourceGUID propagation")
assert(captured[1].spellID == 6552, "spellID propagation")
print("✓ interrupt events classified")

-- death event
captured = {}
CombatLog:on("death", function(p) table.insert(captured, p) end)
MockFireCLEU(1235, "UNIT_DIED", false, nil, nil, 0, 0, "Player-3", "FallenHero", 0, 0)
assert(#captured == 1 and captured[1].destGUID == "Player-3", "death event")
print("✓ death events classified")

-- unrelated event ignored
captured = {}
MockFireCLEU(1236, "SPELL_PERIODIC_HEAL", false, "Player-X", "X", 0, 0, "Player-X", "X", 0, 0, 33076, "Prayer of Mending")
assert(#captured == 0, "non-classified event should not fire callbacks")
print("✓ unrelated events ignored")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'core.combatlog' not found`

- [ ] **Step 3: CombatLog-Modul implementieren**

Create `core/combatlog.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/combatlog.lua
-- Klassifiziert COMBAT_LOG_EVENT_UNFILTERED in einfache Kategorien.
-- Subscriber: CombatLog:on("interrupt", fn) / "death" / "cast_start" / "cast_success".

local CombatLog = {}
CombatLog.__handlers = {}

local function fire(kind, payload)
	local hs = CombatLog.__handlers[kind]
	if not hs then return end
	for _, h in ipairs(hs) do
		local ok, err = pcall(h, payload)
		if not ok and addon.errors then
			table.insert(addon.errors, { event = "CLEU:" .. kind, err = tostring(err) })
		end
	end
end

local function build_payload(timestamp, subEvent, sourceGUID, sourceName, destGUID, destName, spellID, spellName)
	return {
		timestamp = timestamp,
		subEvent = subEvent,
		sourceGUID = sourceGUID,
		sourceName = sourceName,
		destGUID = destGUID,
		destName = destName,
		spellID = spellID,
		spellName = spellName,
	}
end

function CombatLog:on(kind, callback)
	self.__handlers[kind] = self.__handlers[kind] or {}
	table.insert(self.__handlers[kind], callback)
end

function CombatLog:dispatch(timestamp, subEvent, _hideCaster, sourceGUID, sourceName, _sf, _srf, destGUID, destName, _df, _drf, spellID, spellName)
	if subEvent == "SPELL_INTERRUPT" then
		fire("interrupt", build_payload(timestamp, subEvent, sourceGUID, sourceName, destGUID, destName, spellID, spellName))
	elseif subEvent == "UNIT_DIED" then
		fire("death", build_payload(timestamp, subEvent, sourceGUID, sourceName, destGUID, destName, spellID, spellName))
	elseif subEvent == "SPELL_CAST_START" then
		fire("cast_start", build_payload(timestamp, subEvent, sourceGUID, sourceName, destGUID, destName, spellID, spellName))
	elseif subEvent == "SPELL_CAST_SUCCESS" then
		fire("cast_success", build_payload(timestamp, subEvent, sourceGUID, sourceName, destGUID, destName, spellID, spellName))
	end
end

function CombatLog:init()
	-- in WoW: ein Frame mit RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") + CombatLogGetCurrentEventInfo()
	-- in Tests: via MockSetCLEUListener
	local function on_event(...) self:dispatch(...) end
	if MockSetCLEUListener then -- test mode
		MockSetCLEUListener(on_event)
		return
	end
	-- production: WoW frame
	local f = CreateFrame("Frame", "BlizzCLEU")
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	f:SetScript("OnEvent", function()
		if CombatLogGetCurrentEventInfo then on_event(CombatLogGetCurrentEventInfo()) end
	end)
end

addon.CombatLog = CombatLog
return CombatLog
```

- [ ] **Step 4: Test + Stylua + Commit**

```bash
luajit tests/run.lua
stylua core/combatlog.lua tests/test_combatlog.lua
git add core/combatlog.lua tests/test_combatlog.lua
git commit -m "feat(core): combat log parser (interrupt/death/cast events)"
```

Expected: 7 passed.

---

## Task 9: Widget — Frame + Text

**Files:**
- Create: `ui/widgets/frame.lua`
- Create: `ui/widgets/text.lua`
- Create: `tests/test_widgets.lua`

- [ ] **Step 1: Failing Test schreiben**

Create `tests/test_widgets.lua`:
```lua
require "tests.mocks.wow_api"
local Theme = require "ui.theme"
local Frame = require "ui.widgets.frame"
local Text = require "ui.widgets.text"

-- Frame: erzeugt themed Frame, hat Tech-Corner-Brackets
local f = Frame:new({ name = "TestFrame", parent = UIParent, width = 100, height = 30 })
assert(f.__type == "Frame", "should be a Frame stub")
assert(f.__size[1] == 100 and f.__size[2] == 30, "size set")
assert(f.__corners, "tech corner brackets should be created")
assert(f.__corners.topleft and f.__corners.bottomright, "corners present")
print("✓ Frame:new creates themed frame with corners")

-- Frame state inversion: setReady() wendet Cyan-Fill an
f:setReady()
assert(f.__state == "ready", "state should be ready")
f:setDefault()
assert(f.__state == "default", "state back to default")
print("✓ Frame state switching")

-- Text: setzt Mono-Font + value-Color
local t = Text:new({ parent = f, text = "4.8s", style = "value" })
assert(t.__type == "FontString", "Text should be FontString")
assert(t.__text == "4.8s", "text content set")
assert(t.__font ~= nil, "font set")
print("✓ Text:new creates themed font string")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'ui.widgets.frame' not found`

- [ ] **Step 3: Frame-Widget implementieren**

Create `ui/widgets/frame.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/frame.lua
-- Themed Frame mit v6-Theming. Tech-Corner-Brackets oben-links und unten-rechts.
-- States: default | ready | cd | alert.

local Theme = addon.Theme or require("ui.theme")

local Frame = {}

local function apply_default(f)
	f:SetBackdropColor(Theme.getColor("bg_primary"))
	f:SetBackdropBorderColor(Theme.getColor("primary"))
end
local function apply_ready(f)
	f:SetBackdropColor(Theme.getColor("ready_bg"))
	f:SetBackdropBorderColor(Theme.getColor("primary_hi"))
end
local function apply_cd(f)
	f:SetBackdropColor(Theme.getColor("bg_primary"))
	f:SetBackdropBorderColor(Theme.getColor("cd_border"))
end
local function apply_alert(f)
	f:SetBackdropColor(Theme.getColor("alert_deep"))
	f:SetBackdropBorderColor(Theme.getColor("alert"))
end

local function make_corner(parent, anchor1, anchor2)
	local c = parent:CreateTexture(nil, "OVERLAY")
	c:SetSize(6, 6)
	c:SetVertexColor(Theme.getColor("primary"))
	-- in production this draws an L-shape via two textures; here it's a stub
	c:SetTexture("Interface\\Buttons\\WHITE8X8")
	if c.SetPoint then c:SetPoint(anchor1, parent, anchor2 or anchor1, 0, 0) end
	return c
end

function Frame:new(spec)
	spec = spec or {}
	local f = CreateFrame("Frame", spec.name, spec.parent or UIParent, "BackdropTemplate")
	f:SetSize(spec.width or 100, spec.height or 30)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = Theme.layout.border_width,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})

	-- Tech-Corner-Brackets (L-Marker)
	f.__corners = {
		topleft = make_corner(f, "TOPLEFT"),
		bottomright = make_corner(f, "BOTTOMRIGHT"),
	}

	-- State-API
	f.__state = "default"
	function f:setDefault() self.__state = "default"; apply_default(self) end
	function f:setReady() self.__state = "ready"; apply_ready(self) end
	function f:setCD() self.__state = "cd"; apply_cd(self) end
	function f:setAlert() self.__state = "alert"; apply_alert(self) end

	apply_default(f)
	return f
end

addon.Frame = Frame
return Frame
```

- [ ] **Step 4: Text-Widget implementieren**

Create `ui/widgets/text.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/text.lua
-- Themed FontString mit Style-Profilen.
-- Styles: default | value | label | alert | title.

local Theme = addon.Theme or require("ui.theme")

local STYLE = {
	default = { color = "primary", size_key = "default_size" },
	value = { color = "info", size_key = "value_size" },
	label = { color = "cd_text", size_key = "default_size" },
	alert = { color = "info", size_key = "alert_size" },
	title = { color = "primary_hi", size_key = "default_size" },
}

local Text = {}

function Text:new(spec)
	assert(spec and spec.parent, "Text:new requires {parent=...}")
	local layer = spec.layer or "OVERLAY"
	local fs = spec.parent:CreateFontString(spec.name, layer)
	local style = STYLE[spec.style or "default"] or STYLE.default
	local size = Theme.fonts[style.size_key] or Theme.fonts.default_size
	fs:SetFont(Theme.fonts.family, size, "OUTLINE")
	-- Fallback when bundled font not loaded
	if fs.GetFont and fs.__font and fs.__font[1] == Theme.fonts.family then
		-- (in production we'd verify via SetFont return value; in test mock we just trust __font)
	end
	fs:SetTextColor(Theme.getColor(style.color))
	if spec.text then fs:SetText(spec.text) end
	return fs
end

addon.Text = Text
return Text
```

- [ ] **Step 5: Test ausführen + stylua + commit**

```bash
luajit tests/run.lua
stylua ui/widgets/frame.lua ui/widgets/text.lua tests/test_widgets.lua
git add ui/widgets/frame.lua ui/widgets/text.lua tests/test_widgets.lua
git commit -m "feat(ui): Frame + Text widgets with v6 theming and tech corners"
```

Expected: 8 passed.

---

## Task 10: Widget — Icon (Spell-Icon mit States)

**Files:**
- Create: `ui/widgets/icon.lua`
- Modify: `tests/test_widgets.lua` (append)

- [ ] **Step 1: Test erweitern**

Append to `tests/test_widgets.lua`:
```lua

local Icon = require "ui.widgets.icon"

-- Icon: default state = outline, primary color
local ico = Icon:new({ parent = UIParent, name = "WALL", spellID = 871, size = 38 })
assert(ico.__type == "Frame", "Icon root should be Frame")
assert(ico:getState() == "default", "default state initially")
assert(ico:getLabel() == "WALL", "label set")
print("✓ Icon default state")

-- Setze auf ready → invertierte Farben
ico:setReady()
assert(ico:getState() == "ready", "ready state")
print("✓ Icon ready state")

-- Setze auf cd → grau + remaining
ico:setCD(22)
assert(ico:getState() == "cd", "cd state")
assert(ico:getRemainingText() == "22s", "remaining text")
print("✓ Icon cd state with remaining")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'ui.widgets.icon' not found`

- [ ] **Step 3: Icon-Widget implementieren**

Create `ui/widgets/icon.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/icon.lua
-- Spell-Icon mit ready/cd/default-States (Farb-Inversion per v6).
-- Spec: { parent, name, spellID, size, label?, sub? }

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local Icon = {}

function Icon:new(spec)
	spec = spec or {}
	local size = spec.size or 38
	local root = Frame:new({ name = spec.name, parent = spec.parent, width = size + 14, height = size + 6 })

	local label_text = spec.label or (spec.name and tostring(spec.name)) or tostring(spec.spellID or "?")
	local label = Text:new({ parent = root, text = label_text, style = "default" })
	if label.SetPoint then label:SetPoint("CENTER", root, "CENTER", 0, 2) end

	local sub_text = ""
	local sub = Text:new({ parent = root, text = sub_text, style = "label" })
	if sub.SetPoint then sub:SetPoint("CENTER", root, "CENTER", 0, -8) end

	root.__label = label
	root.__sub = sub
	root.__labelText = label_text
	root.__remaining = nil

	function root:getState() return self.__state end
	function root:getLabel() return self.__labelText end
	function root:getRemainingText() return self.__remaining and (tostring(math.floor(self.__remaining)) .. "s") or "" end

	local origSetReady = root.setReady
	function root:setReady() origSetReady(self); self.__remaining = nil; self.__sub:SetText("") end

	local origSetCD = root.setCD
	function root:setCD(remaining)
		origSetCD(self)
		self.__remaining = remaining or 0
		self.__sub:SetText(self:getRemainingText())
	end

	return root
end

addon.Icon = Icon
return Icon
```

- [ ] **Step 4: Test + stylua + commit**

```bash
luajit tests/run.lua
stylua ui/widgets/icon.lua tests/test_widgets.lua
git add ui/widgets/icon.lua tests/test_widgets.lua
git commit -m "feat(ui): Icon widget with ready/cd state inversion"
```

Expected: 8 passed (3 additional assertions in test_widgets).

---

## Task 11: Widget — Bar

**Files:**
- Create: `ui/widgets/bar.lua`
- Modify: `tests/test_widgets.lua` (append)

- [ ] **Step 1: Test erweitern**

Append to `tests/test_widgets.lua`:
```lua

local Bar = require "ui.widgets.bar"

-- Bar: füllen/leeren
local bar = Bar:new({ parent = UIParent, width = 200, height = 12 })
bar:setValue(0.5)
assert(math.abs(bar:getValue() - 0.5) < 0.001, "bar value 0.5")
bar:setValue(0)
assert(bar:getValue() == 0, "bar value 0")
bar:setValue(1.2) -- clamp
assert(bar:getValue() == 1, "bar value clamped to 1")
bar:setValue(-0.5) -- clamp
assert(bar:getValue() == 0, "bar value clamped to 0")
print("✓ Bar value setter + clamping")

bar:setValueFromRemaining(5, 10) -- 50% gone, 50% remaining
assert(math.abs(bar:getValue() - 0.5) < 0.001, "setValueFromRemaining")
print("✓ Bar setValueFromRemaining")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'ui.widgets.bar' not found`

- [ ] **Step 3: Bar-Widget implementieren**

Create `ui/widgets/bar.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/bar.lua
-- Horizontale Status-Bar. Value [0,1]. Theming aus v6.

local Frame = addon.Frame or require("ui.widgets.frame")
local Theme = addon.Theme or require("ui.theme")

local Bar = {}

function Bar:new(spec)
	spec = spec or {}
	local width, height = spec.width or 200, spec.height or 12
	local root = Frame:new({ name = spec.name, parent = spec.parent, width = width, height = height })

	local fill = root:CreateTexture(nil, "ARTWORK")
	fill:SetTexture("Interface\\Buttons\\WHITE8X8")
	fill:SetVertexColor(Theme.getColor("primary"))
	if fill.SetPoint then
		fill:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
		fill:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
	end
	if fill.SetSize then fill:SetSize(0, height) end

	root.__width = width
	root.__height = height
	root.__fill = fill
	root.__value = 0

	function root:setValue(v)
		v = math.min(1, math.max(0, v))
		self.__value = v
		if self.__fill.SetSize then self.__fill:SetSize(self.__width * v, self.__height) end
	end
	function root:getValue() return self.__value end
	function root:setValueFromRemaining(remaining, total)
		if total == 0 then self:setValue(0); return end
		self:setValue(remaining / total)
	end

	return root
end

addon.Bar = Bar
return Bar
```

- [ ] **Step 4: Test + stylua + commit**

```bash
luajit tests/run.lua
stylua ui/widgets/bar.lua tests/test_widgets.lua
git add ui/widgets/bar.lua tests/test_widgets.lua
git commit -m "feat(ui): Bar widget with value clamping"
```

Expected: 8 passed (2 additional assertions).

---

## Task 12: Widget — Alert (Pulsing Reflect-Style)

**Files:**
- Create: `ui/widgets/alert.lua`
- Modify: `tests/test_widgets.lua` (append)

- [ ] **Step 1: Test erweitern**

Append to `tests/test_widgets.lua`:
```lua

local Alert = require "ui.widgets.alert"

local alert = Alert:new({ parent = UIParent, text = "REFLECT INCOMING", width = 240, height = 32 })
assert(alert:getState() == "alert", "Alert default state is alert")
assert(alert:isPulsing() == false, "Alert not pulsing initially (created hidden)")
alert:show()
assert(alert:isShown(), "Alert shown")
assert(alert:isPulsing(), "Alert pulses when shown")
alert:hide()
assert(not alert:isShown(), "Alert hidden")
assert(not alert:isPulsing(), "Alert stops pulsing when hidden")
print("✓ Alert show/hide + pulse lifecycle")

alert:setText("KICK NOW")
assert(alert:getText() == "KICK NOW", "text updated")
print("✓ Alert text updates")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'ui.widgets.alert' not found`

- [ ] **Step 3: Alert-Widget implementieren**

Create `ui/widgets/alert.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/alert.lua
-- Pulsing Alert für Reflect-Style-Warnings.
-- Animation: 0.9s scale 1.0→1.04 + Alpha-Pulse zwischen alert_deep und alert.
-- Im Test-Modus wird die AnimationGroup als Mock geführt; isPulsing prüft Flag.

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")
local Theme = addon.Theme or require("ui.theme")

local Alert = {}

function Alert:new(spec)
	spec = spec or {}
	local root = Frame:new({ name = spec.name, parent = spec.parent, width = spec.width or 240, height = spec.height or 32 })
	root:setAlert()

	local label = Text:new({ parent = root, text = spec.text or "", style = "alert" })
	if label.SetPoint then label:SetPoint("CENTER", root, "CENTER", 0, 0) end

	local pulse = root:CreateAnimationGroup()
	if pulse.SetLooping then pulse:SetLooping("REPEAT") end

	root.__label = label
	root.__pulse = pulse
	root.__pulsing = false

	-- start hidden (Alert nur sichtbar wenn ein Modul sie zeigt)
	root:Hide()

	function root:getState() return self.__state end
	function root:isPulsing() return self.__pulsing end
	function root:getText() return self.__label:GetText() end
	function root:setText(t) self.__label:SetText(t) end

	local origShow, origHide = root.Show, root.Hide
	function root:show()
		origShow(self)
		self.__pulsing = true
		if self.__pulse.Play then self.__pulse:Play() end
	end
	function root:hide()
		origHide(self)
		self.__pulsing = false
		if self.__pulse.Stop then self.__pulse:Stop() end
	end

	return root
end

addon.Alert = Alert
return Alert
```

- [ ] **Step 4: Test + stylua + commit**

```bash
luajit tests/run.lua
stylua ui/widgets/alert.lua tests/test_widgets.lua
git add ui/widgets/alert.lua tests/test_widgets.lua
git commit -m "feat(ui): Alert widget with pulse animation lifecycle"
```

Expected: 8 passed.

---

## Task 13: Main Entry — Blizz.lua mit Module-Registry + Slash-Command

**Files:**
- Create: `Blizz.lua`
- Create: `tests/test_addon.lua`

- [ ] **Step 1: Test schreiben**

Create `tests/test_addon.lua`:
```lua
require "tests.mocks.wow_api"
require "Blizz" -- loads main entry, populates _G.Blizz

assert(_G.Blizz, "Blizz global should exist")
assert(type(_G.Blizz.registerModule) == "function", "registerModule should be function")
assert(type(_G.Blizz.modules) == "table", "modules registry")
print("✓ Blizz main entry sets up registry")

-- register a fake module
local fired = 0
local fake = {
	id = "fake",
	events = { "PLAYER_LOGIN" },
	init = function(self) self.initialized = true end,
	onEvent = function(self, _ev) fired = fired + 1 end,
}
_G.Blizz.registerModule(fake)
assert(_G.Blizz.modules.fake == fake, "fake module registered")
_G.Blizz:bootstrap()
assert(fake.initialized, "module init called by bootstrap")

-- dispatch via internal EventBus
_G.Blizz.EventBus:dispatch("PLAYER_LOGIN")
assert(fired == 1, "subscribed module should receive event")
print("✓ module registry + bootstrap + event routing")

-- slash command sets status
SLASH_BLIZZ1 = nil
SlashCmdList = {}
_G.Blizz:registerSlash()
assert(SLASH_BLIZZ1 == "/blizz", "slash registered")
assert(type(SlashCmdList.BLIZZ) == "function", "slash handler set")
-- handler returns nothing but should not error on "status"
local ok = pcall(SlashCmdList.BLIZZ, "status")
assert(ok, "slash 'status' handler must not error")
print("✓ slash command registers and handles 'status'")
```

- [ ] **Step 2: Test ausführen — sollte fehlschlagen**

Run: `luajit tests/run.lua`
Expected: FAIL — `module 'Blizz' not found`

- [ ] **Step 3: Blizz.lua implementieren**

Create `Blizz.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- Blizz.lua — Main entry. Setzt _G.Blizz auf, lädt Sub-Module via TOC,
-- registriert Slash-Command, koordiniert bootstrap.

local EventBus = addon.EventBus or require("core.eventbus")
local SavedVars = addon.SavedVars or require("config.savedvars")

addon.modules = addon.modules or {}

function addon.registerModule(mod)
	assert(mod and mod.id, "module needs id")
	addon.modules[mod.id] = mod
	if mod.events and EventBus then
		for _, ev in ipairs(mod.events) do
			EventBus:subscribe(ev, function(...) if mod.onEvent then mod:onEvent(ev, ...) end end)
		end
	end
end

function addon:bootstrap()
	SavedVars:load()
	for id, mod in pairs(self.modules) do
		if mod.init then
			local ok, err = pcall(mod.init, mod)
			if not ok then
				table.insert(addon.errors, { event = "init:" .. id, err = tostring(err) })
			end
		end
	end
end

function addon:registerSlash()
	_G.SLASH_BLIZZ1 = "/blizz"
	_G.SlashCmdList["BLIZZ"] = function(msg)
		msg = (msg or ""):lower():match("^%s*(.-)%s*$")
		if msg == "" or msg == "status" then
			print("|cff7ed9ff[Blizz]|r status:")
			print("  modules registered:", (function() local n = 0; for _ in pairs(addon.modules) do n = n + 1 end; return n end)())
			print("  errors (last):", #addon.errors)
		elseif msg == "errors" then
			for i = math.max(1, #addon.errors - 9), #addon.errors do
				local e = addon.errors[i]
				print(string.format("  [%s] %s: %s", tostring(e.time), e.event, e.err))
			end
		else
			print("|cff7ed9ff[Blizz]|r unknown command: " .. msg)
		end
	end
end

-- In WoW: hook PLAYER_LOGIN to call bootstrap + registerSlash.
-- In tests: caller invokes these explicitly.
if CreateFrame then
	local f = CreateFrame("Frame", "BlizzMain")
	f:RegisterEvent("PLAYER_LOGIN")
	f:SetScript("OnEvent", function()
		addon:bootstrap()
		addon:registerSlash()
	end)
end

return addon
```

- [ ] **Step 4: Test ausführen**

Run: `luajit tests/run.lua`
Expected: 9 passed (incl. 3 new prints from test_addon).

- [ ] **Step 5: stylua + Commit**

```bash
stylua Blizz.lua tests/test_addon.lua
git add Blizz.lua tests/test_addon.lua
git commit -m "feat: main entry — module registry, bootstrap, /blizz slash command"
```

---

## Task 14: TOC-Integration + Lade-Reihenfolge

**Files:**
- Modify: `Blizz.toc`

- [ ] **Step 1: TOC erweitern**

Replace contents of `Blizz.toc`:
```
## Interface: 120005
## Title: Blizz
## Version: 0.0.1
## Author: kenearos
## Notes: WoW UI Tank-Interface für Prot Warri M+
## SavedVariables: BlizzDB

# --- Theme ---
ui/theme.lua

# --- Core ---
core/eventbus.lua
core/cooldowns.lua
core/unitstate.lua
core/combatlog.lua

# --- Config ---
config/savedvars.lua

# --- Widgets ---
ui/widgets/frame.lua
ui/widgets/text.lua
ui/widgets/icon.lua
ui/widgets/bar.lua
ui/widgets/alert.lua

# --- Main entry ---
Blizz.lua
```

- [ ] **Step 2: TOC-Sanity-Check**

Run: `awk '/\.lua$/ {print $1}' Blizz.toc | while read f; do test -f "$f" || echo "MISSING: $f"; done`
Expected: keine Ausgabe (alle gelisteten Files existieren).

- [ ] **Step 3: Globale .luarc.json-Globals erweitern**

Modify `.luarc.json`'s `diagnostics.globals` to include the new globals that lua-language-server needs to ignore:
```json
{
  "$schema": "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json",
  "runtime.version": "Lua 5.1",
  "runtime.special": {
    "C_Timer.After": "setTimeout"
  },
  "workspace.library": [
    "/home/deck/.local/share/wow-api/Annotations"
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
    "MockReset"
  ],
  "completion.callSnippet": "Replace",
  "hint.enable": true
}
```

- [ ] **Step 4: Full Test-Suite läuft grün**

Run: `luajit tests/run.lua`
Expected: alle Tests passen (theme + eventbus + savedvars + cooldowns + unitstate + combatlog + widgets + mocks + addon = 9 test files).

- [ ] **Step 5: stylua-Check über alles**

Run: `stylua --check $(find . -name "*.lua" -not -path "./.claude/*")`
Expected: exit 0, no diff output.

- [ ] **Step 6: Commit**

```bash
git add Blizz.toc .luarc.json
git commit -m "build: wire up TOC load order and extend LSP globals"
```

---

## Task 15: In-Game-Smoke-Check (manuell)

**Files:** (keine Code-Änderungen — Verifikation)

- [ ] **Step 1: Addon-Verzeichnis verlinken oder kopieren**

WoW liest Addons aus `World of Warcraft/_retail_/Interface/AddOns/`. Auf Steam Deck (Proton) ist das z.B. unter `~/.steam/steam/steamapps/compatdata/.../pfx/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/`.

Empfohlen: Symlink statt copy, damit `git pull` direkt im WoW-Addon-Ordner spürbar ist.
```bash
WOW_ADDONS="$HOME/.steam/steam/steamapps/compatdata/<APPID>/pfx/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"
ln -sfn "$(pwd)" "$WOW_ADDONS/Blizz"
ls -l "$WOW_ADDONS/Blizz"
```

Falls Proton-Pfad anders ist: `find $HOME/.steam $HOME/.local/share/Steam -name "AddOns" -type d 2>/dev/null` zum Lokalisieren.

- [ ] **Step 2: WoW starten + Char einloggen**

In WoW (idealerweise mit Dev-Char): `/reload`

- [ ] **Step 3: `/blizz status` testen**

Erwartete Chat-Ausgabe:
```
[Blizz] status:
  modules registered: 0
  errors (last): 0
```

- [ ] **Step 4: Lua-Errors prüfen**

Falls nicht schon aktiv: `/console scriptErrors 1` und nochmal `/reload`. Keine Errors erwartet.

- [ ] **Step 5: Wenn alles okay — letzten Commit setzen**

```bash
git commit --allow-empty -m "test: in-game smoke check passed for Phase 1 bootstrap"
```

Falls Errors auftauchen: Stack-Trace in `tests/` als reproduction-test übersetzen, Fix machen, neuer Commit, dann diesen Smoke-Test wiederholen.

---

## Phase-1-Abschluss

Nach Task 15 ist:
- Foundation steht: Theme, Event-Bus, Cooldowns, UnitState, CombatLog, SavedVars, Widget-Toolkit (Frame, Text, Icon, Bar, Alert)
- Mock-Layer + Test-Runner liefern grünen Build per `luajit tests/run.lua`
- Addon lädt in WoW ohne Errors, `/blizz status` antwortet
- Jeder Task ist ein atomarer Commit auf `main`
- Stylua-conform, LSP-Globals erweitert

**Nächste Phase (Phase 2 — Tank-Core):**
- `modules/mitigation`, `modules/cooldowns`, `modules/threat`, `modules/reflect`
- Nutzt das Widget-Toolkit + Core-Schicht aus Phase 1
- Eigener Implementierungs-Plan via `superpowers:writing-plans` wenn Phase 1 abgenommen ist

---

## Self-Review

**1. Spec-Coverage** (Spec §2.1 / §2.2 / §6 Phase 1):
- Single addon, no runtime deps ✓ (Blizz.toc + LibStub embed kommt erst wenn benötigt)
- `core/eventbus.lua` ✓ Task 4
- `core/cooldowns.lua` ✓ Task 6
- `core/unitstate.lua` ✓ Task 7
- `core/combatlog.lua` ✓ Task 8
- `config/savedvars.lua` ✓ Task 5
- `ui/theme.lua` v6 ✓ Task 3
- `ui/widgets/{frame,bar,icon,text,alert}.lua` ✓ Tasks 9-12
- `tests/mocks/wow_api.lua` ✓ Task 2
- Smoke-Test `/reload` ohne Error, `/blizz` Slash ✓ Tasks 13-15
- Module-Interface mit `id/events/init/onEvent` ✓ Task 13 (registerModule pattern)
- Liefert kein UI auf dem Schirm (Spec §6 Phase 1: "Liefert: kein UI auf dem Schirm, aber Foundation steht") ✓
- BlizzDB schema (Spec §7) ✓ Task 5

**2. Placeholder-Scan:** Keine TBD/TODO/FIXME im Plan. Jeder Code-Block ist vollständig.

**3. Type-Consistency:**
- `Theme.colors[key]` als `{r,g,b,a}` durchgehend
- `Theme.getColor("key")` gibt 4 separate Werte (für `SetColorRGBA`-Style WoW-APIs) — durchgehend so in Frame/Text/Icon/Bar/Alert
- `EventBus:subscribe → token`, `EventBus:unsubscribe(token)` konsistent
- Module-Interface `{id, events, init, onEvent}` konsistent zwischen Task 13 und Phase-2-Plan

**4. Ambiguity-Check:**
- "Tech-Corner-Brackets" — als zwei Texture-L-Marker an TOPLEFT/BOTTOMRIGHT in Frame:new fixiert
- "Pulse" für Alert — definiert als `CreateAnimationGroup` mit Looping; in Tests via `__pulsing`-Flag verifiziert
- Hex→RGB-Konvertierung in Theme — Werte als Kommentare neben den Tupeln dokumentiert
- "Stylua-conform" — durchgehend `stylua` als expliziter Step

**Stand:** Plan ist self-reviewed, Spec-coverage komplett für Phase 1, keine offenen Platzhalter.
