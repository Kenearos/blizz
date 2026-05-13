# What Midnight 12.0 broke (and what to use instead)

WoW Midnight (12.0.0, March 2026) is the most aggressive addon-API restriction since the protected-action overhaul of Cataclysm. If you're porting a pre-Midnight addon or writing a new one, **read this before touching any combat-related API.**

## The headline change: the "Addon Prune"

Blizzard deliberately restricted addon access to combat data in Midnight. The official goal: reduce the gap between players using addons vs. not, and reduce the load of script execution during high-event-density encounters (raid bosses, M+ trash pulls).

The two visible consequences for addon developers:

1. **`COMBAT_LOG_EVENT_UNFILTERED` is restricted** for non-allow-listed addons.
2. **"Secret Values"** appear in return values of many combat-related APIs during restricted contexts (Encounter, Mythic+, PvP).

Both are silent failures by default — your addon will load, but the popup "**AddOn '*X*' has been blocked from an action only available to the Blizzard UI**" appears with no chat-frame diagnostic.

---

## 1. CLEU registration

### What broke

```lua
-- This used to be the standard pattern for any combat data addon.
local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", function() ... end)
```

In Midnight 12.0, this triggers `ADDON_ACTION_BLOCKED` for non-allow-listed addons. The popup appears silently (no chat output) because the chat-frame's blocked-action handler is itself restricted in the new chat-restriction state introduced in 12.0.5.

### What to use instead

For most use cases, dedicated unit events still work and aren't restricted:

| You were tracking | Replace CLEU subevent with |
|---|---|
| `SPELL_INTERRUPT` (party member kicked) | `UNIT_SPELLCAST_INTERRUPTED` |
| `SPELL_CAST_SUCCESS` (party member used an ability) | `UNIT_SPELLCAST_SUCCEEDED` |
| `SPELL_CAST_START` (mob is casting something) | `UNIT_SPELLCAST_START` |
| `UNIT_DIED` (someone died) | `UNIT_HEALTH` + `UnitIsDead(unit)` transition |
| `SPELL_AURA_APPLIED/REMOVED` (buff/debuff) | `UNIT_AURA` (but see Section 3 — payload is restricted) |

Concrete pattern: tracking party deaths in M+ without CLEU.

```lua
-- modules/mplus_frame/init.lua (excerpt)
local MPlus = {
    id = "mplus_frame",
    events = { "UNIT_HEALTH", "PLAYER_DEAD", ... },
}

function MPlus:init()
    self.unit_was_dead = {}  -- per-unit alive→dead transition tracking
end

function MPlus:checkUnitDeath(unit)
    if not is_party_unit(unit) then return end
    local isDead = UnitIsDead(unit)
    local wasDead = self.unit_was_dead[unit] == true
    if isDead and not wasDead and self:isActive() then
        self.deaths = self.deaths + 1
        -- ...update display
    end
    self.unit_was_dead[unit] = isDead
end
```

The trick: `UNIT_HEALTH` fires when health changes including reaching 0; check `UnitIsDead` and track the previous state per unit so you don't double-count.

### Reference

- [Cell PR #457 — Midnight Compatibility](https://github.com/enderneko/Cell/pull/457) — explicit CLEU removal commits
- [Wowhead — Combat Addons Disabled in End-Game Content](https://www.wowhead.com/news/combat-addons-disabled-in-end-game-content-in-midnight-378679)
- [forums.blizzard.com — Midnight 12.0.5 Info & Known Issues](https://us.forums.blizzard.com/en/wow/t/midnight-1205-info-known-issues/2295819)

---

## 2. The `C_Spell` namespace migration

### What broke

```lua
-- These globals are now nil in Midnight 12.0:
local start, duration, enabled = GetSpellCooldown(spellID)
local charges, maxCharges = GetSpellCharges(spellID)
local name = GetSpellInfo(spellID)
local texture = GetSpellTexture(spellID)
```

Calling them throws `attempt to call a nil value` and your init code dies.

### What to use instead

```lua
-- All moved into C_Spell, returning tables instead of multiple values:
local info = C_Spell.GetSpellCooldown(spellID)
if info then
    local start, duration = info.startTime, info.duration
    local isEnabled = info.isEnabled
end

local info = C_Spell.GetSpellCharges(spellID)
if info and info.currentCharges then
    local charges, maxCharges = info.currentCharges, info.maxCharges
end

local info = C_Spell.GetSpellInfo(spellID)
-- info = { name, iconID, originalIconID, castTime, minRange, maxRange, spellID }
```

The pattern for backward-compat with pre-12.0 clients:

```lua
local function read_cooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return info.startTime or 0, info.duration or 0, info.isEnabled ~= false
        end
    end
    if _G.GetSpellCooldown then
        local s, d, e = _G.GetSpellCooldown(spellID)
        return s or 0, d or 0, e or 1
    end
    return 0, 0, true
end
```

### Reference

- [C_Spell API — warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCooldown)
- [Patch 12.0.0 API changes — warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)

---

## 3. Secret Values

### What it is

In restricted contexts (Encounter, Mythic+, PvP), many WoW APIs return opaque "Secret" values instead of real numbers/strings. Examples: `UnitHealth("party1")` during a boss fight may return a Secret. Arithmetic on a Secret raises a Lua error (`attempt to perform arithmetic on a secret value`).

### When this hits you

```lua
-- Looks fine, but blows up in M+/raid:
local hp = UnitHealth("party1")
local pct = hp / UnitHealthMax("party1")  -- ERROR if either is secret
print("party1 HP: " .. hp)                -- ERROR if hp is secret
self.bar:SetValue(hp / max)               -- silent breakage
```

### The defense pattern

```lua
-- core/secrets.lua
local Secrets = {}

local issecretvalue_fn = _G.issecretvalue
function Secrets:isSecret(v)
    if not issecretvalue_fn then return false end
    local ok, result = pcall(issecretvalue_fn, v)
    return ok and result == true
end

function Secrets:safeNumber(v, default)
    default = default or 0
    if v == nil then return default end
    if self:isSecret(v) then return default end
    return tonumber(v) or default
end

function Secrets:pcallRead(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then return nil end
    return result
end
```

Then every API read goes through it:

```lua
-- core/unitstate.lua
function UnitState:getHealth(unit)
    return Secrets:safeNumber(safe_unit_call(_G.UnitHealth, unit), 0)
end
```

The cost: an extra pcall per read. The benefit: your addon doesn't crash mid-pull, and your display shows `0` rather than throwing.

For arithmetic safety, pre-check with `C_Secrets.HasSecretRestrictions()` if you can:

```lua
if C_Secrets and C_Secrets.HasSecretRestrictions and C_Secrets.HasSecretRestrictions() then
    -- minimal display, no arithmetic on encounter data
    return
end
-- normal full-feature path
```

### Reference

- [Secret Values — warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/Secret_Values)
- [C_RestrictedActions API — warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/API_C_RestrictedActions.IsAddOnRestrictionActive)
- [Cell — Per-Aura Checks `F.IsAuraNonSecret()`](https://github.com/enderneko/Cell/pull/457) — concrete migration pattern

---

## 4. `GetWorldElapsedTime` returns strings now (sometimes)

### What broke

```lua
-- Used to return seconds as number:
local elapsed = GetWorldElapsedTime(1)
if elapsed < 1800 then ... end  -- ERROR: "attempt to compare string with number"
```

### What to use instead

Track elapsed time yourself from the relevant start event:

```lua
function MPlus:onEvent(event)
    if event == "CHALLENGE_MODE_START" then
        self.start_time = GetTime()  -- GetTime is still reliable
    end
end

function MPlus:getElapsedTime()
    if self.start_time then
        return math.max(0, GetTime() - self.start_time)
    end
    return tonumber(GetWorldElapsedTime(1)) or 0  -- fallback with type coerce
end
```

`GetTime()` returns frame-accurate seconds since session start — still reliable in 12.0 and safe for math.

---

## 5. `C_ChallengeMode.GetActiveChallengeMapID()` returns 0 (not nil) outside M+

A subtle change from documented behavior. Don't use `~= nil`:

```lua
-- WRONG — true outside M+:
function isInMPlus()
    return C_ChallengeMode.GetActiveChallengeMapID() ~= nil
end

-- RIGHT:
function isInMPlus()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    return mapID ~= nil and mapID ~= 0
end
```

---

## 6. `UnitInRange` deprecation behavior

`UnitInRange("party1")` may return `nil` instead of `true`/`false` in some contexts in 12.0. Always coerce:

```lua
local r = UnitInRange("party1")
local inRange = r and true or false
```

---

## 7. The "BLOCKED with no chat output" mystery

The most confusing 12.0 symptom: popup says "*X* has been blocked from an action only available to the Blizzard UI", but the chat frame is silent — no function name, no stack.

This happens because Blizzard's chat-frame handler that historically printed the offending function name is itself restricted in the new `C_RestrictedActions` chat-restriction state introduced in 12.0.5. The C-side error path skips the Lua-side diagnostic.

### Workaround: a homegrown tracer

```lua
-- In your main addon file:
if CreateFrame and DEFAULT_CHAT_FRAME then
    local diag = CreateFrame("Frame", "YourAddOnActionDiag", UIParent)
    diag:RegisterEvent("ADDON_ACTION_BLOCKED")
    diag:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    diag:SetScript("OnEvent", function(_, ev, addonName, funcName)
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cffff4444[Diag]|r %s addon=%s func=%q",
            tostring(ev), tostring(addonName), tostring(funcName)))
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa" .. tostring(debugstack(2, 6, 0)) .. "|r")
    end)
end
```

This writes directly to `DEFAULT_CHAT_FRAME` and bypasses the restricted path. The next time a block fires, you get the function name in chat.

Alternative: `/console taintLog 2` before `/reload`, then check `WoW/_retail_/Logs/taint.log` after `/exit`.

---

## Summary table

| 12.0 change | Symptom | Fix |
|---|---|---|
| CLEU restricted | `ADDON_ACTION_BLOCKED` popup, silent | Use unit-events (UNIT_SPELLCAST_*, UNIT_HEALTH) |
| `C_Spell` namespace | `attempt to call a nil value` | Switch to `C_Spell.GetSpellCooldown` etc. (returns table) |
| Secret Values | `arithmetic on secret value`, silent visual breakage | `pcall` wrap + `issecretvalue` check |
| `GetWorldElapsedTime` | `compare string with number` | Track elapsed locally from start-event |
| `GetActiveChallengeMapID` returns 0 | Frame shown outside M+ | Check `~= nil and ~= 0` |
| `UnitInRange` returns nil | Boolean logic surprises | Coerce to boolean explicitly |
| Silent BLOCKED popup | No chat diagnostic | Install ADDON_ACTION_BLOCKED tracer |

If your addon was working in 11.2.5 and broke in 12.0, work through this table top-to-bottom. The vast majority of breakage falls in these seven buckets.

---

## What this means for new addons

If you're starting an addon in 2026, the implicit advice from Blizzard is: **don't try to be an aimbot, don't try to be a damage-calculation engine, don't process every CLEU event.** Use the addon-friendly APIs that remain. The lighter your combat-runtime footprint, the less you'll have to refactor in the next API cull.

Concretely for the patterns in Blizz:

- Read cooldowns via `C_Spell` (display purposes — fine)
- Listen to unit events (UNIT_*) for state changes (fine)
- Drive UI updates from those events (fine)
- Skip CLEU entirely unless your addon is in the guarded-addon allow-list (you're not)
- Cache values defensively through a Secrets-aware layer (one-time effort)

You can build a useful, polished, complex addon in 2026. You just need a different cookbook than the one from 2018.
