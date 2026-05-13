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
MockResetSounds()
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate1", "cast-tb-1", 88888)
assert(TankBuster.alert:IsShown(), "high-severity tankbuster shows alert")
assert(
	TankBuster.alert:getText():match("SHIELD WALL"),
	"alert text mentions SHIELD WALL: " .. TankBuster.alert:getText()
)
assert(TankBuster.alert:getText():match("Test Crusher"), "alert text mentions Test Crusher")
print("✓ high-severity → SHIELD WALL alert")

-- High-severity gets the violet-charge sound, not raid-warning
local s = MockGetLastPlayedSound()
assert(
	s and s.kind == "kit" and s.id == SOUNDKIT.UI_ALERT_VIOLET_CHARGE_UP,
	"high-severity uses violet charge-up sound"
)
print("✓ high-severity → violet charge sound cue")

-- Stop hides alert
addon.EventBus:dispatch("UNIT_SPELLCAST_STOP", "nameplate1", "cast-tb-1", 88888)
assert(not TankBuster.alert:IsShown(), "alert hides after stop")
print("✓ cast stop hides alert")

-- Medium-severity → IGNORE PAIN alert + raid-warning sound
MockResetSounds()
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate2", "cast-tb-2", 88889)
assert(TankBuster.alert:IsShown(), "medium-severity also shows alert")
assert(TankBuster.alert:getText():match("IGNORE PAIN"), "medium uses IGNORE PAIN")
local s2 = MockGetLastPlayedSound()
assert(
	s2 and s2.kind == "kit" and s2.id == SOUNDKIT.RAID_WARNING,
	"medium-severity uses raid-warning sound"
)
print("✓ medium-severity → IGNORE PAIN alert + raid-warning sound")

-- Unknown spell ignored
addon.EventBus:dispatch("UNIT_SPELLCAST_STOP", "nameplate2", "cast-tb-2", 88889)
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate3", "cast-x", 999999)
assert(not TankBuster.alert:IsShown(), "unknown spell ignored")
print("✓ unknown spell ignored")

-- Player's cast ignored
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "player", "cast-self", 88888)
assert(not TankBuster.alert:IsShown(), "player's own cast ignored")
print("✓ player cast ignored")

-- I-01: production DB must have meaningful coverage (not the empty starter anymore)
local count = 0
local high_count = 0
local medium_count = 0
local valid_suggests = {
	shield_wall = true,
	last_stand = true,
	ignore_pain = true,
	demo_shout = true,
}
for spellID, entry in pairs(addon.TankBustersS1) do
	-- Skip the two test entries we injected at the top
	if spellID ~= 88888 and spellID ~= 88889 then
		count = count + 1
		assert(type(entry.name) == "string" and #entry.name > 0, "entry " .. spellID .. " has name")
		assert(
			entry.severity == "high" or entry.severity == "medium",
			"entry " .. spellID .. " severity"
		)
		assert(
			valid_suggests[entry.suggest],
			"entry " .. spellID .. " suggest is valid: " .. tostring(entry.suggest)
		)
		if entry.severity == "high" then
			high_count = high_count + 1
		elseif entry.severity == "medium" then
			medium_count = medium_count + 1
		end
	end
end
assert(count >= 15, "tankbuster DB has at least 15 curated entries, got " .. count)
assert(high_count >= 5, "at least 5 high-severity entries, got " .. high_count)
assert(medium_count >= 5, "at least 5 medium-severity entries, got " .. medium_count)
print(
	string.format(
		"✓ tankbuster DB has %d curated entries (%d high / %d medium)",
		count,
		high_count,
		medium_count
	)
)
