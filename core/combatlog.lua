local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/combatlog.lua
-- Klassifiziert COMBAT_LOG_EVENT_UNFILTERED in einfache Kategorien.
-- Subscriber: CombatLog:on("interrupt", fn) / "death" / "cast_start" / "cast_success".

local CombatLog = {}
CombatLog.__handlers = {}

local function fire(kind, payload)
	local hs = CombatLog.__handlers[kind]
	if not hs then
		return
	end
	for _, h in ipairs(hs) do
		local ok, err = pcall(h, payload)
		if not ok and addon.errors then
			table.insert(addon.errors, { event = "CLEU:" .. kind, err = tostring(err) })
		end
	end
end

local function build_payload(
	timestamp,
	subEvent,
	sourceGUID,
	sourceName,
	destGUID,
	destName,
	spellID,
	spellName
)
	return {
		timestamp = timestamp,
		subEvent = subEvent,
		sourceGUID = sourceGUID,
		sourceName = sourceName,
		destGUID = destGUID,
		destName = destName,
		spellID = spellID,
		spellName = spellName,
	}
end

function CombatLog:on(kind, callback)
	self.__handlers[kind] = self.__handlers[kind] or {}
	table.insert(self.__handlers[kind], callback)
end

function CombatLog:dispatch(
	timestamp,
	subEvent,
	_hideCaster,
	sourceGUID,
	sourceName,
	_sf,
	_srf,
	destGUID,
	destName,
	_df,
	_drf,
	spellID,
	spellName
)
	if subEvent == "SPELL_INTERRUPT" then
		fire(
			"interrupt",
			build_payload(
				timestamp,
				subEvent,
				sourceGUID,
				sourceName,
				destGUID,
				destName,
				spellID,
				spellName
			)
		)
	elseif subEvent == "UNIT_DIED" then
		fire(
			"death",
			build_payload(
				timestamp,
				subEvent,
				sourceGUID,
				sourceName,
				destGUID,
				destName,
				spellID,
				spellName
			)
		)
	elseif subEvent == "SPELL_CAST_START" then
		fire(
			"cast_start",
			build_payload(
				timestamp,
				subEvent,
				sourceGUID,
				sourceName,
				destGUID,
				destName,
				spellID,
				spellName
			)
		)
	elseif subEvent == "SPELL_CAST_SUCCESS" then
		fire(
			"cast_success",
			build_payload(
				timestamp,
				subEvent,
				sourceGUID,
				sourceName,
				destGUID,
				destName,
				spellID,
				spellName
			)
		)
	end
end

function CombatLog:init()
	-- in WoW Midnight 12.0+: COMBAT_LOG_EVENT_UNFILTERED ist als catch-all-Event
	-- für Addons restricted (Blizzard's Addon-Prune). Registrierung outside of
	-- allow-listed/guarded contexts kann das ADDON_ACTION_BLOCKED Popup ohne
	-- Chat-Output triggern. Daher hier nur in Test-Mode wirklich subscriben;
	-- production läuft ohne CLEU bis wir einen sicheren Pfad gefunden haben.
	--
	-- Konsequenz: Death-Counter, Kickrota-Tracking und Party-CDs bleiben stumm
	-- bis CLEU re-aktiviert ist. Module sind funktionsfähig, sehen nur keine Events.
	local function on_event(...)
		self:dispatch(...)
	end
	if MockSetCLEUListener then -- test mode
		MockSetCLEUListener(on_event)
		return
	end
	-- production: CLEU bewusst NICHT registriert (siehe Kommentar oben).
	-- Wenn Blizzard die Restriction lockert, hier wieder einkommentieren:
	-- local f = CreateFrame("Frame", "BlizzCLEU")
	-- f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	-- f:SetScript("OnEvent", function()
	-- 	if CombatLogGetCurrentEventInfo then
	-- 		on_event(CombatLogGetCurrentEventInfo())
	-- 	end
	-- end)
end

addon.CombatLog = CombatLog
return CombatLog
