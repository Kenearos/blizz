local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/unitstate.lua
-- Wrappers für UnitHealth/UnitAura/UnitThreatSituation mit Convenience-Helpers.
-- Defensive gegen Secret-Values (Midnight 12.0+).

local Secrets = addon.Secrets or require("core.secrets")

local UnitState = {}

local function safe_unit_call(fn, ...)
	if not fn then
		return nil
	end
	local ok, v = pcall(fn, ...)
	if not ok then
		return nil
	end
	return v
end

function UnitState:getHealth(unit)
	return Secrets:safeNumber(safe_unit_call(_G.UnitHealth, unit), 0)
end

function UnitState:getMaxHealth(unit)
	return Secrets:safeNumber(safe_unit_call(_G.UnitHealthMax, unit), 0)
end

function UnitState:getHealthPercent(unit)
	local max = self:getMaxHealth(unit)
	if max == 0 then
		return 0
	end
	return self:getHealth(unit) / max
end

function UnitState:getAbsorb(unit)
	return Secrets:safeNumber(safe_unit_call(_G.UnitGetTotalAbsorbs, unit), 0)
end

-- 0 = low/no threat, 1 = high threat, 2 = primary target, 3 = securely tanking
function UnitState:getThreatLevel(unit, target)
	return Secrets:safeNumber(safe_unit_call(_G.UnitThreatSituation, unit, target), 0)
end

function UnitState:isTanking(unit, target)
	return self:getThreatLevel(unit, target) == 3
end

function UnitState:isInRange(unit)
	local r = safe_unit_call(_G.UnitInRange, unit)
	if r == nil then
		return false
	end
	return r and true or false
end

addon.UnitState = UnitState
return UnitState
