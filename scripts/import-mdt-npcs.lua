#!/usr/bin/env luajit
-- scripts/import-mdt-npcs.lua
-- Liest MDT's Midnight-S1-Dungeon-Files und emittiert blizz/data/npcs_midnight_s1.lua
-- mit allen NPCs + Heuristik-basierter Kategorisierung.
--
-- Heuristik:
--   name matched "healer|priest|mender|cleric|surgeon|shaman"           → healer
--   name matched "caster|mage|warlock|sorcerer|spellweaver|mystic"
--     ODER hat einen Spell mit ["magic"]=true                            → caster
--   health >= 2x dungeon-Median                                          → priority_kill
--   sonst                                                                → generic
--
-- Usage: luajit scripts/import-mdt-npcs.lua > data/npcs_midnight_s1.lua

local MDT_ROOT = os.getenv("HOME")
	.. "/Games/battlenet/World of Warcraft/_retail_/Interface/AddOns/MythicDungeonTools"
local MIDNIGHT_DIR = MDT_ROOT .. "/Midnight"

-- Stub the MDT globals + L localization
_G.MDT = {
	dungeonList = {},
	dungeonEnemies = {},
	dungeonMaps = {},
	dungeonSubLevels = {},
	dungeonTotalCount = {},
	mapInfo = {},
	mapPOIs = {},
	zoneIdToDungeonIdx = {},
	L = setmetatable({}, {
		__index = function(_, k)
			return k
		end,
	}),
}
MDT.L = MDT.L

-- Iterate Midnight dungeon files
local function list_files(dir)
	local out = {}
	-- Quote the directory to survive spaces in path
	local cmd = string.format("ls %q/*.lua 2>/dev/null", dir)
	local p = io.popen(cmd)
	if p then
		for line in p:lines() do
			table.insert(out, line)
		end
		p:close()
	end
	return out
end

-- Map dungeonIndex → friendly name (parse from englishName in mapInfo)
local function load_dungeon(filepath)
	local addonName = "MythicDungeonTools"
	local f, err = loadfile(filepath, "bt", _G)
	if not f then
		io.stderr:write("loadfile error: " .. tostring(err) .. "\n")
		return
	end
	-- Execute with arg "MythicDungeonTools" (addonName), simulating addon load
	setfenv(f, _G)
	local ok, exec_err = pcall(f, addonName)
	if not ok then
		io.stderr:write("exec error in " .. filepath .. ": " .. tostring(exec_err) .. "\n")
	end
end

local files = list_files(MIDNIGHT_DIR)
io.stderr:write("Loading " .. #files .. " MDT Midnight files...\n")
for _, f in ipairs(files) do
	load_dungeon(f)
end

-- Classification heuristics
local HEALER_PATTERNS =
	{ "[Hh]ealer", "[Pp]riest", "[Mm]ender", "[Cc]leric", "[Ss]urgeon", "[Ss]haman", "[Dd]ruid" }
local CASTER_PATTERNS = {
	"[Cc]aster",
	"[Mm]age",
	"[Ww]arlock",
	"[Ss]orcerer",
	"[Ss]pellweaver",
	"[Mm]ystic",
	"[Ss]eer",
	"[Ss]ummoner",
	"[Ee]vocaty",
	"[Cc]ultist",
	"[Cc]onjurer",
}

local function name_matches(name, patterns)
	for _, p in ipairs(patterns) do
		if name:match(p) then
			return true
		end
	end
	return false
end

local function has_magic_spell(spells)
	for _, info in pairs(spells or {}) do
		if type(info) == "table" and info.magic then
			return true
		end
	end
	return false
end

-- Per dungeon: compute health median to flag priority_kill
local function compute_median(values)
	if #values == 0 then
		return 0
	end
	table.sort(values)
	local mid = math.ceil(#values / 2)
	return values[mid]
end

-- Walk dungeons + emit
local out = {}
table.insert(out, "local _, addon = ...")
table.insert(out, "if not addon then")
table.insert(out, "\taddon = _G.Blizz or {}")
table.insert(out, "\t_G.Blizz = addon")
table.insert(out, "end")
table.insert(out, "")
table.insert(out, "-- data/npcs_midnight_s1.lua")
table.insert(out, "-- AUTO-GENERATED from MDT (MythicDungeonTools) Midnight-S1 dungeon data.")
table.insert(out, "-- Generator: scripts/import-mdt-npcs.lua")
table.insert(
	out,
	"-- Re-run after MDT updates: `luajit scripts/import-mdt-npcs.lua > data/npcs_midnight_s1.lua`"
)
table.insert(out, "--")
table.insert(out, "-- Kategorien:")
table.insert(out, "--   'caster'        — name hint or magic-flagged spell")
table.insert(out, "--   'healer'        — name hint (priest/mender/etc.)")
table.insert(out, "--   'priority_kill' — health > 2x dungeon median")
table.insert(out, "--   'generic'       — default")
table.insert(
	out,
	"-- 'frontal' NICHT auto-erkannt — manuell in dieser DB nachpflegen falls relevant."
)
table.insert(out, "")
table.insert(out, "local NPCs = {}")
table.insert(out, "")

local total_npcs, by_category = 0, { caster = 0, healer = 0, priority_kill = 0, generic = 0 }

for dungeonIndex, _ in pairs(MDT.dungeonList) do
	local mapInfo = MDT.mapInfo[dungeonIndex] or {}
	local dungeonName = mapInfo.englishName or ("Dungeon-" .. dungeonIndex)
	local enemies = MDT.dungeonEnemies[dungeonIndex] or {}

	-- Compute health median for priority_kill detection
	local healths = {}
	for _, e in pairs(enemies) do
		if type(e) == "table" and e.health and e.health > 0 then
			table.insert(healths, e.health)
		end
	end
	local median_health = compute_median(healths)
	local priority_threshold = median_health * 2

	table.insert(out, "-- " .. dungeonName .. " (median HP: " .. math.floor(median_health) .. ")")
	for _, e in pairs(enemies) do
		if type(e) == "table" and e.id and e.name then
			local category = "generic"
			if name_matches(e.name, HEALER_PATTERNS) then
				category = "healer"
			elseif name_matches(e.name, CASTER_PATTERNS) or has_magic_spell(e.spells) then
				category = "caster"
			elseif e.health and e.health >= priority_threshold and priority_threshold > 0 then
				category = "priority_kill"
			end

			by_category[category] = by_category[category] + 1
			total_npcs = total_npcs + 1

			table.insert(
				out,
				string.format(
					"NPCs[%d] = { category = %q, name = %q, dungeon = %q }",
					e.id,
					category,
					e.name,
					dungeonName
				)
			)
		end
	end
	table.insert(out, "")
end

table.insert(out, "addon.NPCsMidnightS1 = NPCs")
table.insert(out, "return NPCs")

print(table.concat(out, "\n"))

io.stderr:write(
	string.format(
		"\nDone: %d NPCs total | caster=%d, healer=%d, priority_kill=%d, generic=%d\n",
		total_npcs,
		by_category.caster,
		by_category.healer,
		by_category.priority_kill,
		by_category.generic
	)
)
