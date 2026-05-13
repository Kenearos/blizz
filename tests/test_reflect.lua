require("tests.mocks.wow_api")
require("Blizz")
require("data.reflect_spells")
local Reflect = require("modules.reflect")

local addon = _G.Blizz

MockReset()
-- Inject reflectable spell IDs for testing (real data file is empty starter)
addon.ReflectSpells[12345] = { name = "Test Reflectable", source = "Test Dungeon" }
addon.ReflectSpells[67890] = { name = "Another", source = "Test" }

assert(addon.modules.reflect == Reflect, "reflect module registered")
print("✓ module registered with id 'reflect'")

addon:bootstrap()
assert(Reflect.alert, "reflect alert widget exists")
assert(not Reflect.alert:IsShown(), "alert starts hidden")
print("✓ init() creates alert (hidden by default)")

-- nameplate unit starts casting a reflectable spell → alert fires
MockResetSounds()
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate1", "cast-guid-1", 12345)
assert(Reflect.alert:IsShown(), "alert shown when reflectable cast starts")
assert(Reflect.alert:isPulsing(), "alert pulses")
print("✓ reflectable cast → alert visible + pulsing")

-- rising-edge sound cue plays exactly once
local s = MockGetLastPlayedSound()
assert(s and s.kind == "kit" and s.id == SOUNDKIT.RAID_WARNING, "raid-warning sound cue played")
assert(#MockGetPlayedSounds() == 1, "exactly one sound queued on rising edge")

-- second overlapping cast must NOT re-chime (still active)
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate2", "cast-guid-overlap", 67890)
assert(#MockGetPlayedSounds() == 1, "overlapping cast does not re-chime")
print("✓ sound cue fires only on rising edge")
addon.EventBus:dispatch("UNIT_SPELLCAST_STOP", "nameplate2", "cast-guid-overlap", 67890)

-- cast stops → alert hides
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
