require("tests.mocks.wow_api")

-- CreateFrame should return a table with WoW frame methods
local f = CreateFrame("Frame", "TestFrame", UIParent)
assert(type(f) == "table", "CreateFrame returned non-table")
assert(type(f.SetSize) == "function", "frame:SetSize missing")
assert(type(f.SetPoint) == "function", "frame:SetPoint missing")
assert(type(f.RegisterEvent) == "function", "frame:RegisterEvent missing")
assert(UIParent ~= nil, "UIParent missing")
print("✓ CreateFrame returns themed frame stub")

-- UnitHealth / UnitGetTotalAbsorbs return mocked numeric values
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 38000 })
assert(UnitHealth("player") == 50000, "UnitHealth")
assert(UnitGetTotalAbsorbs("player") == 38000, "UnitGetTotalAbsorbs")
print("✓ unit state mock works")

-- GetSpellCooldown mock
MockSetCooldown(871, GetTime() - 1, 240) -- Shield Wall, started 1s ago, 240s CD
local start, dur = GetSpellCooldown(871)
assert(start ~= 0 and dur == 240, "GetSpellCooldown shape")
print("✓ cooldown mock works")

-- Combat-log injection
local captured
MockSetCLEUListener(function(event, ...)
	captured = { event, ... }
end)
MockFireCLEU("SPELL_INTERRUPT", "Player-123", "Target-456", 6552)
assert(captured and captured[1] == "SPELL_INTERRUPT", "CLEU injection")
print("✓ CLEU mock works")
