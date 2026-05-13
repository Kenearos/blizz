require("tests.mocks.wow_api")
require("Blizz")
require("data.tankbusters_s1")
local TankBuster = require("modules.tankbuster")

local addon = _G.Blizz

MockReset()
-- Inject test data (real DB is empty starter)
addon.TankBustersS1[88888] = { name = "Test Crusher", severity = "high", suggest = "shield_wall" }
addon.TankBustersS1[88889] = { name = "Test Slam", severity = "medium", suggest = "ignore_pain" }

assert(addon.modules.tankbuster == TankBuster, "tankbuster module registered")
print("✓ module registered with id 'tankbuster'")

addon:bootstrap()
assert(TankBuster.alert, "alert widget exists")
assert(not TankBuster.alert:IsShown(), "alert starts hidden")
print("✓ init() creates alert (hidden)")

-- High-severity cast → SHIELD WALL alert
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate1", "cast-tb-1", 88888)
assert(TankBuster.alert:IsShown(), "high-severity tankbuster shows alert")
assert(
	TankBuster.alert:getText():match("SHIELD WALL"),
	"alert text mentions SHIELD WALL: " .. TankBuster.alert:getText()
)
assert(TankBuster.alert:getText():match("Test Crusher"), "alert text mentions Test Crusher")
print("✓ high-severity → SHIELD WALL alert")

-- Stop hides alert
addon.EventBus:dispatch("UNIT_SPELLCAST_STOP", "nameplate1", "cast-tb-1", 88888)
assert(not TankBuster.alert:IsShown(), "alert hides after stop")
print("✓ cast stop hides alert")

-- Medium-severity → IGNORE PAIN alert
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate2", "cast-tb-2", 88889)
assert(TankBuster.alert:IsShown(), "medium-severity also shows alert")
assert(TankBuster.alert:getText():match("IGNORE PAIN"), "medium uses IGNORE PAIN")
print("✓ medium-severity → IGNORE PAIN alert")

-- Unknown spell ignored
addon.EventBus:dispatch("UNIT_SPELLCAST_STOP", "nameplate2", "cast-tb-2", 88889)
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate3", "cast-x", 999999)
assert(not TankBuster.alert:IsShown(), "unknown spell ignored")
print("✓ unknown spell ignored")

-- Player's cast ignored
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "player", "cast-self", 88888)
assert(not TankBuster.alert:IsShown(), "player's own cast ignored")
print("✓ player cast ignored")
