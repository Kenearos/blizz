-- tests/mocks/wow_api.lua
-- Minimal WoW-Global-Stubs für headless Tests.
-- Nur das was Phase 1 braucht. Erweitern wenn Module mehr APIs nutzen.

local Mock = {}
Mock.units = {}
Mock.cooldowns = {}
Mock.cleu_listener = nil
Mock.time = 1000 -- fake game time, in seconds
Mock.frames = {} -- tracks all created frames for event-broadcast

local function frame_method_stub() end

local function make_frame(frameType, name, parent, template)
	local f = {
		__type = frameType or "Frame",
		__name = name,
		__parent = parent,
		__template = template,
		__events = {},
		__scripts = {},
		__points = {},
		__size = { 0, 0 },
		__shown = true,
	}
	function f:SetSize(w, h)
		self.__size = { w, h }
	end
	function f:GetSize()
		return self.__size[1], self.__size[2]
	end
	function f:SetPoint(...)
		table.insert(self.__points, { ... })
	end
	function f:ClearAllPoints()
		self.__points = {}
	end
	function f:RegisterEvent(ev)
		self.__events[ev] = true
	end
	function f:UnregisterEvent(ev)
		self.__events[ev] = nil
	end
	function f:RegisterUnitEvent(ev, _)
		self.__events[ev] = true
	end
	function f:IsEventRegistered(ev)
		return self.__events[ev] == true
	end
	function f:SetScript(name, fn)
		self.__scripts[name] = fn
	end
	function f:GetScript(name)
		return self.__scripts[name]
	end
	function f:Show()
		self.__shown = true
	end
	function f:Hide()
		self.__shown = false
	end
	function f:IsShown()
		return self.__shown
	end
	function f:SetAlpha(_) end
	function f:SetFrameStrata(_) end
	function f:SetFrameLevel(_) end
	function f:SetParent(p)
		self.__parent = p
	end
	function f:GetName()
		return self.__name
	end
	function f:SetBackdrop(_) end
	function f:SetBackdropColor(_, _, _, _) end
	function f:SetBackdropBorderColor(_, _, _, _) end
	function f:CreateTexture(_, _)
		return make_frame("Texture")
	end
	function f:CreateFontString(_, _, _)
		return make_frame("FontString")
	end
	function f:CreateAnimationGroup(_)
		return make_frame("AnimationGroup")
	end
	function f:SetText(t)
		self.__text = t
	end
	function f:GetText()
		return self.__text
	end
	function f:SetFont(...)
		self.__font = { ... }
	end
	function f:SetTextColor(...)
		self.__textColor = { ... }
	end
	function f:SetVertexColor(...)
		self.__vertexColor = { ... }
	end
	function f:SetTexture(t)
		self.__texture = t
	end
	function f:GetParent()
		return self.__parent
	end
	-- Method stub catch-all for anything else
	setmetatable(f, {
		__index = function(_, k)
			if type(k) == "string" and k:match("^Set") or k:match("^Get") then
				return frame_method_stub
			end
			return nil
		end,
	})
	-- track frame so MockFireFrameEvent can broadcast to it
	table.insert(Mock.frames, f)
	return f
end

-- ---------- WoW Globals ----------
_G.UIParent = make_frame("Frame", "UIParent")
_G.WorldFrame = make_frame("Frame", "WorldFrame")
_G.CreateFrame = function(frameType, name, parent, template)
	return make_frame(frameType, name, parent, template)
end
_G.GetTime = function()
	return Mock.time
end
_G.UnitExists = function(unit)
	return Mock.units[unit] ~= nil
end
_G.UnitHealth = function(unit)
	return (Mock.units[unit] or {}).health or 0
end
_G.UnitHealthMax = function(unit)
	return (Mock.units[unit] or {}).maxHealth or 0
end
_G.UnitGetTotalAbsorbs = function(unit)
	return (Mock.units[unit] or {}).absorb or 0
end
_G.UnitThreatSituation = function(_, _)
	return Mock.threat or 3
end
_G.UnitInRange = function(_)
	return true
end
_G.UnitAura = function(_, _)
	return nil
end
_G.UnitGUID = function(unit)
	return (Mock.units[unit] or {}).guid
end
_G.UnitName = function(unit)
	return (Mock.units[unit] or {}).name or unit, nil
end
_G.UnitClass = function(unit)
	local u = Mock.units[unit] or {}
	return u.classLocalized or u.class, u.class
end
_G.GetNumGroupMembers = function()
	return Mock.numGroupMembers or 0
end
_G.GetSpellCooldown = function(spellID)
	local c = Mock.cooldowns[spellID]
	if not c then
		return 0, 0, 1
	end
	return c.start, c.duration, c.enable
end
_G.GetSpellCharges = function(spellID)
	local c = Mock.cooldowns[spellID]
	if not c or not c.charges then
		return nil
	end
	return c.charges, c.maxCharges or c.charges, c.start, c.duration
end
_G.GetSpellInfo = function(spellID)
	return tostring(spellID), nil, nil
end

-- Midnight 12.0+: C_Spell-Namespace ist die neue offizielle API
_G.C_Spell = {
	GetSpellCooldown = function(spellID)
		local c = Mock.cooldowns[spellID]
		if not c then
			return { startTime = 0, duration = 0, isEnabled = true, modRate = 1 }
		end
		return {
			startTime = c.start,
			duration = c.duration,
			isEnabled = c.enable == 1,
			modRate = 1,
		}
	end,
	GetSpellCharges = function(spellID)
		local c = Mock.cooldowns[spellID]
		if not c or not c.charges then
			return nil
		end
		return {
			currentCharges = c.charges,
			maxCharges = c.maxCharges or c.charges,
			cooldownStartTime = c.start,
			cooldownDuration = c.duration,
		}
	end,
	GetSpellInfo = function(spellID)
		return { name = tostring(spellID), spellID = spellID }
	end,
}

_G.C_Timer = _G.C_Timer or { After = function(_, _) end }

-- ---------- M+ API Mocks ----------
Mock.mythicplus = {
	active = false,
	mapID = 0,
	keystoneLevel = 0,
	affixes = {},
	timeLimit = 1800, -- par time in seconds, default 30min
}
Mock.forces = {
	total = 100,
	current = 0,
}
Mock.timer_elapsed = 0 -- seconds since pull

_G.C_ChallengeMode = {
	GetActiveChallengeMapID = function()
		return Mock.mythicplus.active and Mock.mythicplus.mapID or nil
	end,
	GetActiveKeystoneInfo = function()
		if not Mock.mythicplus.active then
			return 0, {}
		end
		return Mock.mythicplus.keystoneLevel, Mock.mythicplus.affixes
	end,
	GetMapUIInfo = function(mapID)
		if mapID ~= Mock.mythicplus.mapID then
			return nil
		end
		return "Mock Dungeon", mapID, Mock.mythicplus.timeLimit
	end,
}

_G.C_Scenario = {
	GetInfo = function()
		if not Mock.mythicplus.active then
			return nil
		end
		return "Mock Dungeon", nil, 1, nil, true
	end,
	GetCriteriaInfo = function(index)
		if not Mock.mythicplus.active or index ~= 1 then
			return nil
		end
		return "Enemy Forces",
			0,
			Mock.forces.current >= Mock.forces.total,
			tostring(Mock.forces.current),
			Mock.forces.total
	end,
	GetStepInfo = function()
		if not Mock.mythicplus.active then
			return 0, 0, 0
		end
		return 1, 1, 1
	end,
}

_G.GetWorldElapsedTime = function(_)
	return Mock.timer_elapsed
end

_G.SLASH_BLIZZ1 = nil -- gets set by addon
_G.SlashCmdList = _G.SlashCmdList or {}

-- ---------- Mock-Control-API (Tests rufen das auf) ----------
function MockSetUnit(unit, props)
	Mock.units[unit] = props
end
function MockSetCooldown(spellID, start, duration, charges, maxCharges)
	Mock.cooldowns[spellID] = {
		start = start or 0,
		duration = duration or 0,
		enable = 1,
		charges = charges,
		maxCharges = maxCharges,
	}
end
function MockSetThreat(level)
	Mock.threat = level
end
function MockSetTime(t)
	Mock.time = t
end
function MockSetCLEUListener(fn)
	Mock.cleu_listener = fn
end
function MockFireCLEU(...)
	if Mock.cleu_listener then
		Mock.cleu_listener(...)
	end
end
function MockFireFrameEvent(eventName, ...)
	for _, f in ipairs(Mock.frames) do
		if f.__events and f.__events[eventName] then
			local handler = f.__scripts and f.__scripts["OnEvent"]
			if handler then
				handler(f, eventName, ...)
			end
		end
	end
end
function MockSetMythicPlus(active, mapID, keystoneLevel, timeLimit)
	Mock.mythicplus.active = active and true or false
	Mock.mythicplus.mapID = mapID or 0
	Mock.mythicplus.keystoneLevel = keystoneLevel or 0
	Mock.mythicplus.timeLimit = timeLimit or 1800
end
function MockSetForces(current, total)
	Mock.forces.current = current or 0
	Mock.forces.total = total or 100
end
function MockSetTimer(elapsed)
	Mock.timer_elapsed = elapsed or 0
end
function MockSetGroup(members)
	Mock.numGroupMembers = members or 0
end
function MockReset()
	Mock.units = {}
	Mock.cooldowns = {}
	Mock.cleu_listener = nil
	Mock.threat = 3
	Mock.time = 1000
	Mock.mythicplus =
		{ active = false, mapID = 0, keystoneLevel = 0, affixes = {}, timeLimit = 1800 }
	Mock.forces = { total = 100, current = 0 }
	Mock.timer_elapsed = 0
	-- NOTE: Mock.frames bleibt — sonst verlieren wir die UIParent/WorldFrame-Refs.
end

return Mock
