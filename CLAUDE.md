# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

Blizz ist ein standalone WoW-UI-Addon (Tank-Fokus, Prot Warri M+) für den **Midnight 12.0**-Client. Runtime ist LuaJIT 2.1 mit Lua-5.1-Semantik — *nicht* Standard-Lua 5.3+. Kein Ace3, kein oUF, keine Runtime-Dependencies.

Ausführliche Doku liegt unter `docs/cookbook/` (Architektur, Midnight-12.0-API-Änderungen, Testing) und in der `README.md`. Vor nicht-trivialen strukturellen Änderungen `docs/cookbook/02-architecture.md` lesen.

## Häufige Kommandos

```bash
# Komplette Test-Suite (headless, ~130ms)
luajit tests/run.lua

# Einzelner Test
luajit -e 'package.path="./?.lua;./?/init.lua;"..package.path; require("tests.test_eventbus")'

# Format (muss vor Commit clean sein)
stylua .
stylua --check .

# Symlink ins WoW-AddOns-Verzeichnis
./scripts/install.sh                              # Autodetect typischer Linux-Pfade
./scripts/install.sh /pfad/zu/Interface/AddOns    # explizit
```

Im Spiel nach Edits: `/reload`, dann `/blizz status` (weitere Slash-Subcommands: `errors`, `modules`, `disable <id>`, `enable <id>`, `capture <bargain>`). Keinen Build-Step — WoW lädt die Files direkt gemäß TOC.

## Architektur

Bootstrap-Flow (siehe `Blizz.lua`):

1. TOC lädt Files top-down: `core/*` → `config/savedvars.lua` → `data/*` → `ui/*` → `Blizz.lua` → `modules/*/init.lua`.
2. Jedes Modul-File endet mit `addon.registerModule(self)`. Die Registrierung abonniert `onEvent` des Moduls beim internen EventBus für jeden Eintrag in `self.events` und ref-counted ein `frame:RegisterEvent` via `core/wowevents.lua`.
3. Der Bridge-Frame (`BlizzEventBridge`) wartet auf WoWs `PLAYER_LOGIN`. Beim Feuern läuft `addon:bootstrap()`: `SavedVars:load()` (mit Version-Migration), dann `pcall` auf jedes `mod.init` — ein kaputtes Modul kann die anderen nicht reißen.
4. WoW-Frame-Events landen über die Bridge im `core/eventbus.lua`. Der Bus `pcall`t jeden Subscriber und schiebt Fehler in einen Ring-Buffer (max 50) unter `addon.errors` (sichtbar via `/blizz errors`).

Modul-Kontrakt — jedes `modules/*/init.lua` folgt diesem Muster:

```lua
local _, addon = ...
if not addon then addon = _G.Blizz or {}; _G.Blizz = addon end  -- dual-load: WoW-TOC + headless require

local Mod = {
  id = "mitigation",                              -- eindeutig (auch Key für disable/positions)
  events = { "SPELL_UPDATE_COOLDOWN", "UNIT_AURA" },
  init = function(self) ... end,                  -- Frames + State, einmalig nach PLAYER_LOGIN
  onEvent = function(self, event, ...) ... end,
}
addon.registerModule(Mod)
return Mod
```

Combat-API-Reads (`UnitHealth`, `C_Spell.GetSpellCooldown`, …) gehen durch `core/unitstate.lua` / `core/cooldowns.lua`, die `pcall`en und über `core/secrets.lua` `issecretvalue()` prüfen. **Diese WoW-APIs niemals direkt aus Modulen aufrufen** — Midnight 12.0 liefert Secret Values zurück, die stille Arithmetik-Fehler verursachen.

UI läuft komplett über `ui/widgets/*` (Frame, Text, Icon, Bar, Alert) mit Theme-Tokens aus `ui/theme.lua`. State-Wechsel sind Methodencalls (`frame:setReady() / :setCD() / :setAlert() / :setDefault()`) — niemals rohes `:SetBackdropColor` aus Modulen. So bleiben Widgets reskinbar und Tests können `frame:getState() == "ready"` asserten statt Farben zu inspizieren.

Positions-Persistenz: in `init()` nach Frame-Erstellung `addon.restorePosition(frame, self.id, default_anchor, default_x, default_y)` aufrufen. Lädt aus `BlizzDB.profiles[active].positions[id]` falls vorhanden, sonst Default, und schaltet Drag-to-Move ein, das via `SavedVars:setPosition` zurückschreibt.

SavedVars-Schema (`config/savedvars.lua`) hat ein `version`-Feld und eine `migrators`-Tabelle keyed by alter Version. Schema ändern: `CURRENT_VERSION` hochziehen und Migrator von `[v-1]` nach `v` ergänzen.

## Neues Modul / File hinzufügen (Lade-Reihenfolge)

1. `modules/<name>/init.lua` nach Modul-Kontrakt anlegen.
2. **In `Blizz.toc` in korrekter Reihenfolge eintragen** — Module *nach* `Blizz.lua`; alles was sie `require`n (core/data/ui) muss *vor* `Blizz.lua` stehen. Files, die nicht in der TOC stehen, ignoriert WoW stillschweigend.
3. Neue Globals (weitere `SLASH_*`-Konstanten, addonweite Tables) in `.luarc.json` unter `diagnostics.globals` ergänzen, sonst meckert lua-language-server.
4. `tests/test_<name>.lua` anlegen — der Runner discovert `tests/test_*.lua` automatisch.

## Testing

`tests/mocks/wow_api.lua` stubt die WoW-Globals (CreateFrame, UnitHealth, GetTime, C_Spell.*, CLEU-Listener, …) und stellt `MockSet*` / `MockFire*`-Helfer bereit, mit denen Tests State setzen und Events feuern. Der Mock hat ein Catch-all-`__index`, das für jede vergessene `Set*`/`Get*`-Methode eine No-op-Funktion zurückgibt — fehlende Stubs crashen also nicht, sie passieren stillschweigend.

Wenn ein Modul eine WoW-API anfasst, die noch nicht gemockt ist:
1. Stub in `tests/mocks/wow_api.lua` ergänzen (plus `MockSetX`-Helper falls State-tragend).
2. Helper-Namen in `.luarc.json` unter `diagnostics.globals` aufnehmen.

`tests/run.lua` cleart `_G.Blizz` und `package.loaded[...]` zwischen Test-Files, sodass jeder in einem frischen Scope läuft. Test-API ist plain `assert()` — kein busted/luaunit. Pro Pass eine Zeile `"✓ <Beschreibung>"` printen.

## Stolperfallen

- **TOC `## Interface: 120005`** muss zum live-Client-Major passen. Bei Patch-Tagen hochziehen, sonst zeigt das Addon "Out of Date" und lädt nicht.
- **Nur LuaJIT 5.1.** Kein `//` Integer-Division, kein natives `&|~` (stattdessen `bit.band/bor/bxor/lshift/rshift`), keine 5.2+-`goto`-Continue-Idiome, kein `<const>`-Attribut.
- **EventBus nicht umgehen** — kein `frame:SetScript("OnEvent", ...)` in Modul-Code, sonst verlierst du pcall-Containment und den Diag-Tracer. Immer der `events = { ... }` + `onEvent`-Kontrakt.
- **Combat-APIs nicht direkt lesen** — immer durch `core/unitstate.lua` / `core/cooldowns.lua`. Midnight-12.0-Secret-Values kontaminieren sonst still die Arithmetik. Siehe `docs/cookbook/01-midnight-12.0-changes.md`.
- **`/blizz disable <id>` braucht `/reload`** um zu greifen (die Disabled-Liste wird nur einmal beim Bootstrap gelesen).
- Der `BlizzActionDiag`-Frame in `Blizz.lua` capturet `ADDON_ACTION_BLOCKED`/`ADDON_ACTION_FORBIDDEN` mit `debugstack` — beim Debuggen von Midnight-Blocked-Action-Popups einfach drin lassen.
