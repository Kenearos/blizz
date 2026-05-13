require("tests.mocks.wow_api")
require("Blizz")
require("data.spells_prot_warrior")
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

-- entering M+ → frames visible
MockSetMythicPlus(true, 1234, 18, 1800)
MockSetForces(0, 151)
addon.EventBus:dispatch("CHALLENGE_MODE_START")
assert(MPlus.left_frame:IsShown(), "left_frame shown after CHALLENGE_MODE_START")
assert(MPlus.right_frame:IsShown(), "right_frame shown after CHALLENGE_MODE_START")
print("✓ CHALLENGE_MODE_START → frames shown")

-- wipe (reset) → frames stay visible
addon.EventBus:dispatch("CHALLENGE_MODE_RESET")
assert(MPlus.left_frame:IsShown(), "left_frame stays shown on reset")
print("✓ CHALLENGE_MODE_RESET keeps frame visible")

-- completed → frames hidden
MockSetMythicPlus(false)
addon.EventBus:dispatch("CHALLENGE_MODE_COMPLETED")
assert(not MPlus.left_frame:IsShown(), "left_frame hidden after completion")
assert(not MPlus.right_frame:IsShown(), "right_frame hidden after completion")
print("✓ CHALLENGE_MODE_COMPLETED → frames hidden")

-- Timer + Thresholds — elapsed wird aus GetTime() - start_time gerechnet,
-- start_time wird auf CHALLENGE_MODE_START gesetzt. Tests rücken GetTime vor.
MockSetMythicPlus(true, 1234, 18, 1800) -- 30min par
MockSetTime(1000)
MockSetForces(0, 151)
addon.EventBus:dispatch("CHALLENGE_MODE_START") -- start_time = 1000

MPlus:refresh_timer()
local txt = MPlus.timer_text:GetText() or ""
assert(txt:match("0") or txt:match("00:00"), "timer at 0s shows 0, got '" .. txt .. "'")
print("✓ timer at 0:00")

MockSetTime(1600) -- 600s elapsed = 33% of 1800s par → +3
MPlus:refresh_timer()
local thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("%+3"), "should project +3 at 600s, got '" .. thr .. "'")
print("✓ +3 threshold projection at 10min/30min par")

MockSetTime(2200) -- 1200s = 67% → +2
MPlus:refresh_timer()
thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("%+2"), "should project +2 at 20min/30min par, got '" .. thr .. "'")
print("✓ +2 threshold projection at 20min/30min par")

MockSetTime(2500) -- 1500s = 83% → +1
MPlus:refresh_timer()
thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("%+1"), "should project +1 at 25min/30min par, got '" .. thr .. "'")
print("✓ +1 threshold projection")

MockSetTime(2900) -- 1900s = > 100% → depleted
MPlus:refresh_timer()
thr = MPlus.threshold_text:GetText() or ""
assert(thr:match("DEPLET") or thr:match("depleted"), "depleted state, got '" .. thr .. "'")
print("✓ depleted state past par time")

-- Forces
MockSetMythicPlus(true, 1234, 18, 1800)
MockSetForces(0, 151)
addon.EventBus:dispatch("CHALLENGE_MODE_START")

MPlus:refresh_forces()
local ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("0") and ftxt:match("151"), "forces at 0/151, got '" .. ftxt .. "'")
print("✓ forces at 0%")

MockSetForces(96, 151)
addon.EventBus:dispatch("SCENARIO_CRITERIA_UPDATE")
ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("63") or ftxt:match("64"), "forces at ~64%, got '" .. ftxt .. "'")
assert(ftxt:match("96"), "current count 96, got '" .. ftxt .. "'")
print("✓ forces at 64% updates via SCENARIO_CRITERIA_UPDATE")

MockSetForces(151, 151)
addon.EventBus:dispatch("SCENARIO_CRITERIA_UPDATE")
ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("100"), "forces at 100%, got '" .. ftxt .. "'")
print("✓ forces at 100%")

MockSetForces(160, 151)
addon.EventBus:dispatch("SCENARIO_CRITERIA_UPDATE")
ftxt = MPlus.forces_text:GetText() or ""
assert(ftxt:match("100"), "forces capped at 100%, got '" .. ftxt .. "'")
print("✓ forces clamped to 100% on overcap")

-- Death counter — via UNIT_HEALTH events (CLEU ist in Midnight 12.0 blocked)
MockSetMythicPlus(true, 1234, 18, 1800)
addon.EventBus:dispatch("CHALLENGE_MODE_START")
assert(MPlus.deaths == 0, "deaths reset on start")
assert(MPlus.deaths_text:GetText() == "☠ 0", "deaths text reset")
print("✓ deaths reset on start")

-- party1 stirbt: UnitIsDead returnt true + UNIT_HEALTH event
MockSetUnitDead("party1", true)
addon.EventBus:dispatch("UNIT_HEALTH", "party1")
assert(MPlus.deaths == 1, "1 death after party1 dies, got " .. MPlus.deaths)
assert(MPlus.deaths_text:GetText() == "☠ 1", "deaths text shows 1")
assert(MPlus.penalty_text:GetText() == "(−15s)", "penalty shows -15s")
print("✓ 1 death → ☠ 1 / (−15s) via UNIT_HEALTH")

-- gleiche unit re-fires UNIT_HEALTH ohne respawn → KEINE neue death zählen
addon.EventBus:dispatch("UNIT_HEALTH", "party1")
assert(MPlus.deaths == 1, "no double-count on repeated UNIT_HEALTH while dead")
print("✓ repeated UNIT_HEALTH while dead doesn't double-count")

-- weitere deaths
MockSetUnitDead("party2", true)
addon.EventBus:dispatch("UNIT_HEALTH", "party2")
MockSetUnitDead("party3", true)
addon.EventBus:dispatch("UNIT_HEALTH", "party3")
-- party1 respawnt und stirbt erneut
MockSetUnitDead("party1", false)
addon.EventBus:dispatch("UNIT_HEALTH", "party1")
MockSetUnitDead("party1", true)
addon.EventBus:dispatch("UNIT_HEALTH", "party1")
assert(MPlus.deaths == 4, "4 deaths total, got " .. MPlus.deaths)
assert(MPlus.penalty_text:GetText() == "(−60s)", "penalty -60s after 4 deaths")
print("✓ 4 deaths → ☠ 4 / (−60s) via UNIT_HEALTH transitions")

-- player death via PLAYER_DEAD
MockSetUnitDead("player", true)
addon.EventBus:dispatch("PLAYER_DEAD")
assert(MPlus.deaths == 5, "PLAYER_DEAD increments, got " .. MPlus.deaths)
print("✓ PLAYER_DEAD increments death counter")

-- outside M+: deaths nicht inkrementieren
MockSetMythicPlus(false)
addon.EventBus:dispatch("CHALLENGE_MODE_COMPLETED")
MockSetUnitDead("party1", false)
addon.EventBus:dispatch("UNIT_HEALTH", "party1")
MockSetUnitDead("party1", true)
addon.EventBus:dispatch("UNIT_HEALTH", "party1")
assert(MPlus.deaths == 5, "death outside M+ doesn't increment, got " .. MPlus.deaths)
print("✓ deaths only counted inside M+")
