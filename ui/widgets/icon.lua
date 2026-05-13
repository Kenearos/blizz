local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/icon.lua
-- Spell-Icon mit ready/cd/default-States (Farb-Inversion per v6).
-- Spec: { parent, name, spellID, size, label?, sub? }

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")

local Icon = {}

function Icon:new(spec)
	spec = spec or {}
	local size = spec.size or 38
	local root =
		Frame:new({ name = spec.name, parent = spec.parent, width = size + 14, height = size + 6 })

	local label_text = spec.label
		or (spec.name and tostring(spec.name))
		or tostring(spec.spellID or "?")
	local label = Text:new({ parent = root, text = label_text, style = "default" })
	if label.SetPoint then
		label:SetPoint("CENTER", root, "CENTER", 0, 2)
	end

	local sub_text = ""
	local sub = Text:new({ parent = root, text = sub_text, style = "label" })
	if sub.SetPoint then
		sub:SetPoint("CENTER", root, "CENTER", 0, -8)
	end

	root.__label = label
	root.__sub = sub
	root.__labelText = label_text
	root.__remaining = nil

	function root:getState()
		return self.__state
	end
	function root:getLabel()
		return self.__labelText
	end
	function root:getRemainingText()
		return self.__remaining and (tostring(math.floor(self.__remaining)) .. "s") or ""
	end

	local origSetReady = root.setReady
	function root:setReady()
		origSetReady(self)
		self.__remaining = nil
		self.__sub:SetText("")
	end

	local origSetCD = root.setCD
	function root:setCD(remaining)
		origSetCD(self)
		self.__remaining = remaining or 0
		self.__sub:SetText(self:getRemainingText())
	end

	return root
end

addon.Icon = Icon
return Icon
