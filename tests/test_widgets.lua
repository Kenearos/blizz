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
assert(alert:isShown(), "Alert shown")
assert(alert:isPulsing(), "Alert pulses when shown")
alert:hide()
assert(not alert:isShown(), "Alert hidden")
assert(not alert:isPulsing(), "Alert stops pulsing when hidden")
print("✓ Alert show/hide + pulse lifecycle")

alert:setText("KICK NOW")
assert(alert:getText() == "KICK NOW", "text updated")
print("✓ Alert text updates")
