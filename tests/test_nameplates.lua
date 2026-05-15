require("tests.mocks.wow_api")
require("Blizz")
require("data.npcs_midnight_s1")
local Nameplates = require("modules.nameplates")

local addon = _G.Blizz

MockReset()
-- Inject test NPC entries
addon.NPCsMidnightS1[111] = { category = "caster", name = "Test Caster" }
addon.NPCsMidnightS1[222] = { category = "frontal", name = "Test Frontal" }
addon.NPCsMidnightS1[333] = { category = "healer", name = "Test Healer" }
addon.NPCsMidnightS1[444] = { category = "priority_kill", name = "Test Priority" }

assert(addon.modules.nameplates == Nameplates, "nameplates module registered")
print("✓ module registered with id 'nameplates'")

addon:bootstrap()

-- Caster mob spawns → tracked as caster category
MockSetUnit("nameplate1", { guid = "Creature-0-1234-2660-1-111-000012345001" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate1")
local entry = Nameplates.tracked["nameplate1"]
assert(entry, "nameplate1 should be tracked")
assert(entry.category == "caster", "category should be caster, got " .. tostring(entry.category))
assert(entry.overlay, "overlay frame created")
assert(entry.overlay:getState() == "alert", "caster overlay state is 'alert' (magenta semantic)")
print("✓ caster category classified + overlay alert state")

-- Frontal mob → outline, not filled
MockSetUnit("nameplate2", { guid = "Creature-0-1234-2660-1-222-000012345002" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate2")
local e2 = Nameplates.tracked["nameplate2"]
assert(e2.category == "frontal", "frontal category")
assert(e2.overlay:getState() == "default", "frontal stays default (outline only)")
print("✓ frontal category classified")

-- Healer mob → ready (filled lime semantic)
MockSetUnit("nameplate3", { guid = "Creature-0-1234-2660-1-333-000012345003" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate3")
assert(Nameplates.tracked["nameplate3"].overlay:getState() == "ready", "healer = ready state")
print("✓ healer category classified")

-- Priority kill → priority state (red-outline, kill-priority semantic)
MockSetUnit("nameplate4", { guid = "Creature-0-1234-2660-1-444-000012345004" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate4")
local e4 = Nameplates.tracked["nameplate4"]
assert(e4.category == "priority_kill", "priority_kill category")
assert(
	e4.overlay:getState() == "priority",
	"priority_kill overlay state is 'priority', got " .. tostring(e4.overlay:getState())
)
print("✓ priority_kill category classified + overlay priority state")

-- Unknown mob → generic, no overlay tracked
MockSetUnit("nameplate5", { guid = "Creature-0-1234-2660-1-999999-000012345005" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate5")
assert(not Nameplates.tracked["nameplate5"], "unknown NPC not tracked")
print("✓ unknown NPC not tracked (no overlay)")

-- Mob removed → untracked
addon.EventBus:dispatch("NAME_PLATE_UNIT_REMOVED", "nameplate1")
assert(not Nameplates.tracked["nameplate1"], "removed nameplate untracked")
print("✓ nameplate removal cleans up tracking")
