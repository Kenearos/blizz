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
