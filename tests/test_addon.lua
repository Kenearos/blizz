require("tests.mocks.wow_api")
require("Blizz") -- loads main entry, populates _G.Blizz

assert(_G.Blizz, "Blizz global should exist")
assert(type(_G.Blizz.registerModule) == "function", "registerModule should be function")
assert(type(_G.Blizz.modules) == "table", "modules registry")
print("✓ Blizz main entry sets up registry")

-- register a fake module
local fired = 0
local fake = {
	id = "fake",
	events = { "PLAYER_LOGIN" },
	init = function(self)
		self.initialized = true
	end,
	onEvent = function(self, _ev)
		fired = fired + 1
	end,
}
_G.Blizz.registerModule(fake)
assert(_G.Blizz.modules.fake == fake, "fake module registered")
_G.Blizz:bootstrap()
assert(fake.initialized, "module init called by bootstrap")

-- dispatch via internal EventBus
_G.Blizz.EventBus:dispatch("PLAYER_LOGIN")
assert(fired == 1, "subscribed module should receive event")
print("✓ module registry + bootstrap + event routing")

-- slash command sets status
SLASH_BLIZZ1 = nil
SlashCmdList = {}
_G.Blizz:registerSlash()
assert(SLASH_BLIZZ1 == "/blizz", "slash registered")
assert(type(SlashCmdList.BLIZZ) == "function", "slash handler set")
local ok = pcall(SlashCmdList.BLIZZ, "status")
assert(ok, "slash 'status' handler must not error")
print("✓ slash command registers and handles 'status'")
