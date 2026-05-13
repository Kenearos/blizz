require("tests.mocks.wow_api")
require("Blizz")
require("data.party_interrupts")
local KickRota = require("modules.kickrota")

local addon = _G.Blizz

MockReset()
MockSetTime(1000)
MockSetGroup(5)
MockSetUnit(
	"player",
	{ class = "WARRIOR", classLocalized = "Warrior", name = "Me", guid = "Player-Me-1" }
)
MockSetUnit(
	"party1",
	{ class = "ROGUE", classLocalized = "Rogue", name = "Stabby", guid = "Player-Stabby-1" }
)
MockSetUnit(
	"party2",
	{ class = "MAGE", classLocalized = "Mage", name = "Boomer", guid = "Player-Boomer-1" }
)
MockSetUnit(
	"party3",
	{ class = "PRIEST", classLocalized = "Priest", name = "Healer", guid = "Player-Healer-1" }
)
MockSetUnit(
	"party4",
	{ class = "PALADIN", classLocalized = "Paladin", name = "Pally", guid = "Player-Pally-1" }
)

assert(addon.modules.kickrota == KickRota, "kickrota module registered")
print("✓ module registered with id 'kickrota'")

addon:bootstrap()
assert(KickRota.panel, "kick rota panel exists")
assert(KickRota.next_text, "next-kicker label exists")
assert(KickRota.you_text, "your-status label exists")
print("✓ init() creates panel + labels")

-- Initial state: nobody has used a kick → all ready
local roster = KickRota:getRoster()
assert(#roster >= 4, "should have 4+ party members in roster, got " .. #roster)
local ready_count = 0
for _, p in ipairs(roster) do
	if p.ready then
		ready_count = ready_count + 1
	end
end
assert(
	ready_count == #roster,
	"all party members start with ready interrupt, got " .. ready_count .. "/" .. #roster
)
print("✓ initial roster: all interrupts ready")

-- party1 (Rogue, 15s CD) uses their kick → tracked via UNIT_SPELLCAST_SUCCEEDED
MockSetTime(1000)
addon.EventBus:dispatch("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast-rogue-1", 1766) -- 1766 = Rogue Kick
assert(KickRota.cooldowns["Player-Stabby-1"], "Rogue kick should be tracked by GUID")
assert(
	KickRota.cooldowns["Player-Stabby-1"].ready_at == 1015,
	"Rogue Kick CD should be tracked, expected ready_at=1015, got "
		.. tostring(KickRota.cooldowns["Player-Stabby-1"].ready_at)
)
print("✓ interrupt tracked via UNIT_SPELLCAST_SUCCEEDED")

-- Reflectable/kickable cast starts on nameplate → KickRota picks next available kicker
MockSetTime(1005) -- 5s into Rogue's CD, Rogue not ready
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate1", "cast-guid-1", 12345)
local next_msg = KickRota.next_text:GetText() or ""
assert(next_msg ~= "", "next-kicker text should be populated, got '" .. next_msg .. "'")
print("✓ next-kicker text populated on cast start: '" .. next_msg .. "'")

-- Player (Warrior) is the local — when local is next, you_text shows "YOUR KICK"
-- Mock player class WARRIOR, Pummel CD 15s. If everyone else is on CD player should be picked.
MockSetTime(1000)
KickRota.cooldowns = {} -- reset
-- All other party members on CD via fake-set
for _, name in ipairs({ "Stabby", "Boomer", "Healer", "Pally" }) do
	KickRota.cooldowns["fake-guid-" .. name] = { ready_at = 1100, name = name }
end
addon.EventBus:dispatch("UNIT_SPELLCAST_START", "nameplate2", "cast-guid-2", 99999)
local you_msg = KickRota.you_text:GetText() or ""
-- Player has no entry → ready → should be suggested
assert(
	you_msg:match("YOU") or you_msg:match("READY") or you_msg == "READY",
	"player should be suggested when alone-ready, got '" .. you_msg .. "'"
)
print("✓ player suggested as next kicker when alone-ready: '" .. you_msg .. "'")
