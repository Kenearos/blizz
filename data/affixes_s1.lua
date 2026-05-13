local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/affixes_s1.lua
-- Xal'atath's Bargain Affix-Spawns für M+ Season 1 (Midnight 12.0.5).
-- Pro Bargain: Spawn-NPC-IDs + Alert-Text.
-- NPC-IDs müssen pro Patch verifiziert werden (Wowhead).
-- Starter — wenn ein Affix-Spawn auftaucht und nicht in dieser Tabelle steht,
-- einfach hier eintragen + commit.

local Affixes = {}

Affixes.voidbound = {
	name = "Voidbound",
	spawn_npcs = {
		-- [npcID] = display name
		-- Beispiel-IDs sind Platzhalter — beim ersten Spawn in WoW notieren und einsetzen
	},
	alert_text = "VOIDBOUND EMISSARY — switch & kick Dark Prayer",
}

Affixes.pulsar = {
	name = "Pulsar",
	spawn_npcs = {},
	alert_text = "PULSAR BEAM — avoid the line",
}

Affixes.devour = {
	name = "Devour",
	spawn_npcs = {},
	alert_text = "DEVOUR STACK — dispel/clear stacks",
}

Affixes.ascendant = {
	name = "Ascendant",
	spawn_npcs = {},
	alert_text = "ASCENDANT — priority kill",
}

-- Lookup-Table: [npcID] = { bargain, alert_text }
Affixes.npcLookup = {}
for bargainKey, bargain in pairs(Affixes) do
	if type(bargain) == "table" and bargain.spawn_npcs then
		for npcID, _name in pairs(bargain.spawn_npcs) do
			Affixes.npcLookup[npcID] = { bargain = bargainKey, alert_text = bargain.alert_text }
		end
	end
end

addon.AffixesS1 = Affixes
return Affixes
