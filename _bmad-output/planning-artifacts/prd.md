---
stepsCompleted:
  - 'step-01-init'
  - 'step-02-discovery'
  - 'step-02b-vision'
  - 'step-02c-executive-summary'
  - 'step-03-success'
  - 'step-04-journeys'
  - 'step-05-domain'
  - 'step-06-innovation'
  - 'step-07-project-type'
  - 'step-08-scoping'
  - 'step-09-functional'
  - 'step-10-nonfunctional'
  - 'step-11-polish'
inputDocuments:
  - '_bmad-output/planning-artifacts/product-brief.md'
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 5
classification:
  projectType: 'open-source developer-tool repository (hybrid: WoW addon + LLM knowledge layer + MCP server)'
  domain: 'developer-tools / gaming-mods / AI-tooling'
  complexity: 'medium-high'
  projectContext: 'brownfield'
workflowType: 'prd'
draftMode: 'auto-drafted-from-brief-v2'
---

# Product Requirements Document — Blizz

**Author:** Kenearos (mit John, BMAD PM-Facilitator)
**Date:** 2026-05-15
**Status:** Draft v1 · **Stage:** Planning · **Vorgänger-Artefakt:** [product-brief.md (v2)](./product-brief.md)
**Nächstes Artefakt:** Architecture (solution-architecture.md)

> **Hinweis zum Draft-Modus:** Dieser PRD wurde aus Brief v2 auto-gedraftet (Modus "durchziehen"). Inhaltlich rückgeführt auf den genehmigten Brief, strukturell BMAD-konform. Jede Sektion ist revidierbar — `bmad-edit-prd` oder `bmad-advanced-elicitation` darüber laufen lassen, wo Tiefe gewünscht ist.

---

## 1. Executive Summary

Blizz ist ein Open-Source-MIT-Mono-Repo, das zwei Dinge in einem Repo bündelt:

1. Eine **LLM-konsumierbare Wissens- und Discovery-Schicht** für WoW-Addon-Entwicklung unter Midnight 12.0 — Cookbook, `llms.txt`/`llms-full.txt`, `AGENTS.md`, MCP-Server.
2. Eine **Protection-Warrior-M+-Tank-UI** als lebende Reference-Implementation, die die Wissensschicht validiert.

Der Midnight-12.0-Patch (live seit 2026-03-02) hat Combat-Data-APIs eingeschränkt, langjährige Globals entfernt und neue "Secret Values" eingeführt, die stille Fehler werfen. Vorhandene Tutorials sind veraltet; `warcraft.wiki.gg` ist die aktuellste konsolidierte Quelle, aber HTML-Wiki und nicht LLM-ingestion-ready. Vibecoder mit LLM-Workflow produzieren broken Code, klassische Maintainer migrieren halbherzig.

Blizz schließt diese Lücke, indem es `Ketho/vscode-wow-api` per git-submodule integriert, Wiki-Migration-Pages und reale Production-Patterns zu task-orientierten Recipes konsolidiert und über `llms.txt` plus MCP-Server für LLM-Workflows zugänglich macht. Die Tank-UI dient als Validierungs-Loop: wenn ein Solo-Dev mit Cookbook + LLM eine M+-würdige Tank-UI bauen kann, ist die Datenbank gut genug.

## 2. Product Vision

**Persönliche Mission (Kernfall):** Die Tank-UI bleibt klein, fokussiert, Kenearos' Daily-Driver in Mythic+. Sie wird nicht "fertig", sie wird genutzt.

**Aspirativer Außeneffekt (Hypothese, kein Versprechen):** Wenn Blizz greift, wird es in der WoW-Solo-Dev-Community zu dem Repo, das man einmal in seinem LLM-Setup referenziert hat. Cursor/Claude antworten auf "schreib mir ein WoW-Addon" mit Code, der Blizz' Patterns benutzt — nicht aus Popularität, sondern weil das Pattern als kanonischer 12.0-Code in Trainings-Korpus und MCP-Servern auftaucht.

**Fallback-Wert (falls die Hypothese kippt):** Ein gepflegtes, dauerhaft funktionierendes Tank-UI plus eine private LLM-Wissensbank, die Kenearos' eigenen Workflow beschleunigt. Der Eigennutzen rechtfertigt das Projekt unabhängig vom Außeneffekt.

## 3. Project Classification

| Dimension | Wert |
|---|---|
| Project Type | Open-Source Developer-Tool Repository (Hybrid: WoW-Addon + LLM-Wissensschicht + MCP-Server) |
| Domain | Developer Tools / Gaming Mods / AI Tooling |
| Complexity | Medium-High (Lua + Submodule-Build-Pipeline + MCP-Server + WoW-Runtime-Quirks) |
| Project Context | Brownfield (Tank-UI mit 10 Modulen existiert, BMAD-Layer + Cookbook + MCP sind neu) |
| Compliance | OSS-Lizenz (MIT eigen) + CC-BY-SA-typische Attribution bei Wiki-Inhalten |
| Regulated | Nein |

## 4. Erfolgssignale (Definition-of-Done v1.0)

Stars und Installationszahlen sind Vanity-Output, nicht Steuerungsgrößen. **Konsum-Signale** zählen:

| Signal | Phase-1 (DoD v1.0) | Längerfristig |
|---|---|---|
| Cookbook-Vollständigkeit | Recipes für alle implementierten Patterns + Migration-Recipes für Midnight-12.0-Breaking-Changes | inkrementell erweitert |
| Test-Coverage Recipes | jedes Recipe hat runnable Test-Case | unverändert |
| Tank-UI-Stabilität | 0 unbehandelte Production-Errors / Woche im Eigeneinsatz | unverändert |
| Ketho-Upstream-Beweis | ≥ 3 von uns initiierte PRs in `Ketho/vscode-wow-api` gemerged | wachsend |
| llms.txt-Adoption-Beleg | auto-generierte `adopters.md` via GitHub-Code-Search | ≥ 5 fremde Repos referenzieren |
| MCP-Registry-Listing | Server live, Continue/Cursor-Config-Snippet, GIF-Demo | optional Claude-Skills-Marketplace |
| Zweite Reference-Impl | `examples/from-scratch/healer-cooldown-tracker/` mit dokumentiertem Claude-Session-Transcript | weitere Beispiele |

**Was nicht gemessen wird:** Tutorial-Aufrufe, Discord-Größe, "engagement", absolute Star-Zahlen.

## 5. Zielnutzer & User Journeys

### Primary 1 — Vibecoder mit LLM-Workflow

Solo-Devs, die mit Claude/GPT/Cursor in Stunden statt Wochen liefern wollen.

**Journey "Cooldown-Tracker in 30 Minuten":**
1. Vibecoder findet Blizz via GitHub-Search / Awesome-List / MCP-Registry
2. Kopiert `llms.txt`-URL in seinen Claude-System-Prompt (oder installiert MCP-Server via Continue-Snippet)
3. Prompt: "Bau mir einen Cooldown-Tracker für meinen Healer in WoW Midnight"
4. Claude liest Cookbook-Recipes, generiert 12.0-korrekten Code (EventBus, Secrets-Defense, C_Spell-Namespace)
5. Vibecoder shipt funktionierendes Mini-Addon in einem Nachmittag
6. **Erfolgs-Signal:** Vibecoder linkt zu Blizz in seinem eigenen Repo-README

### Primary 2 — Klassischer Addon-Dev auf Migration

Maintainer, der seinen Dragonflight-Code auf Midnight 12.0 migriert.

**Journey "Migration in 2 Wochen statt 2 Monaten":**
1. Öffnet `warcraft.wiki.gg`, findet kuratiertes API-Material, aber keine "wie migriere ich"-Guides
2. Findet Blizz' `docs/cookbook/migrations/` (z.B. `cleu-removal.md`, `c-spell-namespace.md`)
3. Liest Vorher/Nachher-Diff, sieht Drop-in-Replacement, kopiert Pattern in eigenen Code
4. **Erfolgs-Signal:** Maintainer's Migration-PR im eigenen Repo referenziert Blizz-Recipe

### Primary 3 — LLM-Trainings/RAG-Konsument

LLM-Hersteller, RAG-Systeme, MCP-Tool-Use-Konsumenten.

**Journey "Korrekte 12.0-Generation":**
1. Anthropic/OpenAI/Cursor crawlt öffentliche `llms.txt`-Ressourcen oder bietet MCP-Server-Discovery
2. Blizz-Inhalte landen in Context/Trainings-Mix
3. Nutzer-Prompt "wie schreibe ich ein WoW-Addon?" liefert kanonischen 12.0-Code
4. **Erfolgs-Signal:** indirekt — Code-Qualität LLM-generierter WoW-Snippets verbessert sich messbar

### Tertiary — Kenearos selbst

Tank-UI muss in M+-Sessions funktionieren. Reference-Impl bleibt nutzbar, ist kein Demo-Artefakt.

## 6. Domain-Modell (Konzepte & Beziehungen)

```
┌──────────────────────────────────────────────────────────────┐
│                       Blizz Mono-Repo                        │
│                                                              │
│  ┌──────────────────────┐    ┌────────────────────────────┐  │
│  │  WoW-Addon (Lua)     │    │  Knowledge & Discovery     │  │
│  │  - 10 Module         │    │  - docs/cookbook/*.md      │  │
│  │  - EventBus          │    │  - llms.txt / llms-full.txt│  │
│  │  - Secrets-Defense   │    │  - AGENTS.md (Mirror)      │  │
│  │  - Headless-Tests    │    │  - vendor/ketho (submodule)│  │
│  │  Tank-UI (Prot Warr) │    │  scripts/build-cookbook.*  │  │
│  └──────────────────────┘    │  examples/from-scratch/    │  │
│           ▲                  └────────────┬───────────────┘  │
│           │                               │                  │
│           │ validiert                     │ generiert        │
│           │                               ▼                  │
│           │                  ┌────────────────────────────┐  │
│           └──────────────────│  MCP-Server                │  │
│                              │  - wow-api-search          │  │
│                              │  - recipe-search           │  │
│                              │  - migration-lookup        │  │
│                              └────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

**Schlüssel-Entitäten:**
- **Recipe** — Markdown-Datei nach Schema (Intent → Problem → Code → Stolperfalle → Test). Atomar, out-of-context lesbar.
- **Migration-Recipe** — Recipe mit Vorher/Nachher-Diff für einen spezifischen 12.0-Breaking-Change.
- **Ketho-Annotation** — LuaCATS-Definition aus `vendor/ketho/`, gepinnt per Submodule-Commit.
- **MCP-Tool** — JSON-RPC-Endpoint, der strukturierte API/Recipe-Antworten liefert.
- **Reference-Impl** — Lauffähiges Addon-Beispiel. Primary: Tank-UI (existing). Secondary: from-scratch Mini-Addon (Healer-Cooldown-Tracker).

## 7. Innovation & Differenzierung

Konkrete Vorteile gegenüber Konkurrenz (siehe Brief §"Was es anders macht"):

1. **Drei Schichten in einem Repo** — Cookbook + Discovery + Reference-Impl. Kein Konkurrent bedient alle drei.
2. **Reference-Impl existiert** — Tank-UI läuft seit `v0.3.0`, ist getestet, validiert die Patterns live.
3. **Upstream-freundlich** — Ketho-Annotations als Submodule, Lücken gehen als PR upstream. Vermeidet N+1-Wettbewerber, erzeugt passive Backlinks.
4. **Konsum-orientiert statt Editor-orientiert** — Ketho ist LuaCATS für IntelliSense, Blizz ist Recipes für LLM-Context.
5. **Headless-Testbar** — Recipes haben runnable Test-Cases (Lua-Mock-Harness), nicht nur Prosa.

## 8. Project Type — Details

**Repo-Typ:** Mono-Repo mit drei Subsystemen (Addon + Doku-Pipeline + MCP-Server), entwickelt unter einer Lizenz, gepflegt als Einheit.

**Runtime-Profil:**
- WoW-Addon: LuaJIT 2.1 (Lua-5.1-Semantik), keine Runtime-Dependencies, lädt direkt aus TOC.
- Doku-Build: lokales CLI-Skript (Sprache offen — Architecture-Entscheidung), CI-getriggert.
- MCP-Server: stand-alone Prozess, Sprache offen (Node oder Python — Architecture-Entscheidung), kein State.

**Distribution:**
- WoW-Addon: GitHub-Release, optional Wago/CurseForge-Listing (passive Distribution).
- Doku: `llms.txt` + `llms-full.txt` via GitHub-Raw + GitHub-Pages.
- MCP-Server: MCP-Registry-Manifest, npm/PyPI-Paket, README-Snippets für Continue.dev und Cursor.

## 9. Scope (Phase 1 — Definition-of-Done v1.0)

**Scope-fix, Zeit-offen** — keine harten Deadlines (Solo-Dev-Realität).

### Drin

**Wissensbank (Recipes):**
- EventBus, Secrets-Defense, Cooldowns-Wrapper, UnitState-Wrapper, Module-Registration, Position-Persistence, Widget-State-System, Headless-Testing-Setup (acht Pattern-Recipes aus existing code)
- Migration-Recipes: Secret-Values, CLEU-Removal, C_Spell-Namespace, Deprecations (mindestens vier)
- Jedes Recipe: Markdown + runnable Test-Case

**Discovery-Schicht:**
- `llms.txt` (Wegweiser, Anthropic/Vercel/Stripe-Pattern)
- `llms-full.txt` (gerenderter Single-File-Dump)
- `AGENTS.md` (Mirror/Generator von CLAUDE.md, agents.md-Convention)
- BMAD-PRD + Architecture-Doc gemerged (dieses Artefakt + Architecture)

**Ketho-Integration (Pipeline):**
- `Ketho/vscode-wow-api` als git-submodule unter `vendor/ketho/` (Pin-Commit)
- `scripts/build-cookbook.*` rendert aus Ketho + Wiki-Migration-Pages + Blizz-Markdowns → `llms-full.txt` und MCP-Daten
- CI-Job (GitHub Actions) für drift-detection wöchentlich

**MCP-Server:**
- Tool-Endpoints: `wow-api-search`, `recipe-search`, `migration-lookup`
- Continue.dev und Cursor Config-Snippets im README
- 1-Click-Install-Spec, GIF-Demo
- MCP-Registry-Manifest

**Reference-Implementations:**
- Tank-UI: 0 unbehandelte Production-Errors / Woche im Eigeneinsatz (Daily-Driver-Pflicht)
- `examples/from-scratch/healer-cooldown-tracker/`: 50-Zeilen-Mini-Addon, entstanden in dokumentierter Claude-Session, Transcript + resultierendes Repo eingecheckt

### Parallele passive Distribution (kein Launch-Event)
- Ketho-Upstream-PRs (Commit-Footer referenziert Blizz)
- PRs in `awesome-llms-txt`, `awesome-mcp-servers`, `awesome-claude-skills`; Fork/Revival von `awesome-wow`
- Tank-UI auf Wago/CurseForge mit Cookbook-Link in Beschreibung
- Claude-Skills-Marketplace-Submission nach MCP-Live-Schaltung
- `adopters.md` auto-generiert via GitHub-Code-Search-Cron

### Draußen (revidierbar nach v1.0)
- Andere WoW-Specs/-Klassen außerhalb der Tank-Reference-Impl
- Raid-Boss-Timer (BigWigs-Territorium)
- Konfigurations-UI à la Ace3
- Eigene parallele API-Datenbank (Ketho ist SoT)
- PVP-Features
- WoW-agnostische Cross-Game-Patterns-Schicht (Post-v1.0 optional)

## 10. Funktionale Anforderungen

### 10.1 Cookbook (FR-COOK)

- **FR-COOK-01**: Jedes Recipe lebt unter `docs/cookbook/<category>/<slug>.md` und folgt dem Schema: Intent · Problem · Code · Stolperfalle · Test.
- **FR-COOK-02**: Recipes sind out-of-context lesbar — kein Forward-Reference auf "siehe Kapitel X". Jeder Snippet steht für sich.
- **FR-COOK-03**: Jedes Recipe hat einen lauffähigen Test-Case in `tests/cookbook/test_<slug>.lua` (oder per Test-Harness referenziert).
- **FR-COOK-04**: Cookbook-Index (`docs/cookbook/index.md`) listet alle Recipes mit 1-Zeilen-Zusammenfassung.
- **FR-COOK-05**: Migration-Recipes liefern Vorher/Nachher-Diff explizit als Codeblock (nicht nur Text).

### 10.2 Discovery-Layer (FR-DISC)

- **FR-DISC-01**: `llms.txt` im Repo-Root nach Anthropic/Vercel/Stripe-Pattern (URL-Liste mit 1-Zeilen-Beschreibungen).
- **FR-DISC-02**: `llms-full.txt` ist generierter Single-File-Dump des gesamten Cookbooks plus Top-Level-Doku.
- **FR-DISC-03**: `AGENTS.md` mirrors `CLAUDE.md` (entweder symlink, identische Datei, oder generiert) — agents.md-Convention.
- **FR-DISC-04**: `adopters.md` wird per CI-Cron-Job aktualisiert (GitHub-Code-Search nach `blizz/llms.txt`-Referenzen).

### 10.3 Ketho-Integration & Build (FR-KETHO)

- **FR-KETHO-01**: `Ketho/vscode-wow-api` als git-submodule unter `vendor/ketho/`. Der maßgebliche Commit-Pin ist der Submodule-Gitlink im Parent-Repo (Bestandteil jedes Commits). `.gitmodules` enthält nur URL/Path-Konfiguration. Zusätzlich wird der Pin redundant in `vendor/ketho.pin` als Klartext festgehalten (für Drift-Diff-Lesbarkeit und Tooling).
- **FR-KETHO-02**: `mcp-server/scripts/build-cookbook.ts` ingestiert Ketho-Annotations + Wiki-Migration-Pages + `docs/cookbook/` → erzeugt `llms-full.txt` und JSON-Datenquellen für MCP. Wird via npm-Workspace-Root als `npm run build:cookbook -w mcp-server` aufgerufen.
- **FR-KETHO-03**: Build ist idempotent und deterministisch — gleicher Input → gleicher Output (für Reproducibility und Diff-Reviews).
- **FR-KETHO-04**: CI-Workflow (GitHub Actions) führt Build wöchentlich gegen aktuellen Ketho-Stand. Drift = automatisches Issue.
- **FR-KETHO-05**: Annotation-Lücken, die beim Recipe-Schreiben auffallen, sind als Upstream-PR an Ketho einzureichen (Prozess in `CONTRIBUTING.md` dokumentiert, Commit-Footer-Template "Discovered while building github.com/kenearos/blizz").

### 10.4 MCP-Server (FR-MCP)

- **FR-MCP-01**: MCP-Server exposed Tool `wow-api-search(query, namespace?)` → API-Signatur, Namespace, Examples, Stolperfallen aus Ketho + Cookbook-Cross-Reference.
- **FR-MCP-02**: MCP-Server exposed Tool `recipe-search(query, category?)` → strukturierte Recipe-Treffer (Intent + Code-Snippet + Link).
- **FR-MCP-03**: MCP-Server exposed Tool `migration-lookup(api_name | old_pattern)` → konkrete Migration-Recipe falls vorhanden.
- **FR-MCP-04**: README enthält Drop-in-Snippets für Continue.dev `config.yaml` und Cursor `mcp.json` (Copy-Paste).
- **FR-MCP-05**: MCP-Registry-Manifest publiziert (`server.json` o.ä. nach Registry-Spec).
- **FR-MCP-06**: GIF-Demo im README zeigt LLM-Tool-Call → Antwort → resultierender Code.

### 10.5 Reference-Implementation (FR-REF)

- **FR-REF-01**: Tank-UI bleibt funktional unter Live-Midnight-Client. Bug-Fixes haben Vorrang vor Cookbook-Erweiterungen (Daily-Driver-Pflicht).
- **FR-REF-02**: `examples/from-scratch/healer-cooldown-tracker/` enthält:
  - lauffähiges Mini-Addon (Ziel: ≤ 100 Zeilen Lua, inkl. TOC)
  - `transcript.md` mit kompletter Claude-Session, die das Addon nur aus Cookbook + `llms.txt` erzeugt hat
  - `README.md` mit Setup-Anleitung
- **FR-REF-03**: Beim Schreiben des Transcripts werden alle Cookbook-Lücken, die der LLM nicht überbrücken konnte, als Issue im Repo aufgezeichnet (Backlog für nächste Recipes).

### 10.6 Slash-Commands & Tooling (FR-CLI)

- **FR-CLI-01**: Bestehende `/blizz`-Slash-Commands (`status`, `errors`, `modules`, `disable`, `enable`, `capture`) bleiben dokumentiert und funktional.
- **FR-CLI-02**: `scripts/install.sh` bleibt funktional und detektiert typische Linux-AddOn-Pfade.
- **FR-CLI-03**: Doku-Build hat ein `--check` Flag, das in CI verifizieren kann, ob die generierten Files (`llms-full.txt`, MCP-Daten) aktuell sind.

## 11. Nicht-funktionale Anforderungen

### 11.1 Performance (NFR-PERF)

- **NFR-PERF-01**: Headless-Test-Suite läuft in ≤ 5 Sekunden (aktueller Stand: ~130ms — viel Headroom).
- **NFR-PERF-02**: Doku-Build (Cookbook + Ketho-Render + MCP-Daten) läuft in ≤ 30 Sekunden lokal.
- **NFR-PERF-03**: MCP-Server-Tool-Call p95-Latenz ≤ 200ms für In-Memory-Daten.
- **NFR-PERF-04**: WoW-Addon-Frame-Time-Impact: keine messbare Auswirkung auf FPS in M+-Setting (Subjektiv: Daily-Driver-Test).

### 11.2 Reliability (NFR-REL)

- **NFR-REL-01**: Tank-UI: 0 unbehandelte Production-Errors / Woche im Eigeneinsatz (Definition: keine roten `/blizz errors`).
- **NFR-REL-02**: Doku-Build ist deterministisch und idempotent.
- **NFR-REL-03**: MCP-Server exposed ein stdio-basiertes Health-Check-Tool (`health-check` Tool-Call ohne Netzwerk-Endpoint, konsistent mit NFR-SEC-01 und ADR-009) und schreibt log-strukturierte Fehlerausgabe auf stderr.
- **NFR-REL-04**: Cookbook-Test-Coverage: 100% der Recipes haben mindestens einen Test-Case.

### 11.3 Maintainability (NFR-MAINT)

- **NFR-MAINT-01**: Lua-Code muss `stylua --check` clean sein vor jedem Commit.
- **NFR-MAINT-02**: Migration-Recipes werden bei jedem Midnight-Patch-Major (12.x) auf Aktualität geprüft.
- **NFR-MAINT-03**: Ketho-Submodule-Pin wird mindestens 1× pro Monat aktualisiert (oder bei Breaking-Change in Ketho).
- **NFR-MAINT-04**: BMAD-Artefakte (PRD, Architecture, Epics, Stories) bleiben unter `_bmad-output/planning-artifacts/` und sind versioniert.

### 11.4 Security & Trust (NFR-SEC)

- **NFR-SEC-01**: MCP-Server akzeptiert keinen Netzwerk-Inbound-Traffic über stdio-Transport hinaus (lokale Tool-Use).
- **NFR-SEC-02**: Wiki-Inhalte werden mit Attribution gerendert (CC-BY-SA-typisch). Lizenz-Policy in `LICENSE-CONTENT.md`.
- **NFR-SEC-03**: Keine Geheimnisse im Repo. CI verwendet GitHub-Actions-Secrets.

### 11.5 Compatibility (NFR-COMPAT)

- **NFR-COMPAT-01**: TOC `## Interface:` muss mit live Midnight-Client-Major (aktuell 120005) Schritt halten.
- **NFR-COMPAT-02**: Nur LuaJIT-5.1-Idiome im Addon-Code (kein `//`, kein nativer Bit-Operator, kein `<const>`, keine 5.2+-`goto`-Idiome).
- **NFR-COMPAT-03**: MCP-Server kompatibel mit Continue.dev und Cursor in den jeweils aktuellen Stable-Versionen.
- **NFR-COMPAT-04**: `llms.txt` folgt Anthropic/Vercel/Stripe-De-facto-Standard (Format-Drift toleriert: AGENTS.md als Sekundär-Discovery).

### 11.6 Observability (NFR-OBS)

- **NFR-OBS-01**: Bestehender EventBus-Error-Ring-Buffer (`addon.errors`, max 50, sichtbar via `/blizz errors`) bleibt.
- **NFR-OBS-02**: `BlizzActionDiag`-Frame für `ADDON_ACTION_BLOCKED`/`ADDON_ACTION_FORBIDDEN` bleibt aktiv (Midnight-12.0-Debugging).
- **NFR-OBS-03**: MCP-Server log-strukturiert (JSON-Lines), Loglevel via env-Var.

## 12. Risiken & Annahmen

Aus Brief v2 übernommen, hier mit Bezug auf konkrete PRD-Sektionen:

| Risiko | Wahrscheinlichkeit | Impact | Mitigation | Bezugs-FR/NFR |
|---|---|---|---|---|
| Solo-Dev-Burnout | hoch | hoch | Keine harten Deadlines, DoD statt Sprint, Tank-UI als Notbremse | NFR-REL-01 |
| Ketho-Submodule-Drift | mittel | mittel | Submodule-Pin + CI-drift-detection | FR-KETHO-01, FR-KETHO-04 |
| Midnight 12.x Folge-Patches brechen Recipes | hoch | mittel | Migration-Recipes als Asset; Headless-Tests fangen Drift | NFR-COMPAT-01, FR-COOK-03 |
| `llms.txt`-Standard kippt | mittel | mittel | `llms-full.txt` + MCP + AGENTS.md als Backup-Distributionswege | FR-DISC-03 |
| Ketho lehnt Upstream-PRs ab | niedrig | niedrig | Forken oder lokal patchen | FR-KETHO-05 |
| Konkurrenz reagiert (Wiki kommt mit `llms.txt`) | niedrig–mittel | mittel | Reference-Impl + zweite Mini-Impl bleiben einzigartiger Beweis | FR-REF-02 |
| LLM-Tooling-Shift (MCP wird ersetzt) | mittel | mittel | Cookbook + llms.txt format-agnostisch, MCP nur Kanal | FR-MCP-01..06 |
| Wiki-Attribution-Lücke | mittel | niedrig | Attribution-Policy vor erstem Wiki-Parse | NFR-SEC-02 |

**Annahmen die kippen können:**
- Vibecoder-Workflow bleibt für 2 Jahre relevant
- Midnight 12.0 bleibt grob stabil (keine zweite Cataclysm-Schwere-Reduktion)
- Kenearos' M+-Engagement bleibt hoch genug für Daily-Driver

## 13. Polish & Offene Fragen

**Auto-gedraftet, bedürfen menschlicher Bestätigung:**

1. **MCP-Server-Sprache:** Node oder Python? → Architecture-Stage entscheidet (Trade-off: Continue.dev-Ökosystem-Affinität vs. Lua-API-Reichweite)
2. **Build-Skript-Sprache:** Bash/Lua/Node/Python? → Architecture-Stage entscheidet
3. **CI-Provider:** GitHub Actions als Default — bestätigt?
4. **From-scratch-Beispiel:** Default Healer-Cooldown-Tracker. Alternativen wären DPS-Tracker oder Solo-Boss-Mod. Endgültige Wahl in Story-Aufschlüsselung.
5. **Cookbook-Sprache:** Englisch (Reach) — bestätigt im Brief v2.
6. **Liste der Awesome-Repos für initialen Distribution-Push** — in Architecture-Stage konkretisieren.

## 14. Offene Punkte für die nächsten BMAD-Stages

- **Architecture-Doc** mit konkreten Entscheidungen zu: MCP-Sprache, Build-Sprache, CI-Provider, Test-Pyramide, Deployment-Pfad für MCP-Server, Submodule-Update-Flow
- **Epics & Stories**:
  - Epic A: Wissensbank + Discovery (Cookbook-Recipes, llms.txt, AGENTS.md, adopters.md)
  - Epic B: Ketho-Pipeline + MCP (Submodule, Build-Skript, MCP-Server, Continue/Cursor-Snippets, Registry-Manifest)
  - Epic C: Reference-Impls (Tank-UI-Polish, from-scratch-Beispiel mit Transcript)
  - Epic D: Passive Distribution (Awesome-PRs, Wago-Listing, Skills-Marketplace, auto-adopters)
- **Validation-Pass:** `bmad-validate-prd` über dieses Dokument
- **Readiness-Check:** `bmad-check-implementation-readiness` vor erstem Sprint
