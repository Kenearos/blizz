local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/mitigation/init.lua
-- Active Mitigation Display: Shield Block CD + Ignore Pain absorb readout.
-- Position default: CENTER, x=+144, y=+90 (rechts vom Spieler, ~62% horizontal, +15% vertikal).

local Spells = addon.SpellsProtWarrior or require("data.spells_prot_warrior")
local Cooldowns = addon.Cooldowns or require("core.cooldowns")
local UnitState = addon.UnitState or require("core.unitstate")
local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local Mitigation = {
	id = "mitigation",
	events = { "SPELL_UPDATE_COOLDOWN", "UNIT_AURA" },
}

local function format_remaining(remaining)
	if remaining <= 0 then
		return "RDY"
	elseif remaining < 10 then
		return string.format("%.1fs", remaining)
	else
		return string.format("%ds", math.floor(remaining))
	end
end

local function format_absorb(absorb)
	if absorb <= 0 then
		return "0"
	elseif absorb >= 1000 then
		return string.format("%.0fK", absorb / 1000)
	else
		return tostring(absorb)
	end
end

function Mitigation:init()
	self.frame =
		Frame:new({ name = "BlizzMitigation", parent = UIParent, width = 220, height = 30 })
	self.frame:SetPoint("CENTER", UIParent, "CENTER", 144, 90)

	self.shield_block_label = Text:new({ parent = self.frame, text = "SBLK", style = "label" })
	if self.shield_block_label.SetPoint then
		self.shield_block_label:SetPoint("LEFT", self.frame, "LEFT", 6, 0)
	end

	self.shield_block_text = Text:new({ parent = self.frame, text = "—", style = "value" })
	if self.shield_block_text.SetPoint then
		self.shield_block_text:SetPoint("LEFT", self.frame, "LEFT", 50, 0)
	end

	self.ignore_pain_label = Text:new({ parent = self.frame, text = "IP", style = "label" })
	if self.ignore_pain_label.SetPoint then
		self.ignore_pain_label:SetPoint("LEFT", self.frame, "LEFT", 120, 0)
	end

	self.ignore_pain_text = Text:new({ parent = self.frame, text = "0", style = "value" })
	if self.ignore_pain_text.SetPoint then
		self.ignore_pain_text:SetPoint("LEFT", self.frame, "LEFT", 150, 0)
	end

	self:refresh()
end

function Mitigation:refresh()
	local sb_state = Cooldowns:getState(Spells.active_mitigation.shield_block)
	self.shield_block_text:SetText(format_remaining(sb_state.remaining))

	local absorb = UnitState:getAbsorb("player")
	self.ignore_pain_text:SetText(format_absorb(absorb))
end

function Mitigation:onEvent(event, unit)
	if event == "SPELL_UPDATE_COOLDOWN" then
		self:refresh()
	elseif event == "UNIT_AURA" and (unit == nil or unit == "player") then
		self:refresh()
	end
end

addon.registerModule(Mitigation)
return Mitigation
