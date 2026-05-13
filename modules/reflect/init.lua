local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/reflect/init.lua
-- Reflect-Indicator: hört auf UNIT_SPELLCAST_START von nameplate-Units (NICHT player),
-- matched gegen data/reflect_spells.lua, blendet Pulsing-Alert ein wenn Match.

local Alert = addon.Alert or require("ui.widgets.alert")

local Reflect = {
	id = "reflect",
	events = {
		"UNIT_SPELLCAST_START",
		"UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_INTERRUPTED",
		"UNIT_SPELLCAST_SUCCEEDED",
	},
}

local function is_player_unit(unit)
	return unit == "player" or unit == "pet"
end

function Reflect:init()
	self.alert = Alert:new({
		name = "BlizzReflectAlert",
		parent = UIParent,
		text = "REFLECT INCOMING",
		width = 260,
		height = 32,
	})
	addon.restorePosition(self.alert, self.id, "CENTER", 144, 30)
	self.active_casts = {} -- castGUID → spellID currently flagged
end

function Reflect:onEvent(event, unit, castGUID, spellID)
	if is_player_unit(unit) then
		return
	end
	if event == "UNIT_SPELLCAST_START" then
		local entry = addon.ReflectSpells and addon.ReflectSpells[spellID]
		if entry then
			self.active_casts[castGUID or tostring(spellID)] = spellID
			self.alert:setText("REFLECT: " .. (entry.name or tostring(spellID)))
			self.alert:show()
		end
	elseif
		event == "UNIT_SPELLCAST_STOP"
		or event == "UNIT_SPELLCAST_INTERRUPTED"
		or event == "UNIT_SPELLCAST_SUCCEEDED"
	then
		self.active_casts[castGUID or tostring(spellID)] = nil
		if next(self.active_casts) == nil then
			self.alert:hide()
		end
	end
end

addon.registerModule(Reflect)
return Reflect
