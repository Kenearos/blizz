local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/reflect_spells.lua
-- Reflektierbare Casts. Map [spellID] = { name = "X", source = "Dungeon/NPC" }.
-- Starter-Liste — wird beim Spielen erweitert. Wenn ein Mob einen reflektierbaren
-- Cast macht und nicht in dieser Tabelle steht, einfach hier eintragen + commit.
--
-- WICHTIG: Spell Reflection (23920) reflektiert nur single-target magische Casts.
-- AoE-Magic-Casts (z.B. Dragon's Breath) sind NICHT reflektierbar. Multi-Target-Casts
-- ebenfalls nicht. Diese Liste enthält nur bestätigt reflektierbare Mob-Casts.

local ReflectSpells = {
	-- Format-Vorlage (auskommentiert):
	-- [12345] = { name = "Spell Name", source = "Dungeon/MobName" },
}

addon.ReflectSpells = ReflectSpells
return ReflectSpells
