local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- Blizz.lua — Main entry. Setzt _G.Blizz auf, lädt Sub-Module via TOC,
-- registriert Slash-Command, koordiniert bootstrap.

local EventBus = addon.EventBus or require("core.eventbus")
local SavedVars = addon.SavedVars or require("config.savedvars")
local WoWEvents = addon.WoWEvents or require("core.wowevents")

addon.modules = addon.modules or {}

function addon.registerModule(mod)
	assert(mod and mod.id, "module needs id")
	addon.modules[mod.id] = mod
	if mod.events and EventBus then
		for _, ev in ipairs(mod.events) do
			EventBus:subscribe(ev, function(...)
				if mod.onEvent then
					mod:onEvent(ev, ...)
				end
			end)
			WoWEvents:register(ev)
		end
	end
end

function addon:bootstrap()
	WoWEvents:init()
	SavedVars:load()
	for id, mod in pairs(self.modules) do
		if mod.init then
			local ok, err = pcall(mod.init, mod)
			if not ok then
				table.insert(addon.errors, { event = "init:" .. id, err = tostring(err) })
			end
		end
	end
end

function addon:registerSlash()
	_G.SLASH_BLIZZ1 = "/blizz"
	_G.SlashCmdList["BLIZZ"] = function(msg)
		msg = (msg or ""):lower():match("^%s*(.-)%s*$")
		if msg == "" or msg == "status" then
			print("|cff7ed9ff[Blizz]|r status:")
			local n = 0
			for _ in pairs(addon.modules) do
				n = n + 1
			end
			print("  modules registered:", n)
			print("  errors (last):", #addon.errors)
		elseif msg == "errors" then
			for i = math.max(1, #addon.errors - 9), #addon.errors do
				local e = addon.errors[i]
				print(string.format("  [%s] %s: %s", tostring(e.time), e.event, e.err))
			end
		else
			print("|cff7ed9ff[Blizz]|r unknown command: " .. msg)
		end
	end
end

-- In WoW: bridge captures PLAYER_LOGIN; we bootstrap then.
if CreateFrame then
	WoWEvents:init()
	WoWEvents:register("PLAYER_LOGIN")
	if EventBus then
		EventBus:subscribe("PLAYER_LOGIN", function()
			addon:bootstrap()
			addon:registerSlash()
		end)
	end
end

return addon
