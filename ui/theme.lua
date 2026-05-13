local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/theme.lua
-- v6 Cyan Cyber Tactical Tokens (siehe docs/superpowers/specs/2026-05-13-blizz-tank-ui-design.md §4)
-- Farben als {r, g, b, a} normalisiert auf [0,1].

local Theme = {}

Theme.colors = {
	bg_primary = { 0.008, 0.024, 0.059, 1.00 }, -- #02060f
	primary = { 0.494, 0.851, 1.000, 1.00 }, -- #7ed9ff
	primary_hi = { 0.831, 0.933, 0.976, 1.00 }, -- #d4eef9
	ready_bg = { 0.494, 0.851, 1.000, 1.00 }, -- #7ed9ff
	ready_fg = { 0.000, 0.102, 0.165, 1.00 }, -- #001a2a
	alert = { 1.000, 0.161, 0.400, 1.00 }, -- #ff2966
	alert_deep = { 0.502, 0.000, 0.125, 1.00 }, -- #800020
	info = { 0.941, 0.941, 0.941, 1.00 }, -- #f0f0f0
	caster = { 1.000, 0.365, 0.784, 1.00 }, -- #ff5dc8
	frontal = { 0.302, 0.878, 0.784, 1.00 }, -- #4de0c8
	healer = { 0.773, 1.000, 0.180, 1.00 }, -- #c5ff2e
	cd_border = { 0.165, 0.227, 0.290, 1.00 }, -- #2a3a4a
	cd_text = { 0.353, 0.439, 0.502, 1.00 }, -- #5a7080
	-- v7 Tier-1 visual-pattern tokens
	hatch = { 0.494, 0.851, 1.000, 0.35 },
	id_label = { 0.494, 0.851, 1.000, 0.60 },
	pip_ready = { 0.494, 0.851, 1.000, 1.00 },
	pip_cast = { 0.302, 0.878, 0.784, 1.00 },
	pip_alert = { 1.000, 0.161, 0.400, 1.00 },
	pip_idle = { 0.353, 0.439, 0.502, 0.40 },
	box_header = { 0.494, 0.851, 1.000, 0.70 },
}

Theme.fonts = {
	family = "Interface\\AddOns\\Blizz\\fonts\\JetBrainsMono-Bold.ttf",
	fallback = "Fonts\\FRIZQT__.TTF",
	default_size = 12,
	value_size = 13,
	alert_size = 16,
}

Theme.layout = {
	border_width = 1.5,
	outer_ring_offset = 1.5,
	letter_spacing_title = 3, -- WoW kennt kein letter-spacing — wird via Spacing-Hack umgesetzt
	radius = 0,
	container_radius = 4,
	-- v7 Tier-1 layout knobs
	hatch_strip_w = 6,
	id_label_offset_y = -2,
	pip_size = 4,
	box_header_size = 10,
}

-- Convenience: getColor("primary") → 4 separate Werte (für SetColorRGBA-Style)
function Theme.getColor(key)
	local c = Theme.colors[key]
	if not c then
		return 1, 1, 1, 1
	end
	return c[1], c[2], c[3], c[4]
end

addon.Theme = Theme
return Theme
