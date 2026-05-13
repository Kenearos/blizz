#!/usr/bin/env luajit
-- scripts/import-mdt-reflect-candidates.lua
-- Liest MDT's Midnight-S1-Dungeon-Files und emittiert eine KANDIDATEN-Liste
-- reflektierbarer Casts. Quelle: jeder Mob-Spell mit ["magic"]=true wird gelistet.
--
-- WARNUNG: Die Liste hat HOHE FALSE-POSITIVE-RATE.
-- 'magic' bei MDT = magischer Schadenstyp, NICHT zwangsläufig reflektierbar.
-- Spell Reflection (23920) reflektiert nur SINGLE-TARGET-Magic-Casts mit Cast-Time.
-- AoE-Magic, instant-casts und Channels sind NICHT reflektierbar.
--
-- Diese Liste ist ein Starter. Beim Spielen unbrauchbare Einträge entfernen,
-- bestätigte ergänzen.
--
-- Usage: luajit scripts/import-mdt-reflect-candidates.lua > data/reflect_spells.lua

local MDT_ROOT = os.getenv("HOME")
	.. "/Games/battlenet/World of Warcraft/_retail_/Interface/AddOns/MythicDungeonTools"
local MIDNIGHT_DIR = MDT_ROOT .. "/Midnight"

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

local function list_files(dir)
	local out = {}
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

local function load_dungeon(filepath)
	local f, err = loadfile(filepath, "bt", _G)
	if not f then
		io.stderr:write("loadfile error: " .. tostring(err) .. "\n")
		return
	end
	setfenv(f, _G)
	local ok, exec_err = pcall(f, "MythicDungeonTools")
	if not ok then
		io.stderr:write("exec error in " .. filepath .. ": " .. tostring(exec_err) .. "\n")
	end
end

local files = list_files(MIDNIGHT_DIR)
io.stderr:write("Loading " .. #files .. " MDT Midnight files...\n")
for _, f in ipairs(files) do
	load_dungeon(f)
end

-- Collect magic-flagged spells per dungeon
local candidates = {} -- [spellID] = { mob_name, dungeon }
for dungeonIndex, _ in pairs(MDT.dungeonList) do
	local mapInfo = MDT.mapInfo[dungeonIndex] or {}
	local dungeonName = mapInfo.englishName or ("Dungeon-" .. dungeonIndex)
	local enemies = MDT.dungeonEnemies[dungeonIndex] or {}

	for _, e in pairs(enemies) do
		if type(e) == "table" and e.spells then
			for spellID, info in pairs(e.spells) do
				if type(info) == "table" and info.magic then
					candidates[spellID] = candidates[spellID]
						or { mob = e.name or "?", dungeon = dungeonName }
				end
			end
		end
	end
end

local total = 0
for _ in pairs(candidates) do
	total = total + 1
end

local out = {}
table.insert(out, "local _, addon = ...")
table.insert(out, "if not addon then")
table.insert(out, "\taddon = _G.Blizz or {}")
table.insert(out, "\t_G.Blizz = addon")
table.insert(out, "end")
table.insert(out, "")
table.insert(out, "-- data/reflect_spells.lua")
table.insert(out, "-- AUTO-GENERATED candidate list from MDT magic-flagged mob spells.")
table.insert(out, "-- Generator: scripts/import-mdt-reflect-candidates.lua")
table.insert(out, "--")
table.insert(out, "-- WARNUNG: HOHE FALSE-POSITIVE-RATE.")
table.insert(out, "-- 'magic' in MDT = magischer Schadenstyp, NICHT zwangsläufig reflektierbar.")
table.insert(
	out,
	"-- Spell Reflection (23920) reflektiert nur Single-Target-Magic-Casts mit Cast-Time."
)
table.insert(
	out,
	"-- Beim Spielen unbrauchbare Einträge entfernen, bestätigte werden vom Modul gehighlightet."
)
table.insert(out, "--")
table.insert(
	out,
	"-- Re-Import: `luajit scripts/import-mdt-reflect-candidates.lua > data/reflect_spells.lua`"
)
table.insert(out, "")
table.insert(out, "local ReflectSpells = {")

-- Sort by spellID for stable output
local sorted_ids = {}
for id in pairs(candidates) do
	table.insert(sorted_ids, id)
end
table.sort(sorted_ids)

for _, id in ipairs(sorted_ids) do
	local c = candidates[id]
	table.insert(
		out,
		string.format(
			"\t[%d] = { name = %q, source = %q }, -- mob: %s",
			id,
			c.mob,
			c.dungeon,
			c.mob
		)
	)
end

table.insert(out, "}")
table.insert(out, "")
table.insert(out, "addon.ReflectSpells = ReflectSpells")
table.insert(out, "return ReflectSpells")

print(table.concat(out, "\n"))

io.stderr:write(string.format("\nDone: %d candidate reflect spells\n", total))
