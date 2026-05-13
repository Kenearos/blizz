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

-- I-08 Position-Persistenz helper: Module rufen das nach Frame-Erstellung im init().
-- Stellt SavedVars-gespeicherte Position wieder her, falls vorhanden, sonst nutzt
-- den Default. Aktiviert Drag-to-Move auf dem Frame, so dass der User seine
-- bevorzugte Position einfach via Mouse setzt und sie via SavedVars persistiert.
--
--   frame             — der zu positionierende Frame (muss SetPoint + enableDrag haben)
--   moduleId          — eindeutiger string key in BlizzDB.profiles[active].positions
--   default_anchor    — fallback "TOP"/"CENTER"/"BOTTOM"/...
--   default_x, _y     — fallback Pixel-Offsets relativ zu UIParent
--   default_rel       — optional: relative anchor (defaults to default_anchor)
function addon.restorePosition(frame, moduleId, default_anchor, default_x, default_y, default_rel)
	if not frame or not moduleId then
		return
	end
	local p = SavedVars and SavedVars.getPosition and SavedVars:getPosition(moduleId)
	local anchor = (p and p.anchor) or default_anchor or "CENTER"
	local rel = (p and p.relativeAnchor) or default_rel or anchor
	local x = (p and p.x) or default_x or 0
	local y = (p and p.y) or default_y or 0
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if frame.SetPoint then
		frame:SetPoint(anchor, _G.UIParent or frame:GetParent(), rel, x, y)
	end
	if frame.enableDrag then
		frame:enableDrag(moduleId)
	end
end

function addon:bootstrap()
	WoWEvents:init()
	SavedVars:load()
	-- Diagnose-Tracer: capture ADDON_ACTION_BLOCKED/FORBIDDEN mit Stack & function name.
	-- Schreibt direkt in DEFAULT_CHAT_FRAME (bypassen das normale Print).
	if CreateFrame and DEFAULT_CHAT_FRAME then
		local diag = CreateFrame("Frame", "BlizzActionDiag", UIParent)
		diag:RegisterEvent("ADDON_ACTION_BLOCKED")
		diag:RegisterEvent("ADDON_ACTION_FORBIDDEN")
		diag:SetScript("OnEvent", function(_, ev, addonName, funcName)
			local msg = string.format(
				"|cffff4444[BlizzDiag]|r %s addon=%s func=%q",
				tostring(ev),
				tostring(addonName),
				tostring(funcName)
			)
			DEFAULT_CHAT_FRAME:AddMessage(msg)
			DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa" .. tostring(debugstack(2, 6, 0)) .. "|r")
			table.insert(
				addon.errors,
				{ event = ev, err = (funcName or "?") .. " :: " .. tostring(addonName) }
			)
		end)
	end
	local p = SavedVars:getCurrentProfile() or {}
	local disabled = p.disabled or {}
	for id, mod in pairs(self.modules) do
		if disabled[id] then
			DEFAULT_CHAT_FRAME:AddMessage("|cff999999[Blizz]|r module disabled: " .. id)
		elseif mod.init then
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
		elseif msg:match("^disable ") then
			local mod_id = msg:match("^disable%s+(%S+)")
			local profile = addon.SavedVars:getCurrentProfile()
			if profile and mod_id then
				profile.disabled = profile.disabled or {}
				profile.disabled[mod_id] = true
				print(
					"|cff7ed9ff[Blizz]|r " .. mod_id .. " disabled — /reload um wirksam zu werden"
				)
			end
		elseif msg:match("^enable ") then
			local mod_id = msg:match("^enable%s+(%S+)")
			local profile = addon.SavedVars:getCurrentProfile()
			if profile and mod_id then
				profile.disabled = profile.disabled or {}
				profile.disabled[mod_id] = nil
				print(
					"|cff7ed9ff[Blizz]|r " .. mod_id .. " enabled — /reload um wirksam zu werden"
				)
			end
		elseif msg == "modules" then
			for id, _ in pairs(addon.modules) do
				print("  " .. id)
			end
		elseif msg:match("^capture ") then
			local target = msg:match("^capture%s+(%S+)")
			local affix_mod = addon.modules.affix_s1
			if not affix_mod or not affix_mod.setCaptureMode then
				print("|cff7ed9ff[Blizz]|r affix_s1 module not loaded")
			elseif target == "off" or target == "stop" then
				affix_mod:setCaptureMode(nil)
				print("|cff7ed9ff[Blizz]|r capture mode OFF")
			elseif
				target == "voidbound"
				or target == "pulsar"
				or target == "devour"
				or target == "ascendant"
			then
				affix_mod:setCaptureMode(target)
				print(
					"|cff7ed9ff[Blizz]|r capture mode "
						.. target
						.. " — neue Mobs in Sichtweite werden gemeldet"
				)
				print("|cff7ed9ff[Blizz]|r /blizz capture off zum stoppen")
			else
				print(
					"|cff7ed9ff[Blizz]|r usage: /blizz capture voidbound|pulsar|devour|ascendant|off"
				)
			end
		else
			print(
				"|cff7ed9ff[Blizz]|r commands: status, errors, modules, disable <id>, enable <id>, capture <bargain>"
			)
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
