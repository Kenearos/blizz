require("tests.mocks.wow_api")
require("Blizz")
require("data.spells_prot_warrior")
local CDModule = require("modules.cooldowns")

local addon = _G.Blizz
local order = addon.SpellsProtWarrior.defensive_bar_order

MockReset()
MockSetTime(1000)

-- module registered under id 'cooldowns'
assert(addon.modules.cooldowns == CDModule, "cooldowns module registered")
print("✓ module registered with id 'cooldowns'")

-- bootstrap creates 8 icons in order
addon:bootstrap()
assert(type(CDModule.icons) == "table", "icons table exists")
assert(#CDModule.icons == 8, "exactly 8 defensive icons, got " .. #CDModule.icons)
for i, ico in ipairs(CDModule.icons) do
	assert(ico.__type == "Frame", "icon " .. i .. " should be Frame")
	assert(ico.__spellID == order[i], "icon " .. i .. " spellID mismatch")
end
print("✓ 8 icons created in order")

-- all ready by default
for _, ico in ipairs(CDModule.icons) do
	assert(ico:getState() == "ready", "all icons start ready")
end
print("✓ default state is ready")

-- put Shield Wall on cooldown
MockSetCooldown(871, 995, 240)
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
local wall_icon = CDModule.icons[1]
assert(wall_icon:getState() == "cd", "wall icon should be cd, got " .. wall_icon:getState())
assert(
	wall_icon:getRemainingText():match("23") ~= nil,
	"remaining text should match ~235s, got " .. wall_icon:getRemainingText()
)
print("✓ icon flips to cd state on cooldown")

-- back to ready when cooldown clears
MockSetCooldown(871, 0, 0)
addon.EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(CDModule.icons[1]:getState() == "ready", "back to ready")
print("✓ icon flips back to ready when CD clears")
