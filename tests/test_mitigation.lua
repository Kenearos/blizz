require("tests.mocks.wow_api")
require("Blizz")
require("data.spells_prot_warrior")
local Mitigation = require("modules.mitigation")

local addon = _G.Blizz
local SB = addon.SpellsProtWarrior.active_mitigation.shield_block -- 2565

MockReset()
MockSetTime(1000)
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 0 })

-- module is registered with the expected id
assert(addon.modules.mitigation == Mitigation, "mitigation module registered")
print("✓ module registered with id 'mitigation'")

-- bootstrap calls init → frame exists
addon:bootstrap()
assert(Mitigation.frame, "mitigation frame should be created on init")
assert(Mitigation.frame.__type == "Frame", "mitigation frame is a Frame stub")
assert(Mitigation.shield_block_text, "shield_block_text label exists")
assert(Mitigation.ignore_pain_text, "ignore_pain_text label exists")
print("✓ init() creates display frame + labels")

-- Shield Block on cooldown → label shows remaining time
MockSetCooldown(SB, 995, 6) -- 5s elapsed, 6s duration → 1s remaining
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(
	Mitigation.shield_block_text:GetText():match("1") ~= nil,
	"shield_block_text should show ~1s remaining, got '"
		.. tostring(Mitigation.shield_block_text:GetText())
		.. "'"
)
print("✓ Shield Block CD readout updates")

-- Shield Block ready → label shows "RDY"
MockSetCooldown(SB, 0, 0)
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(Mitigation.shield_block_text:GetText() == "RDY", "ready label should be 'RDY'")
print("✓ Shield Block ready state")

-- Ignore Pain absorb → label shows kvalue
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 38000 })
addon.EventBus:dispatch("UNIT_AURA", "player")
assert(
	Mitigation.ignore_pain_text:GetText():match("38") ~= nil,
	"ignore_pain_text should show ~38k absorb, got '"
		.. tostring(Mitigation.ignore_pain_text:GetText())
		.. "'"
)
print("✓ Ignore Pain absorb readout updates")

-- Zero absorb → label shows '0'
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 0 })
addon.EventBus:dispatch("UNIT_AURA", "player")
local ip_text = Mitigation.ignore_pain_text:GetText() or ""
assert(ip_text == "0" or ip_text:match("^0"), "zero absorb shows '0', got '" .. ip_text .. "'")
print("✓ Ignore Pain zero state")
