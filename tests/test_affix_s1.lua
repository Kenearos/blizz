require("tests.mocks.wow_api")
require("Blizz")
require("data.affixes_s1")
local AffixS1 = require("modules.affix_s1")

local addon = _G.Blizz

MockReset()
-- Inject test NPC-IDs into the lookup (real data file is empty starter)
addon.AffixesS1.npcLookup[99001] = {
	bargain = "voidbound",
	alert_text = "VOIDBOUND EMISSARY — switch & kick",
}

assert(addon.modules.affix_s1 == AffixS1, "affix_s1 module registered")
print("✓ module registered with id 'affix_s1'")

addon:bootstrap()
assert(AffixS1.alert, "alert widget exists")
assert(not AffixS1.alert:IsShown(), "alert hidden initially")
print("✓ init() creates alert hidden")

-- Spawn a Voidbound Emissary mob
MockSetUnit("nameplate1", { guid = "Creature-0-1234-2660-1-99001-000012345678" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate1")
assert(AffixS1.alert:IsShown(), "alert shown when affix mob spawns")
assert(AffixS1.alert:getText():match("VOIDBOUND"), "alert text matches voidbound")
print("✓ affix mob spawn → alert shown")

-- Spawn a non-affix mob
MockSetUnit("nameplate2", { guid = "Creature-0-1234-2660-1-12345-000012345679" })
addon.EventBus:dispatch("NAME_PLATE_UNIT_ADDED", "nameplate2")
-- alert stays shown from previous, but no NEW alert fires
print("✓ non-affix mob ignored (no error)")

-- Mob removed → alert hides if all affix mobs gone
addon.EventBus:dispatch("NAME_PLATE_UNIT_REMOVED", "nameplate1")
assert(not AffixS1.alert:IsShown(), "alert hidden when affix mob despawns")
print("✓ affix mob removed → alert hidden")
