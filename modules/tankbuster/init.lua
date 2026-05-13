local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/tankbuster/init.lua
-- Tank-Buster Alert: hört auf UNIT_SPELLCAST_START von nameplate-Units (NICHT player),
-- matched gegen data/tankbusters_s1.lua, blendet Pulsing-Alert mit Defensive-Suggestion
-- ein wenn Match.

local Alert = addon.Alert or require("ui.widgets.alert")

local SUGGEST_TEXT = {
	shield_wall = "PRESS SHIELD WALL",
	last_stand = "PRESS LAST STAND",
	ignore_pain = "USE IGNORE PAIN",
	demo_shout = "USE DEMO SHOUT",
	-- fallback handled by build_alert_text
}

local function is_player_unit(unit)
	return unit == "player" or unit == "pet"
end

local function build_alert_text(entry)
	local prefix = SUGGEST_TEXT[entry.suggest]
	if not prefix then
		prefix = (entry.severity == "high") and "DEFENSIVE — BIG" or "DEFENSIVE NEEDED"
	end
	return prefix .. " — " .. (entry.name or "?")
end

local TankBuster = {
	id = "tankbuster",
	events = {
		"UNIT_SPELLCAST_START",
		"UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_INTERRUPTED",
		"UNIT_SPELLCAST_SUCCEEDED",
	},
}

function TankBuster:init()
	self.alert = Alert:new({
		name = "BlizzTankBusterAlert",
		parent = UIParent,
		text = "TANKBUSTER",
		width = 280,
		height = 36,
	})
	addon.restorePosition(self.alert, self.id, "CENTER", 0, 90)
	self.active_casts = {} -- castGUID → spellID
end

function TankBuster:onEvent(event, unit, castGUID, spellID)
	if is_player_unit(unit) then
		return
	end
	if event == "UNIT_SPELLCAST_START" then
		local entry = addon.TankBustersS1 and addon.TankBustersS1[spellID]
		if entry then
			local was_active = next(self.active_casts) ~= nil
			self.active_casts[castGUID or tostring(spellID)] = spellID
			self.alert:setText(build_alert_text(entry))
			self.alert:show()
			-- Rising-edge sound cue — high severity gets the louder kit.
			if not was_active and PlaySound and SOUNDKIT then
				local kit = (entry.severity == "high") and SOUNDKIT.UI_ALERT_VIOLET_CHARGE_UP
					or SOUNDKIT.RAID_WARNING
				if kit then
					PlaySound(kit)
				end
			end
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

addon.registerModule(TankBuster)
return TankBuster
