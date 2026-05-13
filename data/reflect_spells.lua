local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/reflect_spells.lua
-- AUTO-GENERATED candidate list from MDT magic-flagged mob spells.
-- Generator: scripts/import-mdt-reflect-candidates.lua
--
-- WARNUNG: HOHE FALSE-POSITIVE-RATE.
-- 'magic' in MDT = magischer Schadenstyp, NICHT zwangsläufig reflektierbar.
-- Spell Reflection (23920) reflektiert nur Single-Target-Magic-Casts mit Cast-Time.
-- Beim Spielen unbrauchbare Einträge entfernen, bestätigte werden vom Modul gehighlightet.
--
-- Re-Import: `luajit scripts/import-mdt-reflect-candidates.lua > data/reflect_spells.lua`

local ReflectSpells = {
	[374350] = { name = "Echo of Doragosa", source = "Algethar Academy" }, -- mob: Echo of Doragosa
	[388392] = { name = "Unruly Textbook", source = "Algethar Academy" }, -- mob: Unruly Textbook
	[468966] = { name = "Arcane Magister", source = "Magisters Terrace" }, -- mob: Arcane Magister
	[1214038] = { name = "Arcanotron Custos", source = "Magisters Terrace" }, -- mob: Arcanotron Custos
	[1216298] = { name = "Restless Steward", source = "Windrunner Spire" }, -- mob: Restless Steward
	[1216860] = { name = "Territorial Dragonhawk", source = "Windrunner Spire" }, -- mob: Territorial Dragonhawk
	[1245068] = { name = "Void Infuser", source = "Magisters Terrace" }, -- mob: Void Infuser
	[1248689] = { name = "Seranel Sunlash", source = "Magisters Terrace" }, -- mob: Seranel Sunlash
	[1249815] = { name = "Corewright Arcanist", source = "Nexus Point Xenas" }, -- mob: Corewright Arcanist
	[1254306] = { name = "Lightward Healer", source = "Magisters Terrace" }, -- mob: Lightward Healer
	[1254670] = { name = "Blooded Bladefeather", source = "Skyreach" }, -- mob: Blooded Bladefeather
	[1255187] = { name = "Lightward Healer", source = "Magisters Terrace" }, -- mob: Lightward Healer
	[1255434] = { name = "Voidling", source = "Magisters Terrace" }, -- mob: Voidling
	[1256008] = { name = "Ritual Hexxer", source = "Maisara Caverns" }, -- mob: Ritual Hexxer
	[1258437] = { name = "Rimebone Coldwraith", source = "Pit of Saron" }, -- mob: Rimebone Coldwraith
	[1258448] = { name = "Deathwhisper Necrolyte", source = "Pit of Saron" }, -- mob: Deathwhisper Necrolyte
	[1258806] = { name = "Hex Guardian", source = "Maisara Caverns" }, -- mob: Hex Guardian
	[1259255] = { name = "Tormented Shade", source = "Maisara Caverns" }, -- mob: Tormented Shade
	[1260709] = { name = "Muro'jin", source = "Maisara Caverns" }, -- mob: Muro'jin
	[1261921] = { name = "Forgemaster Garfrost", source = "Pit of Saron" }, -- mob: Forgemaster Garfrost
	[1262526] = { name = "Dire Voidbender", source = "Seat of the Triumvirate" }, -- mob: Dire Voidbender
	[1263783] = { name = "Flarebat", source = "Nexus Point Xenas" }, -- mob: Flarebat
	[1265561] = { name = "Sunblade Enforcer", source = "Magisters Terrace" }, -- mob: Sunblade Enforcer
	[1270079] = { name = "Grim Skirmisher", source = "Maisara Caverns" }, -- mob: Grim Skirmisher
	[1271623] = { name = "Hollow Soulrender", source = "Maisara Caverns" }, -- mob: Hollow Soulrender
	[1273356] = { name = "Blinding Sun Priestess", source = "Skyreach" }, -- mob: Blinding Sun Priestess
	[1277557] = { name = "Lightwrought", source = "Nexus Point Xenas" }, -- mob: Lightwrought
	[1280330] = { name = "Rift Warden", source = "Seat of the Triumvirate" }, -- mob: Rift Warden
	[1282055] = { name = "Arcane Sentry", source = "Magisters Terrace" }, -- mob: Arcane Sentry
	[1284627] = { name = "Degentrius", source = "Magisters Terrace" }, -- mob: Degentrius
}

addon.ReflectSpells = ReflectSpells
return ReflectSpells
