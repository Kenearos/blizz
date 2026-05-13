local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/unitstate.lua
-- Wrappers für UnitHealth/UnitAura/UnitThreatSituation mit Convenience-Helpers.

local UnitState = {}

function UnitState:getHealth(unit)
	return UnitHealth(unit) or 0
end

function UnitState:getMaxHealth(unit)
	return UnitHealthMax(unit) or 0
end

function UnitState:getHealthPercent(unit)
	local max = self:getMaxHealth(unit)
	if max == 0 then
		return 0
	end
	return self:getHealth(unit) / max
end

function UnitState:getAbsorb(unit)
	return UnitGetTotalAbsorbs(unit) or 0
end

-- 0 = low/no threat, 1 = high threat, 2 = primary target, 3 = securely tanking
function UnitState:getThreatLevel(unit, target)
	return UnitThreatSituation(unit, target) or 0
end

function UnitState:isTanking(unit, target)
	return self:getThreatLevel(unit, target) == 3
end

function UnitState:isInRange(unit)
	return UnitInRange(unit)
end

addon.UnitState = UnitState
return UnitState
