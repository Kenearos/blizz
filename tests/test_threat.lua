require("tests.mocks.wow_api")
require("Blizz")
local Threat = require("modules.threat")

local addon = _G.Blizz

MockReset()
MockSetUnit("target", { health = 100000, maxHealth = 100000 })

assert(addon.modules.threat == Threat, "threat module registered")
print("✓ module registered with id 'threat'")

addon:bootstrap()
assert(Threat.pill, "threat pill exists")
assert(Threat.lost_alert, "lost-aggro alert exists")
assert(not Threat.lost_alert:IsShown(), "lost-alert starts hidden")
print("✓ init() creates pill + alert (hidden)")

-- securely tanking → pill ready, alert hidden
MockSetThreat(3)
addon.EventBus:dispatch("UNIT_THREAT_SITUATION_UPDATE", "player")
assert(Threat.pill:getState() == "ready", "tanking → pill is ready (filled)")
assert(not Threat.lost_alert:IsShown(), "no alert when securely tanking")
print("✓ pill = ready when tanking")

-- threat dropped → pill alert + lost alert visible
MockSetThreat(1)
addon.EventBus:dispatch("UNIT_THREAT_SITUATION_UPDATE", "player")
assert(Threat.pill:getState() == "alert", "low threat → pill alert")
assert(Threat.lost_alert:IsShown(), "alert shown when losing aggro")
print("✓ pill + alert on lost aggro")

-- recovered → pill ready, alert hidden
MockSetThreat(3)
addon.EventBus:dispatch("UNIT_THREAT_SITUATION_UPDATE", "player")
assert(Threat.pill:getState() == "ready", "recovered → ready")
assert(not Threat.lost_alert:IsShown(), "alert hidden after recovery")
print("✓ recovery flips pill + hides alert")
