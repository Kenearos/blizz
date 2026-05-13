local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/spells_prot_warrior.lua
-- Spell-IDs für Protection Warrior in WoW Midnight 12.0.5.
-- Quelle: Wowhead + Class-Guides. Bei jedem WoW-Patch verifizieren.
-- Hero-Talent-Spells für Mountain Thane (~96% Usage) + Colossus (~3% Usage)
-- sind in eigenen sub-tables unten. IDs verifiziert via Wowhead Mai 2026.

local Spells = {}

Spells.active_mitigation = {
	shield_block = 2565, -- 6s aura, +Block-Chance, blockt magic damage mit Heavy Repercussions talent
	ignore_pain = 190456, -- absorb buff, 40 rage cost, off-GCD
}

Spells.defensives = {
	shield_wall = 871, -- 8s, 40% DR, ~3.5min CD
	last_stand = 12975, -- 15s, +30% max HP
	spell_reflection = 23920, -- 5s, reflektiert nächsten Single-Target-Spell
	demoralizing_shout = 1160, -- 8s, -20% damage from affected enemies
	rallying_cry = 97462, -- 10s, +15% HP group-wide
	avatar = 107574, -- offensive but pairs with defensives (CD-rotation)
	demoralizing_banner = 236320, -- talented (Bannerlord), platziert Banner
	charge = 100, -- mobility/Charge-Pool
	demolish = 436358, -- Colossus only: channeled big-damage + 10% DR + stun-immune during channel (45s CD)
}

Spells.utility = {
	pummel = 6552, -- interrupt, 15s CD (with talents)
	heroic_leap = 6544, -- jump mobility
	intervene = 3411, -- friendly Charge
	berserker_rage = 18499, -- fear-break, rage burst
}

-- Mountain Thane hero talent tree (~96% Usage in S1, dominant choice).
-- Alle Spells sind passive Procs/Buffs — keine active defensives. Diese sub-table
-- ist für künftige Buff/Proc-Tracker und Aura-Anzeigen relevant, nicht für die
-- Defensive-CD-Bar. Quelle: wowhead spell-IDs.
Spells.hero_talent_mountain_thane = {
	lightning_strikes = 434969, -- passive AoE-Proc auf Melee-Swings
	thorims_might = 436152, -- passive Buff aktiv während Avatar
	thunder_blast = 435607, -- transformiert Thunder Clap, stacks bis 2
	burst_of_power = 437121, -- proc: Shield-Slam-CD-reset (15% chance)
	crashing_thunder = 436707, -- passive Thunder-Clap-Modifier
	ground_current = 436148, -- passive AoE-Splash auf Lightning-Strikes
}

-- Colossus hero talent tree (~3% Usage in S1, niche). Demolish ist die einzige
-- active ability (auch in Spells.defensives gelistet wegen 10% DR im Channel).
-- Quelle: wowhead spell-IDs.
Spells.hero_talent_colossus = {
	demolish = 436358, -- active 45s CD, channel + 10% DR + stun-immun
	earthquaker = 440992, -- passive Shockwave-Modifier (-5s CD)
	boneshaker = 429639, -- passive Shockwave-Modifier (+1s stun + slow)
	practiced_strikes = 429647, -- passive +15% damage auf Shield Slam/Revenge/Thunder Clap
	tide_of_battle = 429641, -- passive Revenge-Buff
	colossal_might = 440989, -- buff-stack resource
	dominance_of_colossus = 429636, -- passive capstone
}

-- Reihenfolge im Defensive-CD-Bar (links nach rechts)
Spells.defensive_bar_order = {
	Spells.defensives.shield_wall,
	Spells.defensives.last_stand,
	Spells.defensives.spell_reflection,
	Spells.defensives.demoralizing_shout,
	Spells.defensives.rallying_cry,
	Spells.defensives.avatar,
	Spells.defensives.demoralizing_banner,
	Spells.defensives.charge,
}

-- Convenience: Reverse-Lookup spellID → label (für Icon-Beschriftung)
Spells.labels = {
	[2565] = "SBLK",
	[190456] = "IP",
	[871] = "WALL",
	[12975] = "LS",
	[23920] = "SPRFL",
	[1160] = "DEMO",
	[97462] = "RALLY",
	[107574] = "AVTR",
	[236320] = "BNR",
	[100] = "CHA",
	[6552] = "PMML",
	[6544] = "LEAP",
	[3411] = "ITVN",
	[18499] = "BRSK",
	[436358] = "DMLSH", -- Demolish (Colossus)
	[435607] = "TBLST", -- Thunder Blast (Mountain Thane)
	[437121] = "BURST", -- Burst of Power proc
}

addon.SpellsProtWarrior = Spells
return Spells
