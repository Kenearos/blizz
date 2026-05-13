local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/cooldowns.lua
-- Wrapper um Spell-Cooldown + Charges. Bevorzugt C_Spell-Namespace (Midnight 12.0+).
-- Defensive gegen Secret-Values (siehe core/secrets.lua).

local Secrets = addon.Secrets or require("core.secrets")

local Cooldowns = {}

local function read_cooldown(spellID)
	if C_Spell and C_Spell.GetSpellCooldown then
		local info = Secrets:pcallRead(C_Spell.GetSpellCooldown, spellID)
		if type(info) == "table" then
			return Secrets:safeNumber(info.startTime, 0),
				Secrets:safeNumber(info.duration, 0),
				info.isEnabled ~= false
		end
		return 0, 0, true
	end
	if _G.GetSpellCooldown then
		local s, d, e = Secrets:pcallRead(_G.GetSpellCooldown, spellID), nil, nil
		-- pcall wrapping multi-return: re-call to get all three
		local ok, ss, dd, ee = pcall(_G.GetSpellCooldown, spellID)
		if ok then
			s, d, e = ss, dd, ee
		end
		return Secrets:safeNumber(s, 0), Secrets:safeNumber(d, 0), (e or 1) ~= 0
	end
	return 0, 0, true
end

local function read_charges(spellID)
	if C_Spell and C_Spell.GetSpellCharges then
		local info = Secrets:pcallRead(C_Spell.GetSpellCharges, spellID)
		if type(info) == "table" and info.currentCharges then
			return Secrets:safeNumber(info.currentCharges, 0),
				Secrets:safeNumber(info.maxCharges, 0),
				Secrets:safeNumber(info.cooldownStartTime, 0),
				Secrets:safeNumber(info.cooldownDuration, 0)
		end
		return nil
	end
	if _G.GetSpellCharges then
		local ok, c, mc, start, dur = pcall(_G.GetSpellCharges, spellID)
		if ok and c then
			return Secrets:safeNumber(c, 0),
				Secrets:safeNumber(mc, 0),
				Secrets:safeNumber(start, 0),
				Secrets:safeNumber(dur, 0)
		end
	end
	return nil
end

function Cooldowns:getState(spellID)
	local start, duration = read_cooldown(spellID)
	local now = (GetTime and GetTime()) or 0
	local charges, maxCharges = read_charges(spellID)

	local state = {
		spellID = spellID,
		ready = false,
		remaining = 0,
		percent = 0,
		charges = charges,
		maxCharges = maxCharges,
	}

	if charges and charges > 0 then
		state.ready = true
		if duration > 0 and start > 0 then
			local elapsed = now - start
			state.remaining = math.max(0, duration - elapsed)
			state.percent = math.min(1, elapsed / duration)
		end
		return state
	end

	if duration == 0 then
		state.ready = true
		return state
	end

	local elapsed = now - start
	if elapsed >= duration then
		state.ready = true
		return state
	end

	state.remaining = duration - elapsed
	state.percent = elapsed / duration
	return state
end

function Cooldowns:getStates(spellIDs)
	local out = {}
	for _, id in ipairs(spellIDs) do
		out[id] = self:getState(id)
	end
	return out
end

addon.Cooldowns = Cooldowns
return Cooldowns
