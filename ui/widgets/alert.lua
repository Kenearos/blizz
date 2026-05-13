local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/alert.lua
-- Pulsing Alert für Reflect-Style-Warnings.
-- Animation: 0.9s scale 1.0→1.04 + Alpha-Pulse zwischen alert_deep und alert.
-- Im Test-Modus wird die AnimationGroup als Mock geführt; isPulsing prüft Flag.

local Frame = addon.Frame or require("ui.widgets.frame")
local Text = addon.Text or require("ui.widgets.text")
local Theme = addon.Theme or require("ui.theme")

local Alert = {}

function Alert:new(spec)
	spec = spec or {}
	local root = Frame:new({
		name = spec.name,
		parent = spec.parent,
		width = spec.width or 240,
		height = spec.height or 32,
	})
	root:setAlert()

	local label = Text:new({ parent = root, text = spec.text or "", style = "alert" })
	if label.SetPoint then
		label:SetPoint("CENTER", root, "CENTER", 0, 0)
	end

	local pulse = root:CreateAnimationGroup()
	if pulse.SetLooping then
		pulse:SetLooping("REPEAT")
	end

	root.__label = label
	root.__pulse = pulse
	root.__pulsing = false

	-- start hidden (Alert nur sichtbar wenn ein Modul sie zeigt)
	root:Hide()

	function root:getState()
		return self.__state
	end
	function root:isPulsing()
		return self.__pulsing
	end
	function root:getText()
		return self.__label:GetText()
	end
	function root:setText(t)
		self.__label:SetText(t)
	end

	local origShow, origHide = root.Show, root.Hide
	function root:show()
		origShow(self)
		self.__pulsing = true
		if self.__pulse.Play then
			self.__pulse:Play()
		end
	end
	function root:hide()
		origHide(self)
		self.__pulsing = false
		if self.__pulse.Stop then
			self.__pulse:Stop()
		end
	end

	return root
end

addon.Alert = Alert
return Alert
