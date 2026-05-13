local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/text.lua
-- Themed FontString mit Style-Profilen.
-- Styles: default | value | label | alert | title.

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
	local fs = spec.parent:CreateFontString(spec.name, layer)
	local style = STYLE[spec.style or "default"] or STYLE.default
	local size = Theme.fonts[style.size_key] or Theme.fonts.default_size
	fs:SetFont(Theme.fonts.family, size, "OUTLINE")
	fs:SetTextColor(Theme.getColor(style.color))
	if spec.text then
		fs:SetText(spec.text)
	end
	return fs
end

addon.Text = Text
return Text
