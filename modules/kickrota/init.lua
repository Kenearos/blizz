local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/kickrota/init.lua
-- Kick-Rotation-Suggester:
--   1. Tracked Interrupts via CombatLog SPELL_CAST_SUCCESS (filterte auf bekannte Interrupt-SpellIDs).
--   2. Bei UNIT_SPELLCAST_START auf nameplate-Unit → pick Spieler mit niedrigster Restzeit.
--   3. Wenn der eigene Spieler dran ist, "YOUR KICK"; sonst "Next: <name>".

local Interrupts = addon.PartyInterrupts or require("data.party_interrupts")
local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local KickRota = {
	id = "kickrota",
	events = { "UNIT_SPELLCAST_START", "GROUP_ROSTER_UPDATE" },
}

-- Build reverse lookup: spellID → class
local function build_spell_lookup()
	local map = {}
	for class, def in pairs(Interrupts) do
		map[def.spellID] = { class = class, name = def.name, default_cd = def.default_cd }
	end
	return map
end

KickRota.spell_lookup = build_spell_lookup()

function KickRota:init()
	self.cooldowns = {} -- [guid] = { ready_at = time, name = string, class = string }

	self.panel = Frame:new({ name = "BlizzKickRota", parent = UIParent, width = 180, height = 64 })
	self.panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 80)

	self.header = Text:new({ parent = self.panel, text = "KICK ROTA", style = "label" })
	if self.header.SetPoint then
		self.header:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 6, -4)
	end

	self.next_text = Text:new({ parent = self.panel, text = "Next: —", style = "value" })
	if self.next_text.SetPoint then
		self.next_text:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 6, -22)
	end

	self.you_text = Text:new({ parent = self.panel, text = "READY", style = "default" })
	if self.you_text.SetPoint then
		self.you_text:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 6, -40)
	end

	-- Subscribe to CombatLog for interrupt-cast tracking
	local CombatLog = addon.CombatLog or require("core.combatlog")
	CombatLog:init()
	CombatLog:on("cast_success", function(payload)
		self:on_cast_success(payload)
	end)
end

function KickRota:on_cast_success(payload)
	if not payload or not payload.spellID then
		return
	end
	local entry = self.spell_lookup[payload.spellID]
	if not entry then
		return
	end
	local now = (GetTime and GetTime()) or 0
	self.cooldowns[payload.sourceGUID or payload.sourceName or "unknown"] = {
		ready_at = now + entry.default_cd,
		name = payload.sourceName or "?",
		class = entry.class,
	}
end

local UNITS = { "player", "party1", "party2", "party3", "party4" }

function KickRota:getRoster()
	local now = (GetTime and GetTime()) or 0
	local roster = {}
	for _, unit in ipairs(UNITS) do
		local guid = UnitGUID and UnitGUID(unit)
		if guid then
			local name = UnitName and UnitName(unit) or unit
			local _, class = UnitClass and UnitClass(unit)
			local def = Interrupts[class or ""]
			local cd = self.cooldowns[guid]
			local ready_at = cd and cd.ready_at or 0
			table.insert(roster, {
				unit = unit,
				name = name,
				class = class,
				guid = guid,
				ready = now >= ready_at,
				remaining = math.max(0, ready_at - now),
				has_interrupt = def ~= nil,
			})
		end
	end
	return roster
end

function KickRota:pickNext()
	local roster = self:getRoster()
	-- Prefer ready interrupts; among non-ready pick lowest remaining
	local best_ready, best_pending
	for _, p in ipairs(roster) do
		if p.has_interrupt then
			if p.ready then
				if not best_ready or p.unit == "player" then
					best_ready = p -- prefer player among ready
				end
			else
				if not best_pending or p.remaining < best_pending.remaining then
					best_pending = p
				end
			end
		end
	end
	return best_ready or best_pending
end

function KickRota:refresh()
	local next_kicker = self:pickNext()
	if not next_kicker then
		self.next_text:SetText("Next: —")
		self.you_text:SetText("READY")
		return
	end
	self.next_text:SetText(
		string.format(
			"Next: %s%s",
			next_kicker.name,
			next_kicker.ready and "" or string.format(" (%ds)", math.floor(next_kicker.remaining))
		)
	)
	if next_kicker.unit == "player" and next_kicker.ready then
		self.you_text:SetText("YOUR KICK")
		self.panel:setAlert()
	elseif next_kicker.unit == "player" then
		self.you_text:SetText(string.format("YOU IN %ds", math.floor(next_kicker.remaining)))
		self.panel:setDefault()
	else
		self.you_text:SetText("READY")
		self.panel:setDefault()
	end
end

function KickRota:onEvent(event)
	if event == "UNIT_SPELLCAST_START" then
		self:refresh()
	elseif event == "GROUP_ROSTER_UPDATE" then
		self:refresh()
	end
end

addon.registerModule(KickRota)
return KickRota
