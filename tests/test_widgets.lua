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
