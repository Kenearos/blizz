require("tests.mocks.wow_api")
local Cooldowns = require("core.cooldowns")

MockReset()
MockSetTime(1000)

-- spell off cooldown
MockSetCooldown(871, 0, 0) -- Shield Wall, not used
local st = Cooldowns:getState(871)
assert(st.ready == true, "fresh spell should be ready")
assert(st.remaining == 0, "remaining should be 0")
print("✓ ready spell detected")

-- spell on cooldown
MockSetCooldown(871, 995, 240) -- started 5s ago, 240s CD
st = Cooldowns:getState(871)
assert(st.ready == false, "spell on CD should not be ready")
assert(math.abs(st.remaining - 235) < 0.1, "remaining should be ~235s (got " .. st.remaining .. ")")
assert(math.abs(st.percent - (5 / 240)) < 0.01, "percent should be ~2%")
print("✓ on-cd spell calculated correctly")

-- spell mit charges
MockSetCooldown(100, 995, 20, 2, 3) -- Charge: 2 of 3 charges, recharging
st = Cooldowns:getState(100)
assert(st.charges == 2, "charges should be 2")
assert(st.maxCharges == 3, "maxCharges should be 3")
assert(st.ready == true, "spell with charges available should be ready")
print("✓ charges tracked correctly")

-- bulk poll
MockSetCooldown(1, 0, 0)
MockSetCooldown(2, 999, 10)
local states = Cooldowns:getStates({ 1, 2 })
assert(states[1].ready and not states[2].ready, "bulk poll")
print("✓ bulk getStates works")
