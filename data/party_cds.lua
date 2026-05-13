local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/party_cds.lua
-- Top externe Defensives für M+ (Tank-Perspektive).
-- Map [spellID] = { name, default_cd, label }.
-- Default-CDs in Sekunden, ohne Talent-CDR (Talents werden hier nicht modelliert —
-- die DB ist absichtlich klein; für Vollabdeckung Phase X mit OmniCD-Daten-Import).

local PartyCDs = {
	[33206] = { name = "Pain Suppression", label = "PS", default_cd = 180 },
	[62618] = { name = "Power Word: Barrier", label = "BARR", default_cd = 180 },
	[29166] = { name = "Innervate", label = "INV", default_cd = 180 },
	[740] = { name = "Tranquility", label = "TRNQ", default_cd = 180 },
	[1022] = { name = "Blessing of Protection", label = "BoP", default_cd = 300 },
	[6940] = { name = "Blessing of Sacrifice", label = "BoSac", default_cd = 120 },
	[633] = { name = "Lay on Hands", label = "LoH", default_cd = 600 },
	[116849] = { name = "Life Cocoon", label = "COC", default_cd = 120 },
	[115310] = { name = "Revival", label = "REV", default_cd = 180 },
	[51052] = { name = "Anti-Magic Zone", label = "AMZ", default_cd = 120 },
}

addon.PartyCDsData = PartyCDs
return PartyCDs
