require("tests.mocks.wow_api")
local Spells = require("data.spells_prot_warrior")

assert(type(Spells.active_mitigation) == "table", "active_mitigation table missing")
assert(Spells.active_mitigation.shield_block == 2565, "Shield Block spellID")
assert(Spells.active_mitigation.ignore_pain == 190456, "Ignore Pain spellID")

assert(type(Spells.defensives) == "table", "defensives table missing")
local def = Spells.defensives
assert(def.shield_wall == 871, "Shield Wall")
assert(def.last_stand == 12975, "Last Stand")
assert(def.spell_reflection == 23920, "Spell Reflection")
assert(def.demoralizing_shout == 1160, "Demoralizing Shout")
assert(def.rallying_cry == 97462, "Rallying Cry")
assert(def.avatar == 107574, "Avatar")
assert(def.demoralizing_banner == 236320, "Demoralizing Banner (talented)")
assert(def.charge == 100, "Charge")
print("✓ active mitigation + 8 defensive spell IDs present")

assert(type(Spells.utility) == "table", "utility table missing")
assert(Spells.utility.pummel == 6552, "Pummel")
assert(Spells.utility.heroic_leap == 6544, "Heroic Leap")
assert(Spells.utility.intervene == 3411, "Intervene")
print("✓ utility spell IDs present")

assert(type(Spells.defensive_bar_order) == "table", "defensive_bar_order missing")
assert(#Spells.defensive_bar_order == 8, "defensive_bar_order should have 8 entries")
print("✓ defensive bar order defined")
