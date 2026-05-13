require("tests.mocks.wow_api")
local SavedVars = require("config.savedvars")

-- erster Load: erzeugt Defaults
_G.BlizzDB = nil
local db = SavedVars:load()
assert(db.version == 1, "version should be 1, got " .. tostring(db.version))
assert(db.active_profile == "default", "active_profile should be 'default'")
assert(db.profiles.default, "profiles.default missing")
assert(db.profiles.default.hero_talent == "auto", "hero_talent default should be 'auto'")
assert(type(db.profiles.default.positions) == "table", "positions table missing")
assert(type(db.profiles.default.disabled) == "table", "disabled table missing")
assert(type(db.profiles.default.module_options) == "table", "module_options missing")
assert(type(db.errors) == "table", "errors table missing")
print("✓ first-load creates correct defaults")

-- zweiter Load: behält bestehende Daten
_G.BlizzDB = {
	version = 1,
	active_profile = "raid",
	profiles = {
		raid = { positions = {}, disabled = {}, module_options = {}, hero_talent = "colossus" },
	},
	errors = {},
}
local db2 = SavedVars:load()
assert(db2.active_profile == "raid", "should preserve active_profile")
assert(db2.profiles.raid.hero_talent == "colossus", "should preserve hero_talent")
print("✓ second-load preserves existing data")

-- getCurrentProfile gibt aktives Profil zurück
_G.BlizzDB = nil
SavedVars:load()
local p = SavedVars:getCurrentProfile()
assert(p.hero_talent == "auto", "current profile should be default")
print("✓ getCurrentProfile works")

-- migration: version 0 → 1 fügt fehlende Felder hinzu
_G.BlizzDB = { version = 0 }
local db3 = SavedVars:load()
assert(db3.version == 1, "migration should bump version to 1")
assert(db3.profiles, "migration should populate profiles")
print("✓ migration v0 → v1 works")
