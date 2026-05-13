# Blizz — Tank-UI Design Spec

**Datum:** 2026-05-13
**Stand:** Brainstorming abgeschlossen, vor Implementierungsplanung
**Ziel-Spec:** Prot Warrior Tank Interface für Mythic+ in WoW Midnight 12.0.5, Season 1
**Autor-Tooling:** brainstorming-Skill v5.1.0 + Recherche-Subagent

---

## 1. Was wir bauen

Ein eigenständiges WoW-Addon namens **Blizz**, das einem Protection-Warrior-Tank in Mythic+ ein vollständiges Tank-zentrisches HUD bietet — ohne dass externe Addons (Plater, BigWigs, OmniCD, MDT) zur Laufzeit installiert sein müssen. Daten aus diesen Addons werden als statische Lua-Files importiert; die Wartung pro Patch ist eine eigene Sub-Aufgabe.

**Primärer Nutzer:** Ein Spieler (kenearos), der M+ als Prot Warri pusht und maximale Information bei minimaler kognitiver Last will.

**Erfolgs­kriterium:** Während eines aktiven M+-Runs kann der Spieler ausschließlich mit Blizz (ohne Plater/BigWigs/etc.) folgende Entscheidungen ohne Augen-Wandern treffen:
- Wann Shield Block / Ignore Pain drücken (Active Mitigation)
- Welche Defensive ich jetzt fahre (CD-Bar)
- Ob ein reflektierbarer Cast kommt (Reflect-Indicator)
- Ob ich Aggro auf jemand anderen verloren habe
- Wer als nächstes kicken muss (Kick-Rota)
- Welcher Mob im Pack priorisiert wird (Nameplate-Klassifizierung)
- Wie der Run-Stand ist (Forces %, Timer, Death-Penalty)
- Welcher Affix-Mob spawnt und wie damit umgehen

---

## 2. Architektur

### 2.1 High-level
- **Einziges Addon, keine Runtime-Dependencies.** Kein OmniCD/Plater/MDT-Bedarf zur Laufzeit.
- **Embedded `LibStub`** für interne Modul-Registrierung (klein, Standard, unproblematisch).
- **Daten als statische Lua-Files** unter `blizz/data/`, importiert aus Open-Source-Quellen (MDT, BigWigs/LittleWigs, OmniCD). Lizenz-Attribution in `blizz/data/LICENSES.md`.
- **TOC-Manifest:** alle Lua-Files müssen in `Blizz.toc` in Ladereihenfolge eingetragen werden (WoW-Eigenheit).

### 2.2 Verzeichnisstruktur
```
blizz/
├── Blizz.toc                          # Manifest, Interface 120005
├── CLAUDE.md
├── core/
│   ├── eventbus.lua                   # Pub/Sub für Module-Kommunikation
│   ├── combatlog.lua                  # CLEU-Parser, klassifiziert Events
│   ├── cooldowns.lua                  # GetSpellCooldown-Polling + Charges
│   ├── unitstate.lua                  # UnitAura/UnitHealth/UnitThreatSituation-Wrapper
│   └── addoncomm.lua                  # Party-Sync für Kickrota (C_ChatInfo)
├── data/
│   ├── LICENSES.md
│   ├── spells_prot_warrior.lua        # Shield Block, IP, Wall, LS, SpRfl, Demo, Rally, Avatar, Banner, Charge, Pummel + IDs
│   ├── reflect_spells.lua             # Reflektierbare Casts pro S1-Dungeon
│   ├── npcs_midnight_s1.lua           # Mob-DB aus MDT-Import: {npcID, name, role, important_spells, is_priority_kill}
│   ├── affixes_s1.lua                 # Voidbound/Pulsar/Devour/Ascendant-Definitionen
│   ├── party_cds.lua                  # Top-10 externe Defensives
│   └── encounters_s1.lua              # Boss-Encounter-Spell-IDs (für spätere Timer-Engine)
├── ui/
│   ├── theme.lua                      # v6 Cyan-Cyber-Tactical Tokens
│   ├── widgets/
│   │   ├── frame.lua                  # Basis-Frame mit v6-Theming
│   │   ├── bar.lua                    # Cooldown/Status-Bar
│   │   ├── icon.lua                   # Spell-Icon mit Ready/CD-States
│   │   ├── text.lua                   # Themed Text (Mono, Letter-Spacing)
│   │   └── alert.lua                  # Reflect-Style Pulsing Alert mit Clip-Path
│   └── corner.lua                     # Tech-Corner-Bracket-Decorator
├── modules/
│   ├── mitigation/                    # Phase 2 — Shield Block + IP
│   ├── cooldowns/                     # Phase 2 — Defensive-CD-Bar
│   ├── threat/                        # Phase 2 — Aggro-Status + Lost-Aggro-Warn
│   ├── reflect/                       # Phase 2 — Reflektierbar-Cast-Indicator
│   ├── mplus_frame/                   # Phase 3 — Forces %, Timer, Deaths
│   ├── affix_s1/                      # Phase 4 — Bargain-Tracker
│   ├── nameplates/                    # Phase 5 — Klassifizierung
│   ├── kickrota/                      # Phase 6 — Combat-Log + Party-Sync
│   └── party_cds/                     # Phase 7 — Top-10 externe Defensives
├── config/
│   ├── savedvars.lua                  # BlizzDB-Defaults und Migration
│   └── options.lua                    # In-game Optionspanel
├── tests/
│   ├── mocks/
│   │   └── wow_api.lua                # Stubs für CreateFrame, UnitHealth, GetSpellCooldown, UnitAura, CLEU
│   └── modules/
│       ├── test_mitigation.lua
│       └── test_cooldowns.lua
└── docs/
    └── superpowers/specs/2026-05-13-blizz-tank-ui-design.md  # diese Datei
```

### 2.3 Module-Architektur
Jedes Modul ist ein Lua-Table mit Standard-Interface:
```lua
local Module = {
  id = "mitigation",
  enabled = true,
  init = function(self) ... end,     -- Frame-Setup, Event-Subscribe
  enable = function(self) ... end,   -- aktiviert beim Login/Reload
  disable = function(self) ... end,
  events = { "UNIT_AURA", "SPELL_UPDATE_COOLDOWN", ... },
  onEvent = function(self, event, ...) ... end,
}
Blizz.registerModule(Module)
```
Der `core/eventbus.lua` ruft `onEvent` per Subscription auf, fängt Errors mit `pcall` ab, loggt sie in `BlizzDB.errors[]`, und lässt andere Module weiterlaufen.

---

## 3. Datenfluss

```
WoW-Engine
  │
  ├─ Game-Events ──────► core/eventbus ──► Module subscribers
  │   (UNIT_AURA, NAME_PLATE_UNIT_ADDED, ...)
  │
  ├─ COMBAT_LOG_EVENT_UNFILTERED ─► core/combatlog (Filter + Tag) ─► Module
  │
  ├─ Polling-Loop (10 Hz) ────────► core/cooldowns ─► def-cd-bar, kickrota
  │   (GetSpellCooldown, GetSpellCharges)
  │
  └─ Addon-Comm-Channel "BLIZZ" ──► core/addoncomm ─► kickrota module
      (Party-Sync: gesendete/verbrauchte Interrupts)

SavedVariables (BlizzDB) ◄──► config/savedvars ◄──► Module-State

tests/ (nur dev-Build)
  Mock WoW-API ─► geladene Module ─► Assertions
```

---

## 4. Visueller Stil — v6 Cyan Cyber Tactical

Vollständige Definition siehe `memory/project_visual_style.md` und Mockup `docs/superpowers/mockups/style-v6.html`.

**Token-Tabelle** (in `ui/theme.lua` zu hinterlegen):

| Token | Hex | Verwendung |
|---|---|---|
| `bg.primary`        | `#02060f` | Hauptseiten-Hintergrund |
| `bg.surface`        | `#02060f` | Frame-Innerres |
| `color.primary`     | `#7ed9ff` | Default-Border, Default-Text |
| `color.primary.hi`  | `#d4eef9` | Outer-Ring auf Ready-States |
| `color.ready.bg`    | `#7ed9ff` | Ready-State Fill |
| `color.ready.fg`    | `#001a2a` | Ready-State Text |
| `color.alert`       | `#ff2966` | Reflect-Alert Fill |
| `color.alert.deep`  | `#800020` | Alert-Puls-Tiefe |
| `color.info`        | `#f0f0f0` | M+/Affix/Kick-Header |
| `color.caster`      | `#ff5dc8` | Nameplate Caster (Kick-Priority) |
| `color.frontal`     | `#4de0c8` | Nameplate Frontal (Outline) |
| `color.healer`      | `#c5ff2e` | Nameplate Healer (Priority-Kill) |
| `color.cd.border`   | `#2a3a4a` | Cooldown-State Border |
| `color.cd.text`     | `#5a7080` | Cooldown-State Text |
| `font.family`       | "JetBrains Mono", "IBM Plex Mono", monospace |  |
| `font.weight.default` | 600 |  |
| `font.weight.ready`   | 800 |  |
| `font.weight.alert`   | 900 |  |
| `border.width`      | `1.5px` (WoW: 1px-Backdrop oder Texturen) |  |
| `radius`            | `0` (außer Container: `4px`) |  |
| `letter-spacing.title` | `3px` |  |

**Form-Vokabular:**
- Farb-Inversion für Ready-States (gefüllte Fläche + dunkler Text statt outline + heller Text)
- 1.5px Outer-Ring in `color.primary.hi` zusätzlich zum Border
- Inset-Top-Highlight (1px halbtransparent weiß oben) für subtile Tiefe
- Sanfter `text-shadow: 0 0 4px rgba(...,0.35)` und `box-shadow: 0 0 10px rgba(...,0.5)` auf Ready/Alert — kein Bleed
- Clip-Path-Schrägschnitte (Parallelogramm) auf Reflect-Alert
- L-förmige Tech-Corner-Brackets (`::before`/`::after`) als Frame-Decorator
- Scanlines `repeating-linear-gradient` mit ~4.5 % Opacity
- Alert-Animation: 0.9 s ease-in-out, Background-Sättigung wechselt + scale 1.0→1.04

> **WoW-spezifische Anmerkung:** WoW kennt kein CSS. Visuelle Effekte müssen über `Frame:SetBackdrop`, Layered Textures, `:SetVertexColor`, eigene Pixel-Border-Libs (z.B. eingebettete Mini-Helper) und `:SetGradient` simuliert werden. Clip-Path-Schrägschnitte werden über zwei gespiegelte Texture-Dreiecke realisiert. Pulse-Animationen über `:CreateAnimationGroup` (Alpha + Scale).

---

## 5. Layout — v3

Vollständige Karte siehe `memory/project_layout_decision.md` und Mockup `docs/superpowers/mockups/layout-v3.html`.

**Anchor-Default-Karte (relativ zu `UIParent`):**

| Element | Anchor | Position (rel) |
|---|---|---|
| Top-Strip (Threat/Lust/Combat/Range/BR) | TOP | center, y = -2 % |
| M+ Run Frame (Timer/Forces/Affix) | TOPLEFT | x = 2 %, y = -2 % |
| Death-Counter / Pulls | TOPRIGHT | x = -2 %, y = -2 % |
| Reaktions-Cluster (Reflect-Alert) | CENTER | x = +12 % (entspricht 62% horizontal), y = +5 % |
| Reaktions-Cluster (Active Mit) | CENTER | x = +12 %, y = +15 % |
| Defensive-CD-Bar | BOTTOM | center, y = +24 % |
| Party-CDs (Healer/DPS/Externals) | RIGHT | y-cluster mid |
| Kick-Rota Panel | BOTTOMLEFT | x = 2 %, y = +4 % |
| Combat-Log Hint | BOTTOMRIGHT | x = -2 %, y = +4 % |
| Nameplate-Zone | (overlay on WoW nameplates) | n/a |

Alle Positionen sind in `BlizzDB.positions[moduleId]` überschreibbar.

---

## 6. Bauphasen (Implementation-Reihenfolge)

### Phase 1 — Bootstrap (Sprint 1)
- `Blizz.toc` erweitern, Lade-Reihenfolge der Module festlegen.
- `core/eventbus.lua`, `core/cooldowns.lua`, `core/unitstate.lua`, `core/combatlog.lua` (Skelette).
- `config/savedvars.lua` mit `BlizzDB`-Defaults.
- `ui/theme.lua` mit den v6-Tokens.
- `ui/widgets/{frame,bar,icon,text,alert}.lua` als Basis-Widgets.
- `tests/mocks/wow_api.lua` als Mock-Layer.
- Smoke-Test: Addon lädt ohne Error, `/blizz` slash command zeigt Status.
- **Liefert:** kein UI auf dem Schirm, aber Foundation steht und Tests laufen headless.

### Phase 2 — Tank-Core
Vier Module parallel implementierbar:
- **`modules/mitigation`** — Shield Block CD/Charges + Ignore Pain absorb readout. Anchor: center +12 % +15 %.
- **`modules/cooldowns`** — Defensive-CD-Bar (Wall, LastStand, SpellReflect, Demo, Rally, Avatar, Banner, Charge). Anchor: bottom center +24 %.
- **`modules/threat`** — Aggro-Status-Pill im Top-Strip + Lost-Aggro-Pulse-Frame über Spieler.
- **`modules/reflect`** — listened auf `UNIT_SPELLCAST_START` von Nameplate-Units, matched gegen `data/reflect_spells.lua`, triggert Alert-Widget mit Pulse.
- **Liefert:** spielbar als Tank-HUD ohne M+-Features.

### Phase 3 — M+ Run-Frame
- **`modules/mplus_frame`** — Forces %, Timer, +2/+3-Schwellen, Death-Counter (CLEU-basiert), Pulls (basierend auf Forces-Delta). Anchor: topleft + topright.
- Referenz-Code: WarpDeplete (MIT-lizenziert) für Formeln zur Schwellen-Berechnung.

### Phase 4 — Affix-Modul Season 1
- **`modules/affix_s1`** — registriert sich für `NAME_PLATE_UNIT_ADDED`, filtert auf `data/affixes_s1.lua`-NPC-IDs (Voidbound-Emissary, Pulsar-Beam-Spawn etc.), zeigt Warning-Banner. Audio-Cue optional über `PlaySoundFile`.
- Pflege: pro Saison neu zu kuratieren.

### Phase 5 — Nameplate-Klassifizierung
- **`modules/nameplates`** — hookt `NAME_PLATE_UNIT_ADDED`/`_REMOVED`, schaut NPC-ID in `data/npcs_midnight_s1.lua` nach, ordnet zu Kategorie (Caster/Frontal/Healer/Priority/Generic), overlay-Frame in v6-Stil:
  - Caster: gefülltes Magenta-Plate
  - Frontal: Teal-Outline
  - Healer: gefülltes Lime-Plate mit Skull-Icon
  - Priority-Kill: Red-Outline mit Skull
- WoW Standard-Nameplate bleibt erhalten; Blizz fügt nur Overlay hinzu.

### Phase 6 — Kick-Rota
- **`modules/kickrota`** — kombiniert:
  1. CLEU für `SPELL_INTERRUPT` und `SPELL_CAST_SUCCESS` (Interrupt-CDs lokal tracken).
  2. Addon-Comm-Channel `BLIZZ` für Party-Sync (welcher Player hat welchen Interrupt up).
  3. Algorithmus: bei `UNIT_SPELLCAST_START` auf kickbarem Cast (Spell in `data/reflect_spells.lua` mit Flag `interruptible`) → Bestimme nächsten Kicker basierend auf CDs → Highlight Plate + "YOUR KICK"-Alert wenn du dran bist.
- Fallback: nicht alle Spieler haben Blizz → graceful, nur lokaler Player wird getrackt.

### Phase 7 — Party-CDs (mini)
- **`modules/party_cds`** — Top-10 externe Defensives (Pain Suppression, Innervate, Tranquility, BoP, Cocoon, etc.), via CLEU + addon-comm-broadcast. Keine Spec/Talent-Database — nur Default-CDs aus `data/party_cds.lua`.

### Phase 8 (optional/später) — Boss-Timer-Engine
- Wenn BigWigs/LittleWigs abgelöst werden soll. Datenstruktur aus `data/encounters_s1.lua`. Erstmal **out of scope**, BigWigs/LittleWigs parallel zu Blizz laufen lassen.

---

## 7. Saved-Variables

```lua
-- BlizzDB (account-wide)
BlizzDB = {
  version = 1,
  profiles = {
    ["default"] = {
      positions = { [moduleId] = {x=0, y=0, anchor="CENTER", relativeAnchor="CENTER"} },
      disabled = { [moduleId] = false },
      hero_talent = "auto",  -- "auto" | "mountain_thane" | "colossus"
      theme_overrides = {},  -- token overrides
      module_options = {
        mitigation = { show_charges = true, show_absorb_value = true },
        kickrota = { announce_to_party = false },
        nameplates = { override_default = false },
      },
    },
  },
  active_profile = "default",
  errors = {},  -- ring buffer of last 50 errors
}
```

`BlizzDB.version` ermöglicht Migration bei Schema-Änderungen (`config/savedvars.lua` enthält `migrators[1→2]`).

---

## 8. Error-Handling

- **Event-Bus** `pcall`t jeden Subscriber. Fehler landen in `BlizzDB.errors` mit Modul-ID, Event-Name, Stack. `/blizz errors` zeigt die letzten 10.
- **Daten-Files** validieren beim Load mit `assert`-Statements:
  ```lua
  assert(type(BlizzData.spells_prot_warrior) == "table", "spells_prot_warrior missing")
  ```
  Fällt eine Validation, deaktiviert sich nur das betroffene Modul, `print("|cffff2966[Blizz]|r module X disabled (missing data)")`.
- **Mock-Layer** nur in dev-Builds geladen (`if BlizzMock then ... end`), nicht in Production-TOC eingetragen.
- **Stale data** (z.B. neuer Boss-Encounter den unsere DB nicht kennt): Module degradieren elegant — z.B. Affix-Modul zeigt keine Warning, statt zu crashen.

---

## 9. Testing

### 9.1 Headless via Mock-Layer
- `tests/mocks/wow_api.lua` exportiert Stubs für die WoW-Globals die Blizz nutzt:
  - `CreateFrame`, `UIParent`, `UnitHealth`, `UnitGetTotalAbsorbs`, `UnitAura`, `UnitThreatSituation`
  - `GetSpellCooldown`, `GetSpellCharges`
  - `C_Timer.After`, `C_Scenario.GetCriteriaInfo`
  - `COMBAT_LOG_EVENT_UNFILTERED`-Event-Simulation via `MockCLEU(...)`
- Tests laufen mit Standalone `lua5.1` Interpreter, kein WoW nötig.
- Beispiel-Test:
  ```lua
  -- tests/modules/test_mitigation.lua
  require "tests.mocks.wow_api"
  local M = require "modules.mitigation"
  M:init()
  MockSetCooldown(46968, 0, 6)  -- Shield Wall
  M:onEvent("SPELL_UPDATE_COOLDOWN")
  assert(M:getBar("wall").state == "cd")
  assert(M:getBar("wall").remaining > 5)
  ```

### 9.2 In-Game-Test
- Nach jedem größeren Modul-Wechsel: `/reload` in WoW, manuell durchklicken.
- Test-Dungeon: Maisara Caverns Trash (viele Caster, kickbare Spells, Voidbound-Spawns).

### 9.3 Test-Runner
- Simpler Lua-Script `tests/run.lua` der alle `test_*.lua` Files lädt und Asserts zählt.
- Optional: lua-language-server `--check` als Pre-Commit-Style-Gate (manuell).

---

## 10. Out of Scope (Phase 1–7)

- Eigene Boss/Trash-Timer-Engine als Vollersatz für BigWigs (Phase 8, optional).
- Rotation-Suggester / Hekili-Style — fragil/TOS-riskant nach Midnight 12.0 API-Lockdown. `LibButtonGlow` für "next priority" reicht.
- Multi-Spec-Support außerhalb Prot Warrior (Phase 1 ist Prot-only; andere Tank-Specs in späteren Milestones).
- PvP-Features (Enemy-CD-Tracking, Diminishing Returns).
- Detailliertes In-Game-Optionspanel (Phase 1: Slash-Command + SavedVars hand-edit reicht; richtige Options-UI in späterer Phase).
- Multi-Profile-Management (Sharing, Import/Export) — kommt mit Options-UI.
- WeakAuras-Ersatz als generisches Aura-Framework — bewusst keine Konkurrenz.

---

## 11. Risiken und offene Punkte

| Risiko | Mitigation |
|---|---|
| WoW Patch ändert API/Spell-IDs | Saison-Refresh-Phase in jedem Major-Patch; Daten-Files versioniert |
| MDT-Daten-Import: Lizenz-Klärung | `data/LICENSES.md` mit Quellen-Attribution; MDT ist MIT/GPL — prüfen vor Phase 5 |
| Addon-Comm-Protokoll-Drift | Channel-Name `BLIZZ`, Message-Format mit `version` Prefix für Forward-Compat |
| Visuelle Effekte ohne CSS schwierig | WoW-spezifische Anmerkung in Abschnitt 4 — Texture-Layering + Animation-Groups, Aufwand realistisch einplanen |
| Headless-Mock vollständig genug? | Erstmal nur die ~15 wichtigsten APIs mocken; mehr nachschieben bei Bedarf |
| Hero-Talent-Switch-Detection | "auto"-Mode liest beim Login `C_ClassTalents.GetActiveConfigID` und checkt die Talent-Tree-IDs — Fallback "mountain_thane" |

### Offene Fragen für die Implementierungs-Phase
- Genaue Spell-IDs für 12.0.5 in `data/spells_prot_warrior.lua` müssen aus Wowhead/Class-Guides bestätigt werden (Phase-2-Vorarbeit).
- MDT-NPC-DB-Lizenz prüfen vor Phase-5-Import.
- Addon-Comm-Format definieren (Phase-6-Vorarbeit).

---

## 12. Referenzen

- Mockups (permanent, im Repo):
  - `docs/superpowers/mockups/layout-v3.html` — finales Layout
  - `docs/superpowers/mockups/style-v6.html` — finaler Stil
- Memory-Files:
  - `~/.claude/projects/-home-deck-claude-blizz/memory/project_blizz.md`
  - `~/.claude/projects/-home-deck-claude-blizz/memory/project_toolchain.md`
  - `~/.claude/projects/-home-deck-claude-blizz/memory/project_architecture_decision.md`
  - `~/.claude/projects/-home-deck-claude-blizz/memory/project_layout_decision.md`
  - `~/.claude/projects/-home-deck-claude-blizz/memory/project_visual_style.md`
- Recherche: durchgeführt 2026-05-13 via brainstorming-Subagent. Quellen u.a. Wowhead, Icy-Veins, Maxroll, Method, Raider.IO, MDT GitHub, BigWigs GitHub, OmniCD CurseForge, WarpDeplete GitHub.
- Projekt-Repo: `/home/deck/claude/blizz/` (kein Git-Repo Stand 2026-05-13)

---

## 13. Nächste Schritte

1. **User-Review** dieser Spec → diese Spec.
2. **Implementation-Plan** via `superpowers:writing-plans` für Phase 1 (Bootstrap).
3. **Spike**: einmal `/reload` mit leerem Addon-Skelett um TOC + lua-language-server-Setup zu validieren.
4. **Optional vor Phase 1**: Git init (`git init && git add -A && git commit -m "initial"`) damit wir atomare Commits pro Phase machen können — empfohlen.
