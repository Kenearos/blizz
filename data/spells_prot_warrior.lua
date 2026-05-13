local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/spells_prot_warrior.lua
-- Spell-IDs für Protection Warrior in WoW Midnight 12.0.5.
-- Quelle: Wowhead + Class-Guides. Bei jedem WoW-Patch verifizieren.
-- Hero-Talent-spezifische Spells (Mountain Thane / Colossus) hier NICHT enthalten —
-- werden in einer eigenen Phase nachgepflegt sobald Talents implementiert sind.

local Spells = {}

Spells.active_mitigation = {
	shield_block = 2565, -- 6s aura, +Block-Chance, blockt magic damage mit Heavy Repercussions talent
	ignore_pain = 190456, -- absorb buff, 40 rage cost, off-GCD
}

Spells.defensives = {
	shield_wall = 871, -- 8s, 40% DR, ~3.5min CD
	last_stand = 12975, -- 15s, +30% max HP
	spell_reflection = 23920, -- 5s, reflektiert nächsten Single-Target-Spell
	demoralizing_shout = 1160, -- 8s, -20% damage from affected enemies
	rallying_cry = 97462, -- 10s, +15% HP group-wide
	avatar = 107574, -- offensive but pairs with defensives (CD-rotation)
	demoralizing_banner = 236320, -- talented (Bannerlord), platziert Banner
	charge = 100, -- mobility/Charge-Pool
}

Spells.utility = {
	pummel = 6552, -- interrupt, 15s CD (with talents)
	heroic_leap = 6544, -- jump mobility
	intervene = 3411, -- friendly Charge
	berserker_rage = 18499, -- fear-break, rage burst
}

-- Reihenfolge im Defensive-CD-Bar (links nach rechts)
Spells.defensive_bar_order = {
	Spells.defensives.shield_wall,
	Spells.defensives.last_stand,
	Spells.defensives.spell_reflection,
	Spells.defensives.demoralizing_shout,
	Spells.defensives.rallying_cry,
	Spells.defensives.avatar,
	Spells.defensives.demoralizing_banner,
	Spells.defensives.charge,
}

-- Convenience: Reverse-Lookup spellID → label (für Icon-Beschriftung)
Spells.labels = {
	[2565] = "SBLK",
	[190456] = "IP",
	[871] = "WALL",
	[12975] = "LS",
	[23920] = "SPRFL",
	[1160] = "DEMO",
	[97462] = "RALLY",
	[107574] = "AVTR",
	[236320] = "BNR",
	[100] = "CHA",
	[6552] = "PMML",
	[6544] = "LEAP",
	[3411] = "ITVN",
	[18499] = "BRSK",
}

addon.SpellsProtWarrior = Spells
return Spells
