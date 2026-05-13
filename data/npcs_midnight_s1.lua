local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/npcs_midnight_s1.lua
-- Mob-Klassifizierung für Midnight Season 1 Dungeons.
-- Map [npcID] = { category, name?, dungeon? }
--
-- Kategorien:
--   "caster"        — Kick-Priority (Magenta-Plate gefüllt)
--   "frontal"       — Frontal-Cone-Damage (Teal-Outline)
--   "healer"        — Healer (Lime-Plate gefüllt, Top-Kill)
--   "priority_kill" — High-HP/Important target (Red-Outline + Skull)
--   "generic"       — Default-Plate, kein Overlay
--
-- Starter — kann beim Spielen erweitert werden. Quelle: MDT-Datenbank
-- (https://github.com/Nnoggie/MythicDungeonTools) sobald per Phase importiert.

local NPCs = {}

-- Beispiel-Format (auskommentiert):
-- [123456] = { category = "caster",        name = "Voidbound Cultist",   dungeon = "Maisara Caverns" },
-- [234567] = { category = "frontal",       name = "Frostfang Hunter",    dungeon = "Windrunner Spire" },
-- [345678] = { category = "healer",        name = "Cult Surgeon",        dungeon = "Maisara Caverns" },
-- [456789] = { category = "priority_kill", name = "Elite Warleader",     dungeon = "Nexus-Point Xenas" },

addon.NPCsMidnightS1 = NPCs
return NPCs
