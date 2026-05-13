local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/threat/init.lua
-- Threat-Status-Pill (Top-Strip) + Lost-Aggro-Pulse-Alert über Spieler.
-- pill.state == "ready" wenn tanking (Level 3), "alert" wenn Aggro verloren (Level 1-2).
-- Level 0 (kein Threat / out of combat) = default state.

local UnitState = addon.UnitState or require("core.unitstate")
local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")
local Alert = addon.Alert or require("ui.widgets.alert")

local Threat = {
	id = "threat",
	events = { "UNIT_THREAT_SITUATION_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
}

function Threat:init()
	self.pill = Frame:new({ name = "BlizzThreatPill", parent = UIParent, width = 78, height = 18 })
	self.pill:SetPoint("TOP", UIParent, "TOP", -120, -16)

	self.pill_label = Text:new({ parent = self.pill, text = "THREAT", style = "default" })
	if self.pill_label.SetPoint then
		self.pill_label:SetPoint("CENTER", self.pill, "CENTER", 0, 0)
	end

	self.lost_alert = Alert:new({
		name = "BlizzAggroLostAlert",
		parent = UIParent,
		text = "AGGRO LOST",
		width = 200,
		height = 28,
	})
	self.lost_alert:SetPoint("CENTER", UIParent, "CENTER", 0, 60)

	self:refresh()
end

function Threat:refresh()
	local level = UnitState:getThreatLevel("player", "target")
	if level == 3 then
		self.pill:setReady()
		self.lost_alert:hide()
	elseif level == nil or level == 0 then
		self.pill:setDefault()
		self.lost_alert:hide()
	else
		self.pill:setAlert()
		self.lost_alert:show()
	end
end

function Threat:onEvent(event)
	if event == "UNIT_THREAT_SITUATION_UPDATE" then
		self:refresh()
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:refresh()
	elseif event == "PLAYER_REGEN_ENABLED" then
		self.pill:setDefault()
		self.lost_alert:hide()
	end
end

addon.registerModule(Threat)
return Threat
