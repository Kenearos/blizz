---
stepsCompleted:
  - 'step-01-validate-prerequisites'
  - 'step-02-design-epics'
  - 'step-03-create-stories'
  - 'step-04-final-validation'
inputDocuments:
  - '_bmad-output/planning-artifacts/product-brief.md'
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/solution-architecture.md'
workflowType: 'epics-stories'
draftMode: 'auto-drafted-from-prd-arch-v1'
---

# Blizz — Epic & Story Breakdown

**Author:** Kenearos (mit Bob, BMAD Scrum-Master/Story-Author)
**Date:** 2026-05-15
**Status:** Draft v1 · **Stage:** Planning
**Vorgänger-Artefakte:** [Brief v2](./product-brief.md) · [PRD v1](./prd.md) · [Architecture v1](./solution-architecture.md)

> **Hinweis:** Auto-gedraftet aus PRD + Architecture. Story-Aufschnitt 1 Recipe = 1 Story, MCP-Tools je eigene Story. Acceptance-Criteria im Given/When/Then-Format, kompakt. Reihenfolge innerhalb Epic = Implementierungs-Vorschlag, nicht starr.

## Overview

Vier Epics, gemappt auf PRD-Sektion 14:

- **Epic A — Wissensbank + Discovery** (16 Stories): Cookbook-Schema, Pattern-Recipes, Migration-Recipes, `llms.txt`, `AGENTS.md`, `adopters.md`
- **Epic B — Ketho-Pipeline + MCP** (18 Stories): git-submodule, Build-Skript, MCP-Server mit drei Tools, CI-Workflows, README-Snippets, Registry, Upstream-PR-Prozess
- **Epic C — Reference-Implementations** (4 Stories): Tank-UI-Polish, from-scratch Healer-Cooldown-Tracker mit Claude-Session-Transcript
- **Epic D — Passive Distribution** (4 Stories): Awesome-Lists, Wago/CurseForge, Skills-Marketplace, Lizenz-Klarstellung

**Gesamt: 42 Stories.** Phase-1-DoD = alle Stories Done. Keine harte Reihenfolge zwischen Epics, aber innerhalb Epic B gilt: B.1 → B.2 vor B.3..B.7; B.8..B.10 nach B.7; B.15..B.17 nach allem anderen; B.18 (Upstream-Prozess-Doku) kann jederzeit parallel laufen.

## Requirements Inventory

### Functional Requirements (aus PRD §10)

- **FR-COOK-01..05** (Cookbook-Schema und Recipe-Struktur)
- **FR-DISC-01..04** (llms.txt, llms-full.txt, AGENTS.md, adopters.md)
- **FR-KETHO-01..05** (Submodule, Build, Drift-CI, Upstream-Prozess)
- **FR-MCP-01..06** (3 Tools, Continue/Cursor-Snippets, Registry, GIF)
- **FR-REF-01..03** (Tank-UI-Stabilität, from-scratch-Beispiel mit Transcript)
- **FR-CLI-01..03** (Slash-Commands, install.sh, Build-`--check`-Flag)

### Non-Functional Requirements (aus PRD §11)

- **NFR-PERF-01..04** (Test-Suite ≤5s, Build ≤30s, MCP-Latenz, Addon-Frame-Time)
- **NFR-REL-01..04** (Tank-UI 0 Errors/Woche, Build-Determinismus, MCP-Health, 100% Recipe-Coverage)
- **NFR-MAINT-01..04** (stylua, Patch-Review, Ketho-Pin-Refresh, BMAD-Artefakte)
- **NFR-SEC-01..03** (stdio-only, Attribution, keine Secrets)
- **NFR-COMPAT-01..04** (TOC-Pflege, LuaJIT-Idiome, Continue/Cursor, llms.txt-Drift)
- **NFR-OBS-01..03** (EventBus-Errors, ActionDiag, MCP-Strukturlog)

### FR Coverage Map

| FR/NFR | Stories |
|---|---|
| FR-COOK-01..05 | A.1, A.2–A.13 |
| FR-DISC-01..04 | A.14, A.15, A.16 |
| FR-KETHO-01 (Submodule + Pin) | B.1 |
| FR-KETHO-02 (Build-Skript) | B.3, B.4, B.5, B.6, B.7 |
| FR-KETHO-03 (Determinismus) | B.6, B.7 |
| FR-KETHO-04 (CI Drift-Detection) | B.16 |
| FR-KETHO-05 (Upstream-PR-Prozess + CONTRIBUTING.md) | B.18 |
| FR-MCP-01..06 | B.8, B.9, B.10, B.11, B.12, B.13, B.14 |
| FR-REF-01..03 | C.1, C.2, C.3, C.4 |
| FR-CLI-01..03 | A.1 (--check Hook in Build), bestehende Lua-Slash-Commands bleiben |
| NFR-PERF-* | B.2 (Test-Setup), B.7 (Build-Perf-Constraint) |
| NFR-REL-* | C.1 (Tank-UI-Audit), B.2 (Vitest-Setup), A.x (Recipe-Tests), B.8 (Health-Check-Tool über stdio) |
| NFR-MAINT-* | bestehende stylua-Pflege; A.1 (Recipe-Schema-Validation) |
| NFR-SEC-* | D.4 (Lizenz), B.8..B.10 (stdio-only Implementation) |
| NFR-COMPAT-* | bestehend (TOC, LuaJIT); A.15 (AGENTS.md) |
| NFR-OBS-* | bestehend; B.8..B.10 (MCP-JSON-Log) |

## Epic List

1. Epic A — Wissensbank + Discovery
2. Epic B — Ketho-Pipeline + MCP
3. Epic C — Reference-Implementations
4. Epic D — Passive Distribution

---

## Epic A: Wissensbank + Discovery

**Ziel:** Konsolidiere alle in Blizz bereits implementierten Patterns und alle Midnight-12.0-Migration-Pfade als task-orientierte Recipes mit runnable Test-Cases. Mache sie via `llms.txt`/`llms-full.txt`/`AGENTS.md` für LLM-Workflows konsumierbar. `adopters.md` auto-trackt Adoption.

**FR-Bezug:** FR-COOK-01..05, FR-DISC-01..04

### Story A.1: Cookbook-Schema, Index und Validation

**As a** Solo-Maintainer,
**I want** ein verbindliches Recipe-Schema mit Front-Matter-Spec, einen Cookbook-Index und einen CI-Validator,
**so that** alle nachfolgenden Recipes konsistent strukturiert sind und Drift früh erkannt wird.

**Acceptance Criteria:**
- **Given** ein neues Recipe wird unter `docs/cookbook/<category>/<slug>.md` angelegt,
  **When** der Build-Validator läuft (`npm run build:cookbook -w mcp-server -- --check`),
  **Then** wird das Front-Matter (`id`, `category`, `title`, `tags`, `source`, `test_file`) gegen das Schema geprüft und der Body auf die Schema-Sektionen (Intent, Problem, Code, Stolperfalle, Test).
- **Given** das Cookbook hat ≥ 1 Recipe,
  **When** Build läuft,
  **Then** wird `docs/cookbook/index.md` mit Auto-Liste aller Recipes (Titel + 1-Zeilen-Intent) generiert oder gegen handgepflegte Version validiert.
- **Given** ein Recipe fehlt im `test_file`-Pfad,
  **When** Build/CI läuft,
  **Then** fail mit klarer Fehlermeldung.
- **Given** der bestehende Lua-Runner `tests/run.lua` scannt aktuell nur top-level `tests/test_*.lua` (siehe `tests/run.lua:8-29`),
  **When** A.1 abgeschlossen ist,
  **Then** wurde der Runner so erweitert, dass er `tests/**/test_*.lua` rekursiv discovered (Voraussetzung dafür, dass `tests/cookbook/test_<slug>.lua` aus den nachfolgenden Stories tatsächlich läuft).

### Story A.2: Recipe — EventBus mit Pcall-Containment (pattern)

**As a** Vibecoder/Maintainer,
**I want** ein Recipe, das den EventBus + Pcall-Containment-Pattern aus `core/eventbus.lua` reproduzierbar erklärt,
**so that** ich es in mein eigenes Addon kopieren kann ohne `core/`-Tree zu reverse-engineeren.

**Acceptance Criteria:**
- **Given** ich öffne `docs/cookbook/patterns/eventbus.md`,
  **Then** sehe ich Intent (1 Absatz), Problem (warum nicht direkt `SetScript("OnEvent")`), Code (minimaler Bus + Subscribe + Pcall-Wrap), Stolperfalle (Forgotten-Pcall, Error-Ring-Buffer), Test (Headless-Mock-Beispiel).
- **Given** ich kopiere das Code-Snippet allein,
  **Then** läuft es ohne weitere Cookbook-Lookups (out-of-context).
- **Given** `tests/cookbook/test_eventbus.lua` existiert,
  **When** `luajit tests/run.lua`,
  **Then** Test grün.

### Story A.3: Recipe — Secrets-Defense für Combat-APIs (pattern)

**As a** Maintainer auf Midnight-12.0-Migration,
**I want** ein Recipe für den `issecretvalue()`-Wrapper-Pattern,
**so that** mein Code nicht still mit Secret-Values gefüttert wird.

**Acceptance Criteria:**
- **Given** Recipe `docs/cookbook/patterns/secrets-defense.md` existiert,
  **Then** zeigt es `core/secrets.lua` + `core/unitstate.lua` + `core/cooldowns.lua` als Verbund.
- **Given** ich kopiere das Pattern,
  **Then** weiß ich, welche APIs zwingend gewrapped werden müssen (`UnitHealth`, `C_Spell.GetSpellCooldown`, etc.).
- **Given** Test `tests/cookbook/test_secrets_defense.lua` existiert,
  **When** Mock liefert Secret-Value,
  **Then** Wrapper liefert Sentinel (statt zu crashen).

### Story A.4: Recipe — Cooldowns-Wrapper (pattern)

**As a** Vibecoder,
**I want** das `core/cooldowns.lua`-Pattern als Drop-in,
**so that** ich Cooldown-Anzeigen ohne Midnight-12.0-Recherche bauen kann.

**Acceptance Criteria:**
- **Given** Recipe + Test existieren,
  **Then** Code-Snippet zeigt `C_Spell.GetSpellCooldown` mit Pcall + Secret-Check + Fallback-Sentinel.
- **Given** Test feuert `MockSetCooldown(<spellID>, GetTime(), 5)` (Signatur `MockSetCooldown(spellID, start, duration, charges?, maxCharges?)` aus `tests/mocks/wow_api.lua:334`),
  **Then** Wrapper liefert ein Cooldown-Objekt mit `remaining ≈ 5` und secret-value-sicher.

### Story A.5: Recipe — UnitState-Wrapper (pattern)

**As a** Vibecoder,
**I want** das `core/unitstate.lua`-Pattern,
**so that** ich `UnitHealth`/`UnitPower` ohne Secret-Value-Risiko lesen kann.

**Acceptance Criteria:**
- **Given** Recipe + Test existieren,
  **Then** zeigt der Code `UnitHealth`/`UnitHealthMax` mit Wrapper.
- **Given** Test feuert `MockSetUnit("player", { health = 50, maxHealth = 100 })` (Signatur `MockSetUnit(unit, props)` aus `tests/mocks/wow_api.lua:331`),
  **Then** Wrapper liefert ratio 0.5 ± epsilon.

### Story A.6: Recipe — Module-Registration & Bootstrap-Flow

**As a** Vibecoder,
**I want** den Modul-Kontrakt (`id`/`events`/`init`/`onEvent` + `addon.registerModule`) als Recipe,
**so that** ich neue Module schreiben kann, ohne `Blizz.lua`-Bootstrap zu kopieren.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** zeigt es Minimal-Modul + Erklärung, was registrieren bewirkt (EventBus-Subscribe, ref-counted RegisterEvent).
- **Given** Test feuert simuliertes `PLAYER_LOGIN` + `UNIT_AURA`,
  **Then** Modul `init` läuft einmal, `onEvent` läuft für jedes UNIT_AURA.

### Story A.7: Recipe — Position-Persistence & Drag-to-Move

**As a** Vibecoder,
**I want** `addon.restorePosition(...)` als Recipe,
**so that** mein Addon Position-Persistenz ohne Ace3-DB hat.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** zeigt es `restorePosition` + `SavedVars:setPosition` + Drag-Handler.
- **Given** Test setzt Position via Mock, simuliert Reload,
  **Then** Frame ist an gespeicherter Position.

### Story A.8: Recipe — Widget-State-System

**As a** Vibecoder,
**I want** das `:setReady()/:setCD()/:setAlert()/:setDefault()`-Widget-Pattern,
**so that** mein UI-Code keine direkten `:SetBackdropColor`-Calls aus Modulen macht.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** zeigt es Frame/Text/Icon/Bar/Alert mit State-Methoden + Theme-Tokens.
- **Given** Test setzt State,
  **Then** `frame:getState()` liefert erwarteten State-Namen (Test asserted nicht Farbe, sondern State).

### Story A.9: Recipe — Headless-Testing-Setup

**As a** Maintainer/Contributor,
**I want** das Lua-Mock-Harness als Recipe,
**so that** ich ohne WoW-Client testen kann.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** zeigt es `tests/run.lua` + `tests/mocks/wow_api.lua`-Strukturprinzip + Beispiel-Test.
- **Given** Cookbook-Test selbst,
  **When** `luajit tests/run.lua`,
  **Then** Test grün (meta-validierung).

### Story A.10: Migration-Recipe — Secret-Values

**As a** Maintainer auf Migration,
**I want** ein Diff-Beispiel "Dragonflight-API → Midnight-Secret-Value-Wrapper",
**so that** ich meine Combat-Reads systematisch porten kann.

**Acceptance Criteria:**
- **Given** Recipe `docs/cookbook/migrations/secret-values.md`,
  **Then** zeigt Front-Matter `source: own` (Eigentext), Vorher-Diff (Dragonflight-Style), Nachher-Diff (mit Wrapper).
- **Given** Test `test_migration_secret_values.lua` simuliert beide Pfade,
  **Then** Vorher-Pattern crashed mit Secret-Value, Nachher-Pattern liefert Sentinel.

### Story A.11: Migration-Recipe — CLEU-Removal

**As a** Maintainer,
**I want** das Recipe für die `COMBAT_LOG_EVENT_UNFILTERED`-Beschneidung in Midnight,
**so that** ich nicht stundenlang Wiki-Pages durchklicke.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** zeigt es entfernte Subevents, Drop-in-Replacements oder Workarounds, Test-Case.

### Story A.12: Migration-Recipe — C_Spell-Namespace

**As a** Maintainer,
**I want** das Recipe für die Verschiebung von `GetSpellCooldown`/`GetSpellInfo`/etc. nach `C_Spell.*`,
**so that** ich Mass-Rename mit Confidence machen kann.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** zeigt es Mapping-Tabelle alt→neu, Pcall-Hinweis, Test.

### Story A.13: Migration-Recipe — Deprecations Sammel-Liste

**As a** Maintainer,
**I want** ein Recipe, das die übrigen Midnight-Deprecations sammelt (Globals, Frame-Hooks, …),
**so that** ich eine Checkliste habe statt zu suchen.

**Acceptance Criteria:**
- **Given** Recipe existiert,
  **Then** enthält strukturierte Tabelle der Deprecations mit Replacement-Hinweisen.
- **Given** Build,
  **Then** Tabelle ist in `llms-full.txt` als Mapping rendert (für LLM-Lookup).

### Story A.14: `llms.txt` als Discovery-Wegweiser

**As a** Vibecoder,
**I want** eine `llms.txt` im Repo-Root,
**so that** ich nur einen URL in meinen System-Prompt packen muss.

**Acceptance Criteria:**
- **Given** `llms.txt` im Repo-Root existiert,
  **Then** folgt sie Anthropic/Vercel/Stripe-Pattern (URL-Liste mit 1-Zeilen-Beschreibungen).
- **Given** alle Recipes existieren,
  **Then** linkt `llms.txt` auf Cookbook-Index + Top-Level-Doku.
- **Given** GitHub-Raw-URL,
  **Then** ist `llms.txt` direkt fetchbar (kein Build nötig).

### Story A.15: `AGENTS.md` aus `CLAUDE.md` generieren

**As a** Cursor/Codex-User,
**I want** `AGENTS.md` mit demselben Inhalt wie `CLAUDE.md`,
**so that** mein Tool die Convention-Datei findet.

**Acceptance Criteria:**
- **Given** `CLAUDE.md` wird editiert,
  **When** `npm run build:cookbook -w mcp-server` läuft,
  **Then** wird `AGENTS.md` mit identischem Kern-Inhalt + Tool-Spektrum-Header neu generiert.
- **Given** `AGENTS.md` im Repo,
  **Then** ist sie konsistent mit `CLAUDE.md` (CI-Check).

### Story A.16: `adopters.md` Auto-Update via GitHub-Code-Search

**As a** Repo-Maintainer,
**I want** eine `adopters.md`, die wöchentlich automatisch Repos listet, die unsere `llms.txt` referenzieren,
**so that** Adoption sichtbar wird ohne manuelles Tracking.

**Acceptance Criteria:**
- **Given** GitHub-Action `adopters.yml` läuft per cron (weekly),
  **When** sie `gh search code "blizz/llms.txt"` ausführt,
  **Then** rendert sie `adopters.md` mit Repo-Liste (Name, Beschreibung, Link).
- **Given** kein neuer Adopter,
  **When** Action läuft,
  **Then** kein Commit (idempotent).
- **Given** Adopters-File ist sichtbar im Repo-Root,
  **Then** README linkt darauf.

---

## Epic B: Ketho-Pipeline + MCP

**Ziel:** Integriere `Ketho/vscode-wow-api` per git-submodule + Build-Skript. Baue MCP-Server mit drei Tools (wow-api-search, recipe-search, migration-lookup), publiziere im MCP-Registry, mit Continue.dev/Cursor-Config-Snippets.

**FR-Bezug:** FR-KETHO-01..05, FR-MCP-01..06

### Story B.1: Ketho als git-submodule + Pin-File

**As a** Maintainer,
**I want** Ketho/vscode-wow-api unter `vendor/ketho/` als submodule mit explizitem Commit-Pin,
**so that** Builds reproduzierbar sind und Drift sichtbar wird.

**Acceptance Criteria:**
- **Given** `.gitmodules` + `vendor/ketho.pin`,
  **When** `git clone --recursive` oder `git submodule update --init`,
  **Then** ist `vendor/ketho/` auf dem pinnten Commit.
- **Given** Submodule-Update via `scripts/update-ketho.sh`,
  **Then** wird Pin-File mit neuem Hash committed.

### Story B.2: `mcp-server/`-Workspace Setup

**As a** Maintainer,
**I want** einen TypeScript/Node-Workspace unter `mcp-server/` plus eine minimale Root-`package.json` mit Workspace-Deklaration (ADR-002b),
**so that** Build-Skript und MCP-Server Code teilen, Tests laufen und `-w mcp-server`-Aufrufe vom Repo-Root funktionieren.

**Acceptance Criteria:**
- **Given** `mcp-server/package.json` existiert,
  **Then** mit `@modelcontextprotocol/sdk`, `vitest`, `typescript`, ESM-Modul-Typ.
- **Given** im Repo-Root existiert eine minimale `package.json` mit `"private": true` und `"workspaces": ["mcp-server"]` (ADR-002b),
  **And** `mcp-server/package.json` mit `vitest`, `typescript`, ESM-Modul-Typ,
  **When** ich `npm install` und dann `npm test -w mcp-server` vom Repo-Root ausführe,
  **Then** läuft Vitest (ggf. zunächst leer/grün).
- **Given** `tsconfig.json` strict-Mode,
  **Then** TypeScript-Build clean.

### Story B.3: Build-Skript — Recipe-Parser

**As a** Build-System,
**I want** einen Markdown-Parser, der Recipe-Front-Matter und Sektionen extrahiert,
**so that** strukturierte Daten an MCP-Datenquelle und Renderer fließen.

**Acceptance Criteria:**
- **Given** ein Recipe-Markdown mit gültigem Schema,
  **When** Parser läuft,
  **Then** liefert er ein typsicheres `Recipe`-Objekt (id, category, title, tags, source, test_file, intent, problem, code, pitfall, test).
- **Given** ein Recipe mit Schema-Fehler,
  **Then** wirft Parser mit Pfad + Zeile.

### Story B.4: Build-Skript — Ketho-Annotation-Parser

**As a** Build-System,
**I want** einen LuaCATS-Parser, der `vendor/ketho/**` extrahiert,
**so that** API-Signaturen + Namespaces in MCP-Datenquelle landen.

**Acceptance Criteria:**
- **Given** Ketho-Submodule-Inhalt,
  **When** Parser läuft,
  **Then** liefert er `{name, namespace, signature, params, returns, examples?}`-Records.
- **Given** Parser-Fehler (z.B. unverarbeitbarer Ketho-Edge-Case),
  **Then** strukturiertes Logging + non-fatal-Skip (Drift-Issue später).

### Story B.5: Build-Skript — Wiki-Mirror-Parser

**As a** Build-System,
**I want** Wiki-Migration-Pages aus `data-wiki/` parsen,
**so that** Migration-Lookups Wiki-Kontext anreichern.

**Acceptance Criteria:**
- **Given** `data-wiki/` mit Migration-Page-HTML/Markdown-Mirror,
  **When** Parser läuft,
  **Then** strukturierte Migration-Einträge mit Attribution-Footer.
- **Given** Wiki-Inhalt fehlt für eine API,
  **Then** Parser ist tolerant (no-op statt fail).

### Story B.6: Build-Skript — `llms-full.txt`-Renderer

**As a** Vibecoder mit Single-File-Ingestion,
**I want** einen `llms-full.txt`-Dump,
**so that** ich das gesamte Cookbook in einen Prompt-Context kippen kann.

**Acceptance Criteria:**
- **Given** alle Recipes + Top-Level-Doku,
  **When** Renderer läuft,
  **Then** entsteht eine `dist/llms-full.txt` mit klaren Section-Headern und stabiler Reihenfolge.
- **Given** zweiter Build ohne Source-Änderungen,
  **Then** ist `llms-full.txt` byte-identisch (Determinismus).

### Story B.7: Build-Skript — `mcp-data.json` Output

**As a** MCP-Server,
**I want** eine `mcp-data.json` als In-Memory-Quelle,
**so that** Tool-Calls O(log n)- oder O(1)-Lookups machen können.

**Acceptance Criteria:**
- **Given** alle Recipe-/Ketho-/Wiki-Daten,
  **When** Renderer läuft,
  **Then** ist `dist/mcp-data.json` valides JSON mit Indizes für Tool-Lookups.
- **Given** Build,
  **Then** Wallclock ≤ 30s (NFR-PERF-02), in CI gemessen.

### Story B.8: MCP-Tool — `wow-api-search`

**As a** LLM (über Cursor/Claude),
**I want** ein Tool, das einen Query → API-Signatur+Examples+Stolperfallen löst,
**so that** ich korrekte 12.0-Calls generieren kann.

**Acceptance Criteria:**
- **Given** MCP-Server läuft via stdio,
  **When** Tool-Call `wow-api-search({query: "UnitHealth"})`,
  **Then** Antwort enthält Namespace, Signatur, Cookbook-Cross-Ref (z.B. Secrets-Defense), Stolperfalle.
- **Given** kein Match,
  **Then** strukturierte "not found"-Antwort statt Fehler.
- **Given** p95-Latenz-Messung,
  **Then** ≤ 200ms (NFR-PERF-03).

### Story B.9: MCP-Tool — `recipe-search`

**As a** LLM,
**I want** ein Tool, das nach Recipes mit Query + optional Category sucht,
**so that** ich Pattern-Code direkt referenzieren kann.

**Acceptance Criteria:**
- **Given** Tool-Call `recipe-search({query: "EventBus"})`,
  **Then** Antwort enthält Recipe-Title, Intent, Code-Snippet, Link.
- **Given** Tool-Call mit `category: "migrations"`,
  **Then** nur Migration-Recipes.

### Story B.10: MCP-Tool — `migration-lookup`

**As a** LLM/Maintainer,
**I want** ein Tool, das alte API/Pattern → Migrations-Recipe löst,
**so that** Drop-in-Replacements auffindbar sind.

**Acceptance Criteria:**
- **Given** Tool-Call `migration-lookup({api_name: "GetSpellCooldown"})`,
  **Then** Antwort verlinkt `migrations/c-spell-namespace.md` + zeigt direkten Replacement-Diff.
- **Given** alte Pattern (Substring) statt API-Name,
  **Then** Fuzzy-Match auf Migration-Front-Matter.

### Story B.11: README — Continue.dev Config-Snippet

**As a** Continue-User,
**I want** einen Copy-Paste-Block für `config.yaml`,
**so that** ich Blizz-MCP in einer Minute aktiviere.

**Acceptance Criteria:**
- **Given** README enthält Continue-Snippet-Block,
  **Then** mit korrektem `mcpServers`-Schema und `npx`-Befehl (oder global-Install-Pfad).
- **Given** ich kopiere den Block,
  **Then** funktioniert MCP-Discovery in Continue (manuell verifiziert).

### Story B.12: README — Cursor Config-Snippet

**As a** Cursor-User,
**I want** dasselbe für Cursor `mcp.json`,
**so that** Cursor Blizz-MCP findet.

**Acceptance Criteria:**
- **Given** README enthält Cursor-Snippet-Block,
  **Then** ist `mcp.json`-Format korrekt.
- **Given** ich kopiere den Block,
  **Then** Cursor sieht den Server in seiner MCP-Liste.

### Story B.13: GIF-Demo im README

**As a** README-Leser,
**I want** ein animiertes Demo,
**so that** ich vor dem Setup sehe, was passiert.

**Acceptance Criteria:**
- **Given** README enthält GIF-Embed,
  **Then** zeigt es: LLM-Prompt → MCP-Tool-Call → strukturierte Antwort → resultierender Code.
- **Given** GIF ist ≤ 5 MB,
  **Then** GitHub-rendert es performant.

### Story B.14: MCP-Registry-Manifest

**As a** MCP-Registry-Crawler,
**I want** ein Manifest (`server.json` oder vergleichbar) im Repo,
**so that** Blizz im Registry-Listing erscheint.

**Acceptance Criteria:**
- **Given** Manifest existiert nach aktueller MCP-Registry-Spec,
  **Then** enthält es: name, description, tools, install-command.
- **Given** Submission im Registry,
  **Then** Listing geht live.

### Story B.15: CI — `test.yml` (Lua + Node)

**As a** PR-Autor,
**I want** automatische Tests auf jedem PR,
**so that** keine roten Builds gemerged werden.

**Acceptance Criteria:**
- **Given** PR mit Lua- oder TS-Änderung,
  **When** `test.yml` läuft (Repo ist npm-Workspace mit `mcp-server` als Workspace, siehe ADR-002b),
  **Then** `luajit tests/run.lua` und `npm test -w mcp-server` werden vom Repo-Root ausgeführt.
- **Given** stylua-Verstoß,
  **Then** Workflow fail.

### Story B.16: CI — `ketho-drift.yml` (weekly cron)

**As a** Maintainer,
**I want** wöchentliche Drift-Detection gegen Ketho-`HEAD`,
**so that** ich neue Annotations früh integriere.

**Acceptance Criteria:**
- **Given** Cron triggert,
  **When** Action läuft `git submodule update --remote vendor/ketho` + `npm run build:cookbook -w mcp-server -- --check` (vom Repo-Root, dank Workspace-Setup aus ADR-002b),
  **Then** bei Drift wird Issue mit Diff-Summary erstellt.
- **Given** kein Drift,
  **Then** Action no-op.

### Story B.17: CI — `build.yml` + GitHub-Pages-Deploy

**As a** LLM-Tool-User,
**I want** stabile `llms-full.txt`-URL auf GitHub Pages,
**so that** mein System-Prompt einen unveränderlichen URL referenzieren kann.

**Acceptance Criteria:**
- **Given** Push auf main mit Cookbook-Change,
  **When** `build.yml` läuft,
  **Then** wird `dist/llms-full.txt` auf GitHub Pages deployed.
- **Given** Pages-URL,
  **Then** liefert das aktuelle `llms-full.txt`.
- **Given** Tag-Release,
  **Then** wird `llms-full.txt` auch als Release-Asset attached.

### Story B.18: Upstream-PR-Prozess für Ketho-Annotation-Lücken (CONTRIBUTING.md)

**As a** Recipe-Autor,
**I want** einen dokumentierten Prozess für Ketho-Upstream-PRs (CONTRIBUTING.md-Sektion + Commit-Footer-Template + Checkliste),
**so that** Annotation-Lücken systematisch (statt ad-hoc) als PRs an `Ketho/vscode-wow-api` zurückfließen — gemäß FR-KETHO-05 und ADR-004.

**Acceptance Criteria:**
- **Given** `CONTRIBUTING.md` existiert im Repo-Root,
  **Then** enthält sie eine Sektion "Ketho-Upstream-Prozess" mit (a) Schritt-für-Schritt-Anleitung, (b) Commit-Footer-Template `Discovered while building github.com/kenearos/blizz`, (c) Hinweis auf `scripts/update-ketho.sh` für Pin-Update nach Merge.
- **Given** ein Recipe-Autor findet eine Annotation-Lücke,
  **When** sie dem Prozess folgen,
  **Then** entsteht ein Upstream-PR; falls abgelehnt, beschreibt der Prozess Fallback auf `vendor/ketho-patches/` (siehe ADR-004 Fallback).
- **Given** Repo-Doku-Index,
  **Then** wird `CONTRIBUTING.md` vom README verlinkt.

---

## Epic C: Reference-Implementations

**Ziel:** Tank-UI bleibt funktionaler Daily-Driver (Bug-Polish wo nötig). Zweites Mini-Addon als from-scratch-Beweis, dass das Cookbook + LLM ein Mini-Addon erzeugen kann.

**FR-Bezug:** FR-REF-01..03, NFR-REL-01

### Story C.1: Tank-UI Backlog-Audit & Polish

**As a** Daily-Driver-Nutzer (Kenearos),
**I want** alle offenen Tank-UI-Bugs gefixt,
**so that** Phase-1-DoD (0 unbehandelte Errors/Woche) erreichbar ist.

**Acceptance Criteria:**
- **Given** `/blizz errors`-Audit aktuell + Backlog in `docs/alt-superpowers/plans/`,
  **When** Audit-Story durchgeführt wird,
  **Then** ist eine Issue-Liste erstellt + priorisiert (P0=Daily-Driver-Blocker, P1=Nervig, P2=Nice).
- **Given** alle P0+P1 abgearbeitet,
  **Then** ist Phase-1-DoD aus dieser Achse erreicht.

### Story C.2: `examples/from-scratch/` Setup + Konvention

**As a** Cookbook-Validator,
**I want** ein `examples/from-scratch/`-Verzeichnis mit README-Template,
**so that** zukünftige Beispiele konsistent gestaltet werden.

**Acceptance Criteria:**
- **Given** Verzeichnis + `README.md` mit Konvention (transcript.md + Addon-Files + Test-Note),
  **Then** ist Template für weitere Beispiele klar.
- **Given** Verzeichnis bleibt leer bis C.3,
  **Then** keine Placeholder-Files.

### Story C.3: Healer-Cooldown-Tracker — Claude-Session + Transcript + Addon

**As a** Cookbook-Validator,
**I want** ein 50–100-Zeilen-Mini-Addon, das ein Dritter mit nur dem Cookbook + LLM erzeugt hat,
**so that** Cookbook-Validation-Loop empirisch nachweisbar ist.

**Acceptance Criteria:**
- **Given** dokumentierte Claude-Session,
  **Then** ist `transcript.md` mit komplettem Verlauf eingecheckt (Prompts + Responses).
- **Given** Session,
  **Then** wurden ausschließlich Cookbook-Recipes und `llms.txt` als Quelle benutzt (keine extra-Hinweise vom Author).
- **Given** resultierendes Addon,
  **Then** lädt in WoW Midnight 12.0, zeigt Healer-Cooldowns korrekt, hat TOC + Lua-Source ≤ 100 Zeilen.
- **Given** Addon,
  **Then** läuft `luajit -e ...` Headless-Test (Smoke).

### Story C.4: Cookbook-Lücken aus Transcript als Backlog-Issues

**As a** Maintainer,
**I want** alle Stellen, an denen der LLM stockte oder Halluzination zeigte, als Issues,
**so that** Cookbook iterativ verbessert wird.

**Acceptance Criteria:**
- **Given** Transcript-Analyse,
  **When** Issues geschrieben werden,
  **Then** Label `cookbook-gap` + Referenz auf konkrete Stelle im Transcript.
- **Given** Issue zu LLM-Halluzination,
  **Then** Issue benennt: erwarteter API-Call, halluzinierter API-Call, fehlendes Recipe.

---

## Epic D: Passive Distribution

**Ziel:** Setze parallel zur Entwicklung passive Distributionskanäle an. Kein Launch-Event, sondern Discovery-Hooks die mit der Zeit Reach erzeugen.

**FR-Bezug:** Brief v2 §"Passive Distribution"; NFR-SEC-02 (Lizenz)

### Story D.1: Awesome-Lists-PR-Set

**As a** Repo-Maintainer,
**I want** initiale PRs in den wichtigsten Awesome-Repos,
**so that** Blizz in Backlink-Aggregatoren auftaucht.

**Acceptance Criteria:**
- **Given** Liste der Target-Repos: `awesome-llms-txt`, `awesome-mcp-servers`, `awesome-claude-skills`, `JuanjoSalvador/awesome-wow` (PR oder Fork),
  **When** PRs eingereicht,
  **Then** jeweils 2-Zeilen-Eintrag mit Repo-Link + 1-Zeile-Beschreibung.
- **Given** PR-Status,
  **Then** dokumentiert in `docs/distribution.md` (eigene Tracking-Tabelle).

### Story D.2: Tank-UI auf Wago/CurseForge listen

**As a** WoW-Spieler-Discovery,
**I want** Blizz-Tank-UI auf Wago und/oder CurseForge auffindbar,
**so that** Discovery-Funnel zum Cookbook entsteht.

**Acceptance Criteria:**
- **Given** Listing-Eintrag,
  **Then** Beschreibung enthält in Zeile 1 einen Link zu Blizz-Cookbook.
- **Given** Release-Asset,
  **Then** zip-Bundle der Addon-Dateien (`Blizz.lua`, `Blizz.toc`, `core/`, `modules/`, `ui/`, `data/`, `config/`).

### Story D.3: Claude-Skills-Marketplace Submission

**As a** Claude-User,
**I want** Blizz als Skill auffindbar,
**so that** ich es mit einem Klick aktivieren kann.

**Acceptance Criteria:**
- **Given** MCP-Server live + Registry-gelistet,
  **When** Skill-Submission eingereicht,
  **Then** Skill-Bundle enthält MCP-Konfig + Cookbook-Link.
- **Given** Skill akzeptiert,
  **Then** in `docs/distribution.md` dokumentiert.

### Story D.4: `LICENSE-CONTENT.md` (Lizenz-Hybrid)

**As a** Repo-Konsument,
**I want** explizite Lizenz-Trennung Code/Inhalte/Wiki-Derivate,
**so that** rechtssichere Übernahme möglich ist.

**Acceptance Criteria:**
- **Given** `LICENSE-CONTENT.md`,
  **Then** erklärt: Code MIT, Cookbook-Eigenprosa MIT, Wiki-Derivate CC-BY-SA mit Attribution.
- **Given** Recipe-Front-Matter mit `source: wiki-derivative`,
  **Then** Build-Renderer fügt Attribution-Footer automatisch hinzu.
- **Given** README,
  **Then** verlinkt `LICENSE` + `LICENSE-CONTENT.md`.

---

## Offene Punkte / nächste Schritte

- `bmad-validate-prd` über `prd.md` laufen lassen (Smoke-Check)
- `bmad-check-implementation-readiness` vor Sprint-Start
- Stories priorisieren falls Sprint-Pakete gebildet werden sollen (Default: Epic-Reihenfolge, B.1+B.2 vor allem anderen)
- Konkrete Wahl des From-scratch-Beispiels final bestätigen (Default: Healer-Cooldown-Tracker)
