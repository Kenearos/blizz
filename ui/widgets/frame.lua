local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/frame.lua
-- Themed Frame mit v6-Theming. Tech-Corner-Brackets oben-links und unten-rechts.
-- States: default | ready | cd | alert.

local Theme = addon.Theme or require("ui.theme")

local Frame = {}

local function apply_default(f)
	f:SetBackdropColor(Theme.getColor("bg_primary"))
	f:SetBackdropBorderColor(Theme.getColor("primary"))
end
local function apply_ready(f)
	f:SetBackdropColor(Theme.getColor("ready_bg"))
	f:SetBackdropBorderColor(Theme.getColor("primary_hi"))
end
local function apply_cd(f)
	f:SetBackdropColor(Theme.getColor("bg_primary"))
	f:SetBackdropBorderColor(Theme.getColor("cd_border"))
end
local function apply_alert(f)
	f:SetBackdropColor(Theme.getColor("alert_deep"))
	f:SetBackdropBorderColor(Theme.getColor("alert"))
end

local function make_corner(parent, anchor1, anchor2)
	local c = parent:CreateTexture(nil, "OVERLAY")
	c:SetSize(6, 6)
	c:SetVertexColor(Theme.getColor("primary"))
	-- in production this draws an L-shape via two textures; here it's a stub
	c:SetTexture("Interface\\Buttons\\WHITE8X8")
	if c.SetPoint then
		c:SetPoint(anchor1, parent, anchor2 or anchor1, 0, 0)
	end
	return c
end

function Frame:new(spec)
	spec = spec or {}
	local f = CreateFrame("Frame", spec.name, spec.parent or UIParent, "BackdropTemplate")
	f:SetSize(spec.width or 100, spec.height or 30)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = Theme.layout.border_width,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})

	-- Tech-Corner-Brackets (L-Marker)
	f.__corners = {
		topleft = make_corner(f, "TOPLEFT"),
		bottomright = make_corner(f, "BOTTOMRIGHT"),
	}

	-- State-API
	f.__state = "default"
	function f:getState()
		return self.__state
	end
	function f:setDefault()
		self.__state = "default"
		apply_default(self)
	end
	function f:setReady()
		self.__state = "ready"
		apply_ready(self)
	end
	function f:setCD()
		self.__state = "cd"
		apply_cd(self)
	end
	function f:setAlert()
		self.__state = "alert"
		apply_alert(self)
	end

	apply_default(f)
	return f
end

addon.Frame = Frame
return Frame
