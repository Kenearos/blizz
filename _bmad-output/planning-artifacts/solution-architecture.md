---
stepsCompleted:
  - 'step-01-init'
  - 'step-02-context'
  - 'step-03-starter'
  - 'step-04-decisions'
  - 'step-05-patterns'
  - 'step-06-structure'
  - 'step-07-validation'
inputDocuments:
  - '_bmad-output/planning-artifacts/product-brief.md'
  - '_bmad-output/planning-artifacts/prd.md'
workflowType: 'architecture'
project_name: 'Blizz'
user_name: 'Kenearos'
date: '2026-05-15'
draftMode: 'auto-drafted-from-prd-v1'
---

# Solution Architecture — Blizz

**Author:** Kenearos (mit Winston, BMAD Architect-Facilitator)
**Date:** 2026-05-15
**Status:** Draft v1 · **Stage:** Planning · **Vorgänger-Artefakte:** [Brief v2](./product-brief.md), [PRD v1](./prd.md)
**Nächstes Artefakt:** Epics & Stories

> **Hinweis zum Draft-Modus:** Auto-gedraftet aus PRD v1 im "durchziehen"-Modus. Architektonische Entscheidungen sind hier benannt und begründet, aber jede ist revidierbar — bei Bedarf einzelne Decisions per `bmad-advanced-elicitation` vertiefen.

---

## 1. Context

### 1.1 System-Zweck

Blizz ist ein Mono-Repo mit drei Subsystemen, die sich gegenseitig speisen:

- **WoW-Addon (Lua, existierend):** Protection-Warrior-M+-Tank-UI mit EventBus, Secrets-Defense, Position-Persistence. Läuft unter LuaJIT 2.1 in WoW Midnight 12.0.
- **Wissens- & Discovery-Layer (neu):** Cookbook-Markdowns + Build-Pipeline + `llms.txt`/`llms-full.txt`/`AGENTS.md` + auto-`adopters.md`.
- **MCP-Server (neu):** stdio-Transport, exposed Cookbook + Ketho-Annotations als LLM-Tool-Use.

### 1.2 Constraints

- **Solo-Maintainer (Kenearos)** — keine harten Deadlines, Definition-of-Done statt Sprint
- **WoW-Runtime ist nicht änderbar** — LuaJIT 5.1, Midnight 12.0 API ist Vorgabe
- **Headless-Test-Harness existiert** — `tests/run.lua` mit Mock-WoW-Globals (~130ms full run)
- **Ketho/vscode-wow-api** ist Source-of-Truth für API-Annotations, wird nicht dupliziert

### 1.3 Stakeholder & Use-Cases (aus PRD §5)

- Vibecoder mit LLM-Workflow (Primary)
- Klassischer Addon-Dev auf Migration (Primary)
- LLM-Trainings/RAG-Konsumenten (Primary, indirekt)
- Kenearos selbst (Tertiary, Daily-Driver-Pflicht)

## 2. Starter-Kontext (Brownfield)

Existierende Codebase ist die Basis, nicht Greenfield:

```
blizz/
├── Blizz.lua              Bootstrap, EventBridge, /blizz Slash-Commands
├── Blizz.toc              WoW-Manifest (## Interface: 120005)
├── core/
│   ├── eventbus.lua       Pcall-containment + Error-Ring-Buffer
│   ├── wowevents.lua      Ref-counted RegisterEvent
│   ├── unitstate.lua      Sichere UnitHealth/-Power-Reads
│   ├── cooldowns.lua      Sichere C_Spell.GetSpellCooldown
│   └── secrets.lua        issecretvalue()-Wrapper
├── config/savedvars.lua   BlizzDB-Schema + Migrations
├── data/                  Static-Data (Tankbusters, Spells)
├── ui/
│   ├── theme.lua          Tokens
│   └── widgets/           Frame/Text/Icon/Bar/Alert
├── modules/<name>/init.lua  10 Module nach Modul-Kontrakt
├── tests/
│   ├── run.lua            Test-Discovery + Runner
│   ├── mocks/wow_api.lua  WoW-API-Stubs
│   └── test_*.lua         Headless-Test-Files
├── docs/
│   ├── cookbook/          (1)–(5) bereits vorhanden
│   ├── alt-superpowers/   Historische Plans/Specs
│   └── ...
├── scripts/install.sh
├── stylua.toml
├── .luarc.json
└── CLAUDE.md              Projekt-Instruktionen (Deutsch)
```

**Wesentliche bestehende Patterns** (werden dokumentiert, nicht refactored):
- Modul-Kontrakt mit `events = {…}` + `onEvent` (EventBus-Subscription)
- Bootstrap-Flow: TOC top-down → `Blizz.lua` → `addon:bootstrap()` auf `PLAYER_LOGIN`
- Widget-State-Methoden (`:setReady()/:setCD()/:setAlert()/:setDefault()`)
- SavedVars-Versioning + Migrators
- Position-Persistence via `addon.restorePosition(frame, id, anchor, x, y)`

## 3. Architektonische Entscheidungen (ADRs)

### ADR-001: Mono-Repo statt Multi-Repo

**Status:** Accepted
**Context:** Drei Subsysteme (Addon, Docs/Build, MCP-Server) könnten separate Repos sein.
**Decision:** Ein einzelnes Repo unter `github.com/kenearos/blizz`.
**Rationale:**
- Atomare Commits über Addon + Docs (z.B. neuer Pattern + zugehöriges Recipe)
- Reference-Impl steht direkt neben Cookbook (Validierungs-Loop ist sichtbar)
- Niedrigere kognitive Last für Solo-Dev (eine Issue-Liste, ein PR-Stream)
- Distribution: GitHub-Raw funktioniert für `llms.txt` aus Repo-Root
**Consequences:**
- MCP-Server-Versionierung muss explizit gemacht werden (eigener Pfad `mcp-server/` mit eigener `package.json` o.ä.)
- CI braucht Path-Filter für unabhängige Test-Läufe (Addon vs. MCP-Server)

---

### ADR-002: MCP-Server-Sprache — TypeScript/Node.js

**Status:** Accepted
**Context:** PRD §13.1 — Node oder Python.
**Decision:** TypeScript auf Node.js 20+ mit `@modelcontextprotocol/sdk`.
**Rationale:**
- Continue.dev und Cursor sind primäre Targets — beide Node-zentrisch, native Integration via npm ohne Python-Runtime-Friction
- MCP-SDK ist in TypeScript am ausgereiftesten
- Cookbook-Inhalte sind Markdown — Parser-Ökosystem in Node ist reicher
- Kenearos ist mit JS/TS vertraut (existierende `.claude/` Tooling)
**Consequences:**
- Node-Toolchain wird Dev-Requirement (war es vorher nicht)
- Distribution via npm-Paket (`@kenearos/blizz-mcp` o.ä.)
- Lua-Hauptcode bleibt unangetastet — saubere Subsystem-Trennung

**Considered alternatives:**
- Python + `mcp` SDK: gut für Lua-Annotation-Parsing (luaparser-Pakete reifer), aber Continue/Cursor-Friction höher
- Lua-MCP-Server: SDK-Unreife, kein Argument für Konsistenz

---

### ADR-003: Build-Skript-Sprache — Node/TypeScript

**Status:** Accepted
**Context:** PRD §13.2.
**Decision:** Build-Skript als Node-Subkommandos im selben MCP-Server-Workspace (`mcp-server/scripts/build-cookbook.ts`).
**Rationale:**
- Shared Code: MCP-Server lädt dieselben gerenderten Datenquellen, die Build erzeugt → kein duplizierter Parser
- Konsistenz mit ADR-002
- TypeScript-Typen für Recipe-Schema sind selbst Doku
**Consequences:**
- Bash bleibt nur für `scripts/install.sh` (WoW-AddOns-Verzeichnis-Symlink)
- `package.json` script: `npm run build:cookbook`
- WoW-Addon kann ohne Node weiter installiert/getestet werden (Lua-Pfad bleibt sauber)

---

### ADR-004: Ketho-Integration — git-submodule mit Commit-Pin

**Status:** Accepted
**Context:** PRD FR-KETHO-01. Alternativen: Build-Time-Pull (curl/git-archive), npm-Paket falls Ketho eines published, eigene API-Datenbank.
**Decision:** `git submodule` unter `vendor/ketho/`, Pin in `.gitmodules` + dokumentiert in `vendor/ketho.pin`.
**Rationale:**
- Pin = reproducible builds, Drift wird explizit
- Submodule erlaubt lokale PRs gegen Ketho direkt aus diesem Workspace (Upstream-Strategie aus PRD FR-KETHO-05)
- Kein npm-Paket vorhanden, eigener Build wäre N+1-Problem
- Eigene API-DB → PRD §"Bewusst out-of-scope" verbietet das
**Consequences:**
- `git clone --recursive` wird Pflicht für Contributor
- CI-Workflow muss `submodule update --init` ausführen
- Pin-Update ist ein expliziter Commit (sichtbar im Log)

---

### ADR-005: CI-Provider — GitHub Actions

**Status:** Accepted
**Context:** PRD §13.3, NFR-MAINT-04.
**Decision:** GitHub Actions (`.github/workflows/`).
**Rationale:**
- Repo lebt auf GitHub — kein anderer Provider rechtfertigt zusätzlichen Account
- Cron für drift-detection nativ (`schedule:`)
- Code-Search-API für `adopters.md`-Auto-Update gut integriert
- MCP-Demo-GIF kann via Action gerendert werden (optional)
**Consequences:**
- Free-Tier reicht für Solo-Repo (öffentlich)
- Workflows: `test.yml` (Lua + Node-Tests), `ketho-drift.yml` (weekly cron), `adopters.yml` (weekly cron), `build.yml` (auf push für `llms-full.txt`)

---

### ADR-006: `llms-full.txt` als Build-Artefakt, nicht checked-in

**Status:** Accepted
**Context:** `llms-full.txt` ist gerenderter Dump aus Cookbook + Ketho — entweder ständig committed (Diff-Noise) oder Build-Artefakt (Release-Asset / Pages-Deploy).
**Decision:** Build-Artefakt. Deploy auf GitHub Pages unter `blizz.kenearos.dev/llms-full.txt` (oder direkt `github.io`-Subdomain). README-Link zeigt auf stable URL.
**Rationale:**
- Diff-Noise wäre toxisch für PR-Reviews (jedes Recipe-Update würde 1000+ Zeilen `llms-full.txt`-Diff erzeugen)
- Stable URL ist wichtiger als git-history für Discovery (LLM-Tools cachen URL-Inhalte)
- `llms.txt` (Wegweiser, klein) bleibt committed
**Consequences:**
- GitHub Pages-Setup in M1 nötig
- Build-CI deployed auf Tag-Release
- Lokal: `npm run build:cookbook` erzeugt File für Inspection

---

### ADR-007: `AGENTS.md` — generiert aus `CLAUDE.md` via Build

**Status:** Accepted
**Context:** PRD FR-DISC-03. Optionen: Symlink, identische Kopie, generiert.
**Decision:** Build-Step generiert `AGENTS.md` aus `CLAUDE.md` mit Front-Matter, das das Tool-Spektrum (agents.md, Cursor, Claude, Codex) explizit listet.
**Rationale:**
- Symlink funktioniert auf Linux/Mac, aber nicht zuverlässig auf Windows
- Identische Kopie führt zu Drift (zwei Wahrheiten)
- Generierung erlaubt Tool-spezifische Headers/Footer, ohne Kern-Inhalt zu duplizieren
**Consequences:**
- Build-Skript-Verantwortung wächst um diese Transformation
- `CLAUDE.md` bleibt Source-of-Truth (heißt: nur dort editieren)

---

### ADR-008: Recipe-Schema als TypeScript-Typ + JSON-Schema-Export

**Status:** Accepted
**Context:** PRD FR-COOK-01 definiert Schema (Intent · Problem · Code · Stolperfalle · Test). Wie erzwingen?
**Decision:** Recipe-Markdown hat Front-Matter mit `{id, category, title, tags, test_file}`. Build-Parser validiert. Schema ist TypeScript-Interface in `mcp-server/src/recipe-schema.ts`, JSON-Schema-Export für Editor-Validation.
**Rationale:**
- Maschinell parsierbar → MCP-Server kann strukturierte Antworten geben
- Front-Matter-Felder steuern auch MCP-Tool-Filter (`recipe-search(category: "migrations")`)
- Validation in CI fängt Schema-Drift früh
**Consequences:**
- Cookbook-Autoren (Kenearos + Contributors) müssen Front-Matter pflegen
- Editor-Plugin-Vorschlag: YAML-Front-Matter mit Schema-Hint im README

---

### ADR-009: MCP-Tool-Transport — stdio-only für v1.0

**Status:** Accepted
**Context:** PRD FR-MCP-01..03, NFR-SEC-01. MCP unterstützt stdio + HTTP/SSE.
**Decision:** Nur stdio-Transport in v1.0.
**Rationale:**
- Continue.dev und Cursor unterstützen stdio nativ
- Kein Netzwerk-Inbound = drastisch weniger Security-Surface
- Lokaler Tool-Use ist primärer Use-Case
**Consequences:**
- Hosted-MCP-Service ist out-of-scope für v1.0
- Falls später Remote-MCP gewünscht: separate Decision, nicht v1.0-blocker

---

### ADR-010: Test-Harness — bestehend für Lua, Vitest für Node

**Status:** Accepted
**Context:** NFR-REL-04 (Cookbook-Recipe-Test-Coverage 100%), NFR-PERF-01 (Test-Run ≤ 5s).
**Decision:**
- Lua-Tests bleiben in `tests/` mit `luajit tests/run.lua` (kein Refactor)
- Node-Tests (MCP-Server, Build-Skript) mit Vitest in `mcp-server/test/`
- Recipe-Test-Cases: Lua-Tests in `tests/cookbook/test_<slug>.lua`, vom existierenden Runner discovered (Naming-Convention reicht)
**Rationale:**
- Bestehendes Lua-Harness ist schnell, fokussiert, kein Grund zu ersetzen
- Vitest ist de-facto-Standard für TS/Node 2026, schnell, Watch-Mode
- Recipe-Tests laufen im selben Runner wie Modul-Tests → kein zweiter Test-Befehl
**Consequences:**
- Zwei Test-Befehle insgesamt: `luajit tests/run.lua` und `npm test -w mcp-server`
- CI hat zwei parallele Jobs

---

### ADR-011: Lizenzierung — Code MIT, Inhalte attribuiert

**Status:** Accepted
**Context:** PRD NFR-SEC-02. Wiki-Inhalte (warcraft.wiki.gg) sind typischerweise CC-BY-SA. Ketho ist MIT.
**Decision:**
- Blizz-Eigencode: MIT (bestehend)
- Cookbook-Eigenprosa: MIT
- Wiki-derivative Inhalte (z.B. wenn Migration-Recipe direkt aus Wiki-Page übernommen wird): CC-BY-SA mit Attribution-Footer
- Ketho-Annotations in `vendor/ketho/`: bleiben unter Ketho's Lizenz (Submodule, nicht copy-paste)
- `LICENSE-CONTENT.md` erklärt Hybrid
**Rationale:**
- CC-BY-SA-Pflicht beim Übernehmen, MIT für eigene Arbeit, klare Trennung
- Submodule-Strategie umgeht Lizenz-Inkompatibilität bei Ketho
**Consequences:**
- Recipe-Front-Matter braucht `source:` Feld (eigen vs. wiki vs. ketho-derivative)
- Build-Skript rendert Attribution-Footer pro Recipe basierend auf `source:`

## 4. Architectural Patterns

### 4.1 Pattern: EventBus mit Pcall-Containment (bestehend, dokumentiert)

Frame `BlizzEventBridge` registriert via `frame:RegisterEvent`, EventBus pcall-wrapped jeden Subscriber. Modul-Code geht ausschließlich über `events = {…}` + `onEvent(self, event, ...)`. **Niemals** rohes `SetScript("OnEvent")` in Modul-Code.

Begründung: Pcall-Containment isoliert ein crashendes Modul. Errors landen in `addon.errors` (Ring-Buffer max 50), via `/blizz errors` sichtbar.

### 4.2 Pattern: Secret-Value-Wrapper (bestehend, dokumentiert)

Alle Combat-Reads gehen durch `core/unitstate.lua` / `core/cooldowns.lua`. Diese pcall-wrapen und prüfen via `core/secrets.lua` `issecretvalue()`. **WoW-APIs niemals direkt aus Modulen aufrufen.**

Begründung: Midnight 12.0 gibt für viele Combat-Reads "Secret Values" zurück, die in stiller Arithmetik schmutzige Werte erzeugen.

### 4.3 Pattern: Recipe-Schema mit Front-Matter (neu, ADR-008)

```yaml
---
id: eventbus-pcall-containment
category: patterns
title: EventBus mit Pcall-Containment
tags: [events, error-handling]
source: own
test_file: tests/cookbook/test_eventbus_pcall.lua
related: [secrets-defense, error-ring-buffer]
---
```

Markdown-Body folgt Schema: Intent → Problem → Code → Stolperfalle → Test.

### 4.4 Pattern: Build-Pipeline (neu)

```
                    ┌───────────────────┐
docs/cookbook/*.md  │                   │
vendor/ketho/       │ build-cookbook.ts │
data/wiki-mirror/   │  (Node script)    │
                    │                   │
                    └────────┬──────────┘
                             │
                ┌────────────┼────────────┐
                ▼            ▼            ▼
        llms-full.txt   AGENTS.md   mcp-data.json
        (Pages-Deploy)  (Repo)      (MCP-Server-Input)
```

### 4.5 Pattern: Upstream-First für Ketho-Lücken (neu, ADR-004 + ADR-011)

Annotation-Lücke gefunden → PR an `Ketho/vscode-wow-api` → Commit-Message-Footer: `Discovered while building github.com/kenearos/blizz`. Submodule-Pin nach Merge updaten. Falls Upstream ablehnt: lokal patchen unter `vendor/ketho-patches/` (Override-Mechanismus im Build).

## 5. Repo-Struktur (Ziel-Zustand v1.0)

```
blizz/
├── Blizz.lua                          [bestehend]
├── Blizz.toc                          [bestehend]
├── core/                              [bestehend]
├── config/                            [bestehend]
├── data/                              [bestehend]
├── ui/                                [bestehend]
├── modules/                           [bestehend]
├── tests/
│   ├── run.lua                        [bestehend]
│   ├── mocks/                         [bestehend]
│   ├── test_*.lua                     [bestehend]
│   └── cookbook/                      [neu] runnable Test-Cases pro Recipe
│       └── test_<slug>.lua
├── docs/
│   ├── cookbook/                      [erweitert]
│   │   ├── index.md                   [neu]
│   │   ├── patterns/                  [neu]
│   │   │   ├── eventbus.md
│   │   │   ├── secrets-defense.md
│   │   │   ├── cooldowns-wrapper.md
│   │   │   ├── unitstate-wrapper.md
│   │   │   ├── module-registration.md
│   │   │   ├── position-persistence.md
│   │   │   ├── widget-state-system.md
│   │   │   └── headless-testing.md
│   │   ├── migrations/                [neu]
│   │   │   ├── secret-values.md
│   │   │   ├── cleu-removal.md
│   │   │   ├── c-spell-namespace.md
│   │   │   └── deprecations.md
│   │   ├── 01-…05- *.md               [bestehend, ggf. integriert]
│   │   └── _meta.md                   [neu] (Format-Spec für Recipes)
│   ├── alt-superpowers/               [bestehend]
│   └── (sonstiges)
├── examples/
│   └── from-scratch/
│       └── healer-cooldown-tracker/   [neu]
│           ├── README.md
│           ├── transcript.md
│           ├── HealerCDs.toc
│           └── HealerCDs.lua
├── mcp-server/                        [neu]
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/
│   │   ├── index.ts                   (stdio entry)
│   │   ├── tools/
│   │   │   ├── wow-api-search.ts
│   │   │   ├── recipe-search.ts
│   │   │   └── migration-lookup.ts
│   │   ├── recipe-schema.ts
│   │   └── data-loader.ts
│   ├── scripts/
│   │   ├── build-cookbook.ts
│   │   └── render-agents.ts
│   └── test/
│       └── *.test.ts
├── vendor/
│   ├── ketho/                         [neu, git submodule]
│   ├── ketho.pin                      [neu] explicit commit hash
│   └── ketho-patches/                 [neu, optional Override]
├── data-wiki/                         [neu] mirrored Wiki-Migration-Pages
├── scripts/
│   ├── install.sh                     [bestehend]
│   └── update-ketho.sh                [neu] Submodule-Update-Helper
├── .github/workflows/
│   ├── test.yml                       [neu]
│   ├── ketho-drift.yml                [neu] weekly cron
│   ├── adopters.yml                   [neu] weekly cron
│   └── build.yml                      [neu] llms-full.txt + Pages
├── llms.txt                           [neu, Wegweiser]
├── AGENTS.md                          [neu, generiert]
├── CLAUDE.md                          [bestehend]
├── LICENSE                            [bestehend, MIT]
├── LICENSE-CONTENT.md                 [neu] Hybrid-Erklärung
├── README.md                          [bestehend, erweitert]
├── stylua.toml                        [bestehend]
├── .luarc.json                        [bestehend]
└── .gitmodules                        [neu]
```

## 6. Datenflüsse

### 6.1 Cookbook-Build (lokal)

```
Developer-Edit auf docs/cookbook/patterns/eventbus.md
     │
     ▼
npm run build:cookbook -w mcp-server
     │
     ├─► parse: docs/cookbook/**/*.md  (Front-Matter + Body)
     ├─► parse: vendor/ketho/**         (LuaCATS annotations)
     ├─► parse: data-wiki/**            (mirrored Wiki pages)
     │
     ▼
emit: dist/llms-full.txt   (single-file dump for ingestion)
emit: dist/mcp-data.json   (structured for MCP-Server)
emit: AGENTS.md            (generated from CLAUDE.md)
```

### 6.2 MCP-Tool-Call (Runtime)

```
LLM (Claude/Cursor)
     │
     │ stdio JSON-RPC
     ▼
mcp-server (Node process)
     │
     ├─► load on startup: dist/mcp-data.json (in-memory)
     │
     │   Tool-Calls:
     ├─► wow-api-search(query)      → fuzzy-match auf API-Names + Cookbook-Cross-Ref
     ├─► recipe-search(query, cat?) → fuzzy-match auf Recipe-Front-Matter + Body
     └─► migration-lookup(api_name) → exakte Lookup in Migration-Recipes
```

### 6.3 CI-Drift-Detection (weekly cron)

```
GitHub Actions weekly cron
     │
     ▼
ketho-drift.yml:
     ├─► git submodule update --remote vendor/ketho
     ├─► npm run build:cookbook --check
     ├─► diff dist/mcp-data.json baseline
     └─► falls Drift: auto-create Issue mit Diff-Summary

adopters.yml:
     ├─► gh search code "blizz/llms.txt" --json
     ├─► render adopters.md
     └─► commit + push (skip if no change)
```

## 7. Validation gegen PRD

| PRD-Anforderung | Architektur-Mapping |
|---|---|
| FR-COOK-01..05 | Recipe-Schema (ADR-008), `docs/cookbook/` Struktur (§5) |
| FR-DISC-01..04 | `llms.txt` checked-in, `llms-full.txt` als Build-Artefakt (ADR-006), `AGENTS.md` generiert (ADR-007), `adopters.yml` cron (§6.3) |
| FR-KETHO-01..05 | Submodule (ADR-004), Build-Pipeline (§6.1), CI-Drift (§6.3), Upstream-First-Pattern (§4.5) |
| FR-MCP-01..06 | MCP-Server in `mcp-server/` (§5), TypeScript (ADR-002), stdio-only (ADR-009), Continue/Cursor-Snippets im README |
| FR-REF-01..03 | Tank-UI bleibt (existing), `examples/from-scratch/` (§5), Transcript als Asset |
| FR-CLI-01..03 | Slash-Commands bleiben, `install.sh` bleibt, Build-`--check`-Flag (§6.3) |
| NFR-PERF-01..04 | Test-Pyramide (ADR-010), Build-Idempotenz, MCP-In-Memory-Daten (§6.2) |
| NFR-REL-01..04 | EventBus + Error-Ring-Buffer (bestehend, §4.1), 100%-Recipe-Coverage (ADR-010) |
| NFR-MAINT-01..04 | stylua (bestehend), Submodule-Pin-Review (ADR-004), BMAD-Artefakte unter `_bmad-output/` (bestehend) |
| NFR-SEC-01..03 | stdio-only (ADR-009), Lizenz-Policy (ADR-011), keine Secrets im Repo |
| NFR-COMPAT-01..04 | TOC-Pflege, LuaJIT-Idiome (bestehend), `llms.txt`-De-facto-Standard mit AGENTS.md-Backup |
| NFR-OBS-01..03 | EventBus + `BlizzActionDiag` bleiben, MCP-Server JSON-strukturiertes Log |

## 8. Architectural Risks & Open Decisions

| Risiko / offene Frage | Trigger | Default-Pfad |
|---|---|---|
| Node-Toolchain als neue Dev-Dep schreckt Contributor ab | Issue/Feedback | Pre-built Binary auf Releases anbieten, Dev-Docs in CONTRIBUTING.md |
| MCP-Spec ändert sich (1.0 in Vorbereitung) | SDK-Release | SDK-Pin in `package.json`, Adoption auf neue Spec in Follow-up-PR |
| Wiki-Crawling rechtlich problematisch | Cease-and-desist | Recipes als Eigentext, Wiki-Links statt Mirror falls nötig |
| Ketho-Maintainer-Aktivität sinkt | < 1 PR-Response in 4 Wochen | Fork-Plan-B; bisher kein Anzeichen (217★, daily updates per 2026-05) |
| GitHub-Pages-Limits (Build-Frequenz, Größe) | Build hits limit | `llms-full.txt` via Release-Asset oder externes CDN |

## 9. Migration-Pfad

Da Brownfield: keine "Migration" vom bestehenden Addon, sondern **additive Erweiterung**:

1. **Phase 1a (foundational, blocking):** Submodule + Build-Skript + minimaler MCP-Server (3 Tools, leere Datenquellen)
2. **Phase 1b (content, iterativ):** Recipes schreiben (Pattern-Recipes zuerst, weil aus existierendem Code ableitbar)
3. **Phase 1c (content, iterativ):** Migration-Recipes
4. **Phase 1d (validation):** From-scratch-Beispiel als Cookbook-Loop-Beweis
5. **Phase 1e (distribution):** GitHub Pages deploy, MCP-Registry-Submission, Awesome-PRs, Wago-Listing

Reihenfolge: Foundational vor Content (1a vor 1b). Pattern-Recipes können parallel zu Migration-Recipes geschrieben werden. From-scratch (1d) erst wenn Pattern-Recipes komplett.

## 10. Offene Punkte für Epics & Stories

- Epic-Schnitt entlang der vier PRD-Epics (A: Wissensbank+Discovery, B: Ketho+MCP, C: Reference-Impls, D: Distribution)
- Story-Schnitt pro Recipe (1 Recipe = 1 Story, mit Test-Case und ggf. Ketho-Upstream-PR-Subtask)
- Setup-Story für `mcp-server/`-Workspace (TypeScript-Toolchain, package.json, Vitest)
- Setup-Story für GitHub-Workflows
- Wahl des konkreten From-scratch-Beispiels final bestätigen (PRD-Default: Healer-Cooldown-Tracker)
