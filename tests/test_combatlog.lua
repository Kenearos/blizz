require("tests.mocks.wow_api")
local CombatLog = require("core.combatlog")

MockReset()
CombatLog:init()

local captured = {}
CombatLog:on("interrupt", function(payload)
	table.insert(captured, payload)
end)

local function fire_interrupt(sourceGUID, destGUID, spellID)
	MockFireCLEU(
		1234,
		"SPELL_INTERRUPT",
		false,
		sourceGUID,
		"Caster",
		0,
		0,
		destGUID,
		"Target",
		0,
		0,
		spellID,
		"Interrupted Cast"
	)
end

fire_interrupt("Player-1", "Creature-1", 6552)
fire_interrupt("Player-2", "Creature-2", 47528)
assert(#captured == 2, "expected 2 interrupt events, got " .. #captured)
assert(captured[1].sourceGUID == "Player-1", "sourceGUID propagation")
assert(captured[1].spellID == 6552, "spellID propagation")
print("✓ interrupt events classified")

-- death event
captured = {}
CombatLog:on("death", function(p)
	table.insert(captured, p)
end)
MockFireCLEU(1235, "UNIT_DIED", false, nil, nil, 0, 0, "Player-3", "FallenHero", 0, 0)
assert(#captured == 1 and captured[1].destGUID == "Player-3", "death event")
print("✓ death events classified")

-- unrelated event ignored
captured = {}
MockFireCLEU(
	1236,
	"SPELL_PERIODIC_HEAL",
	false,
	"Player-X",
	"X",
	0,
	0,
	"Player-X",
	"X",
	0,
	0,
	33076,
	"Prayer of Mending"
)
assert(#captured == 0, "non-classified event should not fire callbacks")
print("✓ unrelated events ignored")
