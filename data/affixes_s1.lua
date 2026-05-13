local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/affixes_s1.lua
-- Xal'atath's Bargain Affix-Spawns für M+ Season 1 (Midnight 12.0.5).
-- Pro Bargain: Spawn-NPC-IDs + Alert-Text.
--
-- Quellen für die hier hinterlegten IDs:
--   * Wowhead NPC-Datenbank (npc=<id>, gepingt 2026-05)
--   * Wowhead News-Posts zu den jeweiligen Bargain-Affixen
--   * MDT/BigWigs/LittleWigs lieferten KEINE Affix-Spawn-IDs
--     (sie tracken nur normale Dungeon-Mobs, nicht das Xal-Overlay)
--
-- NPC-IDs sollten pro Patch verifiziert werden. Wenn neue IDs auftauchen,
-- gerne via /blizz capture <bargain> in-game sammeln und hier eintragen.

local Affixes = {}

Affixes.voidbound = {
	name = "Voidbound",
	spawn_npcs = {
		-- Wowhead: https://www.wowhead.com/npc=229537/voidbound-emissary
		-- Level 80 Elite, spawnt mit Absorb-Shield, castet "Dark Prayer".
		[229537] = "Voidbound Emissary",
	},
	alert_text = "VOIDBOUND EMISSARY — switch & kick Dark Prayer",
}

Affixes.pulsar = {
	name = "Pulsar",
	spawn_npcs = {
		-- Wowhead: https://www.wowhead.com/npc=250271/wandering-pulsar
		-- Midnight-Variante; orbiting pulsar object.
		[250271] = "Wandering Pulsar",
		-- Wowhead: https://www.wowhead.com/npc=180433/wandering-pulsar
		-- Älteres Tazavesh-Modell — Blizzard recycelt manchmal die alte ID.
		-- candidate, verify in-game
		[180433] = "Wandering Pulsar (legacy)",
		-- Wowhead: https://www.wowhead.com/npc=257809/void-pulsar
		-- Datamined Midnight-Variante in einigen Dungeons.
		-- candidate, verify in-game
		[257809] = "Void Pulsar",
	},
	alert_text = "PULSAR BEAM — avoid the line",
}

Affixes.devour = {
	name = "Devour",
	spawn_npcs = {
		-- Wowhead: https://www.wowhead.com/npc=257810/devouring-rift
		-- Rift-Objekt mit Devouring-Essence-DoT.
		[257810] = "Devouring Rift",
	},
	alert_text = "DEVOUR STACK — dispel/clear stacks",
}

Affixes.ascendant = {
	name = "Ascendant",
	spawn_npcs = {
		-- Wowhead: https://www.wowhead.com/npc=229296/orb-of-ascendance
		-- 10 Orbs spawnen alle 60s, casten "Cosmic Ascension".
		[229296] = "Orb of Ascendance",
		-- Wowhead: https://www.wowhead.com/npc=143017/voidborne-ascendant
		-- Legacy / Stormsong Valley — fraglich für aktuellen S1, aber sicherheitshalber.
		-- candidate, verify in-game
		[143017] = "Voidborne Ascendant (legacy)",
	},
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
