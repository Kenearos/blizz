local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- ui/widgets/frame.lua
-- Themed Frame mit v6-Theming + Tech-Corner-Brackets.
-- States: default | ready | cd | alert | priority.
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
local function apply_priority(f)
	safe_call(f.SetBackdropColor, f, Theme.getColor("bg_primary"))
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

-- v7 Tier-1: vertical hatch strip on left edge (6px wide, full height)
local function make_hatch_strip(parent)
	local t = parent:CreateTexture(nil, "OVERLAY")
	t:SetTexture("Interface\\Buttons\\WHITE8X8")
	t:SetVertexColor(Theme.getColor("hatch"))
	local w = Theme.layout.hatch_strip_w or 6
	t:SetWidth(w)
	if t.SetPoint then
		t:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
		t:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
	end
	return t
end

-- v7 Tier-1: ID-code FontString rendered in TOPLEFT
local function make_id_code(parent, id_code)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	local family = Theme.fonts.family or Theme.fonts.fallback
	if fs.SetFont then
		pcall(fs.SetFont, fs, family, 9, "")
	end
	if fs.SetTextColor then
		fs:SetTextColor(Theme.getColor("id_label"))
	end
	if fs.SetText then
		fs:SetText("[ " .. tostring(id_code) .. " ]")
	end
	if fs.SetPoint then
		fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, Theme.layout.id_label_offset_y or -2)
	end
	return fs
end

-- v7 Tier-1: 4x4 status pip in TOPRIGHT
local function make_status_pip(parent)
	local p = parent:CreateTexture(nil, "OVERLAY")
	local sz = Theme.layout.pip_size or 4
	p:SetTexture("Interface\\Buttons\\WHITE8X8")
	p:SetSize(sz, sz)
	p:SetVertexColor(Theme.getColor("pip_idle"))
	if p.SetPoint then
		p:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
	end
	return p
end

local PIP_TOKEN = {
	ready = "pip_ready",
	casting = "pip_cast",
	alert = "pip_alert",
	idle = "pip_idle",
}

local function apply_pip(f, state)
	local token = PIP_TOKEN[state] or "pip_idle"
	if f.__status_pip and f.__status_pip.SetVertexColor then
		f.__status_pip:SetVertexColor(Theme.getColor(token))
	end
	f.__pip_state = state
end

-- v7 Tier-1: ANSI box-drawing header.
-- Renders something like "┌─[ TITLE ]─────────┐" sized to frame width.
local function format_box_header(title, frame_w)
	local upper = string.upper(tostring(title or ""))
	local prefix = "┌─[ " .. upper .. " ]"
	local suffix = "┐"
	-- Approximate char-width for JetBrains Mono 10px ≈ 6.0px. Compute total chars.
	local char_w = 6.0
	local total_chars = math.max(#prefix + 2, math.floor((frame_w or 100) / char_w))
	-- ASCII length is fine for prefix because box chars count as multi-byte in #;
	-- but we only need a rough dash count for layout. Use a visible-glyph estimate:
	-- prefix visible glyphs ≈ 4 + #upper + 3 = #upper + 7
	local visible_prefix = #upper + 7
	local visible_suffix = 1
	local dashes = math.max(3, total_chars - visible_prefix - visible_suffix)
	return prefix .. string.rep("─", dashes) .. suffix
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

	-- v7 Tier-1: vertical hatch strip on left edge (all frames)
	f.__hatch_strip = make_hatch_strip(f)

	-- v7 Tier-1: 4x4 status pip in TOPRIGHT (all frames, starts idle)
	f.__status_pip = make_status_pip(f)
	f.__pip_state = "idle"

	-- v7 Tier-1: optional ID-code strip
	if spec.id_code and spec.id_code ~= "" then
		f.__id_code = make_id_code(f, spec.id_code)
	end

	-- I-08: Drag-to-Move support. Activated explicitly via Frame:enableDrag(moduleId).
	-- Uses SavedVars to persist position; combat-lockdown aware.
	f.__drag_module_id = nil
	f.__drag_started_in_combat = false
	function f:enableDrag(moduleId)
		assert(
			type(moduleId) == "string" and moduleId ~= "",
			"enableDrag requires a moduleId string"
		)
		self.__drag_module_id = moduleId
		if self.SetMovable then
			self:SetMovable(true)
		end
		if self.EnableMouse then
			self:EnableMouse(true)
		end
		if self.RegisterForDrag then
			self:RegisterForDrag("LeftButton")
		end
		if self.SetScript then
			self:SetScript("OnDragStart", function(frame)
				-- In Combat: WoW blocks SetPoint on protected frames. Our frames are
				-- non-secure (UIParent-parented), but better safe than the dread popup.
				if _G.InCombatLockdown and _G.InCombatLockdown() then
					frame.__drag_started_in_combat = true
					return
				end
				if frame.StartMoving then
					frame:StartMoving()
				end
			end)
			self:SetScript("OnDragStop", function(frame)
				if frame.__drag_started_in_combat then
					frame.__drag_started_in_combat = false
					return
				end
				if frame.StopMovingOrSizing then
					frame:StopMovingOrSizing()
				end
				-- Persist position relative to UIParent's CENTER for stability across resolutions.
				if frame.GetPoint and addon.SavedVars and addon.SavedVars.setPosition then
					local anchor, _, relativeAnchor, x, y = frame:GetPoint()
					addon.SavedVars:setPosition(
						frame.__drag_module_id,
						anchor or "CENTER",
						x or 0,
						y or 0,
						relativeAnchor or anchor or "CENTER"
					)
				end
			end)
		end
	end

	-- State-API
	f.__state = "default"
	function f:getState()
		return self.__state
	end
	function f:setPipState(state)
		apply_pip(self, state)
	end
	function f:setDefault()
		self.__state = "default"
		apply_default(self)
		apply_pip(self, "idle")
	end
	function f:setReady()
		self.__state = "ready"
		apply_ready(self)
		apply_pip(self, "ready")
	end
	function f:setCD()
		self.__state = "cd"
		apply_cd(self)
		apply_pip(self, "idle")
	end
	function f:setAlert()
		self.__state = "alert"
		apply_alert(self)
		apply_pip(self, "alert")
	end
	function f:setPriority()
		self.__state = "priority"
		apply_priority(self)
		apply_pip(self, "alert")
	end

	-- v7 Tier-1: opt-in ANSI box-drawing header
	function f:setBoxHeader(title)
		if title == nil or title == "" then
			-- Clear: hide existing if present
			if self.__box_header and self.__box_header.SetText then
				self.__box_header:SetText("")
			end
			return
		end
		if not self.__box_header then
			local fs = self:CreateFontString(nil, "OVERLAY")
			local family = Theme.fonts.family or Theme.fonts.fallback
			local sz = Theme.layout.box_header_size or 10
			if fs.SetFont then
				pcall(fs.SetFont, fs, family, sz, "")
			end
			if fs.SetTextColor then
				fs:SetTextColor(Theme.getColor("box_header"))
			end
			if fs.SetPoint then
				fs:SetPoint("TOPLEFT", self, "TOPLEFT", 0, sz + 2)
			end
			self.__box_header = fs
		end
		local w = (self.__size and self.__size[1]) or (self.GetWidth and self:GetWidth()) or 100
		if self.__box_header.SetText then
			self.__box_header:SetText(format_box_header(title, w))
		end
	end

	apply_default(f)
	apply_pip(f, "idle")
	return f
end

addon.Frame = Frame
return Frame
