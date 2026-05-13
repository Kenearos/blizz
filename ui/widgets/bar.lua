local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/bar.lua
-- Horizontale Status-Bar. Value [0,1]. Theming aus v6.

local Frame = addon.Frame or require("ui.widgets.frame")
local Theme = addon.Theme or require("ui.theme")

local Bar = {}

function Bar:new(spec)
	spec = spec or {}
	local width, height = spec.width or 200, spec.height or 12
	local root =
		Frame:new({ name = spec.name, parent = spec.parent, width = width, height = height })

	local fill = root:CreateTexture(nil, "ARTWORK")
	fill:SetTexture("Interface\\Buttons\\WHITE8X8")
	fill:SetVertexColor(Theme.getColor("primary"))
	if fill.SetPoint then
		fill:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
		fill:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
	end
	if fill.SetSize then
		fill:SetSize(0, height)
	end

	root.__width = width
	root.__height = height
	root.__fill = fill
	root.__value = 0

	function root:setValue(v)
		v = math.min(1, math.max(0, v))
		self.__value = v
		if self.__fill.SetSize then
			self.__fill:SetSize(self.__width * v, self.__height)
		end
	end
	function root:getValue()
		return self.__value
	end
	function root:setValueFromRemaining(remaining, total)
		if total == 0 then
			self:setValue(0)
			return
		end
		self:setValue(remaining / total)
	end

	return root
end

addon.Bar = Bar
return Bar
