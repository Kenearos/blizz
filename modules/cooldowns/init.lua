local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/cooldowns/init.lua
-- Defensive-CD-Bar: 8 Icons in horizontaler Reihe.
-- Spells aus data/spells_prot_warrior.lua, defensive_bar_order.
-- Position default: BOTTOM, center, y=+192 (~+24% auf 800px Höhe).

local Spells = addon.SpellsProtWarrior or require("data.spells_prot_warrior")
local Cooldowns = addon.Cooldowns or require("core.cooldowns")
local Frame = addon.Frame or require("ui.widgets.frame")
local Icon = addon.Icon or require("ui.widgets.icon")

local ICON_SIZE = 38
local ICON_GAP = 3
local PADDING = 3

local CDModule = {
	id = "cooldowns",
	events = { "SPELL_UPDATE_COOLDOWN" },
}

function CDModule:init()
	local order = Spells.defensive_bar_order
	local bar_width = #order * (ICON_SIZE + 14) + (#order - 1) * ICON_GAP + 2 * PADDING
	local bar_height = ICON_SIZE + 6 + 2 * PADDING

	self.container = Frame:new({
		name = "BlizzDefBar",
		parent = UIParent,
		width = bar_width,
		height = bar_height,
	})
	self.container:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 192)

	self.icons = {}
	for i, spellID in ipairs(order) do
		local label = Spells.labels[spellID] or tostring(spellID)
		local ico = Icon:new({
			parent = self.container,
			name = "BlizzDefIcon_" .. label,
			spellID = spellID,
			size = ICON_SIZE,
			label = label,
		})
		ico.__spellID = spellID
		if ico.SetPoint then
			local x_offset = PADDING + (i - 1) * (ICON_SIZE + 14 + ICON_GAP)
			ico:SetPoint("LEFT", self.container, "LEFT", x_offset, 0)
		end
		table.insert(self.icons, ico)
	end

	self:refresh()
end

function CDModule:refresh()
	for _, ico in ipairs(self.icons) do
		local state = Cooldowns:getState(ico.__spellID)
		if state.ready then
			ico:setReady()
		else
			ico:setCD(state.remaining)
		end
	end
end

function CDModule:onEvent(event)
	if event == "SPELL_UPDATE_COOLDOWN" then
		self:refresh()
	end
end

addon.registerModule(CDModule)
return CDModule
