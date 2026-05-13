local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/wowevents.lua
-- Brücke zwischen WoW-Frame-Events und addon.EventBus.
-- Modules sagen `events = {"UNIT_AURA", ...}` — registerModule ruft hier register(),
-- und der Bridge-Frame leitet WoW-Events an den internen Bus weiter.

local WoWEvents = {}
WoWEvents.frame = nil
WoWEvents.refCount = {} -- event → number of registrants

function WoWEvents:init()
	if self.frame then
		return -- idempotent
	end
	self.frame = CreateFrame("Frame", "BlizzEventBridge")
	self.frame:SetScript("OnEvent", function(_, event, ...)
		if addon.EventBus then
			addon.EventBus:dispatch(event, ...)
		end
	end)
end

function WoWEvents:register(event)
	if not self.frame then
		return
	end
	self.refCount[event] = (self.refCount[event] or 0) + 1
	if self.refCount[event] == 1 then
		self.frame:RegisterEvent(event)
	end
end

function WoWEvents:unregister(event)
	if not self.frame then
		return
	end
	if not self.refCount[event] then
		return
	end
	self.refCount[event] = self.refCount[event] - 1
	if self.refCount[event] <= 0 then
		self.refCount[event] = nil
		self.frame:UnregisterEvent(event)
	end
end

addon.WoWEvents = WoWEvents
return WoWEvents
