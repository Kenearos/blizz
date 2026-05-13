local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/tankbusters_s1.lua
-- Static-DB tank-buster mob-casts für Midnight S1 dungeons.
-- Map [spellID] = { name, severity, suggest, source }
--   severity = "high"   → großer Defensive (Shield Wall / Last Stand)
--   severity = "medium" → kleiner Defensive (Ignore Pain / Demo Shout)
-- suggest = symbolic key for which defensive to use; modul rendert text daraus.
--
-- Quellen (verifiziert Mai 2026):
--   * Höchste Konfidenz: LittleWigs-Module mit explizitem TANK_HEALER-Marker
--   * Mittlere Konfidenz: LittleWigs CASTBAR-Flagged heavy casts
--   * Niedrige Konfidenz: Spell-Name-Archetyp (z.B. Orebreaker = klassischer Tank-Buster)
--     — bei In-Game-Validation ggf. severity nachregulieren.
--
-- Erweitern: /blizz capture-mode oder direkt hier neue Zeilen einfügen.
-- Maisara Caverns + Murder Row haben keine klassischen Tank-Buster (mechanic-driven).

local TankBusters = {
	-- =========================================================================
	-- Windrunner Spire
	-- =========================================================================
	[466064] = {
		name = "Searing Beak",
		severity = "medium",
		suggest = "demo_shout",
		source = "Windrunner Spire/Emberdawn — TANK_HEALER magic",
	},
	[467620] = {
		name = "Rampage",
		severity = "high",
		suggest = "shield_wall",
		source = "Windrunner Spire/Commander Kroluk — TANK_HEALER physical buildup",
	},
	[472888] = {
		name = "Bone Hack",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Windrunner Spire/Derelict Duo — TANK_HEALER physical stack",
	},

	-- =========================================================================
	-- Nexus-Point Xenas
	-- =========================================================================
	[1247937] = {
		name = "Umbral Lash",
		severity = "high",
		suggest = "shield_wall",
		source = "Nexus-Point Xenas/Nysarra — TANK_HEALER shadow heavy hit",
	},
	[1257509] = {
		name = "Corespark Detonation",
		severity = "medium",
		suggest = "demo_shout",
		source = "Nexus-Point Xenas/Kasreth — CASTBAR arcane heavy cast",
	},

	-- =========================================================================
	-- Algeth'ar Academy (Midnight-tuned)
	-- =========================================================================
	[376997] = {
		name = "Savage Peck",
		severity = "high",
		suggest = "shield_wall",
		source = "Algeth'ar Academy/Crawth — TANK_HEALER big physical melee",
	},
	[388544] = {
		name = "Barkbreaker",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Algeth'ar Academy/Overgrown Ancient — TANK_HEALER physical stack",
	},
	[1282251] = {
		name = "Astral Blast",
		severity = "high",
		suggest = "shield_wall",
		source = "Algeth'ar Academy/Echo of Doragosa — TANK_HEALER arcane (Midnight retune)",
	},
	[388911] = {
		name = "Severing Slash",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Algeth'ar Academy/Trash (Faculty Specter) — TANK",
	},
	[377991] = {
		name = "Storm Slash",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Algeth'ar Academy/Trash (Storm Crawler) — TANK",
	},

	-- =========================================================================
	-- Seat of the Triumvirate (Midnight-tuned)
	-- =========================================================================
	[1263440] = {
		name = "Void Slash",
		severity = "high",
		suggest = "shield_wall",
		source = "Seat of the Triumvirate/Zuraal — TANK_HEALER big void hit",
	},

	-- =========================================================================
	-- Skyreach (Midnight-tuned + legacy fallback IDs)
	-- =========================================================================
	[1253519] = {
		name = "Burning Claws",
		severity = "high",
		suggest = "shield_wall",
		source = "Skyreach/Rukhran — TANK_HEALER big fire/physical (Midnight retune)",
	},
	[153794] = {
		name = "Pierce Armor",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Skyreach/Rukhran — TANK physical armor-debuff (legacy WoD ID)",
	},
	[154110] = {
		name = "Smash",
		severity = "high",
		suggest = "shield_wall",
		source = "Skyreach/Araknath — TANK big physical melee (legacy)",
	},

	-- =========================================================================
	-- Magisters' Terrace (Midnight-tuned)
	-- =========================================================================
	[474345] = {
		name = "Refueling Protocol",
		severity = "medium",
		suggest = "demo_shout",
		source = "Magisters' Terrace/Arcanotron Custos — CASTBAR magic",
	},
	[1225193] = {
		name = "Wave of Silence",
		severity = "medium",
		suggest = "demo_shout",
		source = "Magisters' Terrace/Seranel Sunlash — CASTBAR arcane wave",
	},

	-- =========================================================================
	-- Pit of Saron (Midnight retune; severity = best-guess, in-game verify)
	-- =========================================================================
	[1261546] = {
		name = "Orebreaker",
		severity = "high",
		suggest = "shield_wall",
		source = "Pit of Saron/Forgemaster Garfrost — physical Tank-Buster archetype (Midnight)",
	},
	[1261847] = {
		name = "Cryostomp",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Pit of Saron/Forgemaster Garfrost — frost slam (Midnight)",
	},
	[1262745] = {
		name = "Rime Blast",
		severity = "medium",
		suggest = "demo_shout",
		source = "Pit of Saron/Tyrannus — frost cast (Midnight retune)",
	},
	[1264287] = {
		name = "Blight Smash",
		severity = "medium",
		suggest = "ignore_pain",
		source = "Pit of Saron/Ick and Krick — physical smash (Midnight retune)",
	},
}

addon.TankBustersS1 = TankBusters
return TankBusters
