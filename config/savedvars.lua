local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- config/savedvars.lua
-- BlizzDB lifecycle: erstmaliges Anlegen, Version-Migration, Profil-Lookup.
-- BlizzDB ist eine SavedVariables-Tabelle (siehe Blizz.toc ## SavedVariables: BlizzDB).

local SavedVars = {}
local CURRENT_VERSION = 1

local function default_profile()
	return {
		positions = {}, -- [moduleId] = {x, y, anchor, relativeAnchor}
		disabled = {}, -- [moduleId] = true
		hero_talent = "auto", -- "auto" | "mountain_thane" | "colossus"
		theme_overrides = {},
		module_options = {
			mitigation = { show_charges = true, show_absorb_value = true },
			kickrota = { announce_to_party = false },
			nameplates = { override_default = false },
		},
	}
end

local function default_db()
	return {
		version = CURRENT_VERSION,
		active_profile = "default",
		profiles = { default = default_profile() },
		errors = {},
	}
end

local migrators = {
	-- migration step: 0 → 1 (initial)
	[0] = function(db)
		local fresh = default_db()
		for k, v in pairs(fresh) do
			if db[k] == nil then
				db[k] = v
			end
		end
		db.version = 1
		return db
	end,
}

function SavedVars:load()
	if _G.BlizzDB == nil or next(_G.BlizzDB) == nil then
		_G.BlizzDB = default_db()
		return _G.BlizzDB
	end
	local v = _G.BlizzDB.version or 0
	while v < CURRENT_VERSION do
		local mig = migrators[v]
		if not mig then
			break
		end
		_G.BlizzDB = mig(_G.BlizzDB)
		v = _G.BlizzDB.version
	end
	return _G.BlizzDB
end

function SavedVars:getCurrentProfile()
	local db = _G.BlizzDB
	if not db then
		return nil
	end
	return db.profiles[db.active_profile]
end

function SavedVars:getModuleOption(moduleId, key)
	local p = self:getCurrentProfile()
	if not p or not p.module_options[moduleId] then
		return nil
	end
	return p.module_options[moduleId][key]
end

-- Position-Persistenz (I-08): jedes Modul speichert sein Frame-Anchor in
-- BlizzDB.profiles[active].positions[moduleId] = { anchor, relativeAnchor, x, y }.
-- Wird beim Bootstrap via addon.restorePosition() gelesen; beim OnDragStop
-- via setPosition() geschrieben.

function SavedVars:getPosition(moduleId)
	local p = self:getCurrentProfile()
	if not p then
		return nil
	end
	p.positions = p.positions or {}
	return p.positions[moduleId]
end

function SavedVars:setPosition(moduleId, anchor, x, y, relativeAnchor)
	local p = self:getCurrentProfile()
	if not p then
		return
	end
	p.positions = p.positions or {}
	p.positions[moduleId] = {
		anchor = anchor or "CENTER",
		relativeAnchor = relativeAnchor or anchor or "CENTER",
		x = tonumber(x) or 0,
		y = tonumber(y) or 0,
	}
end

function SavedVars:clearPosition(moduleId)
	local p = self:getCurrentProfile()
	if p and p.positions then
		p.positions[moduleId] = nil
	end
end

addon.SavedVars = SavedVars
return SavedVars
