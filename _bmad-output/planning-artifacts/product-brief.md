# Product Brief: Blizz

> **Status:** Draft v2 · **Datum:** 2026-05-15 · **Autor:** Mary (BMAD Business Analyst) mit Kenearos
> **Stage:** Planning · **Nächstes Artefakt:** PRD (Product Requirements Document)
> **Änderungen ggü. v1:** Risiken-Sektion ergänzt, Erfolgs-Tabelle in "Signale statt Ziele" umgegliedert, Ketho-Submodule + MCP in Phase 1 gezogen (Zeitfenster pro Phase entfernt, Scope ist fix), Marketingsprache entschärft.

---

## Executive Summary

**Blizz** ist ein Open-Source-Repository (MIT), das in einem Mono-Repo zwei Dinge liefert: (1) eine **LLM-konsumierbare Wissens- und Discovery-Schicht für WoW-Addon-Entwicklung unter Midnight 12.0** und (2) eine **Protection-Warrior-M+-Tank-UI** als lebende Reference-Implementation, die die Wissensschicht validiert.

Mit dem Midnight-12.0-Patch (live seit 2026-03-02) ist ein großer Teil der Addon-API ersetzt oder eingeschränkt worden. Combat-Data-APIs sind beschnitten, langjährige Globals entfernt, neue "Secret Values" werfen stille Fehler. Bestehende Tutorials und YouTube-Anleitungen sind älter als diese Änderungen; die aktuellste konsolidierte API-Referenz ist `warcraft.wiki.gg` — kuratiert, aber HTML-Wiki, nicht LLM-ingestion-ready. Parallel etabliert sich Vibecoding: Solo-Devs erwarten, mit Claude/GPT/Cursor in Stunden zu liefern, was früher Wochen brauchte. Es fehlt die Brücke: ein Repo, das `Ketho/vscode-wow-api`s Annotations (per git-submodule), Wiki-Migration-Pages und reale Production-Patterns zu einem **task-orientierten Cookbook mit `llms.txt`-Discovery und MCP-Tool-Exposure** konsolidiert.

Blizz konkurriert nicht mit den bestehenden Wissensquellen, sondern konsolidiert sie über einen Build-Step und macht sie LLM-tauglich. Validiert wird das Ganze durch die Tank-UI: wenn ein Solo-Dev mit Blizz' Cookbook + LLM eine M+-würdige Tank-UI bauen kann, ist die Datenbank gut genug.

## Das Problem

**Wer leidet:**
- **Solo-Devs mit LLM-Workflow ("Vibecoder"):** geben Claude/GPT die Aufgabe "bau mir einen Cooldown-Tracker für WoW Midnight" und bekommen Code zurück, der gegen entfernte APIs läuft, in Secret-Value-Errors stirbt oder veraltete Patterns benutzt. Das LLM hat schlicht keine kuratierte 12.0-Wissensquelle in seinem Context.
- **Klassische Addon-Maintainer auf Migration:** öffnen ihren Dragonflight-Code und müssen Stück für Stück herausfinden, welche API noch existiert, welche Secret Values zurückgibt, welche durch `C_Spell.*` ersetzt wurde. Cell's PR #457 und einzelne BigWigs-Commits sind die de-facto-Migration-Doku — schwer zu finden, nicht systematisch.
- **LLMs selbst:** haben in ihrem Training-Cutoff (meist 2024) noch das alte API-Modell. Beim Generieren halluzinieren sie `GetSpellCooldown` statt `C_Spell.GetSpellCooldown` und `UNIT_HEALTH_FREQUENT` statt `UNIT_HEALTH`.

**Coping-Strategien heute:**
- `warcraft.wiki.gg` durchklicken (langsam, nicht copy-paste-fertig, nicht in LLM-Context fütterbar)
- Cell / BigWigs Source-Code lesen und Patterns rekonstruieren (50.000+ Zeilen, hohe Einstiegshürde)
- Reddit/Discord fragen (alt, widersprüchlich, episodisch)
- `Ketho/vscode-wow-api` als IntelliSense in VS Code laufen lassen (gut, aber Format ist LuaCATS für Editoren, nicht narrativer Context für LLMs)

**Kosten des Status quo:** Vibecoder geben auf oder produzieren broken Addons. Maintainer migrieren halbherzig oder gar nicht (der Addon-Friedhof seit März 2026 ist groß). LLM-generierter WoW-Code ist statistisch fehleranfällig, was Vertrauen in den Workflow untergräbt.

## Die Lösung

Blizz ist ein einziges Repository mit drei sich gegenseitig verstärkenden Schichten:

1. **Konsolidierungs-Layer (Wissensbank):** ein `docs/cookbook/` mit task-orientierten Recipes (Refactoring.guru / Anthropic-Cookbook-Stil) — pro Recipe: Intent → Problem → Code → Stolperfalle → Test. Ergänzt um eine `llms.txt` + `llms-full.txt` Discovery-Schicht (Anthropic/Vercel/Stripe-Pattern), eine `AGENTS.md` Convention (agents.md, 21k★, Cursor+Claude+OpenAI-Codex-kompatibel), und einen **MCP-Server**, der `Ketho/vscode-wow-api`s Annotations live für LLM-Tool-Use exposed.
2. **Reference-Implementation (Tank-UI):** das existierende Blizz-Addon — 10 Module, EventBus, Secrets-Defense, headless LuaJIT-Test-Harness — bleibt fokussiert auf Protection Warrior in Mythic+. Es ist nicht das Produkt; es ist der Beweis, dass die Wissensbank funktioniert.
3. **Discovery & LLM-Ergonomie:** alle Recipes sind so geschrieben, dass jeder Snippet *out-of-context* funktioniert (kein Forward-Reference auf "siehe Kapitel 2"). `llms-full.txt` rendert das gesamte Cookbook in einen einzigen Ingestion-fertigen Dump. Der MCP-Server liefert API-Lookups + Recipe-Search als Tool-Calls.

**Wie es sich anfühlt für den Zielnutzer:**
- Vibecoder: "Hier ist Blizz' `llms.txt`. Bau mir einen Cooldown-Tracker." → Claude liest die Recipes, schreibt korrekten 12.0-Code, der Vibecoder shipt in 30 Minuten.
- Migration-Maintainer: `docs/cookbook/migrations/cleu-removal.md` → Diff-Beispiel, Drop-in-Replacement, Test-Case.
- LLM-Tool-User: MCP-Server `wow-api-search` aufrufen → strukturiertes JSON zurück mit aktueller Signatur, Examples, Stolperfallen.

## Was es anders macht

| Konkurrent | Stand | Lücke, die Blizz füllt |
|---|---|---|
| `Ketho/vscode-wow-api` (217★, daily updates) | LuaCATS-Annotations für VS-Code-IntelliSense | Nicht LLM-narrativ, kein Cookbook, keine `llms.txt`, kein Use-Case-Layer |
| `warcraft.wiki.gg` | Kuratierte API + Patch-Notes | HTML/Wiki, nicht ingestion-ready, kein "wie bauen", nur "was ist es" |
| `DennysOliveira/wow-addon-dev` (4★, 6 Wochen alt) | Claude-Code-Skills für Addon-Dev | Klein, jung, keine Reference-Impl, kein MCP, keine llms.txt |
| `spartanui-wow/wow-api-mcp` (8★, 3 Mon. alt) | MCP-Server über Ketho's Daten | Nur API-Exposure, kein Cookbook, keine Patterns, keine Reference-Impl |
| `JuanjoSalvador/awesome-wow` (38★) | Klassische Awesome-Liste | Letzter Push 2019. Tot. |
| Cell/BigWigs/Plater | Production-Addons mit Migration-Patterns | 50k+ Zeilen, kein "for-other-devs" Layer |

**Konkrete Vorteile:**
1. **Drei Schichten in einem Repo** — Cookbook + LLM-Discovery + Reference-Impl. Jeder andere Konkurrent bedient nur eine davon.
2. **Reference-Impl existiert bereits** — Tank-UI läuft, ist getestet, ist die lebende Validierung. Wir vermessen kein Greenfield-Risiko.
3. **Upstream-freundlich statt N+1-Wettbewerber** — Ketho's Annotations werden per git-submodule integriert. Annotation-Lücken, die wir beim Cookbook-Schreiben finden, gehen als PR zurück nach upstream (mit Commit-Footer "Discovered while building github.com/kenearos/blizz"). Reduziert Wartung *und* erzeugt passive Backlinks von einem Repo, das genau unsere Zielgruppe liest.
4. **Sprache:** Repo + Cookbook auf Englisch für Reach, BMAD-Planungsartefakte und einzelne Dev-Notes auf Deutsch.

## Wer das bedient

**Primary 1: Vibecoder mit LLM-Workflow**
Solo-Devs, die Claude/GPT/Cursor benutzen, um ein WoW-Addon in Stunden statt Wochen zu shippen. Sie wollen den `llms.txt`-Link in ihren System-Prompt packen und vertrauen, dass das LLM danach 12.0-korrekten Code generiert. *Erfolg für sie:* "Ich habe in einem Nachmittag einen Cooldown-Tracker gebaut, der nicht crasht."

**Primary 2: Klassische Addon-Devs auf der Suche nach modernen Patterns**
Maintainer, die ihren Dragonflight-Code auf 12.0 migrieren oder ein Neuprojekt anfangen. Sie lesen Code, keine YouTube-Tutorials. *Erfolg für sie:* "Ich habe das EventBus-Pattern + Secrets-Defense aus Blizz übernommen und meine Migration in 2 Wochen statt 2 Monaten geschafft."

**Primary 3: LLMs selbst (als Training/Context-Konsument)**
LLM-Trainings-Datasets, RAG-Systeme, MCP-Tool-Use-Konsumenten. *Erfolg für sie:* gemessen indirekt — wenn Claude/GPT mit Blizz im Context konsistent korrekten 12.0-Code generiert.

**Tertiary: Kenearos selbst**
Tank-UI muss in M+-Sessions funktionieren. Reference-Impl bleibt nutzbar; sie ist kein Demo-Artefakt das jemals "fertig" gehyped wird, sondern Daily-Driver.

## Erfolgssignale

Stars und Installationszahlen werden tracked, aber nicht als Ziele gesetzt — sie sind Vanity-Output, nicht Steuerungsgröße. Was wirklich zählt sind **Konsum-Signale**: greift das Repo als LLM-Wissensquelle?

| Signal | Phase-1 (Definition-of-Done v1.0) | Längerfristig (offen) |
|---|---|---|
| **Cookbook-Vollständigkeit** | Recipes für alle in Blizz implementierten Patterns (EventBus, Secrets, Cooldowns, UnitState, Module-Reg, Position-Persistence, Widget-State, Headless-Test) + Migration-Recipes für Midnight-12.0-Breaking-Changes | inkrementell erweitert |
| **Test-Coverage Recipes** | jedes Recipe hat einen runnable Test-Case | unverändert |
| **Tank-UI-Stabilität** | 0 unbehandelte Production-Errors / Woche im Eigeneinsatz | unverändert |
| **Ketho-Upstream-Beweis** | ≥ 3 von uns initiierte PRs in `Ketho/vscode-wow-api` gemerged | wachsend |
| **llms.txt-Adoption-Beleg** | öffentliche `adopters.md`, automatisch befüllt via GitHub-Code-Search nach `blizz/llms.txt`-Referenzen | nachweisbare Adoption durch ≥ 5 fremde Repos |
| **MCP-Registry-Listing** | Server live, Continue/Cursor-Config-Snippet im README, GIF-Demo | optionale Anbindung an Claude-Skills-Marketplace |
| **Zweite Reference-Impl** | `examples/from-scratch/` mit dokumentiertem Claude-Session-Transcript, in dem ein Dritter mit nur dem Cookbook ein Mini-Addon baut | weitere Beispiele |

**Was wir nicht messen:** Tutorial-Aufrufe, Discord-Größe, "engagement", absolute Star-Zahlen. Konsum-Signale schlagen Popularitäts-Signale.

## Scope

Da Kenearos solo arbeitet, gibt es **keine harten Phasen-Deadlines** — der Scope ist fix, die Zeit ist offen. Der Brief unterscheidet zwischen dem **Definition-of-Done für v1.0** (Phase 1, alles muss drin sein bevor wir "v1.0" sagen) und **passiver Distribution**, die parallel zur Entwicklung läuft und keinen eigenen "Launch-Moment" braucht.

### Phase 1 — Definition-of-Done für v1.0 (Scope-fix, Zeit-offen)

**Wissensbank:**
- Recipes für alle in Blizz bereits implementierten Patterns: EventBus, Secrets-Defense, Cooldowns-Wrapper, UnitState-Wrapper, Module-Registration, Position-Persistence, Widget-State-System, headless-Testing-Setup
- Migration-Recipes pro Midnight-12.0-Breaking-Change (Secret-Values, CLEU-Removal, C_Spell-Namespace, Deprecations) mit Vorher/Nachher-Diffs
- Jedes Recipe hat einen runnable Test-Case

**Discovery-Schicht:**
- `llms.txt` (Wegweiser) + `llms-full.txt` (Cookbook-Dump als Single-File-Ingestion)
- `AGENTS.md` als Mirror/Generator von `CLAUDE.md`
- BMAD-PRD + Architecture-Doc gemerged

**Ketho-Integration (Pipeline):**
- `Ketho/vscode-wow-api` als git-submodule unter `vendor/ketho/`
- Build-Skript in `mcp-server/scripts/build-cookbook.ts` (Sprache durch Architecture festgelegt: TypeScript/Node im selben Workspace wie der MCP-Server) das aus Ketho-Annotations + Wiki-Migration-Pages + Blizz-Markdowns die Datenquellen für `llms-full.txt` und MCP-Server rendert
- CI-Job, der das Build wöchentlich gegen aktuellen Ketho-Stand fährt (drift-detection)

**MCP-Server (vorgezogen, war v1-M3):**
- Node oder Python, ingestiert Ketho-Annotations + Cookbook
- Tool-Endpoints: `wow-api-search`, `recipe-search`, `migration-lookup`
- Continue.dev und Cursor Config-Snippets im README, 1-Click-Install-Spec, GIF-Demo
- MCP-Registry-Manifest

**Reference-Implementations:**
- Tank-UI (existierend) bleibt Daily-Driver, 0 unbehandelte Production-Errors / Woche
- **Zweite Mini-Reference-Impl** in `examples/from-scratch/`: ein 50-Zeilen-Mini-Addon (z.B. Healer-Cooldown-Tracker), entstanden in einer dokumentierten Claude-Session, Transcript + resultierendes Repo eingecheckt. Das ist der eigentliche Beweis des Cookbook-Validation-Loops.

### Passive Distribution (parallel zur Phase 1, keine separate Phase)

Hebel, die mit Stunden statt Wochen greifen — laufen mit jedem neuen Recipe automatisch:

- **Ketho-Upstream-PRs**: jede Annotation-Lücke, die beim Recipe-Schreiben auffällt, wird als PR an `Ketho/vscode-wow-api` eingereicht. Commit-Footer referenziert Blizz.
- **Awesome-Lists-Einträge**: PRs in `awesome-llms-txt`, `awesome-mcp-servers`, `awesome-claude-skills`, ggf. Fork/Revival von `awesome-wow`.
- **Wago / CurseForge**: Tank-UI dort listen mit Cookbook-Link in der Beschreibung (nicht für Downloads, für Discovery-Funnel).
- **Claude-Skills-Marketplace**: nach MCP-Live-Schaltung als `blizz-wow-addon`-Skill publizieren.
- **`adopters.md`** auto-generiert per GitHub-Code-Search nach `blizz/llms.txt`-Referenzen.

### Post-v1.0 (offen, nicht committed)

- WoW-agnostische `docs/cookbook/patterns/`-Schicht für Cross-Game-Reach (ESO, FFXIV-Dalamud, generisches Game-UI-in-Lua) — nur wenn nach v1.0 Energie übrig ist
- Erweiterte Migration-Recipes für Folge-Patches (12.1+)
- Weitere from-scratch-Beispiele

### Bewusst out-of-scope (Stand jetzt — revidierbar nach v1.0)

- Andere WoW-Specs oder -Klassen außerhalb der Tank-Reference-Impl
- Raid-Boss-Timer (BigWigs-Territorium)
- Konfigurations-UI à la Ace3 (Position-Persistenz + SavedVars reichen)
- Eigene parallele API-Datenbank (Ketho ist Source of Truth)
- PVP-Features

## Vision (2–3 Jahre)

Persönliche Mission zuerst: die Tank-UI bleibt klein, fokussiert, Kenearos' Daily-Driver in M+. Sie wird nicht "fertig", sie wird genutzt.

Aspirativer Außeneffekt — kein Versprechen, eine Hypothese: wenn Blizz greift, wird es in der WoW-Solo-Dev-Community zu dem Repo, das man einmal in seinem LLM-Setup referenziert hat. Cursor/Claude antworten auf "schreib mir ein WoW-Addon" mit Code, der Blizz' Patterns benutzt — nicht weil das Pattern "berühmt" wäre, sondern weil es im Trainings-Korpus und in MCP-Servern als kanonischer 12.0-Code auftaucht. Die `llms.txt`-Convention bleibt für die Lebensdauer dieser Hypothese ein nützliches Standard-Pattern.

Falls die Hypothese kippt (siehe Risiken), bleibt der Eigennutzen: ein gepflegtes, dokumentiertes, dauerhaft funktionierendes Tank-UI plus eine private LLM-Wissensbank, die Kenearos' eigenen Workflow beschleunigt.

## Risiken & Annahmen

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|---|---|---|---|
| **Solo-Dev-Burnout / Scope drückt Tank-UI als Daily-Driver weg** | hoch | hoch | Keine harten Deadlines, "Definition-of-Done" statt Sprint. Tank-UI bleibt explizit Phase-1-Pflicht: kaputter Daily-Driver = Notbremse. |
| **Ketho-Submodule-Drift / Breakage** | mittel | mittel | Build-Step pinnt Submodule-Commit. CI-Job mit drift-detection. Bei Breakage: Cookbook bleibt benutzbar mit altem Stand bis Pin-Update. |
| **Midnight 12.x Folge-Patches brechen Recipes** | hoch | mittel | Migration-Recipes sind selbst ein Asset (jeder Breaking-Change wird zu neuem Recipe). Headless-Tests fangen API-Signaturen-Drift früh. |
| **`llms.txt`-Standard setzt sich nicht durch** | mittel | mittel | `llms-full.txt` und MCP-Server sind eigenständige Distributionswege. AGENTS.md als Mirror reduziert Abhängigkeit von einer Convention. |
| **Ketho lehnt Upstream-PRs ab / Konflikt** | niedrig | niedrig | Lizenzkompatibel forken oder lokal patchen. Backlink-Effekt entfällt, Wartungsaufwand steigt minimal. |
| **Konkurrenz reagiert (Ketho rendert eigenes Cookbook, Wiki kommt mit `llms.txt`)** | niedrig–mittel | mittel | Reference-Impl + zweite Mini-Impl bleiben einzigartiger Beweis-Mechanismus. Wenn upstream übernimmt, ist die Mission erfüllt. |
| **LLM-Tooling-Landschaft verschiebt sich (MCP wird ersetzt, Cursor pivotiert)** | mittel | mittel | Cookbook + llms.txt + AGENTS.md bleiben Format-agnostisch. MCP ist Distributionskanal, nicht Hauptasset. |
| **Lizenz-/Attribution-Stolpersteine bei Wiki-Migration-Pages** | mittel | niedrig | Vor erstem Wiki-Parse: Attribution-Policy lesen (CC-BY-SA-typisch). Vorher-Nachher-Diffs eher als Eigentext schreiben. |

**Annahmen die kippen können:**
- Vibecoder-Workflow bleibt für die nächsten 2 Jahre relevant (vs. AI-Agents übernehmen komplett, dann braucht's andere Schnittstellen)
- Midnight 12.0 bleibt grob stabil (keine zweite Cataclysm-Schwere-Reduktion in 12 Monaten)
- Kenearos' M+-Engagement bleibt hoch genug, dass die Tank-UI Daily-Driver-Status hält

## Technischer Ansatz (High-Level)

- **Runtime:** LuaJIT 2.1 / Lua 5.1 (WoW Midnight 12.0), keine Runtime-Dependencies im Addon selbst.
- **Existing Codebase:** 10 Module, EventBus, Secrets-Defense, headless Test-Harness — bleibt wie ist, wird *dokumentiert*, nicht refactored.
- **Cookbook-Format:** Markdown pro Recipe in `docs/cookbook/`. Build-Step rendert daraus + Ketho-Annotations + Wiki-Migration-Pages → `llms-full.txt` (Single-File-Ingestion) und MCP-Server-Datenquelle.
- **Ketho-Anbindung:** `Ketho/vscode-wow-api` als git-submodule unter `vendor/ketho/`. Pin-Commit im Repo, CI-Job für drift-detection. Lücken werden upstream als PR eingereicht, nicht lokal gepatcht (wenn möglich).
- **MCP-Server (Phase 1):** Node oder Python — Entscheidung in der Architecture-Stage. Ingestiert Cookbook + Ketho. Exposed `wow-api-search`, `recipe-search`, `migration-lookup` als Tools. Continue.dev + Cursor Config-Snippets als README-Beilagen.
- **Build:** kein WoW-side Build. Doku-/MCP-Build = `scripts/build-cookbook.*` (Sprache offen, Architecture-Entscheidung).
- **Planning-Tooling:** BMAD-Method (installiert) für PRD/Architecture/Stories.

---

## Offene Punkte für die nächsten BMAD-Stages

- PRD mit Epic A (Wissensbank + Discovery), Epic B (Ketho-Pipeline + MCP), Epic C (Tank-UI + zweite Reference-Impl) sharden
- Architecture-Entscheidungen: MCP-Server-Sprache (Node vs Python), Build-Skript-Sprache, CI-Provider, Test-Pyramide für die neue Pipeline
- Story-Aufschlüsselung für Phase 1 (Recipes aus Existing-Patterns + Migration-Recipes + Ketho-Integration + MCP-Endpoints)
- Cookbook-Sprache: bestätigt Englisch (Reach), BMAD-Artefakte Deutsch
- Konkrete Wahl des zweiten from-scratch-Beispiels (Healer-Cooldown? DPS-Tracker? Solo-Boss-Mod?)
- Liste der Awesome-Repos für initialen Distribution-Push
