require("tests.mocks.wow_api")
local Theme = require("ui.theme")
local Frame = require("ui.widgets.frame")
local Text = require("ui.widgets.text")

-- Frame: erzeugt themed Frame, hat Tech-Corner-Brackets
local f = Frame:new({ name = "TestFrame", parent = UIParent, width = 100, height = 30 })
assert(f.__type == "Frame", "should be a Frame stub")
assert(f.__size[1] == 100 and f.__size[2] == 30, "size set")
assert(f.__corners, "tech corner brackets should be created")
assert(f.__corners.topleft and f.__corners.bottomright, "corners present")
print("✓ Frame:new creates themed frame with corners")

-- Frame state inversion: setReady() wendet Cyan-Fill an
f:setReady()
assert(f.__state == "ready", "state should be ready")
f:setDefault()
assert(f.__state == "default", "state back to default")
print("✓ Frame state switching")

-- Text: setzt Mono-Font + value-Color
local t = Text:new({ parent = f, text = "4.8s", style = "value" })
assert(t.__type == "FontString", "Text should be FontString")
assert(t.__text == "4.8s", "text content set")
assert(t.__font ~= nil, "font set")
print("✓ Text:new creates themed font string")

local Icon = require("ui.widgets.icon")

-- Icon: default state = outline, primary color
local ico = Icon:new({ parent = UIParent, name = "WALL", spellID = 871, size = 38 })
assert(ico.__type == "Frame", "Icon root should be Frame")
assert(ico:getState() == "default", "default state initially")
assert(ico:getLabel() == "WALL", "label set")
print("✓ Icon default state")

-- Setze auf ready → invertierte Farben
ico:setReady()
assert(ico:getState() == "ready", "ready state")
print("✓ Icon ready state")

-- Setze auf cd → grau + remaining
ico:setCD(22)
assert(ico:getState() == "cd", "cd state")
assert(ico:getRemainingText() == "22s", "remaining text")
print("✓ Icon cd state with remaining")

local Bar = require("ui.widgets.bar")

-- Bar: füllen/leeren
local bar = Bar:new({ parent = UIParent, width = 200, height = 12 })
bar:setValue(0.5)
assert(math.abs(bar:getValue() - 0.5) < 0.001, "bar value 0.5")
bar:setValue(0)
assert(bar:getValue() == 0, "bar value 0")
bar:setValue(1.2) -- clamp
assert(bar:getValue() == 1, "bar value clamped to 1")
bar:setValue(-0.5) -- clamp
assert(bar:getValue() == 0, "bar value clamped to 0")
print("✓ Bar value setter + clamping")

bar:setValueFromRemaining(5, 10) -- 50% gone, 50% remaining
assert(math.abs(bar:getValue() - 0.5) < 0.001, "setValueFromRemaining")
print("✓ Bar setValueFromRemaining")

local Alert = require("ui.widgets.alert")

local alert = Alert:new({ parent = UIParent, text = "REFLECT INCOMING", width = 240, height = 32 })
assert(alert:getState() == "alert", "Alert default state is alert")
assert(alert:isPulsing() == false, "Alert not pulsing initially (created hidden)")
alert:show()
assert(alert:IsShown(), "Alert shown")
assert(alert:isPulsing(), "Alert pulses when shown")
alert:hide()
assert(not alert:IsShown(), "Alert hidden")
assert(not alert:isPulsing(), "Alert stops pulsing when hidden")
print("✓ Alert show/hide + pulse lifecycle")

alert:setText("KICK NOW")
assert(alert:getText() == "KICK NOW", "text updated")
print("✓ Alert text updates")

-- v7 Tier-1 patterns
local f_id =
	Frame:new({ name = "T_ID", parent = UIParent, width = 100, height = 30, id_code = "MIT-01" })
assert(f_id.__id_code, "id_code FontString created when id_code prop given")
assert(f_id.__id_code:GetText() == "[ MIT-01 ]", "id_code text formatted")
print("✓ v7: Frame id_code")

local f_h = Frame:new({ name = "T_HATCH", parent = UIParent, width = 100, height = 30 })
assert(f_h.__hatch_strip, "hatch_strip texture exists on all frames")
print("✓ v7: Frame hatch strip")

local f_p = Frame:new({ name = "T_PIP", parent = UIParent, width = 100, height = 30 })
assert(f_p.__status_pip, "status_pip texture exists")
assert(type(f_p.setPipState) == "function", "setPipState method exists")
f_p:setReady()
assert(f_p.__pip_state == "ready", "pip state ready after setReady")
f_p:setAlert()
assert(f_p.__pip_state == "alert", "pip state alert after setAlert")
f_p:setCD()
assert(f_p.__pip_state == "idle", "pip state idle after setCD")
print("✓ v7: Frame status pip state transitions")

local f_b = Frame:new({ name = "T_BOX", parent = UIParent, width = 200, height = 60 })
f_b:setBoxHeader("Mitigation")
assert(f_b.__box_header, "box_header FontString created via setBoxHeader")
assert(f_b.__box_header:GetText():match("MITIGATION"), "box header has uppercase title")
print("✓ v7: Frame box header")

-- I-08: Drag-to-Move support
local f_drag = Frame:new({ name = "T_DRAG", parent = UIParent, width = 100, height = 30 })
assert(type(f_drag.enableDrag) == "function", "enableDrag method exists")
f_drag:enableDrag("test_mod")
assert(f_drag.__drag_module_id == "test_mod", "drag module id stored")
assert(f_drag.__movable == true, "frame marked movable")
assert(f_drag.__mouseEnabled == true, "mouse enabled")
assert(f_drag.__dragButton == "LeftButton", "drag registered for LeftButton")
local on_drag_start = f_drag:GetScript("OnDragStart")
local on_drag_stop = f_drag:GetScript("OnDragStop")
assert(type(on_drag_start) == "function", "OnDragStart handler installed")
assert(type(on_drag_stop) == "function", "OnDragStop handler installed")
print("✓ v7+I-08: Frame:enableDrag installs drag handlers")

-- Drag in combat → StartMoving NOT called, flag set
MockSetCombat(true)
on_drag_start(f_drag)
assert(f_drag.__drag_started_in_combat == true, "combat-flagged drag start")
assert(f_drag.__moving ~= true, "no actual move started in combat")
MockSetCombat(false)
print("✓ v7+I-08: drag blocked in combat-lockdown")
