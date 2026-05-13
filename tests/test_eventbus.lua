require("tests.mocks.wow_api")
local EventBus = require("core.eventbus")

-- subscribe + dispatch
local count = 0
EventBus:subscribe("PLAYER_LOGIN", function()
	count = count + 1
end)
EventBus:dispatch("PLAYER_LOGIN")
EventBus:dispatch("PLAYER_LOGIN")
assert(count == 2, "subscriber should fire on each dispatch (got " .. count .. ")")
print("✓ subscribe/dispatch works")

-- mehrere subscriber für gleiches Event
local a, b = 0, 0
EventBus:subscribe("SPELL_UPDATE_COOLDOWN", function()
	a = a + 1
end)
EventBus:subscribe("SPELL_UPDATE_COOLDOWN", function()
	b = b + 1
end)
EventBus:dispatch("SPELL_UPDATE_COOLDOWN")
assert(a == 1 and b == 1, "both subscribers should fire")
print("✓ multi-subscriber works")

-- Error in einem Subscriber stoppt nicht die anderen
local survived = false
EventBus:subscribe("UNIT_AURA", function()
	error("oopsie")
end)
EventBus:subscribe("UNIT_AURA", function()
	survived = true
end)
EventBus:dispatch("UNIT_AURA")
assert(survived, "second subscriber should still fire after first errors")
print("✓ pcall containment works")

-- unsubscribe per token
local hit = 0
local token = EventBus:subscribe("PLAYER_DEAD", function()
	hit = hit + 1
end)
EventBus:dispatch("PLAYER_DEAD")
EventBus:unsubscribe(token)
EventBus:dispatch("PLAYER_DEAD")
assert(hit == 1, "unsubscribed callback should not fire (got " .. hit .. ")")
print("✓ unsubscribe by token works")

-- dispatch übergibt args
local got_args
EventBus:subscribe("UNIT_HEALTH", function(unit, value)
	got_args = { unit, value }
end)
EventBus:dispatch("UNIT_HEALTH", "player", 12345)
assert(got_args[1] == "player" and got_args[2] == 12345, "args passthrough")
print("✓ args passthrough works")
