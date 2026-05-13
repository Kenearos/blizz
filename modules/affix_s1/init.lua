local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/affix_s1/init.lua
-- Xal'atath's Bargain Affix-Spawn Tracker.
-- NAME_PLATE_UNIT_ADDED → GUID → parsen → npcID lookup in data/affixes_s1.lua → alert.

local Alert = addon.Alert or require("ui.widgets.alert")

local AffixS1 = {
	id = "affix_s1",
	events = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" },
}

-- GUID-Format: "Creature-0-server-instance-zone-npcID-spawn"
local function parse_npcID(guid)
	if not guid then
		return nil
	end
	local id = guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
	return id and tonumber(id) or nil
end

function AffixS1:init()
	self.alert = Alert:new({
		name = "BlizzAffixAlert",
		parent = UIParent,
		text = "AFFIX",
		width = 280,
		height = 28,
	})
	addon.restorePosition(self.alert, self.id, "TOP", 0, -60)
	self.active_units = {} -- nameplate-unit → npcID
	self.capture_mode = nil -- nil oder "voidbound"/"pulsar"/"devour"/"ascendant"
end

-- Runtime-Capture: schaltet sich via /blizz capture <bargain> ein und
-- printed unbekannte npcIDs in den Chat, so dass man sie ins data-File übertragen kann.
function AffixS1:setCaptureMode(bargain)
	self.capture_mode = bargain
end

function AffixS1:onEvent(event, unit)
	if event == "NAME_PLATE_UNIT_ADDED" then
		local guid = UnitGUID and UnitGUID(unit)
		local npcID = parse_npcID(guid)
		if not npcID then
			return
		end
		if self.capture_mode and DEFAULT_CHAT_FRAME then
			local lookup = addon.AffixesS1 and addon.AffixesS1.npcLookup
			if not (lookup and lookup[npcID]) then
				local name = (UnitName and UnitName(unit)) or "?"
				DEFAULT_CHAT_FRAME:AddMessage(
					string.format(
						"|cffff5dc8[Blizz Capture %s]|r new npcID: %d  name: %q",
						self.capture_mode,
						npcID,
						name
					)
				)
			end
		end
		local lookup = addon.AffixesS1 and addon.AffixesS1.npcLookup
		local entry = lookup and lookup[npcID]
		if entry then
			self.active_units[unit] = npcID
			self.alert:setText(entry.alert_text)
			self.alert:show()
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		if self.active_units[unit] then
			self.active_units[unit] = nil
			if next(self.active_units) == nil then
				self.alert:hide()
			end
		end
	end
end

addon.registerModule(AffixS1)
return AffixS1
