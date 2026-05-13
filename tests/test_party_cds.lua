require("tests.mocks.wow_api")
require("Blizz")
require("data.party_cds")
local PartyCDs = require("modules.party_cds")

local addon = _G.Blizz

MockReset()
MockSetTime(1000)

assert(addon.modules.party_cds == PartyCDs, "party_cds module registered")
print("✓ module registered with id 'party_cds'")

addon:bootstrap()
assert(PartyCDs.panel, "panel created")
assert(type(PartyCDs.tracked) == "table", "tracked map exists")
print("✓ init() creates panel + tracked map")

local cds = PartyCDs:listOnCooldown()
assert(#cds == 0, "no party CDs tracked initially, got " .. #cds)
print("✓ no party CDs at start")

-- Healer casts Pain Suppression → tracked via UNIT_SPELLCAST_SUCCEEDED
MockSetUnit("party1", { guid = "Player-Healer1", name = "Pally", class = "PALADIN" })
addon.EventBus:dispatch("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast-ps-1", 33206)
MockSetTime(1001)
cds = PartyCDs:listOnCooldown()
assert(#cds == 1, "1 CD tracked after PS cast, got " .. #cds)
assert(cds[1].name == "Pain Suppression", "name = Pain Suppression")
assert(
	cds[1].remaining >= 178 and cds[1].remaining <= 180,
	"remaining ~179s, got " .. cds[1].remaining
)
print("✓ Pain Suppression tracked via UNIT_SPELLCAST_SUCCEEDED")

-- Druid Innervate
MockSetUnit("party2", { guid = "Player-Druid1", name = "Tree", class = "DRUID" })
addon.EventBus:dispatch("UNIT_SPELLCAST_SUCCEEDED", "party2", "cast-inv-1", 29166)
MockSetTime(1002)
cds = PartyCDs:listOnCooldown()
assert(#cds == 2, "2 CDs tracked, got " .. #cds)
print("✓ multiple party CDs tracked")

-- After full default CD elapsed: removed from on-cooldown list
MockSetTime(1000 + 180 + 1)
cds = PartyCDs:listOnCooldown()
local has_ps = false
for _, c in ipairs(cds) do
	if c.name == "Pain Suppression" then
		has_ps = true
	end
end
assert(not has_ps, "Pain Suppression should be off-list after CD elapsed")
print("✓ expired CDs drop off list")

-- Non-tracked spell → ignored
addon.EventBus:dispatch("UNIT_SPELLCAST_SUCCEEDED", "party3", "cast-x", 999999)
cds = PartyCDs:listOnCooldown()
local count = #cds
addon.EventBus:dispatch("UNIT_SPELLCAST_SUCCEEDED", "party3", "cast-y", 999998)
cds = PartyCDs:listOnCooldown()
assert(#cds == count, "non-tracked spells ignored, count unchanged")
print("✓ non-tracked spells ignored")

-- I-07: Memory-Leak Fix — tracked must not grow unbounded across many casts.
-- Simulate 100 sequential PS casts, advance time so all expire, then verify cleanup.
MockSetTime(2000)
PartyCDs.tracked = {} -- reset for a clean baseline
for i = 1, 100 do
	addon.EventBus:dispatch("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast-bulk-" .. i, 33206)
end
-- Right after burst: tracked has up-to-MAX_TRACKED entries (active CDs)
assert(
	#PartyCDs.tracked <= 60,
	"tracked is hard-capped to MAX_TRACKED after burst, got " .. #PartyCDs.tracked
)
print("✓ tracked is hard-capped under burst load (got " .. #PartyCDs.tracked .. ")")

-- Advance time past all CDs and trigger a refresh — expired entries must be pruned.
MockSetTime(2000 + 200) -- 200s past last cast, well beyond 180s PS CD
PartyCDs:refresh()
assert(
	#PartyCDs.tracked == 0,
	"tracked is fully pruned when all CDs expired, got " .. #PartyCDs.tracked
)
print("✓ expired CDs pruned from tracked on refresh")
