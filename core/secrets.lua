local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/secrets.lua
-- Midnight 12.0+ Secret-Values Defense Layer.
-- Return-Werte vieler Combat-APIs (UnitHealth, UnitAura, C_Spell.GetSpellCooldown,
-- UnitThreatSituation) sind in Restricted-Contexts (Encounter, Keystone, PvP) opake
-- "Secret"-Values. Arithmetik oder string.format darauf wirft Lua-Error.
--
-- Dieses Modul kapselt das defensive Lesen.

local Secrets = {}

-- Ist Restriction global aktiv?
function Secrets:isRestricted()
	if C_Secrets and C_Secrets.HasSecretRestrictions then
		return C_Secrets.HasSecretRestrictions()
	end
	if C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive then
		return C_RestrictedActions.IsAddOnRestrictionActive()
	end
	return false
end

-- Ist DIESER Wert secret?
local issecretvalue_fn = _G.issecretvalue
function Secrets:isSecret(v)
	if not issecretvalue_fn then
		return false
	end
	local ok, result = pcall(issecretvalue_fn, v)
	return ok and result == true
end

-- Sicher numerisch lesen — returnt number oder default
function Secrets:safeNumber(v, default)
	default = default or 0
	if v == nil then
		return default
	end
	if self:isSecret(v) then
		return default
	end
	local n = tonumber(v)
	return n or default
end

-- Sicher string lesen — returnt string oder default
function Secrets:safeString(v, default)
	default = default or ""
	if v == nil then
		return default
	end
	if self:isSecret(v) then
		return default
	end
	return tostring(v)
end

-- Pcall-Wrapper für API-Call der secret oder nil zurückgeben kann
function Secrets:pcallRead(fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		return nil
	end
	return result
end

addon.Secrets = Secrets
return Secrets
