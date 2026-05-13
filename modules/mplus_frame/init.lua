local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- modules/mplus_frame/init.lua
-- M+ Run-Frame: Timer, Forces %, +2/+3-Schwellen, Death-Counter, Penalty.
-- Show/Hide an M+ Run-State gekoppelt.

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local DEATH_PENALTY_SECONDS = 15

local MPlus = {
	id = "mplus_frame",
	events = {
		"CHALLENGE_MODE_START",
		"CHALLENGE_MODE_RESET",
		"CHALLENGE_MODE_COMPLETED",
		"SCENARIO_CRITERIA_UPDATE",
		"PLAYER_ENTERING_WORLD",
		"UNIT_HEALTH",
		"PLAYER_DEAD",
	},
}

local function format_mmss(seconds)
	if seconds <= 0 then
		return "0:00"
	end
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%d:%02d", m, s)
end

function MPlus:init()
	self.left_frame = Frame:new({
		name = "BlizzMPlusLeft",
		parent = UIParent,
		width = 240,
		height = 64,
	})
	self.left_frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)

	self.timer_text = Text:new({ parent = self.left_frame, text = "M+ —", style = "value" })
	if self.timer_text.SetPoint then
		self.timer_text:SetPoint("TOPLEFT", self.left_frame, "TOPLEFT", 6, -4)
	end

	self.forces_text =
		Text:new({ parent = self.left_frame, text = "Forces —", style = "default" })
	if self.forces_text.SetPoint then
		self.forces_text:SetPoint("TOPLEFT", self.left_frame, "TOPLEFT", 6, -22)
	end

	self.threshold_text = Text:new({ parent = self.left_frame, text = "", style = "label" })
	if self.threshold_text.SetPoint then
		self.threshold_text:SetPoint("TOPLEFT", self.left_frame, "TOPLEFT", 6, -40)
	end

	self.right_frame = Frame:new({
		name = "BlizzMPlusRight",
		parent = UIParent,
		width = 160,
		height = 48,
	})
	self.right_frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)

	self.deaths_text = Text:new({ parent = self.right_frame, text = "☠ 0", style = "value" })
	if self.deaths_text.SetPoint then
		self.deaths_text:SetPoint("TOPRIGHT", self.right_frame, "TOPRIGHT", -6, -4)
	end

	self.penalty_text = Text:new({ parent = self.right_frame, text = "(−0s)", style = "label" })
	if self.penalty_text.SetPoint then
		self.penalty_text:SetPoint("TOPRIGHT", self.right_frame, "TOPRIGHT", -6, -22)
	end

	self.deaths = 0
	self.unit_was_dead = {} -- per-unit alive→dead transition tracking

	-- Death counter: tracking via UNIT_HEALTH + PLAYER_DEAD (statt CLEU UNIT_DIED).
	-- CLEU ist in Midnight 12.0 für nicht-guarded Addons blockiert.

	self:refresh_visibility()
	self:refresh_timer()
	self:refresh_forces()
end

function MPlus:isActive()
	if not C_ChallengeMode or not C_ChallengeMode.GetActiveChallengeMapID then
		return false
	end
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()
	return mapID ~= nil and mapID ~= 0
end

function MPlus:refresh_visibility()
	if self:isActive() then
		self.left_frame:Show()
		self.right_frame:Show()
	else
		self.left_frame:Hide()
		self.right_frame:Hide()
	end
end

function MPlus:getElapsedTime()
	-- Bevorzugt: lokal getrackte Startzeit ab CHALLENGE_MODE_START.
	-- Fallback: GetWorldElapsedTime (alte API, manchmal nil/string in Midnight).
	if self.start_time and GetTime then
		return math.max(0, GetTime() - self.start_time)
	end
	if not GetWorldElapsedTime then
		return 0
	end
	local t = GetWorldElapsedTime(1)
	return tonumber(t) or 0
end

function MPlus:getParTime()
	if not C_ChallengeMode or not C_ChallengeMode.GetActiveChallengeMapID then
		return 0
	end
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()
	if not mapID or mapID == 0 then
		return 0
	end
	local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
	return timeLimit or 0
end

function MPlus:getThreshold(elapsed, par)
	if par <= 0 then
		return ""
	end
	if elapsed >= par then
		return "DEPLETED"
	elseif elapsed >= par * 0.8 then
		return "↓ +1"
	elseif elapsed >= par * 0.6 then
		return "↓ +2"
	else
		return "↓ +3"
	end
end

function MPlus:refresh_timer()
	local elapsed = self:getElapsedTime()
	local par = self:getParTime()
	self.timer_text:SetText("M+ " .. format_mmss(elapsed))
	self.threshold_text:SetText(self:getThreshold(elapsed, par))
end

function MPlus:getForces()
	if not C_Scenario or not C_Scenario.GetCriteriaInfo then
		return 0, 0
	end
	local _, _, _, currentStr, total = C_Scenario.GetCriteriaInfo(1)
	if not currentStr or not total then
		return 0, 0
	end
	local current = tonumber(currentStr) or 0
	return current, total
end

function MPlus:refresh_forces()
	local current, total = self:getForces()
	if total == 0 then
		self.forces_text:SetText("Forces —")
		return
	end
	local pct = math.min(100, math.floor((current / total) * 100))
	self.forces_text:SetText(string.format("Forces %d%% (%d/%d)", pct, current, total))
end

local function is_party_unit(unit)
	if not unit then
		return false
	end
	if unit == "player" then
		return true
	end
	if unit:match("^party[1-4]$") then
		return true
	end
	if unit:match("^raid%d+$") then
		return true
	end
	return false
end

function MPlus:checkUnitDeath(unit)
	if not unit or not is_party_unit(unit) then
		return
	end
	if not self:isActive() then
		-- Track state but don't increment outside M+
		self.unit_was_dead[unit] = UnitIsDead and UnitIsDead(unit) or false
		return
	end
	local isDead = UnitIsDead and UnitIsDead(unit) or false
	local wasDead = self.unit_was_dead[unit] == true
	if isDead and not wasDead then
		self.deaths = self.deaths + 1
		local penalty = self.deaths * DEATH_PENALTY_SECONDS
		self.deaths_text:SetText("☠ " .. self.deaths)
		self.penalty_text:SetText(string.format("(−%ds)", penalty))
	end
	self.unit_was_dead[unit] = isDead
end

function MPlus:onEvent(event, unit)
	if event == "CHALLENGE_MODE_START" then
		self.deaths = 0
		self.unit_was_dead = {}
		self.start_time = GetTime and GetTime() or 0
		self.deaths_text:SetText("☠ 0")
		self.penalty_text:SetText("(−0s)")
		self:refresh_visibility()
		self:refresh_timer()
		self:refresh_forces()
	elseif event == "CHALLENGE_MODE_COMPLETED" then
		self.start_time = nil
		self:refresh_visibility()
	elseif event == "CHALLENGE_MODE_RESET" then
		self:refresh_visibility()
	elseif event == "SCENARIO_CRITERIA_UPDATE" then
		self:refresh_forces()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:refresh_visibility()
	elseif event == "UNIT_HEALTH" then
		self:checkUnitDeath(unit)
	elseif event == "PLAYER_DEAD" then
		self:checkUnitDeath("player")
	end
end

addon.registerModule(MPlus)
return MPlus
