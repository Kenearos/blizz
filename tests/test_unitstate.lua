require("tests.mocks.wow_api")
local UnitState = require("core.unitstate")

MockReset()
MockSetUnit("player", { health = 50000, maxHealth = 100000, absorb = 38000 })
MockSetThreat(3)

assert(UnitState:getHealth("player") == 50000, "getHealth")
assert(UnitState:getMaxHealth("player") == 100000, "getMaxHealth")
assert(math.abs(UnitState:getHealthPercent("player") - 0.5) < 0.001, "getHealthPercent")
assert(UnitState:getAbsorb("player") == 38000, "getAbsorb")
print("✓ health/absorb readout")

assert(UnitState:getThreatLevel("player", "target") == 3, "getThreatLevel")
assert(UnitState:isTanking("player", "target") == true, "isTanking at level 3")
MockSetThreat(2)
assert(UnitState:isTanking("player", "target") == false, "not tanking at level 2")
print("✓ threat helpers")

assert(UnitState:isInRange("party1") == true, "isInRange (mocked true)")
print("✓ range check")
