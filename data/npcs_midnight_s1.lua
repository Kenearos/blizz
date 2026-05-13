local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- data/npcs_midnight_s1.lua
-- AUTO-GENERATED from MDT (MythicDungeonTools) Midnight-S1 dungeon data.
-- Generator: scripts/import-mdt-npcs.lua
-- Re-run after MDT updates: `luajit scripts/import-mdt-npcs.lua > data/npcs_midnight_s1.lua`
--
-- Kategorien:
--   'caster'        — name hint or magic-flagged spell
--   'healer'        — name hint (priest/mender/etc.)
--   'priority_kill' — health > 2x dungeon median
--   'generic'       — default
-- 'frontal' NICHT auto-erkannt — manuell in dieser DB nachpflegen falls relevant.

local NPCs = {}

-- Nexus Point Xenas (median HP: 759423)
NPCs[248501] = { category = "generic", name = "Reformed Voidling", dungeon = "Nexus Point Xenas" }
NPCs[254485] = { category = "generic", name = "Corespark Pylon", dungeon = "Nexus Point Xenas" }
NPCs[251853] = { category = "generic", name = "Grand Nullifier", dungeon = "Nexus Point Xenas" }
NPCs[252825] = { category = "generic", name = "Mana Battery", dungeon = "Nexus Point Xenas" }
NPCs[248506] = { category = "priority_kill", name = "Dreadflail", dungeon = "Nexus Point Xenas" }
NPCs[251031] = { category = "generic", name = "Wretched Supplicant", dungeon = "Nexus Point Xenas" }
NPCs[241546] = { category = "priority_kill", name = "Lothraxion", dungeon = "Nexus Point Xenas" }
NPCs[241643] =
	{ category = "priority_kill", name = "Shadowguard Defender", dungeon = "Nexus Point Xenas" }
NPCs[255179] = { category = "caster", name = "Fractured Image", dungeon = "Nexus Point Xenas" }
NPCs[252852] = { category = "generic", name = "Corespark Conduit", dungeon = "Nexus Point Xenas" }
NPCs[251568] = { category = "caster", name = "Fractured Image", dungeon = "Nexus Point Xenas" }
NPCs[259569] = { category = "generic", name = "Mana Battery", dungeon = "Nexus Point Xenas" }
NPCs[248769] = { category = "generic", name = "Smudge", dungeon = "Nexus Point Xenas" }
NPCs[254928] = { category = "caster", name = "Flarebat", dungeon = "Nexus Point Xenas" }
NPCs[254932] = { category = "generic", name = "Radiant Swarm", dungeon = "Nexus Point Xenas" }
NPCs[248502] = { category = "priority_kill", name = "Null Sentinel", dungeon = "Nexus Point Xenas" }
NPCs[241660] =
	{ category = "priority_kill", name = "Duskfright Herald", dungeon = "Nexus Point Xenas" }
NPCs[248706] = { category = "generic", name = "Cursed Voidcaller", dungeon = "Nexus Point Xenas" }
NPCs[248373] = { category = "caster", name = "Circuit Seer", dungeon = "Nexus Point Xenas" }
NPCs[248708] = { category = "generic", name = "Nexus Adept", dungeon = "Nexus Point Xenas" }
NPCs[241647] = { category = "generic", name = "Flux Engineer", dungeon = "Nexus Point Xenas" }
NPCs[249711] = { category = "generic", name = "Core Technician", dungeon = "Nexus Point Xenas" }
NPCs[254459] = { category = "generic", name = "Broken Pipe", dungeon = "Nexus Point Xenas" }
NPCs[241645] =
	{ category = "generic", name = "Hollowsoul Scrounger", dungeon = "Nexus Point Xenas" }
NPCs[254227] =
	{ category = "priority_kill", name = "Corewarden Nysarra", dungeon = "Nexus Point Xenas" }
NPCs[251878] = { category = "generic", name = "Voidcaller", dungeon = "Nexus Point Xenas" }
NPCs[251024] = { category = "generic", name = "Null Guardian", dungeon = "Nexus Point Xenas" }
NPCs[251852] = { category = "generic", name = "Nullifier", dungeon = "Nexus Point Xenas" }
NPCs[250299] =
	{ category = "generic", name = "[DNT] Conduit Stalker", dungeon = "Nexus Point Xenas" }
NPCs[241644] = { category = "caster", name = "Corewright Arcanist", dungeon = "Nexus Point Xenas" }
NPCs[241542] =
	{ category = "priority_kill", name = "Corewarden Nysarra", dungeon = "Nexus Point Xenas" }
NPCs[241539] = { category = "priority_kill", name = "Kasreth", dungeon = "Nexus Point Xenas" }
NPCs[254926] = { category = "caster", name = "Lightwrought", dungeon = "Nexus Point Xenas" }
NPCs[241642] = { category = "caster", name = "Lingering Image", dungeon = "Nexus Point Xenas" }

-- Maisara Caverns (median HP: 1594787)
NPCs[248690] = { category = "caster", name = "Grim Skirmisher", dungeon = "Maisara Caverns" }
NPCs[242964] = { category = "generic", name = "Keen Headhunter", dungeon = "Maisara Caverns" }
NPCs[249030] = { category = "generic", name = "Restless Gnarldin", dungeon = "Maisara Caverns" }
NPCs[254740] = { category = "generic", name = "Umbral Shadowbinder", dungeon = "Maisara Caverns" }
NPCs[253701] = { category = "generic", name = "Death's Grasp", dungeon = "Maisara Caverns" }
NPCs[248678] = { category = "generic", name = "Hulking Juggernaut", dungeon = "Maisara Caverns" }
NPCs[248693] = { category = "generic", name = "Mire Laborer", dungeon = "Maisara Caverns" }
NPCs[250443] = { category = "generic", name = "Unstable Phantom", dungeon = "Maisara Caverns" }
NPCs[249022] = { category = "generic", name = "Bramblemaw Bear", dungeon = "Maisara Caverns" }
NPCs[247570] = { category = "caster", name = "Muro'jin", dungeon = "Maisara Caverns" }
NPCs[249002] = { category = "generic", name = "Warding Mask", dungeon = "Maisara Caverns" }
NPCs[248684] = { category = "generic", name = "Frenzied Berserker", dungeon = "Maisara Caverns" }
NPCs[253302] = { category = "caster", name = "Hex Guardian", dungeon = "Maisara Caverns" }
NPCs[253458] = { category = "generic", name = "Zil'jan", dungeon = "Maisara Caverns" }
NPCs[249020] = { category = "generic", name = "Hexbound Eagle", dungeon = "Maisara Caverns" }
NPCs[253473] = { category = "generic", name = "Gloomwing Bat", dungeon = "Maisara Caverns" }
NPCs[254233] = { category = "priority_kill", name = "Rokh'zal", dungeon = "Maisara Caverns" }
NPCs[248685] = { category = "caster", name = "Ritual Hexxer", dungeon = "Maisara Caverns" }
NPCs[248595] = { category = "priority_kill", name = "Vordaza", dungeon = "Maisara Caverns" }
NPCs[251047] = { category = "generic", name = "Soulbind Totem", dungeon = "Maisara Caverns" }
NPCs[248605] = { category = "priority_kill", name = "Rak'tul", dungeon = "Maisara Caverns" }
NPCs[249024] = { category = "caster", name = "Hollow Soulrender", dungeon = "Maisara Caverns" }
NPCs[247572] = { category = "priority_kill", name = "Nekraxx", dungeon = "Maisara Caverns" }
NPCs[248686] = { category = "generic", name = "Dread Souleater", dungeon = "Maisara Caverns" }
NPCs[249025] = { category = "generic", name = "Bound Defender", dungeon = "Maisara Caverns" }
NPCs[253683] = { category = "priority_kill", name = "Rokh'zal", dungeon = "Maisara Caverns" }
NPCs[249036] = { category = "caster", name = "Tormented Shade", dungeon = "Maisara Caverns" }
NPCs[248692] = { category = "generic", name = "Reanimated Warrior", dungeon = "Maisara Caverns" }

-- Seat of the Triumvirate (median HP: 1670730)
NPCs[122403] =
	{ category = "generic", name = "Shadowguard Champion", dungeon = "Seat of the Triumvirate" }
NPCs[122571] = { category = "caster", name = "Rift Warden", dungeon = "Seat of the Triumvirate" }
NPCs[122319] =
	{ category = "priority_kill", name = "Darkfang", dungeon = "Seat of the Triumvirate" }
NPCs[122316] = { category = "priority_kill", name = "Saprish", dungeon = "Seat of the Triumvirate" }
NPCs[122313] = {
	category = "priority_kill",
	name = "Zuraal the Ascended",
	dungeon = "Seat of the Triumvirate",
}
NPCs[122056] =
	{ category = "priority_kill", name = "Viceroy Nezhar", dungeon = "Seat of the Triumvirate" }
NPCs[122423] =
	{ category = "generic", name = "Grand Shadow-Weaver", dungeon = "Seat of the Triumvirate" }
NPCs[124729] = { category = "priority_kill", name = "L'ura", dungeon = "Seat of the Triumvirate" }
NPCs[252756] =
	{ category = "generic", name = "Void-Infused Destroyer", dungeon = "Seat of the Triumvirate" }
NPCs[124171] =
	{ category = "generic", name = "Merciless Subjugator", dungeon = "Seat of the Triumvirate" }
NPCs[122404] =
	{ category = "caster", name = "Dire Voidbender", dungeon = "Seat of the Triumvirate" }
NPCs[122421] =
	{ category = "generic", name = "Umbral War-Adept", dungeon = "Seat of the Triumvirate" }
NPCs[255320] =
	{ category = "generic", name = "Ravenous Umbralfin", dungeon = "Seat of the Triumvirate" }
NPCs[255551] =
	{ category = "generic", name = "Depravation Wave Stalker", dungeon = "Seat of the Triumvirate" }
NPCs[256424] = { category = "generic", name = "Void Tentacle", dungeon = "Seat of the Triumvirate" }
NPCs[122827] =
	{ category = "generic", name = "Umbral Tentacle", dungeon = "Seat of the Triumvirate" }
NPCs[125340] =
	{ category = "priority_kill", name = "Shadewing", dungeon = "Seat of the Triumvirate" }
NPCs[122413] =
	{ category = "generic", name = "Ruthless Riftstalker", dungeon = "Seat of the Triumvirate" }
NPCs[122716] =
	{ category = "generic", name = "Coalesced Void", dungeon = "Seat of the Triumvirate" }
NPCs[122412] =
	{ category = "generic", name = "Bound Voidcaller", dungeon = "Seat of the Triumvirate" }
NPCs[122405] = { category = "caster", name = "Dark Conjurer", dungeon = "Seat of the Triumvirate" }
NPCs[122322] =
	{ category = "generic", name = "Famished Broken", dungeon = "Seat of the Triumvirate" }

-- Magisters Terrace (median HP: 1518845)
NPCs[231865] = { category = "caster", name = "Degentrius", dungeon = "Magisters Terrace" }
NPCs[234089] = { category = "generic", name = "Animated Codex", dungeon = "Magisters Terrace" }
NPCs[231863] = { category = "caster", name = "Seranel Sunlash", dungeon = "Magisters Terrace" }
NPCs[231861] = { category = "caster", name = "Arcanotron Custos", dungeon = "Magisters Terrace" }
NPCs[249086] = { category = "caster", name = "Void Infuser", dungeon = "Magisters Terrace" }
NPCs[234066] = { category = "generic", name = "Devouring Tyrant", dungeon = "Magisters Terrace" }
NPCs[255376] = { category = "generic", name = "Unstable Voidling", dungeon = "Magisters Terrace" }
NPCs[234068] =
	{ category = "generic", name = "Shadowrift Voidcaller", dungeon = "Magisters Terrace" }
NPCs[234486] = { category = "healer", name = "Lightward Healer", dungeon = "Magisters Terrace" }
NPCs[234064] = { category = "generic", name = "Dreaded Voidwalker", dungeon = "Magisters Terrace" }
NPCs[232369] = { category = "caster", name = "Arcane Magister", dungeon = "Magisters Terrace" }
NPCs[234065] = { category = "generic", name = "Hollowsoul Shredder", dungeon = "Magisters Terrace" }
NPCs[234069] = { category = "caster", name = "Voidling", dungeon = "Magisters Terrace" }
NPCs[259387] = { category = "generic", name = "Spellwoven Familiar", dungeon = "Magisters Terrace" }
NPCs[240973] = { category = "generic", name = "Runed Spellbreaker", dungeon = "Magisters Terrace" }
NPCs[241354] =
	{ category = "generic", name = "Void-Infused Brightscale", dungeon = "Magisters Terrace" }
NPCs[257447] = { category = "generic", name = "Hollowsoul Shredder", dungeon = "Magisters Terrace" }
NPCs[241397] = { category = "generic", name = "Celestial Drifter", dungeon = "Magisters Terrace" }
NPCs[234124] = { category = "caster", name = "Sunblade Enforcer", dungeon = "Magisters Terrace" }
NPCs[239636] = { category = "priority_kill", name = "Gemellus", dungeon = "Magisters Terrace" }
NPCs[251861] = { category = "generic", name = "Blazing Pyromancer", dungeon = "Magisters Terrace" }
NPCs[234067] = { category = "generic", name = "Vigilant Librarian", dungeon = "Magisters Terrace" }
NPCs[234062] = { category = "caster", name = "Arcane Sentry", dungeon = "Magisters Terrace" }
NPCs[232106] = { category = "generic", name = "Brightscale Wyrm", dungeon = "Magisters Terrace" }
NPCs[231864] = { category = "priority_kill", name = "Gemellus", dungeon = "Magisters Terrace" }

-- Murder Row (median HP: 0)

-- Windrunner Spire (median HP: 1670730)
NPCs[238099] = { category = "generic", name = "Pesty Lashling", dungeon = "Windrunner Spire" }
NPCs[232071] =
	{ category = "generic", name = "Dutiful Groundskeeper", dungeon = "Windrunner Spire" }
NPCs[250883] = { category = "generic", name = "Scouting Trapper", dungeon = "Windrunner Spire" }
NPCs[232067] = { category = "generic", name = "Creeping Spindleweb", dungeon = "Windrunner Spire" }
NPCs[234673] = { category = "generic", name = "Spindleweb Hatchling", dungeon = "Windrunner Spire" }
NPCs[231636] = { category = "priority_kill", name = "Restless Heart", dungeon = "Windrunner Spire" }
NPCs[232056] =
	{ category = "caster", name = "Territorial Dragonhawk", dungeon = "Windrunner Spire" }
NPCs[232176] = { category = "priority_kill", name = "Flesh Behemoth", dungeon = "Windrunner Spire" }
NPCs[231606] = { category = "priority_kill", name = "Emberdawn", dungeon = "Windrunner Spire" }
NPCs[232175] = { category = "generic", name = "Devoted Woebringer", dungeon = "Windrunner Spire" }
NPCs[232283] = { category = "generic", name = "Loyal Worg", dungeon = "Windrunner Spire" }
NPCs[232232] = { category = "generic", name = "Zealous Reaver", dungeon = "Windrunner Spire" }
NPCs[232070] = { category = "caster", name = "Restless Steward", dungeon = "Windrunner Spire" }
NPCs[258868] = { category = "generic", name = "Haunting Grunt", dungeon = "Windrunner Spire" }
NPCs[232171] = { category = "generic", name = "Ardent Cutthroat", dungeon = "Windrunner Spire" }
NPCs[232121] = { category = "generic", name = "Phalanx Breaker", dungeon = "Windrunner Spire" }
NPCs[231629] = { category = "priority_kill", name = "Latch", dungeon = "Windrunner Spire" }
NPCs[232173] = { category = "generic", name = "Fervent Apothecary", dungeon = "Windrunner Spire" }
NPCs[231631] =
	{ category = "priority_kill", name = "Commander Kroluk", dungeon = "Windrunner Spire" }
NPCs[232118] = { category = "generic", name = "Flaming Updraft", dungeon = "Windrunner Spire" }
NPCs[232116] = { category = "generic", name = "Windrunner Soldier", dungeon = "Windrunner Spire" }
NPCs[232148] = { category = "generic", name = "Spectral Axethrower", dungeon = "Windrunner Spire" }
NPCs[231626] = { category = "priority_kill", name = "Kalis", dungeon = "Windrunner Spire" }
NPCs[232146] = { category = "caster", name = "Phantasmal Mystic", dungeon = "Windrunner Spire" }
NPCs[232122] = { category = "generic", name = "Phalanx Breaker", dungeon = "Windrunner Spire" }
NPCs[232147] = { category = "generic", name = "Lingering Marauder", dungeon = "Windrunner Spire" }
NPCs[232113] = { category = "generic", name = "Spellguard Magus", dungeon = "Windrunner Spire" }
NPCs[232119] = { category = "generic", name = "Swiftshot Archer", dungeon = "Windrunner Spire" }
NPCs[238049] = { category = "generic", name = "Scouting Trapper", dungeon = "Windrunner Spire" }
NPCs[236894] = { category = "generic", name = "Bloated Lasher", dungeon = "Windrunner Spire" }
NPCs[232063] = { category = "generic", name = "Apex Lynx", dungeon = "Windrunner Spire" }

-- Skyreach (median HP: 1564410)
NPCs[76142] =
	{ category = "priority_kill", name = "Skyreach Sun Construct Prototype", dungeon = "Skyreach" }
NPCs[78932] = { category = "generic", name = "Driving Gale-Caller", dungeon = "Skyreach" }
NPCs[75964] = { category = "priority_kill", name = "Ranjit", dungeon = "Skyreach" }
NPCs[76154] = { category = "generic", name = "Sun Talon Tamer", dungeon = "Skyreach" }
NPCs[79093] = { category = "generic", name = "Skyreach Sun Talon", dungeon = "Skyreach" }
NPCs[76087] = { category = "generic", name = "Solar Construct", dungeon = "Skyreach" }
NPCs[78933] = { category = "generic", name = "Herald of Sunrise", dungeon = "Skyreach" }
NPCs[76266] = { category = "priority_kill", name = "High Sage Viryx", dungeon = "Skyreach" }
NPCs[79467] = { category = "generic", name = "Adept of the Dawn", dungeon = "Skyreach" }
NPCs[76132] = { category = "generic", name = "Soaring Chakram Master", dungeon = "Skyreach" }
NPCs[79466] = { category = "generic", name = "Initiate of the Rising Sun", dungeon = "Skyreach" }
NPCs[79462] = { category = "healer", name = "Blinding Sun Priestess", dungeon = "Skyreach" }
NPCs[75976] = { category = "generic", name = "Outcast Servant", dungeon = "Skyreach" }
NPCs[79303] = { category = "generic", name = "Adorned Bladetalon", dungeon = "Skyreach" }
NPCs[251880] = { category = "priority_kill", name = "Solar Orb", dungeon = "Skyreach" }
NPCs[76227] = { category = "generic", name = "Sunwings", dungeon = "Skyreach" }
NPCs[76285] = { category = "generic", name = "Arakkoa Magnifying Glass", dungeon = "Skyreach" }
NPCs[250992] = { category = "generic", name = "Raging Squall", dungeon = "Skyreach" }
NPCs[76205] = { category = "caster", name = "Blooded Bladefeather", dungeon = "Skyreach" }
NPCs[76149] = { category = "generic", name = "Dread Raven", dungeon = "Skyreach" }
NPCs[76143] = { category = "priority_kill", name = "Rukhran", dungeon = "Skyreach" }
NPCs[76141] = { category = "priority_kill", name = "Araknath", dungeon = "Skyreach" }

-- Pit of Saron (median HP: 1670730)
NPCs[252566] = { category = "caster", name = "Rimebone Coldwraith", dungeon = "Pit of Saron" }
NPCs[252602] = { category = "generic", name = "Risen Soldier", dungeon = "Pit of Saron" }
NPCs[257190] = { category = "generic", name = "Iceborn Proto-Drake", dungeon = "Pit of Saron" }
NPCs[252555] = { category = "generic", name = "Lumbering Plaguehorror", dungeon = "Pit of Saron" }
NPCs[252606] = { category = "generic", name = "Plungetalon Gargoyle", dungeon = "Pit of Saron" }
NPCs[252559] = { category = "generic", name = "Leaping Geist", dungeon = "Pit of Saron" }
NPCs[255037] = { category = "generic", name = "Shade of Krick", dungeon = "Pit of Saron" }
NPCs[252610] = { category = "generic", name = "Ymirjar Graveblade", dungeon = "Pit of Saron" }
NPCs[252648] =
	{ category = "priority_kill", name = "Scourgelord Tyrannus", dungeon = "Pit of Saron" }
NPCs[252558] = { category = "generic", name = "Rotting Ghoul", dungeon = "Pit of Saron" }
NPCs[252551] = { category = "caster", name = "Deathwhisper Necrolyte", dungeon = "Pit of Saron" }
NPCs[252563] = { category = "generic", name = "Dreadpulse Lich", dungeon = "Pit of Saron" }
NPCs[252561] = { category = "generic", name = "Quarry Tormentor", dungeon = "Pit of Saron" }
NPCs[252567] = { category = "generic", name = "Gloombound Shadebringer", dungeon = "Pit of Saron" }
NPCs[254684] = { category = "generic", name = "Rotling", dungeon = "Pit of Saron" }
NPCs[254691] = { category = "generic", name = "Scourge Plaguespreader", dungeon = "Pit of Saron" }
NPCs[252635] = { category = "caster", name = "Forgemaster Garfrost", dungeon = "Pit of Saron" }
NPCs[252653] = { category = "priority_kill", name = "Rimefang", dungeon = "Pit of Saron" }
NPCs[252603] = { category = "caster", name = "Arcanist Cadaver", dungeon = "Pit of Saron" }
NPCs[252625] = { category = "priority_kill", name = "Ick", dungeon = "Pit of Saron" }
NPCs[252621] = { category = "priority_kill", name = "Krick", dungeon = "Pit of Saron" }
NPCs[252564] = { category = "priority_kill", name = "Glacieth", dungeon = "Pit of Saron" }
NPCs[252565] = { category = "generic", name = "Wrathbone Enforcer", dungeon = "Pit of Saron" }

-- Algethar Academy (median HP: 2278268)
NPCs[196482] =
	{ category = "priority_kill", name = "Overgrown Ancient", dungeon = "Algethar Academy" }
NPCs[196577] = { category = "generic", name = "Spellbound Battleaxe", dungeon = "Algethar Academy" }
NPCs[197219] = { category = "generic", name = "Vile Lasher", dungeon = "Algethar Academy" }
NPCs[197406] =
	{ category = "generic", name = "Aggravated Skitterfly", dungeon = "Algethar Academy" }
NPCs[191736] = { category = "priority_kill", name = "Crawth", dungeon = "Algethar Academy" }
NPCs[192333] = { category = "generic", name = "Alpha Eagle", dungeon = "Algethar Academy" }
NPCs[192329] = { category = "generic", name = "Territorial Eagle", dungeon = "Algethar Academy" }
NPCs[192680] = { category = "generic", name = "Guardian Sentry", dungeon = "Algethar Academy" }
NPCs[196045] = { category = "generic", name = "Corrupted Manafiend", dungeon = "Algethar Academy" }
NPCs[194181] = { category = "priority_kill", name = "Vexamus", dungeon = "Algethar Academy" }
NPCs[196044] = { category = "caster", name = "Unruly Textbook", dungeon = "Algethar Academy" }
NPCs[196694] = { category = "generic", name = "Arcane Forager", dungeon = "Algethar Academy" }
NPCs[196671] = { category = "generic", name = "Arcane Ravager", dungeon = "Algethar Academy" }
NPCs[190609] = { category = "caster", name = "Echo of Doragosa", dungeon = "Algethar Academy" }
NPCs[196202] = { category = "generic", name = "Spectral Invoker", dungeon = "Algethar Academy" }
NPCs[196200] = { category = "generic", name = "Algeth'ar Echoknight", dungeon = "Algethar Academy" }
NPCs[197398] = { category = "generic", name = "Hungry Lasher", dungeon = "Algethar Academy" }

addon.NPCsMidnightS1 = NPCs
return NPCs
