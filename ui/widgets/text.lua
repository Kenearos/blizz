local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/text.lua
-- Themed FontString mit Style-Profilen.
-- Styles: default | value | label | alert | title.
-- Defensiv gegen SetFont-Failures in Midnight 12.0 (custom font paths können throwen).

local Theme = addon.Theme or require("ui.theme")

local STYLE = {
	default = { color = "primary", size_key = "default_size" },
	value = { color = "info", size_key = "value_size" },
	label = { color = "cd_text", size_key = "default_size" },
	alert = { color = "info", size_key = "alert_size" },
	title = { color = "primary_hi", size_key = "default_size" },
}

local Text = {}

function Text:new(spec)
	assert(spec and spec.parent, "Text:new requires {parent=...}")
	local layer = spec.layer or "OVERLAY"
	-- Inherit from GameFontNormal — gibt uns einen Default-Font falls SetFont später failt.
	local fs = spec.parent:CreateFontString(spec.name, layer, "GameFontNormal")
	local style = STYLE[spec.style or "default"] or STYLE.default
	local size = Theme.fonts[style.size_key] or Theme.fonts.default_size

	-- SetFont in pcall — in 12.0 kann ein nicht-ladbarer Font-Pfad einen Error werfen.
	-- Fallback auf den vererbten GameFontNormal Font wenn unser Custom-Font failt.
	local font_ok = false
	if fs.SetFont then
		font_ok = pcall(fs.SetFont, fs, Theme.fonts.family, size, "OUTLINE")
	end
	if not font_ok and fs.SetFont then
		-- Versuche Fallback-Font
		pcall(fs.SetFont, fs, Theme.fonts.fallback, size, "OUTLINE")
	end

	if fs.SetTextColor then
		pcall(fs.SetTextColor, fs, Theme.getColor(style.color))
	end
	if spec.text and fs.SetText then
		fs:SetText(spec.text)
	end
	return fs
end

addon.Text = Text
return Text
