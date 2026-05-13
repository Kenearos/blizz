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

-- I-04: Hero-Talent sub-tables (Mountain Thane + Colossus)
assert(type(Spells.hero_talent_mountain_thane) == "table", "mountain_thane sub-table missing")
local mt = Spells.hero_talent_mountain_thane
assert(mt.lightning_strikes == 434969, "Lightning Strikes")
assert(mt.thorims_might == 436152, "Thorim's Might")
assert(mt.thunder_blast == 435607, "Thunder Blast")
assert(mt.burst_of_power == 437121, "Burst of Power")
assert(mt.crashing_thunder == 436707, "Crashing Thunder")
assert(mt.ground_current == 436148, "Ground Current")
print("✓ 6 Mountain Thane hero-talent IDs present")

assert(type(Spells.hero_talent_colossus) == "table", "colossus sub-table missing")
local col = Spells.hero_talent_colossus
assert(col.demolish == 436358, "Demolish")
assert(col.earthquaker == 440992, "Earthquaker")
assert(col.boneshaker == 429639, "Boneshaker")
assert(col.practiced_strikes == 429647, "Practiced Strikes")
assert(col.tide_of_battle == 429641, "Tide of Battle")
assert(col.colossal_might == 440989, "Colossal Might")
assert(col.dominance_of_colossus == 429636, "Dominance of the Colossus")
print("✓ 7 Colossus hero-talent IDs present")

-- Demolish is also in defensives (10% DR during channel)
assert(Spells.defensives.demolish == 436358, "Demolish also in defensives table")
print("✓ Demolish cross-listed in defensives")
