# Blizz Phase 2 — Tank-Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Liefere die vier Tank-Core-Module — Active Mitigation, Defensive-CD-Bar, Threat-Display, Reflect-Indicator — als spielbares Tank-HUD. Phase 1 (Foundation, Widgets, Mocks) ist die Basis; Phase 2 baut das erste tatsächliche UI on top.

**Architecture:** Module-Pattern aus Phase 1 fortsetzen: jedes Modul ist eine Tabelle mit `{id, events, init, onEvent}` und ruft `addon.registerModule(self)`. Phase 2 fügt eine neue Schicht hinzu: einen **WoW-Event-Bridge** (`core/wowevents.lua`), der WoW-Frame-Events in den internen `EventBus` umsetzt — damit Module sich rein über `events`-Listen abonnieren können, ohne selbst Frames zu managen. Daten kommen aus zwei neuen Static-Lua-Files (`data/spells_prot_warrior.lua`, `data/reflect_spells.lua`).

**Tech Stack:** Lua 5.1/LuaJIT 2.1, stylua, lua-language-server, plain `assert()` Tests via `luajit tests/run.lua`. Alle Module nutzen Widgets aus Phase 1 (Frame/Text/Icon/Bar/Alert) + v6-Theme + Core-Schicht (EventBus/Cooldowns/UnitState/CombatLog).

---

## Scope Check

Phase 2 ist eine Sub-Phase des Tank-UI-Specs (`docs/superpowers/specs/2026-05-13-blizz-tank-ui-design.md` §6 Phase 2). Vier Module + ein Bridge-Helper + zwei Daten-Files. Cleanly executable in einer Plan-Sitzung. Kein weiterer Split nötig.

---

## File Structure

| Datei | Status | Verantwortung |
|---|---|---|
| `core/wowevents.lua` | new | Brückt WoW-Frame-Events → `addon.EventBus:dispatch()`. Ref-counted register/unregister. |
| `Blizz.lua` | modify | `registerModule` ruft jetzt `WoWEvents:register(ev)`; `bootstrap` initialisiert die Bridge. |
| `data/spells_prot_warrior.lua` | new | Spell-ID-Tabellen für Prot Warri (Defensives, Active Mit, Mobility, Pummel). |
| `data/reflect_spells.lua` | new | Reflektierbare Casts pro NPC. Starter (klein, kommentiert für Erweiterung). |
| `modules/mitigation/init.lua` | new | Active Mitigation Display: Shield Block + Ignore Pain. |
| `modules/cooldowns/init.lua` | new | Defensive-CD-Bar mit 8 Icons. |
| `modules/threat/init.lua` | new | Threat-Status-Pill (Top-Strip) + Lost-Aggro-Pulse-Alert. |
| `modules/reflect/init.lua` | new | Reflect-Indicator: hookt UNIT_SPELLCAST_START, matched gegen reflect_spells. |
| `Blizz.toc` | modify | Lade-Reihenfolge erweitern: data → Blizz → modules. |
| `tests/test_wowevents.lua` | new | Tests für die Bridge. |
| `tests/test_spells.lua` | new | Tests für spells_prot_warrior. |
| `tests/test_mitigation.lua` | new | Tests für Mitigation-Modul. |
| `tests/test_cooldowns_module.lua` | new | Tests für Defensive-CD-Bar (Filename anders als `test_cooldowns.lua` weil das schon den Core-Tracker testet). |
| `tests/test_threat.lua` | new | Tests für Threat-Modul. |
| `tests/test_reflect.lua` | new | Tests für Reflect-Modul. |
| `tests/test_addon.lua` | modify | Test erweitern: registerModule mit echtem Modul + Bridge-Verifikation. |
| `tests/mocks/wow_api.lua` | modify | Stub für `UnitChannelInfo` ergänzen, Helper `MockFireFrameEvent(eventName, ...)` damit Tests gezielt WoW-Frame-Events simulieren. |

**Naming-Klarstellung gegenüber Spec §6:** Spec nennt das Modul `modules/cooldowns` — wir behalten den Pfad bei. Es kollidiert nicht mit `core/cooldowns.lua` (Core-Tracker) weil das Modul unter `addon.modules.cooldowns` lebt, der Tracker unter `addon.Cooldowns`. Test-Datei heißt `test_cooldowns_module.lua` zur Unterscheidung von `test_cooldowns.lua` (Core).

---

## Task 1: WoW-Event-Bridge

**Files:**
- Create: `core/wowevents.lua`
- Modify: `Blizz.lua`
- Modify: `tests/mocks/wow_api.lua` (add `MockFireFrameEvent` helper)
- Create: `tests/test_wowevents.lua`

- [ ] **Step 1: Mock-Erweiterung — `MockFireFrameEvent`**

`tests/mocks/wow_api.lua` braucht einen Helper der einen WoW-Frame-Event auf alle Frames simuliert, die ihn registriert haben. Ergänze in `tests/mocks/wow_api.lua` direkt nach `function MockFireCLEU(...)`:

```lua
-- Fire a WoW frame event to all frames that registered it
Mock.frames = Mock.frames or {}
function MockFireFrameEvent(eventName, ...)
	for _, f in ipairs(Mock.frames) do
		if f.__events and f.__events[eventName] then
			local handler = f.__scripts and f.__scripts["OnEvent"]
			if handler then
				handler(f, eventName, ...)
			end
		end
	end
end
```

Und in `make_frame`, NACH `local f = { ... }` aber VOR dem `setmetatable`, registriere das Frame in der Liste:

```lua
	Mock.frames = Mock.frames or {}
	table.insert(Mock.frames, f)
```

Und in `MockReset` ergänze:

```lua
	Mock.frames = {}
```

Stylua + Test rerun nach diesem Step:
```bash
cd /home/deck/claude/blizz && stylua tests/mocks/wow_api.lua && stylua --check tests/mocks/wow_api.lua && luajit tests/run.lua 2>&1 | tail -3
```
Expected: `9 passed, 0 failed` (alle Phase-1-Tests bleiben grün).

- [ ] **Step 2: Failing test schreiben**

Create `tests/test_wowevents.lua`:
```lua
require("tests.mocks.wow_api")
require("Blizz")
local WoWEvents = require("core.wowevents")

MockReset()

-- init creates a bridge frame
WoWEvents:init()
assert(WoWEvents.frame, "bridge frame should exist after init")
assert(WoWEvents.frame.__type == "Frame", "bridge is a Frame")

-- register triggers RegisterEvent
WoWEvents:register("UNIT_AURA")
assert(WoWEvents.frame.__events["UNIT_AURA"] == true, "UNIT_AURA should be registered on the frame")
print("✓ bridge registers WoW events")

-- WoW frame event dispatches into EventBus
local got
_G.Blizz.EventBus:subscribe("UNIT_AURA", function(unit)
	got = unit
end)
MockFireFrameEvent("UNIT_AURA", "player")
assert(got == "player", "EventBus subscriber should receive 'player' (got " .. tostring(got) .. ")")
print("✓ frame event flows through bus")

-- ref-counted register: two callers, one unregister doesn't drop the event
WoWEvents:register("UNIT_HEALTH")
WoWEvents:register("UNIT_HEALTH")
WoWEvents:unregister("UNIT_HEALTH")
assert(WoWEvents.frame.__events["UNIT_HEALTH"] == true, "still registered after 1 of 2 unregisters")
WoWEvents:unregister("UNIT_HEALTH")
assert(WoWEvents.frame.__events["UNIT_HEALTH"] == nil, "unregistered after last unregister")
print("✓ ref-counted register/unregister")
```

- [ ] **Step 3: Run → FAIL**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected: FAIL — `module 'core.wowevents' not found`

- [ ] **Step 4: Implement bridge**

Create `core/wowevents.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/wowevents.lua
-- Brücke zwischen WoW-Frame-Events und addon.EventBus.
-- Modules sagen `events = {"UNIT_AURA", ...}` — registerModule ruft hier register(),
-- und der Bridge-Frame leitet WoW-Events an den internen Bus weiter.

local WoWEvents = {}
WoWEvents.frame = nil
WoWEvents.refCount = {} -- event → number of registrants

function WoWEvents:init()
	if self.frame then
		return -- idempotent
	end
	self.frame = CreateFrame("Frame", "BlizzEventBridge")
	self.frame:SetScript("OnEvent", function(_, event, ...)
		if addon.EventBus then
			addon.EventBus:dispatch(event, ...)
		end
	end)
end

function WoWEvents:register(event)
	if not self.frame then
		return
	end
	self.refCount[event] = (self.refCount[event] or 0) + 1
	if self.refCount[event] == 1 then
		self.frame:RegisterEvent(event)
	end
end

function WoWEvents:unregister(event)
	if not self.frame then
		return
	end
	if not self.refCount[event] then
		return
	end
	self.refCount[event] = self.refCount[event] - 1
	if self.refCount[event] <= 0 then
		self.refCount[event] = nil
		self.frame:UnregisterEvent(event)
	end
end

addon.WoWEvents = WoWEvents
return WoWEvents
```

- [ ] **Step 5: Modify `Blizz.lua` — bootstrap initializes bridge + registerModule uses it**

Read current `Blizz.lua` and apply two changes:

1. Add `local WoWEvents = addon.WoWEvents or require("core.wowevents")` near the other requires at top.
2. In `addon.registerModule`, after `EventBus:subscribe(ev, ...)`, add `WoWEvents:register(ev)`.
3. In `addon:bootstrap()`, FIRST line should be `WoWEvents:init()`.
4. Remove the standalone main-frame `CreateFrame("Frame", "BlizzMain")` block at the bottom (it duplicates what the bridge does), and replace with a smaller bootstrap-trigger:

```lua
-- In WoW: bridge captures PLAYER_LOGIN automatically because we register it here.
-- We bootstrap once on PLAYER_LOGIN.
if CreateFrame then
	WoWEvents:init()
	WoWEvents:register("PLAYER_LOGIN")
	if EventBus then
		EventBus:subscribe("PLAYER_LOGIN", function()
			addon:bootstrap()
			addon:registerSlash()
		end)
	end
end
```

Full new content of `Blizz.lua`:

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
local WoWEvents = addon.WoWEvents or require("core.wowevents")

addon.modules = addon.modules or {}

function addon.registerModule(mod)
	assert(mod and mod.id, "module needs id")
	addon.modules[mod.id] = mod
	if mod.events and EventBus then
		for _, ev in ipairs(mod.events) do
			EventBus:subscribe(ev, function(...)
				if mod.onEvent then
					mod:onEvent(ev, ...)
				end
			end)
			WoWEvents:register(ev)
		end
	end
end

function addon:bootstrap()
	WoWEvents:init()
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
			local n = 0
			for _ in pairs(addon.modules) do
				n = n + 1
			end
			print("  modules registered:", n)
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

-- In WoW: bridge captures PLAYER_LOGIN; we bootstrap then.
if CreateFrame then
	WoWEvents:init()
	WoWEvents:register("PLAYER_LOGIN")
	if EventBus then
		EventBus:subscribe("PLAYER_LOGIN", function()
			addon:bootstrap()
			addon:registerSlash()
		end)
	end
end

return addon
```

- [ ] **Step 6: Update `tests/test_addon.lua` (the bootstrap path changed)**

The existing test calls `_G.Blizz:bootstrap()` directly — that still works since bootstrap is the same shape. But the test also resets `SLASH_BLIZZ1` and `SlashCmdList`; these are still set in `registerSlash`. Read `tests/test_addon.lua`, verify it still passes the existing 3 print-checks after the Blizz.lua change. It should — but RUN the suite to confirm:

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -3`
Expected: `10 passed, 0 failed` (incl. new test_wowevents).

If a regression appears in test_addon, the most likely cause is: `Blizz.lua`'s bottom-frame block requires `CreateFrame`. In tests, `CreateFrame` IS defined (via the mock). So the bootstrap-subscribe runs at require-time. That's fine — bootstrap is gated behind `EventBus:dispatch("PLAYER_LOGIN")` which the test triggers via `_G.Blizz:bootstrap()` directly anyway. If something breaks, raise BLOCKED.

- [ ] **Step 7: Stylua**

```bash
cd /home/deck/claude/blizz && stylua core/wowevents.lua Blizz.lua tests/test_wowevents.lua && stylua --check core/wowevents.lua Blizz.lua tests/test_wowevents.lua
```

- [ ] **Step 8: Commit**

```bash
cd /home/deck/claude/blizz
git add core/wowevents.lua Blizz.lua tests/mocks/wow_api.lua tests/test_wowevents.lua
git commit -m "feat(core): WoW event bridge — frame events flow into EventBus"
```

Expected post-commit: full suite still passes (`luajit tests/run.lua 2>&1 | tail -3` shows `10 passed, 0 failed`).

---

## Task 2: Data — Prot Warrior Spell IDs

**Files:**
- Create: `data/spells_prot_warrior.lua`
- Create: `tests/test_spells.lua`

- [ ] **Step 1: Failing test schreiben**

Create `tests/test_spells.lua`:
```lua
require("tests.mocks.wow_api")
local Spells = require("data.spells_prot_warrior")

assert(type(Spells.active_mitigation) == "table", "active_mitigation table missing")
assert(Spells.active_mitigation.shield_block == 2565, "Shield Block spellID")
assert(Spells.active_mitigation.ignore_pain == 190456, "Ignore Pain spellID")

assert(type(Spells.defensives) == "table", "defensives table missing")
local def = Spells.defensives
assert(def.shield_wall == 871, "Shield Wall")
assert(def.last_stand == 12975, "Last Stand")
assert(def.spell_reflection == 23920, "Spell Reflection")
assert(def.demoralizing_shout == 1160, "Demoralizing Shout")
assert(def.rallying_cry == 97462, "Rallying Cry")
assert(def.avatar == 107574, "Avatar")
assert(def.demoralizing_banner == 236320, "Demoralizing Banner (talented)")
assert(def.charge == 100, "Charge")
print("✓ active mitigation + 8 defensive spell IDs present")

assert(type(Spells.utility) == "table", "utility table missing")
assert(Spells.utility.pummel == 6552, "Pummel")
assert(Spells.utility.heroic_leap == 6544, "Heroic Leap")
assert(Spells.utility.intervene == 3411, "Intervene")
print("✓ utility spell IDs present")

-- defensive_bar_order: list of 8 spellIDs, in display order
assert(type(Spells.defensive_bar_order) == "table", "defensive_bar_order missing")
assert(#Spells.defensive_bar_order == 8, "defensive_bar_order should have 8 entries")
print("✓ defensive bar order defined")
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected: `module 'data.spells_prot_warrior' not found`

- [ ] **Step 3: Implement spell database**

Create `data/spells_prot_warrior.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/spells_prot_warrior.lua
-- Spell-IDs für Protection Warrior in WoW Midnight 12.0.5.
-- Quelle: Wowhead + Class-Guides. Bei jedem WoW-Patch verifizieren.
-- Hero-Talent-spezifische Spells (Mountain Thane / Colossus) hier NICHT enthalten —
-- werden in einer eigenen Phase nachgepflegt sobald Talents implementiert sind.

local Spells = {}

Spells.active_mitigation = {
	shield_block = 2565, -- 6s aura, +Block-Chance, blockt magic damage mit Heavy Repercussions talent
	ignore_pain = 190456, -- absorb buff, 40 rage cost, off-GCD
}

Spells.defensives = {
	shield_wall = 871, -- 8s, 40% DR, ~3.5min CD
	last_stand = 12975, -- 15s, +30% max HP
	spell_reflection = 23920, -- 5s, reflektiert nächsten Single-Target-Spell
	demoralizing_shout = 1160, -- 8s, -20% damage from affected enemies
	rallying_cry = 97462, -- 10s, +15% HP group-wide
	avatar = 107574, -- offensive but pairs with defensives (CD-rotation)
	demoralizing_banner = 236320, -- talented (Bannerlord), platziert Banner
	charge = 100, -- mobility/Charge-Pool
}

Spells.utility = {
	pummel = 6552, -- interrupt, 15s CD (with talents)
	heroic_leap = 6544, -- jump mobility
	intervene = 3411, -- friendly Charge
	berserker_rage = 18499, -- fear-break, rage burst
}

-- Reihenfolge im Defensive-CD-Bar (linke nach rechts)
Spells.defensive_bar_order = {
	Spells.defensives.shield_wall,
	Spells.defensives.last_stand,
	Spells.defensives.spell_reflection,
	Spells.defensives.demoralizing_shout,
	Spells.defensives.rallying_cry,
	Spells.defensives.avatar,
	Spells.defensives.demoralizing_banner,
	Spells.defensives.charge,
}

-- Convenience: Reverse-Lookup spellID → label (für Icon-Beschriftung)
Spells.labels = {
	[2565] = "SBLK",
	[190456] = "IP",
	[871] = "WALL",
	[12975] = "LS",
	[23920] = "SPRFL",
	[1160] = "DEMO",
	[97462] = "RALLY",
	[107574] = "AVTR",
	[236320] = "BNR",
	[100] = "CHA",
	[6552] = "PMML",
	[6544] = "LEAP",
	[3411] = "ITVN",
	[18499] = "BRSK",
}

addon.SpellsProtWarrior = Spells
return Spells
```

- [ ] **Step 4: Run → PASS**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -3`
Expected: `11 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
stylua data/spells_prot_warrior.lua tests/test_spells.lua && stylua --check data/spells_prot_warrior.lua tests/test_spells.lua
git add data/spells_prot_warrior.lua tests/test_spells.lua
git commit -m "feat(data): Prot Warrior spell IDs (defensives + AM + utility)"
```

---

## Task 3: Module — Mitigation

**Files:**
- Create: `modules/mitigation/init.lua`
- Create: `tests/test_mitigation.lua`

- [ ] **Step 1: Failing test schreiben**

Create `tests/test_mitigation.lua`:
```lua
require("tests.mocks.wow_api")
require("Blizz")
require("data.spells_prot_warrior")
local Mitigation = require("modules.mitigation")

local addon = _G.Blizz
local SB = addon.SpellsProtWarrior.active_mitigation.shield_block -- 2565
local IP = addon.SpellsProtWarrior.active_mitigation.ignore_pain -- 190456

MockReset()
MockSetTime(1000)
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 0 })

-- module is registered with the expected id
assert(addon.modules.mitigation == Mitigation, "mitigation module registered")
print("✓ module registered with id 'mitigation'")

-- bootstrap calls init → frame exists
addon:bootstrap()
assert(Mitigation.frame, "mitigation frame should be created on init")
assert(Mitigation.frame.__type == "Frame", "mitigation frame is a Frame stub")
assert(Mitigation.shield_block_text, "shield_block_text label exists")
assert(Mitigation.ignore_pain_text, "ignore_pain_text label exists")
print("✓ init() creates display frame + labels")

-- Shield Block on cooldown → label shows remaining time
MockSetCooldown(SB, 995, 6) -- started 5s ago, 6s duration → 1s remaining
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(
	Mitigation.shield_block_text:GetText():match("1") ~= nil,
	"shield_block_text should show ~1s remaining, got '" .. tostring(Mitigation.shield_block_text:GetText()) .. "'"
)
print("✓ Shield Block CD readout updates")

-- Shield Block ready → label shows "RDY"
MockSetCooldown(SB, 0, 0)
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(Mitigation.shield_block_text:GetText() == "RDY", "ready label should be 'RDY'")
print("✓ Shield Block ready state")

-- Ignore Pain absorb → label shows kvalue
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 38000 })
addon.EventBus:dispatch("UNIT_AURA", "player")
assert(
	Mitigation.ignore_pain_text:GetText():match("38") ~= nil,
	"ignore_pain_text should show ~38k absorb, got '" .. tostring(Mitigation.ignore_pain_text:GetText()) .. "'"
)
print("✓ Ignore Pain absorb readout updates")

-- Zero absorb → label shows '0' or empty
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 0 })
addon.EventBus:dispatch("UNIT_AURA", "player")
local ip_text = Mitigation.ignore_pain_text:GetText() or ""
assert(ip_text == "0" or ip_text == "" or ip_text:match("^0"), "zero absorb shows '0' or empty, got '" .. ip_text .. "'")
print("✓ Ignore Pain zero state")
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected: `module 'modules.mitigation' not found`

- [ ] **Step 3: Implement Mitigation module**

Create `modules/mitigation/init.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/mitigation/init.lua
-- Active Mitigation Display: Shield Block CD/charges + Ignore Pain absorb readout.
-- Position default: CENTER, x=+12%, y=+15% (rechts vom Spieler, siehe Layout v3).

local Spells = addon.SpellsProtWarrior or require("data.spells_prot_warrior")
local Cooldowns = addon.Cooldowns or require("core.cooldowns")
local UnitState = addon.UnitState or require("core.unitstate")
local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local Mitigation = {
	id = "mitigation",
	events = { "SPELL_UPDATE_COOLDOWN", "UNIT_AURA" },
}

local function format_remaining(remaining)
	if remaining <= 0 then
		return "RDY"
	elseif remaining < 10 then
		return string.format("%.1fs", remaining)
	else
		return string.format("%ds", math.floor(remaining))
	end
end

local function format_absorb(absorb)
	if absorb <= 0 then
		return "0"
	elseif absorb >= 1000 then
		return string.format("%.0fK", absorb / 1000)
	else
		return tostring(absorb)
	end
end

function Mitigation:init()
	self.frame = Frame:new({ name = "BlizzMitigation", parent = UIParent, width = 220, height = 30 })
	self.frame:SetPoint("CENTER", UIParent, "CENTER", 144, 90) -- ~+12% w / +15% h on 1200x800 ref

	self.shield_block_label = Text:new({ parent = self.frame, text = "SBLK", style = "label" })
	if self.shield_block_label.SetPoint then
		self.shield_block_label:SetPoint("LEFT", self.frame, "LEFT", 6, 0)
	end

	self.shield_block_text = Text:new({ parent = self.frame, text = "—", style = "value" })
	if self.shield_block_text.SetPoint then
		self.shield_block_text:SetPoint("LEFT", self.frame, "LEFT", 50, 0)
	end

	self.ignore_pain_label = Text:new({ parent = self.frame, text = "IP", style = "label" })
	if self.ignore_pain_label.SetPoint then
		self.ignore_pain_label:SetPoint("LEFT", self.frame, "LEFT", 120, 0)
	end

	self.ignore_pain_text = Text:new({ parent = self.frame, text = "0", style = "value" })
	if self.ignore_pain_text.SetPoint then
		self.ignore_pain_text:SetPoint("LEFT", self.frame, "LEFT", 150, 0)
	end

	-- initial render
	self:refresh()
end

function Mitigation:refresh()
	local sb_state = Cooldowns:getState(Spells.active_mitigation.shield_block)
	self.shield_block_text:SetText(format_remaining(sb_state.remaining))

	local absorb = UnitState:getAbsorb("player")
	self.ignore_pain_text:SetText(format_absorb(absorb))
end

function Mitigation:onEvent(event, unit)
	if event == "SPELL_UPDATE_COOLDOWN" then
		self:refresh()
	elseif event == "UNIT_AURA" and (unit == nil or unit == "player") then
		self:refresh()
	end
end

addon.registerModule(Mitigation)
return Mitigation
```

- [ ] **Step 4: Run → PASS**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -10`
Expected: alle Mitigation-asserts grün, Final `12 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
mkdir -p modules/mitigation
stylua modules/mitigation/init.lua tests/test_mitigation.lua && stylua --check modules/mitigation/init.lua tests/test_mitigation.lua
git add modules/mitigation/init.lua tests/test_mitigation.lua
git commit -m "feat(module): mitigation — Shield Block + Ignore Pain display"
```

---

## Task 4: Module — Defensive-CD-Bar (id `cooldowns`)

**Files:**
- Create: `modules/cooldowns/init.lua`
- Create: `tests/test_cooldowns_module.lua`

- [ ] **Step 1: Failing test schreiben**

Create `tests/test_cooldowns_module.lua`:
```lua
require("tests.mocks.wow_api")
require("Blizz")
require("data.spells_prot_warrior")
local CDModule = require("modules.cooldowns")

local addon = _G.Blizz
local order = addon.SpellsProtWarrior.defensive_bar_order

MockReset()
MockSetTime(1000)

-- module registered under id 'cooldowns'
assert(addon.modules.cooldowns == CDModule, "cooldowns module registered")
print("✓ module registered with id 'cooldowns'")

-- bootstrap creates 8 icons in order
addon:bootstrap()
assert(type(CDModule.icons) == "table", "icons table exists")
assert(#CDModule.icons == 8, "exactly 8 defensive icons, got " .. #CDModule.icons)
for i, ico in ipairs(CDModule.icons) do
	assert(ico.__type == "Frame", "icon " .. i .. " should be Frame")
	assert(ico.__spellID == order[i], "icon " .. i .. " spellID mismatch")
end
print("✓ 8 icons created in order")

-- all ready by default
for _, ico in ipairs(CDModule.icons) do
	assert(ico:getState() == "ready", "all icons start ready")
end
print("✓ default state is ready")

-- put Shield Wall on cooldown
MockSetCooldown(871, 995, 240) -- 5s elapsed, 240s CD
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
local wall_icon = CDModule.icons[1] -- shield_wall is first in defensive_bar_order
assert(wall_icon:getState() == "cd", "wall icon should be cd, got " .. wall_icon:getState())
assert(wall_icon:getRemainingText():match("23") ~= nil, "remaining text should match ~235s, got " .. wall_icon:getRemainingText())
print("✓ icon flips to cd state on cooldown")

-- back to ready when cooldown clears
MockSetCooldown(871, 0, 0)
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(CDModule.icons[1]:getState() == "ready", "back to ready")
print("✓ icon flips back to ready when CD clears")
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected: `module 'modules.cooldowns' not found`

- [ ] **Step 3: Implement Defensive-Bar module**

Create `modules/cooldowns/init.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/cooldowns/init.lua
-- Defensive-CD-Bar: 8 Icons in horizontaler Reihe.
-- Spells aus data/spells_prot_warrior.lua, defensive_bar_order.
-- Position default: BOTTOM, center, y=+24% (siehe Layout v3).

local Spells = addon.SpellsProtWarrior or require("data.spells_prot_warrior")
local Cooldowns = addon.Cooldowns or require("core.cooldowns")
local Frame = addon.Frame or require("ui.widgets.frame")
local Icon = addon.Icon or require("ui.widgets.icon")

local ICON_SIZE = 38
local ICON_GAP = 3
local PADDING = 3

local CDModule = {
	id = "cooldowns",
	events = { "SPELL_UPDATE_COOLDOWN" },
}

function CDModule:init()
	local order = Spells.defensive_bar_order
	local bar_width = #order * (ICON_SIZE + 14) + (#order - 1) * ICON_GAP + 2 * PADDING
	local bar_height = ICON_SIZE + 6 + 2 * PADDING

	self.container = Frame:new({
		name = "BlizzDefBar",
		parent = UIParent,
		width = bar_width,
		height = bar_height,
	})
	self.container:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 192) -- ~+24% on 800px ref height

	self.icons = {}
	for i, spellID in ipairs(order) do
		local label = Spells.labels[spellID] or tostring(spellID)
		local ico = Icon:new({
			parent = self.container,
			name = "BlizzDefIcon_" .. label,
			spellID = spellID,
			size = ICON_SIZE,
			label = label,
		})
		ico.__spellID = spellID
		if ico.SetPoint then
			local x_offset = PADDING + (i - 1) * (ICON_SIZE + 14 + ICON_GAP)
			ico:SetPoint("LEFT", self.container, "LEFT", x_offset, 0)
		end
		table.insert(self.icons, ico)
	end

	self:refresh()
end

function CDModule:refresh()
	for _, ico in ipairs(self.icons) do
		local state = Cooldowns:getState(ico.__spellID)
		if state.ready then
			ico:setReady()
		else
			ico:setCD(state.remaining)
		end
	end
end

function CDModule:onEvent(event)
	if event == "SPELL_UPDATE_COOLDOWN" then
		self:refresh()
	end
end

addon.registerModule(CDModule)
return CDModule
```

- [ ] **Step 4: Run → PASS**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -5`
Expected: `13 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
mkdir -p modules/cooldowns
stylua modules/cooldowns/init.lua tests/test_cooldowns_module.lua && stylua --check modules/cooldowns/init.lua tests/test_cooldowns_module.lua
git add modules/cooldowns/init.lua tests/test_cooldowns_module.lua
git commit -m "feat(module): defensive CD bar — 8 spell icons with state inversion"
```

---

## Task 5: Module — Threat

**Files:**
- Create: `modules/threat/init.lua`
- Create: `tests/test_threat.lua`

- [ ] **Step 1: Failing test schreiben**

Create `tests/test_threat.lua`:
```lua
require("tests.mocks.wow_api")
require("Blizz")
local Threat = require("modules.threat")

local addon = _G.Blizz

MockReset()
MockSetUnit("target", { health = 100000, maxHealth = 100000 })

-- module registered
assert(addon.modules.threat == Threat, "threat module registered")
print("✓ module registered with id 'threat'")

-- bootstrap creates pill + lost-alert
addon:bootstrap()
assert(Threat.pill, "threat pill exists")
assert(Threat.lost_alert, "lost-aggro alert exists")
assert(not Threat.lost_alert:IsShown(), "lost-alert starts hidden")
print("✓ init() creates pill + alert (hidden)")

-- securely tanking → pill shows "TANK", alert hidden
MockSetThreat(3)
addon.EventBus:dispatch("UNIT_THREAT_SITUATION_UPDATE", "player")
assert(Threat.pill:getState() == "ready", "tanking → pill is ready (filled)")
assert(not Threat.lost_alert:IsShown(), "no alert when securely tanking")
print("✓ pill = ready when tanking")

-- threat dropped → pill shows warn, alert visible
MockSetThreat(1)
addon.EventBus:dispatch("UNIT_THREAT_SITUATION_UPDATE", "player")
assert(Threat.pill:getState() == "alert", "low threat → pill alert")
assert(Threat.lost_alert:IsShown(), "alert shown when losing aggro")
print("✓ pill + alert on lost aggro")

-- recovered → pill back to ready, alert hidden
MockSetThreat(3)
addon.EventBus:dispatch("UNIT_THREAT_SITUATION_UPDATE", "player")
assert(Threat.pill:getState() == "ready", "recovered → ready")
assert(not Threat.lost_alert:IsShown(), "alert hidden after recovery")
print("✓ recovery flips pill + hides alert")
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected: `module 'modules.threat' not found`

- [ ] **Step 3: Implement Threat module**

Create `modules/threat/init.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/threat/init.lua
-- Threat-Status-Pill (Top-Strip) + Lost-Aggro-Pulse-Alert über Spieler.
-- pill.state == "ready" wenn tanking (Level 3), "alert" wenn Aggro verloren.

local UnitState = addon.UnitState or require("core.unitstate")
local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")
local Alert = addon.Alert or require("ui.widgets.alert")

local Threat = {
	id = "threat",
	events = { "UNIT_THREAT_SITUATION_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
}

function Threat:init()
	-- Top-Strip-Pill
	self.pill = Frame:new({ name = "BlizzThreatPill", parent = UIParent, width = 78, height = 18 })
	self.pill:SetPoint("TOP", UIParent, "TOP", -120, -16) -- left of center in top-strip

	self.pill_label = Text:new({ parent = self.pill, text = "THREAT", style = "default" })
	if self.pill_label.SetPoint then
		self.pill_label:SetPoint("CENTER", self.pill, "CENTER", 0, 0)
	end

	-- Lost-Aggro Alert (centered over player)
	self.lost_alert = Alert:new({
		name = "BlizzAggroLostAlert",
		parent = UIParent,
		text = "AGGRO LOST",
		width = 200,
		height = 28,
	})
	self.lost_alert:SetPoint("CENTER", UIParent, "CENTER", 0, 60)

	self:refresh()
end

function Threat:refresh()
	-- Use "target" as the threat reference (player vs current target)
	local level = UnitState:getThreatLevel("player", "target")
	if level == 3 then
		self.pill:setReady()
		self.lost_alert:hide()
	elseif level == nil or level == 0 then
		-- not in combat or no target → neutral
		self.pill:setDefault()
		self.lost_alert:hide()
	else
		self.pill:setAlert()
		self.lost_alert:show()
	end
end

function Threat:onEvent(event)
	if event == "UNIT_THREAT_SITUATION_UPDATE" then
		self:refresh()
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:refresh() -- entered combat
	elseif event == "PLAYER_REGEN_ENABLED" then
		self.pill:setDefault()
		self.lost_alert:hide()
	end
end

addon.registerModule(Threat)
return Threat
```

- [ ] **Step 4: Run → PASS**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -7`
Expected: `14 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
mkdir -p modules/threat
stylua modules/threat/init.lua tests/test_threat.lua && stylua --check modules/threat/init.lua tests/test_threat.lua
git add modules/threat/init.lua tests/test_threat.lua
git commit -m "feat(module): threat — status pill + lost-aggro alert"
```

---

## Task 6: Data — Reflect-Spells (Starter)

**Files:**
- Create: `data/reflect_spells.lua`

- [ ] **Step 1: Implement (no test — pure data; consumers test their lookup)**

Create `data/reflect_spells.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/reflect_spells.lua
-- Reflektierbare Casts. Map [spellID] = { name = "X", source = "Dungeon/NPC" }.
-- Starter-Liste — wird beim Spielen erweitert. Wenn ein Mob einen reflektierbaren
-- Cast macht und nicht in dieser Tabelle steht, einfach hier eintragen + commit.
--
-- WICHTIG: Spell Reflection (23920) reflektiert nur single-target magische Casts.
-- AoE-Magic-Casts (z.B. Dragon's Breath) sind NICHT reflektierbar. Multi-Target-Casts
-- ebenfalls nicht. Diese Liste enthält nur bestätigt reflektierbare Mob-Casts.

local ReflectSpells = {
	-- TODO-Tabelle: einfügen wenn beim Pulsing entdeckt.
	-- Format: [spellID] = { name = "Spell Name", source = "Dungeon/MobName" }
}

addon.ReflectSpells = ReflectSpells
return ReflectSpells
```

- [ ] **Step 2: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
stylua data/reflect_spells.lua && stylua --check data/reflect_spells.lua
git add data/reflect_spells.lua
git commit -m "feat(data): reflect_spells.lua starter (empty, expand at runtime)"
```

Note: This is intentionally empty. The reflect module (next task) will handle the empty-data case gracefully. The user populates this file with `{ [spellID] = {name=, source=} }` entries as they encounter reflectable casts in dungeons.

---

## Task 7: Module — Reflect-Indicator

**Files:**
- Create: `modules/reflect/init.lua`
- Create: `tests/test_reflect.lua`

- [ ] **Step 1: Failing test schreiben**

Create `tests/test_reflect.lua`:
```lua
require("tests.mocks.wow_api")
require("Blizz")
require("data.reflect_spells")
local Reflect = require("modules.reflect")

local addon = _G.Blizz

MockReset()
-- Inject a reflectable spell ID for testing (real data file is empty for now)
addon.ReflectSpells[12345] = { name = "Test Reflectable", source = "Test Dungeon" }
addon.ReflectSpells[67890] = { name = "Another", source = "Test" }

-- module registered
assert(addon.modules.reflect == Reflect, "reflect module registered")
print("✓ module registered with id 'reflect'")

addon:bootstrap()
assert(Reflect.alert, "reflect alert widget exists")
assert(not Reflect.alert:IsShown(), "alert starts hidden")
print("✓ init() creates alert (hidden by default)")

-- nameplate unit starts casting a reflectable spell → alert fires
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate1", "cast-guid-1", 12345)
assert(Reflect.alert:IsShown(), "alert shown when reflectable cast starts")
assert(Reflect.alert:isPulsing(), "alert pulses")
print("✓ reflectable cast → alert visible + pulsing")

-- cast stops (interrupted/finished) → alert hides
addon.EventBus:dispatch("UNIT_SPELLCAST_STOP", "nameplate1", "cast-guid-1", 12345)
assert(not Reflect.alert:IsShown(), "alert hidden when cast stops")
print("✓ cast end → alert hidden")

-- non-reflectable spell → no alert
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate2", "cast-guid-2", 999999)
assert(not Reflect.alert:IsShown(), "non-reflectable spell does not trigger alert")
print("✓ non-reflectable spell ignored")

-- player's own casts ignored
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "player", "cast-guid-3", 12345)
assert(not Reflect.alert:IsShown(), "player's own casts ignored")
print("✓ player's own casts not flagged")
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua`
Expected: `module 'modules.reflect' not found`

- [ ] **Step 3: Implement Reflect module**

Create `modules/reflect/init.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/reflect/init.lua
-- Reflect-Indicator: hört auf UNIT_SPELLCAST_START von nameplate-Units (NICHT player),
-- matched gegen data/reflect_spells.lua, blendet Pulsing-Alert ein wenn Match.

local Alert = addon.Alert or require("ui.widgets.alert")

local Reflect = {
	id = "reflect",
	events = {
		"UNIT_SPELLCAST_START",
		"UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_INTERRUPTED",
		"UNIT_SPELLCAST_SUCCEEDED",
	},
}

local function is_player_unit(unit)
	return unit == "player" or unit == "pet"
end

function Reflect:init()
	self.alert = Alert:new({
		name = "BlizzReflectAlert",
		parent = UIParent,
		text = "REFLECT INCOMING",
		width = 260,
		height = 32,
	})
	self.alert:SetPoint("CENTER", UIParent, "CENTER", 144, 30) -- ~+12% w, slightly above player
	self.active_casts = {} -- castGUID → spellID currently flagged
end

function Reflect:onEvent(event, unit, castGUID, spellID)
	if is_player_unit(unit) then
		return
	end
	if event == "UNIT_SPELLCAST_START" then
		local entry = addon.ReflectSpells and addon.ReflectSpells[spellID]
		if entry then
			self.active_casts[castGUID or tostring(spellID)] = spellID
			self.alert:setText("REFLECT: " .. (entry.name or tostring(spellID)))
			self.alert:show()
		end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
		self.active_casts[castGUID or tostring(spellID)] = nil
		if next(self.active_casts) == nil then
			self.alert:hide()
		end
	end
end

addon.registerModule(Reflect)
return Reflect
```

- [ ] **Step 4: Run → PASS**

Run: `cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -10`
Expected: alle Reflect-asserts grün, `15 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
mkdir -p modules/reflect
stylua modules/reflect/init.lua tests/test_reflect.lua && stylua --check modules/reflect/init.lua tests/test_reflect.lua
git add modules/reflect/init.lua tests/test_reflect.lua
git commit -m "feat(module): reflect — pulsing alert on reflectable nameplate casts"
```

---

## Task 8: TOC-Integration + Full-Suite-Sanity

**Files:**
- Modify: `Blizz.toc`

- [ ] **Step 1: Update TOC mit neuer Lade-Reihenfolge**

Replace contents of `Blizz.toc` with:
```
## Interface: 120005
## Title: Blizz
## Version: 0.0.2
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
core/wowevents.lua

# --- Config ---
config/savedvars.lua

# --- Static Data ---
data/spells_prot_warrior.lua
data/reflect_spells.lua

# --- Widgets ---
ui/widgets/frame.lua
ui/widgets/text.lua
ui/widgets/icon.lua
ui/widgets/bar.lua
ui/widgets/alert.lua

# --- Main entry (provides addon.registerModule) ---
Blizz.lua

# --- Modules (call addon.registerModule on load) ---
modules/mitigation/init.lua
modules/cooldowns/init.lua
modules/threat/init.lua
modules/reflect/init.lua
```

- [ ] **Step 2: TOC-Sanity-Check**

Run: `cd /home/deck/claude/blizz && awk '/\.lua$/ {print $1}' Blizz.toc | while read f; do test -f "$f" && echo "OK $f" || echo "MISSING $f"; done`

Expected: every line "OK <path>", no MISSING entries.

- [ ] **Step 3: Full test suite + stylua sweep**

```bash
cd /home/deck/claude/blizz
stylua --check $(find . -name "*.lua" -not -path "./.claude/*")
luajit tests/run.lua 2>&1 | tail -5
```

Expected:
- stylua exit 0, no diffs
- `15 passed, 0 failed`

- [ ] **Step 4: Update `.luarc.json` if new globals required**

For Phase 2 we don't introduce new globals beyond what's already there. Skip unless `stylua --check` or LSP reports new unknown globals — then add them to `.luarc.json`'s `diagnostics.globals` and commit alongside.

- [ ] **Step 5: Commit**

```bash
cd /home/deck/claude/blizz
git add Blizz.toc
git commit -m "build: TOC load order — data + 4 tank-core modules"
```

- [ ] **Step 6: In-Game-Smoke (deferred to user — manual)**

After Phase 2 commits land, user runs in WoW:
1. `/reload`
2. `/blizz status` — should show `modules registered: 4` and no errors.
3. Move to a target, watch:
   - Defensive-CD-Bar appears below center
   - Mitigation display appears right of center
   - Threat-Pill in top area
   - In combat, threat-pill switches between ready/alert states

If errors appear: report stack-trace, we translate to a failing test in `tests/`, fix, commit.

---

## Phase-2-Abschluss

Nach Task 8 ist:
- **WoW-Event-Bridge** verdrahtet — Modules subscriben über `events`-Liste, Bridge übersetzt zu/von WoW-Frame-Events
- **4 Tank-Core-Module** registriert und initialisiert auf PLAYER_LOGIN:
  - mitigation (Shield Block + Ignore Pain)
  - cooldowns (8-Icon Defensive-Bar)
  - threat (Pill + Lost-Aggro-Alert)
  - reflect (Pulsing-Alert auf reflektierbare Casts)
- **Daten-Files** für Prot-Warri-SpellIDs und Reflect-Spell-Lookup
- **15 Test-Files** alle grün headless
- **Atomare Commits** pro Task

Spielbar als Tank-HUD in jedem Combat (Trash, Raid, M+) — Phase 3 (M+-Run-Frame) und folgende bauen darauf auf.

---

## Self-Review

**1. Spec-Coverage** (Spec §6 Phase 2):
- ✅ `modules/mitigation` — Task 3
- ✅ `modules/cooldowns` (Defensive-CD-Bar) — Task 4
- ✅ `modules/threat` — Task 5
- ✅ `modules/reflect` — Task 7
- ✅ Liefert spielbares Tank-HUD — bestätigt durch Smoke-Step in Task 8

**Zusätzliche Spec-Touchpoints:**
- Spec §2.1 "Eigenständiges Addon, keine Runtime-Deps" → ✅ keine neuen externen Deps
- Spec §2.2 Verzeichnisstruktur `core/wowevents.lua` taucht in der Spec nicht auf, ist aber notwendig für die Module-Pattern-Implementierung. Aufgenommen als Task 1 mit klarer Begründung in der Plan-File-Structure-Tabelle.
- Spec §4 v6 Theme — alle Module nutzen Theme via Widgets (Frame:setReady/setAlert, Alert-Widget)
- Spec §5 Layout-Anchors — Mitigation bei +12%, Defensive-Bar bei Bottom +24%, Threat-Pill im Top-Strip → übersetzt zu konkreten `:SetPoint` calls
- Spec §7 SavedVars — Module nutzen aktuell harte Anchors; vorgesehene `BlizzDB.positions[moduleId]`-Lookup-Pattern in einer späteren Phase nachgereicht (out of scope für minimal-spielbar)
- Spec §8 Error-Handling — `addon.registerModule` läuft Init in pcall, das deckt Modul-Init-Errors ab. Event-Bus-Errors sind durch `EventBus.pcall` aus Phase 1 bereits abgedeckt.

**2. Placeholder-Scan:**
- Eine "TODO-Tabelle" Comment-Note in `data/reflect_spells.lua` — das ist KEIN Plan-Placeholder, sondern dokumentierter Erweiterungs-Slot im Daten-File (das Wachsen über die Zeit ist explizit Teil der Daten-Strategie der Spec). Kein Issue.
- Keine TBD/TODO/FIXME im eigentlichen Plan-Text.
- Jeder Code-Block ist vollständig copy-pasteable.

**3. Type-Consistency:**
- `addon.SpellsProtWarrior.defensive_bar_order` ist Array (1..8) von spellIDs — konsistent verwendet in cooldowns-module
- `addon.SpellsProtWarrior.labels[spellID]` → string, konsistent
- `ico.__spellID` als Side-Channel auf Icon-Frame um spellID nachzuverfolgen — konsistent zwischen cooldowns-init und Tests
- `Module:onEvent(event, ...)` Signatur konsistent mit Phase-1-Task-13-Pattern
- `Module.id` als String, registriert über `addon.registerModule` — konsistent

**4. Ambiguity-Check:**
- Position-Defaults sind aktuell fest verdrahtete Pixel-Offsets (z.B. `144, 90` für mitigation). Spec sagt "konfigurierbar via BlizzDB" — Verschiebung der Position-Persistenz auf eine spätere Phase ist explizit dokumentiert in Self-Review oben.
- Reflect-Module's empty data file: explizit dokumentiert wie der Konsument mit leerer Tabelle umgeht (graceful, kein Match = kein Alert).
- Threat module behandelt threat-level == 2 als "alert" (Aggro im Wackelzustand) — bewusste Entscheidung, im Modul-Code verbalisiert.

**Stand:** Plan self-reviewed, Phase-2-Scope vollständig, keine offenen Placeholder.
