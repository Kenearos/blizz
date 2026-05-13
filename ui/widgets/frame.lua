local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/frame.lua
-- Themed Frame mit v6-Theming + Tech-Corner-Brackets.
-- States: default | ready | cd | alert.
-- Defensiv gegen API-Drift (BackdropTemplate, SetBackdrop) in Midnight 12.0.

local Theme = addon.Theme or require("ui.theme")

local Frame = {}

local function safe_call(fn, ...)
	if not fn then
		return
	end
	pcall(fn, ...)
end

local function apply_default(f)
	safe_call(f.SetBackdropColor, f, Theme.getColor("bg_primary"))
	safe_call(f.SetBackdropBorderColor, f, Theme.getColor("primary"))
end
local function apply_ready(f)
	safe_call(f.SetBackdropColor, f, Theme.getColor("ready_bg"))
	safe_call(f.SetBackdropBorderColor, f, Theme.getColor("primary_hi"))
end
local function apply_cd(f)
	safe_call(f.SetBackdropColor, f, Theme.getColor("bg_primary"))
	safe_call(f.SetBackdropBorderColor, f, Theme.getColor("cd_border"))
end
local function apply_alert(f)
	safe_call(f.SetBackdropColor, f, Theme.getColor("alert_deep"))
	safe_call(f.SetBackdropBorderColor, f, Theme.getColor("alert"))
end

local function make_corner(parent, anchor1, anchor2)
	local c = parent:CreateTexture(nil, "OVERLAY")
	c:SetSize(6, 6)
	c:SetVertexColor(Theme.getColor("primary"))
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

	-- Defensive: SetBackdrop might error if BackdropTemplate doesn't inject it.
	-- In Midnight 12.0+, edge_size must be integer in some versions.
	local edge_size = math.max(1, math.floor(Theme.layout.border_width or 1))
	if f.SetBackdrop then
		pcall(f.SetBackdrop, f, {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = edge_size,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
	end

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
