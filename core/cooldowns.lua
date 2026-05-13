local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/cooldowns.lua
-- Wrapper um Spell-Cooldown + Charges.
-- Bevorzugt C_Spell.GetSpellCooldown / C_Spell.GetSpellCharges (modern, Midnight 12.0+).
-- Fallback auf alte globale Funktionen (für Mock-Tests und Pre-12.0 WoW).
-- Liefert pro Spell {ready, remaining, percent, charges, maxCharges}.

local Cooldowns = {}

local function read_cooldown(spellID)
	-- Modern API: C_Spell.GetSpellCooldown returns a table
	if C_Spell and C_Spell.GetSpellCooldown then
		local info = C_Spell.GetSpellCooldown(spellID)
		if info then
			return info.startTime or 0, info.duration or 0, info.isEnabled and 1 or 0
		end
		return 0, 0, 1
	end
	-- Legacy API
	if _G.GetSpellCooldown then
		local start, duration, enabled = _G.GetSpellCooldown(spellID)
		return start or 0, duration or 0, enabled or 1
	end
	return 0, 0, 1
end

local function read_charges(spellID)
	-- Modern API: C_Spell.GetSpellCharges returns a table
	if C_Spell and C_Spell.GetSpellCharges then
		local info = C_Spell.GetSpellCharges(spellID)
		if info and info.currentCharges then
			return info.currentCharges,
				info.maxCharges,
				info.cooldownStartTime,
				info.cooldownDuration
		end
		return nil
	end
	-- Legacy API
	if _G.GetSpellCharges then
		local c, mc, start, dur = _G.GetSpellCharges(spellID)
		if c then
			return c, mc, start, dur
		end
	end
	return nil
end

function Cooldowns:getState(spellID)
	local start, duration = read_cooldown(spellID)
	local now = GetTime and GetTime() or 0
	local charges, maxCharges = read_charges(spellID)

	local state = {
		spellID = spellID,
		ready = false,
		remaining = 0,
		percent = 0,
		charges = charges,
		maxCharges = maxCharges,
	}

	-- charges available: always considered "ready"
	if charges and charges > 0 then
		state.ready = true
		if duration and duration > 0 and start and start > 0 then
			local elapsed = now - start
			state.remaining = math.max(0, duration - elapsed)
			state.percent = math.min(1, elapsed / duration)
		end
		return state
	end

	if not start or not duration or duration == 0 then
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
