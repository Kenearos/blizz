# Blizz Phase 3 — M+ Run-Frame Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Liefere ein M+-Run-Frame Modul, das während eines aktiven Mythic+ Runs Timer, Forces-Progress, +2/+3-Schwellen-Vorhersage und Death-Counter mit Zeit-Penalty anzeigt — Default sichtbar nur in M+.

**Architecture:** Eines neues Modul `modules/mplus_frame/init.lua` plus eine Erweiterung des Mock-Layers um die WoW M+ APIs (`C_ChallengeMode.*`, `C_Scenario.*`). Modul registriert sich für `CHALLENGE_MODE_START`, `CHALLENGE_MODE_RESET`, `CHALLENGE_MODE_COMPLETED`, `SCENARIO_CRITERIA_UPDATE`, und für Death-Events über den existierenden `CombatLog`-Parser. Forces-Progress wird per `C_Scenario.GetCriteriaInfo` gepollt; Timer aus `GetWorldElapsedTime`; Schwellen aus `C_ChallengeMode.GetMapUIInfo(mapID).timeLimit`.

**Tech Stack:** Lua 5.1/LuaJIT 2.1, stylua, plain `assert()` Tests, vorhandene Widgets (Frame/Text), Event-Bus + WoW-Event-Bridge aus Phase 1-2.

---

## Scope Check

Phase 3 ist Spec §6 Phase 3. Ein Modul plus Mock-Erweiterungen. Clean in einer Plan-Sitzung.

**Out of scope** (kommt später):
- Pulls-Counter (`Pulls 4/12`) — braucht MDT-Routendaten (Phase 5 oder eigene MDT-Integration)
- Affix-Hinweise — Phase 4 (`affix_s1`)
- Position-Persistenz aus BlizzDB — späteres Polish

---

## File Structure

| Datei | Status | Verantwortung |
|---|---|---|
| `tests/mocks/wow_api.lua` | modify | M+ API-Stubs: `C_ChallengeMode`, `C_Scenario`, `GetWorldElapsedTime`. Mock-Control-Helpers `MockSetMythicPlus`, `MockSetForces`, `MockSetTimer`. |
| `modules/mplus_frame/init.lua` | new | M+ Run-Frame: Timer, Forces, Schwellen, Deaths. Show/Hide-Logic gebunden an M+ Run-State. |
| `tests/test_mplus_frame.lua` | new | Tests für Timer/Forces/Schwellen/Death-Logic. |
| `Blizz.toc` | modify | Neues Modul + neue core-File (falls relevant) registrieren. |

**Anzeigen (siehe Mockup `docs/superpowers/mockups/layout-v3.html`):**
- TOP-LEFT Frame mit 3 Zeilen: Timer + Threshold, Forces % + Count, (placeholder für Affix in Phase 4)
- TOP-RIGHT Frame mit 2 Zeilen: Death-Counter + Penalty, Pulls-Stub (zeigt nur `—` solange Pulls out-of-scope)

---

## Task 1: Mock-Layer-Erweiterung — M+ APIs

**Files:**
- Modify: `tests/mocks/wow_api.lua`

- [ ] **Step 1: Erweitere `tests/mocks/wow_api.lua`**

Ergänze nach den existierenden `_G.C_Timer` / `_G.C_Scenario` Definitionen den vollständigen `C_ChallengeMode`-Stub und erweitere `C_Scenario`:

Replace:
```lua
_G.C_Timer = _G.C_Timer or { After = function(_, _) end }
_G.C_Scenario = _G.C_Scenario or {
	GetCriteriaInfo = function(_)
		return nil
	end,
}
```

With:
```lua
_G.C_Timer = _G.C_Timer or { After = function(_, _) end }

-- ---------- M+ API Mocks ----------
Mock.mythicplus = {
	active = false,
	mapID = 0,
	keystoneLevel = 0,
	affixes = {},
	timeLimit = 1800, -- par time in seconds, default 30min
}
Mock.forces = {
	total = 100,
	current = 0,
}
Mock.timer_elapsed = 0 -- seconds since pull

_G.C_ChallengeMode = {
	GetActiveChallengeMapID = function()
		return Mock.mythicplus.active and Mock.mythicplus.mapID or nil
	end,
	GetActiveKeystoneInfo = function()
		if not Mock.mythicplus.active then
			return 0, {}
		end
		return Mock.mythicplus.keystoneLevel, Mock.mythicplus.affixes
	end,
	GetMapUIInfo = function(mapID)
		if mapID ~= Mock.mythicplus.mapID then
			return nil
		end
		return "Mock Dungeon", mapID, Mock.mythicplus.timeLimit
	end,
}

_G.C_Scenario = {
	GetInfo = function()
		if not Mock.mythicplus.active then
			return nil
		end
		return "Mock Dungeon", nil, 1, nil, true
	end,
	GetCriteriaInfo = function(index)
		-- M+ has 1 criteria: forces. Returns description, type, completed, quantity, totalQuantity, ...
		if not Mock.mythicplus.active or index ~= 1 then
			return nil
		end
		return "Enemy Forces",
			0,
			Mock.forces.current >= Mock.forces.total,
			tostring(Mock.forces.current),
			Mock.forces.total
	end,
	GetStepInfo = function()
		if not Mock.mythicplus.active then
			return 0, 0, 0
		end
		return 1, 1, 1
	end,
}

_G.GetWorldElapsedTime = function(_)
	return Mock.timer_elapsed
end
```

Add Mock-Control helpers right before `function MockReset()`:

```lua
function MockSetMythicPlus(active, mapID, keystoneLevel, timeLimit)
	Mock.mythicplus.active = active and true or false
	Mock.mythicplus.mapID = mapID or 0
	Mock.mythicplus.keystoneLevel = keystoneLevel or 0
	Mock.mythicplus.timeLimit = timeLimit or 1800
end
function MockSetForces(current, total)
	Mock.forces.current = current or 0
	Mock.forces.total = total or 100
end
function MockSetTimer(elapsed)
	Mock.timer_elapsed = elapsed or 0
end
```

In `MockReset()`, append:
```lua
	Mock.mythicplus = { active = false, mapID = 0, keystoneLevel = 0, affixes = {}, timeLimit = 1800 }
	Mock.forces = { total = 100, current = 0 }
	Mock.timer_elapsed = 0
```

- [ ] **Step 2: `.luarc.json` Globals erweitern**

Add the new mock globals to `.luarc.json`'s `diagnostics.globals` array:
```json
    "MockSetMythicPlus",
    "MockSetForces",
    "MockSetTimer"
```

- [ ] **Step 3: Tests bleiben grün**

```bash
cd /home/deck/claude/blizz
stylua tests/mocks/wow_api.lua && stylua --check tests/mocks/wow_api.lua
luajit tests/run.lua 2>&1 | tail -3
```
Expected: `15 passed, 0 failed` (alle Phase 1-2 Tests bleiben grün; keine neuen Tests dazu).

- [ ] **Step 4: Commit**

```bash
cd /home/deck/claude/blizz
git add tests/mocks/wow_api.lua .luarc.json
git commit -m "test: extend mock layer with C_ChallengeMode/C_Scenario M+ stubs"
```

---

## Task 2: Modul-Skeleton + Show/Hide-Logic

**Files:**
- Create: `modules/mplus_frame/init.lua`
- Create: `tests/test_mplus_frame.lua`

- [ ] **Step 1: Failing test schreiben**

Create `tests/test_mplus_frame.lua`:
```lua
require("tests.mocks.wow_api")
require("Blizz")
require("data.spells_prot_warrior") -- shared bootstrap dependency
local MPlus = require("modules.mplus_frame")

local addon = _G.Blizz

MockReset()

-- module registered
assert(addon.modules.mplus_frame == MPlus, "mplus_frame module registered")
print("✓ module registered with id 'mplus_frame'")

-- bootstrap creates frames (hidden initially, no active M+)
addon:bootstrap()
assert(MPlus.left_frame, "left_frame exists")
assert(MPlus.right_frame, "right_frame exists")
assert(not MPlus.left_frame:IsShown(), "left_frame hidden outside M+")
assert(not MPlus.right_frame:IsShown(), "right_frame hidden outside M+")
print("✓ init() creates frames, hidden outside M+")

-- entering M+: frames become visible
MockSetMythicPlus(true, 1234, 18, 1800) -- mapID 1234, level 18, 30min par
MockSetForces(0, 151)
addon.EventBus:dispatch("CHALLENGE_MODE_START")
assert(MPlus.left_frame:IsShown(), "left_frame shown after CHALLENGE_MODE_START")
assert(MPlus.right_frame:IsShown(), "right_frame shown after CHALLENGE_MODE_START")
print("✓ CHALLENGE_MODE_START → frames shown")

-- challenge mode reset (wipe) → frames stay visible (timer keeps running)
addon.EventBus:dispatch("CHALLENGE_MODE_RESET")
assert(MPlus.left_frame:IsShown(), "left_frame stays shown on reset")
print("✓ CHALLENGE_MODE_RESET keeps frame visible")

-- challenge mode completed → frames hidden after delay
MockSetMythicPlus(false)
addon.EventBus:dispatch("CHALLENGE_MODE_COMPLETED")
assert(not MPlus.left_frame:IsShown(), "left_frame hidden after completion")
assert(not MPlus.right_frame:IsShown(), "right_frame hidden after completion")
print("✓ CHALLENGE_MODE_COMPLETED → frames hidden")
```

- [ ] **Step 2: Run → FAIL**

```bash
cd /home/deck/claude/blizz && luajit tests/run.lua
```
Expected: `module 'modules.mplus_frame' not found`

- [ ] **Step 3: Implement skeleton**

Create `modules/mplus_frame/init.lua`:
```lua
local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/mplus_frame/init.lua
-- M+ Run-Frame: Timer, Forces %, +2/+3-Schwellen, Death-Counter, Penalty.
-- Show/Hide an M+ Run-State gekoppelt.
-- Position: TOPLEFT (Timer/Forces) + TOPRIGHT (Deaths) per Layout v3.

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local MPlus = {
	id = "mplus_frame",
	events = {
		"CHALLENGE_MODE_START",
		"CHALLENGE_MODE_RESET",
		"CHALLENGE_MODE_COMPLETED",
		"SCENARIO_CRITERIA_UPDATE",
		"PLAYER_ENTERING_WORLD",
	},
}

function MPlus:init()
	-- Left frame: Timer + Forces (top-left)
	self.left_frame = Frame:new({
		name = "BlizzMPlusLeft",
		parent = UIParent,
		width = 240,
		height = 64,
	})
	self.left_frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)

	self.timer_text = Text:new({ parent = self.left_frame, text = "M+ —", style = "value" })
	if self.timer_text.SetPoint then
		self.timer_text:SetPoint("TOPLEFT", self.left_frame, "TOPLEFT", 6, -4)
	end

	self.forces_text = Text:new({ parent = self.left_frame, text = "Forces —", style = "default" })
	if self.forces_text.SetPoint then
		self.forces_text:SetPoint("TOPLEFT", self.left_frame, "TOPLEFT", 6, -22)
	end

	self.threshold_text = Text:new({ parent = self.left_frame, text = "", style = "label" })
	if self.threshold_text.SetPoint then
		self.threshold_text:SetPoint("TOPLEFT", self.left_frame, "TOPLEFT", 6, -40)
	end

	-- Right frame: Deaths + Penalty (top-right)
	self.right_frame = Frame:new({
		name = "BlizzMPlusRight",
		parent = UIParent,
		width = 160,
		height = 48,
	})
	self.right_frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)

	self.deaths_text = Text:new({ parent = self.right_frame, text = "☠ 0", style = "value" })
	if self.deaths_text.SetPoint then
		self.deaths_text:SetPoint("TOPRIGHT", self.right_frame, "TOPRIGHT", -6, -4)
	end

	self.penalty_text = Text:new({ parent = self.right_frame, text = "(−0s)", style = "label" })
	if self.penalty_text.SetPoint then
		self.penalty_text:SetPoint("TOPRIGHT", self.right_frame, "TOPRIGHT", -6, -22)
	end

	self.deaths = 0

	-- Initial show/hide based on current state
	self:refresh_visibility()
end

function MPlus:isActive()
	return C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID() ~= nil
end

function MPlus:refresh_visibility()
	if self:isActive() then
		self.left_frame:Show()
		self.right_frame:Show()
	else
		self.left_frame:Hide()
		self.right_frame:Hide()
	end
end

function MPlus:onEvent(event)
	if event == "CHALLENGE_MODE_START" then
		self.deaths = 0
		self.deaths_text:SetText("☠ 0")
		self.penalty_text:SetText("(−0s)")
		self:refresh_visibility()
	elseif event == "CHALLENGE_MODE_COMPLETED" then
		self:refresh_visibility()
	elseif event == "CHALLENGE_MODE_RESET" then
		-- frames stay visible during a wipe
		self:refresh_visibility()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:refresh_visibility()
	end
end

addon.registerModule(MPlus)
return MPlus
```

- [ ] **Step 4: Run → PASS**

```bash
cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -8
```
Expected: `16 passed, 0 failed`. test_mplus_frame's 4 prints visible.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
mkdir -p modules/mplus_frame
stylua modules/mplus_frame/init.lua tests/test_mplus_frame.lua && stylua --check modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git add modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git commit -m "feat(module): mplus_frame skeleton — show/hide on M+ state"
```

---

## Task 3: Timer + Schwellen-Vorhersage

**Files:**
- Modify: `modules/mplus_frame/init.lua`
- Modify: `tests/test_mplus_frame.lua` (append)

- [ ] **Step 1: Test ergänzen**

Append to `tests/test_mplus_frame.lua`:
```lua

-- Timer mit Schwellen
MockSetMythicPlus(true, 1234, 18, 1800) -- 30min par
MockSetTimer(0)
MockSetForces(0, 151)
addon.EventBus:dispatch("CHALLENGE_MODE_START")

-- 0s elapsed → all thresholds achievable
MPlus:refresh_timer()
local txt = MPlus.timer_text:GetText() or ""
assert(txt:match("0") or txt:match("00:00"), "timer at 0s shows 0, got '" .. txt .. "'")
print("✓ timer at 0:00")

-- 600s (10min) elapsed of 1800s par → ↓ +3 (we're under 60% = 1080s)
MockSetTimer(600)
MPlus:refresh_timer()
local thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("%+3"), "should project +3 at 600s, got '" .. thr .. "'")
print("✓ +3 threshold projection at 10min/30min par")

-- 1200s (20min, > 1440 *not yet — only above 60%, below 80%) → ↓ +2
MockSetTimer(1200)
MPlus:refresh_timer()
thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("%+2"), "should project +2 at 20min/30min par, got '" .. thr .. "'")
print("✓ +2 threshold projection at 20min/30min par")

-- 1500s (above 80% = 1440s, below 100%) → ↓ +1
MockSetTimer(1500)
MPlus:refresh_timer()
thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("%+1"), "should project +1 at 25min/30min par, got '" .. thr .. "'")
print("✓ +1 threshold projection")

-- 1900s (above 100%) → DEPLETED
MockSetTimer(1900)
MPlus:refresh_timer()
thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("DEPLET") or thr:match("depleted"), "depleted state, got '" .. thr .. "'")
print("✓ depleted state past par time")
```

- [ ] **Step 2: Run → FAIL** (refresh_timer doesn't exist yet)

- [ ] **Step 3: Implement timer + thresholds**

Modify `modules/mplus_frame/init.lua` — add timer methods AFTER `refresh_visibility`:

```lua
local function format_mmss(seconds)
	if seconds <= 0 then
		return "0:00"
	end
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%d:%02d", m, s)
end

function MPlus:getElapsedTime()
	-- WoW's M+ timer uses GetWorldElapsedTime. Treat anything non-nil as the elapsed seconds.
	if not GetWorldElapsedTime then
		return 0
	end
	local t = GetWorldElapsedTime(1) -- M+ timer is on slot 1
	return t or 0
end

function MPlus:getParTime()
	if not C_ChallengeMode or not C_ChallengeMode.GetActiveChallengeMapID then
		return 0
	end
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()
	if not mapID then
		return 0
	end
	local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
	return timeLimit or 0
end

function MPlus:getThreshold(elapsed, par)
	if par <= 0 then
		return ""
	end
	if elapsed >= par then
		return "DEPLETED"
	elseif elapsed >= par * 0.8 then
		return "↓ +1"
	elseif elapsed >= par * 0.6 then
		return "↓ +2"
	else
		return "↓ +3"
	end
end

function MPlus:refresh_timer()
	local elapsed = self:getElapsedTime()
	local par = self:getParTime()
	self.timer_text:SetText("M+ " .. format_mmss(elapsed))
	self.threshold_text:SetText(self:getThreshold(elapsed, par))
end
```

Add `refresh_timer()` call to `MPlus:onEvent` in the `CHALLENGE_MODE_START` branch AFTER `self:refresh_visibility()`:
```lua
		self:refresh_timer()
```

And in `init()` after `self:refresh_visibility()`, add:
```lua
	self:refresh_timer()
```

- [ ] **Step 4: Run → PASS**

```bash
cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -15
```
Expected: `16 passed, 0 failed`. All threshold prints visible.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
stylua modules/mplus_frame/init.lua tests/test_mplus_frame.lua && stylua --check modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git add modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git commit -m "feat(module): mplus_frame timer + threshold projection (+1/+2/+3)"
```

---

## Task 4: Forces-Tracker

**Files:**
- Modify: `modules/mplus_frame/init.lua`
- Modify: `tests/test_mplus_frame.lua` (append)

- [ ] **Step 1: Test ergänzen**

Append to `tests/test_mplus_frame.lua`:
```lua

-- Forces
MockSetMythicPlus(true, 1234, 18, 1800)
MockSetForces(0, 151)
addon.EventBus:dispatch("CHALLENGE_MODE_START")

MPlus:refresh_forces()
local ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("0") and ftxt:match("151"), "forces at 0/151, got '" .. ftxt .. "'")
print("✓ forces at 0%")

-- 96 of 151 → 63.5%
MockSetForces(96, 151)
addon.EventBus:dispatch("SCENARIO_CRITERIA_UPDATE")
ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("63") or ftxt:match("64"), "forces at ~64%, got '" .. ftxt .. "'")
assert(ftxt:match("96"), "current count 96, got '" .. ftxt .. "'")
print("✓ forces at 64% updates via SCENARIO_CRITERIA_UPDATE")

-- 151/151 → 100%
MockSetForces(151, 151)
addon.EventBus:dispatch("SCENARIO_CRITERIA_UPDATE")
ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("100"), "forces at 100%, got '" .. ftxt .. "'")
print("✓ forces at 100%")

-- overcap (rare but possible)
MockSetForces(160, 151)
addon.EventBus:dispatch("SCENARIO_CRITERIA_UPDATE")
ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("100"), "forces capped at 100%, got '" .. ftxt .. "'")
print("✓ forces clamped to 100% on overcap")
```

- [ ] **Step 2: Run → FAIL** (refresh_forces doesn't exist)

- [ ] **Step 3: Implement forces tracking**

Add to `modules/mplus_frame/init.lua` after `refresh_timer`:

```lua
function MPlus:getForces()
	if not C_Scenario or not C_Scenario.GetCriteriaInfo then
		return 0, 0
	end
	local _, _, _, currentStr, total = C_Scenario.GetCriteriaInfo(1)
	if not currentStr or not total then
		return 0, 0
	end
	local current = tonumber(currentStr) or 0
	return current, total
end

function MPlus:refresh_forces()
	local current, total = self:getForces()
	if total == 0 then
		self.forces_text:SetText("Forces —")
		return
	end
	local pct = math.min(100, math.floor((current / total) * 100))
	self.forces_text:SetText(string.format("Forces %d%% (%d/%d)", pct, current, total))
end
```

In `onEvent`, add a new branch:
```lua
	elseif event == "SCENARIO_CRITERIA_UPDATE" then
		self:refresh_forces()
```

Update `init()` to call `self:refresh_forces()` after `self:refresh_timer()`.

Update `CHALLENGE_MODE_START` branch to also call `self:refresh_forces()` after `self:refresh_timer()`.

- [ ] **Step 4: Run → PASS**

```bash
cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -12
```
Expected: `16 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
stylua modules/mplus_frame/init.lua tests/test_mplus_frame.lua && stylua --check modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git add modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git commit -m "feat(module): mplus_frame forces tracker (current %, count, overcap clamp)"
```

---

## Task 5: Death-Counter + Time-Penalty

**Files:**
- Modify: `modules/mplus_frame/init.lua`
- Modify: `tests/test_mplus_frame.lua` (append)

- [ ] **Step 1: Test ergänzen**

Append to `tests/test_mplus_frame.lua`:
```lua

-- Death counter
addon.EventBus:dispatch("CHALLENGE_MODE_START")
assert(MPlus.deaths == 0, "deaths reset on start")
assert(MPlus.deaths_text:GetText() == "☠ 0", "deaths text reset")
print("✓ deaths reset on start")

-- Death of a party member adds 1 + 15s penalty (Midnight default)
addon.CombatLog:dispatch(0, "UNIT_DIED", false, nil, nil, 0, 0, "Player-Mate1", "Mate1", 0, 0)
assert(MPlus.deaths == 1, "1 death after party UNIT_DIED")
assert(MPlus.deaths_text:GetText() == "☠ 1", "deaths text shows 1")
assert(MPlus.penalty_text:GetText() == "(−15s)", "penalty shows -15s")
print("✓ 1 death → ☠ 1 / (−15s)")

-- 3 more deaths → 4 total / -60s
addon.CombatLog:dispatch(0, "UNIT_DIED", false, nil, nil, 0, 0, "Player-Mate2", "Mate2", 0, 0)
addon.CombatLog:dispatch(0, "UNIT_DIED", false, nil, nil, 0, 0, "Player-Mate3", "Mate3", 0, 0)
addon.CombatLog:dispatch(0, "UNIT_DIED", false, nil, nil, 0, 0, "Player-Mate1", "Mate1", 0, 0)
assert(MPlus.deaths == 4, "4 deaths total")
assert(MPlus.penalty_text:GetText() == "(−60s)", "penalty -60s after 4 deaths")
print("✓ 4 deaths → ☠ 4 / (−60s)")

-- Non-player UNIT_DIED ignored (mob death)
addon.CombatLog:dispatch(0, "UNIT_DIED", false, nil, nil, 0, 0, "Creature-1234", "BadGuy", 0, 0)
assert(MPlus.deaths == 4, "mob death does not count")
print("✓ mob deaths ignored")

-- Death penalty disabled outside M+
MockSetMythicPlus(false)
addon.EventBus:dispatch("CHALLENGE_MODE_COMPLETED")
addon.CombatLog:dispatch(0, "UNIT_DIED", false, nil, nil, 0, 0, "Player-Mate1", "Mate1", 0, 0)
-- deaths field is not reset on completion (history kept), but no new death counted outside M+
assert(MPlus.deaths == 4, "death outside M+ doesn't increment, got " .. MPlus.deaths)
print("✓ deaths only counted inside M+")
```

- [ ] **Step 2: Run → FAIL** (death-counter logic missing)

- [ ] **Step 3: Implement death counter**

Add a CombatLog subscription. In `init()` AFTER `self:refresh_forces()`:

```lua
	-- Death counter via CombatLog
	local CombatLog = addon.CombatLog or require("core.combatlog")
	CombatLog:init()
	CombatLog:on("death", function(payload)
		self:on_death(payload)
	end)
```

Then add the on_death method:
```lua
local DEATH_PENALTY_SECONDS = 15

function MPlus:on_death(payload)
	-- Only count player deaths (destGUID starts with Player-)
	if not payload or not payload.destGUID or not payload.destGUID:match("^Player%-") then
		return
	end
	if not self:isActive() then
		return
	end
	self.deaths = self.deaths + 1
	local penalty = self.deaths * DEATH_PENALTY_SECONDS
	self.deaths_text:SetText("☠ " .. self.deaths)
	self.penalty_text:SetText(string.format("(−%ds)", penalty))
end
```

In `CHALLENGE_MODE_START` branch of `onEvent`, the existing reset is fine — `self.deaths = 0` already there.

- [ ] **Step 4: Run → PASS**

```bash
cd /home/deck/claude/blizz && luajit tests/run.lua 2>&1 | tail -14
```
Expected: `16 passed, 0 failed`.

- [ ] **Step 5: Stylua + Commit**

```bash
cd /home/deck/claude/blizz
stylua modules/mplus_frame/init.lua tests/test_mplus_frame.lua && stylua --check modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git add modules/mplus_frame/init.lua tests/test_mplus_frame.lua
git commit -m "feat(module): mplus_frame death counter + time penalty"
```

---

## Task 6: TOC-Integration + Version-Bump

**Files:**
- Modify: `Blizz.toc`

- [ ] **Step 1: TOC erweitern**

Append a line to the `Modules` section in `Blizz.toc` and bump version. Replace the file:

```
## Interface: 120005
## Title: Blizz
## Version: 0.0.3
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
modules/mplus_frame/init.lua
```

- [ ] **Step 2: TOC-Sanity + Full Sweep**

```bash
cd /home/deck/claude/blizz
awk '/\.lua$/ {print $1}' Blizz.toc | while read f; do test -f "$f" && echo "OK $f" || echo "MISSING $f"; done
stylua --check $(find . -name "*.lua" -not -path "./.claude/*")
luajit tests/run.lua 2>&1 | tail -3
```
Expected: all `OK`, stylua exit 0, `16 passed, 0 failed`.

- [ ] **Step 3: Commit**

```bash
cd /home/deck/claude/blizz
git add Blizz.toc
git commit -m "build: TOC adds mplus_frame module, version 0.0.3"
```

---

## Phase-3-Abschluss

Nach Task 6 ist:
- **mplus_frame**-Modul registriert, läuft auf 5 Events
- **Timer** (M:SS) mit **Schwellen-Projektion** (↓+1/+2/+3/DEPLETED) basierend auf elapsed vs par-time
- **Forces** als % + Count + Total, auto-clamped auf 100% bei Overcap
- **Death-Counter** + **15s-Penalty** pro Tod (CombatLog-basiert, nur Player-Deaths, nur in M+)
- **Show/Hide** automatisch beim Eintritt/Austritt aus M+
- 16 Test-Files alle grün headless
- TOC v0.0.3

In WoW jetzt:
```
/reload
# Start a M+ Run: Left frame zeigt "M+ 0:00 / Forces 0% (0/151) / ↓ +3"
# Bei 10min/30min par: "M+ 10:00 / Forces 64% / ↓ +3"
# Bei einem Wipe: alle Deaths zählen, Frame bleibt sichtbar
# Out-of-M+: Frame versteckt
```

---

## Self-Review

**1. Spec-Coverage** (Spec §6 Phase 3):
- ✅ Forces % — Task 4
- ✅ Timer — Task 3
- ✅ +2/+3-Schwellen — Task 3
- ✅ Death-Counter (CLEU-basiert) — Task 5
- ⚠️ Pulls (basierend auf Forces-Delta) — **out of scope**, dokumentiert: braucht MDT-Route-Data (Phase 5)

**Zusätzliche Spec-Touchpoints:**
- Spec §5 Layout — TOPLEFT (Timer/Forces) + TOPRIGHT (Deaths) übersetzt zu konkreten Anchors
- Spec §8 Error-Handling — `addon.registerModule` läuft Init in pcall (vorhandene Foundation aus Phase 1)
- Spec §9 Testing — Mock-Layer um `C_ChallengeMode`/`C_Scenario` erweitert (Task 1)

**2. Placeholder-Scan:** Keine TBD/TODO/FIXME im Plan. Code-Blöcke vollständig.

**3. Type-Consistency:**
- `Mock.mythicplus` / `Mock.forces` / `Mock.timer_elapsed` als Mock-State-Tabellen, konsistent in den Mock-Control-Helpers
- `C_Scenario.GetCriteriaInfo` Return-Shape: `(description, type, completed, quantityString, totalQuantity, ...)` — konsistent zur WoW-Doku
- `payload.destGUID` aus `core/combatlog.lua` build_payload — konsistent verwendet in `on_death`
- `MPlus:isActive()` als Boolean-Helper, konsistent in `refresh_visibility` und `on_death`

**4. Ambiguity-Check:**
- "Schwellen-Projektion" — explizit: ↓+3 unter 60%, ↓+2 unter 80%, ↓+1 unter 100%, DEPLETED ab 100%. Klare Boolean-Branches.
- "Death-Penalty 15s" — explizit als `DEATH_PENALTY_SECONDS` Konstante. Xal'atath's Guile (+12) verschärft das, aber das ist Affix-spezifisch und kommt in Phase 4.
- Mock-Frame und Timer sind während Tests ausreichend: `MockSetTimer(seconds)` simuliert `GetWorldElapsedTime`, `MockSetForces(c, t)` simuliert `C_Scenario.GetCriteriaInfo`.

**Stand:** Plan ist self-reviewed, Spec-Coverage komplett für Phase 3 (außer Pulls — out of scope), keine offenen Placeholder.
