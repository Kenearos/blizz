local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/party_interrupts.lua
-- Interrupt-Spells pro Klasse (Stand Midnight 12.0.5).
-- Map [classToken] = { spellID, name, default_cd, kickable_only_against = "any" | "casts" }.
-- classToken ist der WoW-API-Token aus UnitClass(unit) zweiter Rückgabewert.

local Interrupts = {
	WARRIOR = { spellID = 6552, name = "Pummel", default_cd = 15 },
	PALADIN = { spellID = 96231, name = "Rebuke", default_cd = 15 },
	HUNTER = { spellID = 147362, name = "Counter Shot", default_cd = 24 },
	ROGUE = { spellID = 1766, name = "Kick", default_cd = 15 },
	PRIEST = { spellID = 15487, name = "Silence", default_cd = 45 }, -- Shadow only
	DEATHKNIGHT = { spellID = 47528, name = "Mind Freeze", default_cd = 15 },
	SHAMAN = { spellID = 57994, name = "Wind Shear", default_cd = 12 },
	MAGE = { spellID = 2139, name = "Counterspell", default_cd = 24 },
	WARLOCK = { spellID = 19647, name = "Spell Lock", default_cd = 24 }, -- Felhunter pet
	MONK = { spellID = 116705, name = "Spear Hand Strike", default_cd = 15 },
	DRUID = { spellID = 106839, name = "Skull Bash", default_cd = 15 }, -- Feral/Guardian
	DEMONHUNTER = { spellID = 183752, name = "Disrupt", default_cd = 15 },
	EVOKER = { spellID = 351338, name = "Quell", default_cd = 40 },
}

addon.PartyInterrupts = Interrupts
return Interrupts
