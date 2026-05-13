local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/nameplates/init.lua
-- Klassifiziert Nameplates anhand npcID-Lookup in data/npcs_midnight_s1.lua.
-- Erzeugt pro klassifiziertem Mob ein Overlay-Frame mit Theme-State entsprechend Kategorie.
--
-- Mapping Kategorie → Frame-State (v6 visuals):
--   "caster"        → setAlert()    (Magenta-gefüllt, "kick priority")
--   "frontal"       → setDefault()  (Outline, situational)
--   "healer"        → setReady()    (Lime/Cyan-gefüllt, top-kill)
--   "priority_kill" → setCD()       (Grey-Border, später eigenes 'priority' state)

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local Nameplates = {
	id = "nameplates",
	events = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" },
}

local function parse_npcID(guid)
	if not guid then
		return nil
	end
	local id = guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
	return id and tonumber(id) or nil
end

local function apply_category_state(overlay, category)
	if category == "caster" then
		overlay:setAlert()
	elseif category == "frontal" then
		overlay:setDefault()
	elseif category == "healer" then
		overlay:setReady()
	elseif category == "priority_kill" then
		overlay:setCD()
	else
		overlay:setDefault()
	end
end

function Nameplates:init()
	self.tracked = {} -- nameplate-unit → { npcID, category, overlay, label }
end

function Nameplates:onEvent(event, unit)
	if event == "NAME_PLATE_UNIT_ADDED" then
		local guid = UnitGUID and UnitGUID(unit)
		local npcID = parse_npcID(guid)
		if not npcID then
			return
		end
		local entry = addon.NPCsMidnightS1 and addon.NPCsMidnightS1[npcID]
		if not entry then
			return
		end

		local overlay = Frame:new({
			name = "BlizzNPOverlay_" .. unit,
			parent = UIParent,
			width = 140,
			height = 22,
		})
		apply_category_state(overlay, entry.category)

		local label = Text:new({
			parent = overlay,
			text = (entry.name or tostring(npcID)),
			style = entry.category == "caster" and "alert" or "value",
		})
		if label.SetPoint then
			label:SetPoint("CENTER", overlay, "CENTER", 0, 0)
		end

		self.tracked[unit] = {
			npcID = npcID,
			category = entry.category,
			overlay = overlay,
			label = label,
		}
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local entry = self.tracked[unit]
		if entry then
			if entry.overlay and entry.overlay.Hide then
				entry.overlay:Hide()
			end
			self.tracked[unit] = nil
		end
	end
end

addon.registerModule(Nameplates)
return Nameplates
