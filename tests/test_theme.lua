require("tests.mocks.wow_api")
local Theme = require("ui.theme")

-- alle Schlüssel da
local required_colors = {
	"bg_primary",
	"primary",
	"primary_hi",
	"ready_bg",
	"ready_fg",
	"alert",
	"alert_deep",
	"info",
	"caster",
	"frontal",
	"healer",
	"cd_border",
	"cd_text",
}
for _, key in ipairs(required_colors) do
	assert(Theme.colors[key], "missing color: " .. key)
	local c = Theme.colors[key]
	assert(type(c) == "table" and #c == 4, "color " .. key .. " is not {r,g,b,a}")
	for i = 1, 4 do
		assert(
			type(c[i]) == "number" and c[i] >= 0 and c[i] <= 1,
			"color " .. key .. "[" .. i .. "] out of [0,1]"
		)
	end
end
print("✓ all v6 color tokens present and well-formed")

-- spezifische bekannte Werte verifizieren
local primary = Theme.colors.primary
assert(math.abs(primary[1] - 0.494) < 0.01, "primary R")
assert(math.abs(primary[2] - 0.851) < 0.01, "primary G")
assert(math.abs(primary[3] - 1.000) < 0.01, "primary B")
print("✓ primary cyan #7ed9ff verified")

-- fonts und layout-tokens da
assert(Theme.fonts.family, "fonts.family missing")
assert(Theme.fonts.fallback, "fonts.fallback missing")
assert(Theme.fonts.default_size, "fonts.default_size missing")
assert(Theme.layout.border_width == 1.5, "border_width should be 1.5")
print("✓ font + layout tokens present")
