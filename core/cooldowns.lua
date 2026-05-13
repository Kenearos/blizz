local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/cooldowns.lua
-- Wrapper um GetSpellCooldown + GetSpellCharges.
-- Liefert pro Spell {ready, remaining, percent, charges, maxCharges}.

local Cooldowns = {}

function Cooldowns:getState(spellID)
	local start, duration, _enabled = GetSpellCooldown(spellID)
	local now = GetTime()
	local charges, maxCharges = nil, nil
	if GetSpellCharges then
		local c, mc = GetSpellCharges(spellID)
		if c then
			charges, maxCharges = c, mc
		end
	end

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
		-- still track recharge progress for next charge
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
