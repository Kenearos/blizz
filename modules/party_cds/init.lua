local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/party_cds/init.lua
-- Tracker für externe Defensives (Top-10) via CombatLog SPELL_CAST_SUCCESS.
-- Speichert pro Cast: { source_name, spell_label, ready_at }.
-- Display: kompakter Panel rechts mitte, listet aktive CDs mit Restzeit.

local Data = addon.PartyCDsData or require("data.party_cds")
local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local MAX_ROWS = 6 -- show top 6 most recently used CDs

local PartyCDs = {
	id = "party_cds",
	events = { "UNIT_SPELLCAST_SUCCEEDED", "GROUP_ROSTER_UPDATE" },
}

function PartyCDs:init()
	self.tracked = {} -- list of { source_guid, source_name, spellID, ready_at, label, name }

	self.panel = Frame:new({ name = "BlizzPartyCDs", parent = UIParent, width = 160, height = 110 })
	self.panel:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)

	self.header = Text:new({ parent = self.panel, text = "PARTY CDS", style = "label" })
	if self.header.SetPoint then
		self.header:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 6, -4)
	end

	self.rows = {}
	for i = 1, MAX_ROWS do
		local row = Text:new({ parent = self.panel, text = "", style = "default" })
		if row.SetPoint then
			row:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 6, -16 - (i - 1) * 14)
		end
		self.rows[i] = row
	end

	-- Cast-Success-Tracking via UNIT_SPELLCAST_SUCCEEDED (statt CLEU).
	-- Unit-Events sind in Midnight 12.0 nicht restricted.
end

function PartyCDs:on_cast_success(unit, spellID)
	if not spellID then
		return
	end
	local entry = Data[spellID]
	if not entry then
		return
	end
	local now = (GetTime and GetTime()) or 0
	table.insert(self.tracked, {
		source_guid = UnitGUID and UnitGUID(unit),
		source_name = (UnitName and UnitName(unit)) or unit or "?",
		spellID = spellID,
		ready_at = now + entry.default_cd,
		label = entry.label,
		name = entry.name,
	})
	self:refresh()
end

function PartyCDs:listOnCooldown()
	local now = (GetTime and GetTime()) or 0
	local out = {}
	for _, t in ipairs(self.tracked) do
		if t.ready_at > now then
			table.insert(out, {
				source_name = t.source_name,
				name = t.name,
				label = t.label,
				remaining = t.ready_at - now,
			})
		end
	end
	-- sort by lowest remaining first
	table.sort(out, function(a, b)
		return a.remaining < b.remaining
	end)
	return out
end

function PartyCDs:refresh()
	local active = self:listOnCooldown()
	for i = 1, MAX_ROWS do
		local row = self.rows[i]
		if active[i] then
			row:SetText(string.format("%s %ds", active[i].label, math.floor(active[i].remaining)))
		else
			row:SetText("")
		end
	end
end

function PartyCDs:onEvent(event, unit, castGUID, spellID)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		self:on_cast_success(unit, spellID)
	elseif event == "GROUP_ROSTER_UPDATE" then
		self:refresh()
	end
end

addon.registerModule(PartyCDs)
return PartyCDs
