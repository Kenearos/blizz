local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/tankbusters_s1.lua
-- Static-DB tank-buster mob-casts für Midnight S1 dungeons.
-- Map [spellID] = { name, severity, suggest }
--   severity = "high"   → großer Defensive (Shield Wall / Last Stand)
--   severity = "medium" → kleiner Defensive (Ignore Pain / Demo Shout)
-- suggest = symbolic key for which defensive to use; modul rendert text daraus.
--
-- Starter — fülle beim Spielen nach.

local TankBusters = {
	-- Format-Vorlage (auskommentiert):
	-- [123456] = { name = "Crushing Slam", severity = "high",   suggest = "shield_wall" },
	-- [234567] = { name = "Heavy Blow",    severity = "medium", suggest = "ignore_pain" },
}

addon.TankBustersS1 = TankBusters
return TankBusters
