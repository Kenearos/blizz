# Product Brief: Blizz

> **Status:** Draft v1 · **Datum:** 2026-05-15 · **Autor:** Mary (BMAD Business Analyst) mit Kenearos
> **Stage:** Planning · **Nächstes Artefakt:** PRD (Product Requirements Document)

---

## Executive Summary

**Blizz** ist ein Open-Source-Repository (MIT), das in *einer kohärenten Codebasis* zwei Dinge liefert: (1) eine **kanonische, LLM-konsumierbare Wissens- und Discovery-Schicht für moderne WoW-Addon-Entwicklung** und (2) eine **vollwertige Protection-Warrior-M+-Tank-UI** als lebende Reference-Implementation, die die Wissensschicht validiert.

Mit dem Midnight-12.0-Patch (live seit 2026-03-02) hat Blizzard die aggressivste Addon-API-Reduktion seit Cataclysm ausgespielt. Combat-Data-APIs sind beschnitten, langjährige Globals entfernt, neue "Secret Values" werfen stille Fehler. Praktisch alle Tutorials und YouTube-Anleitungen sind älter als diese Welt; die einzige aktuelle API-Referenz ist `warcraft.wiki.gg` — kuratiert, aber HTML-Wiki, nicht LLM-ingestion-ready. Gleichzeitig hat sich Vibecoding etabliert: Solo-Devs erwarten, mit Claude/GPT/Cursor in Stunden zu liefern, was früher Wochen brauchte. Was fehlt, ist die Brücke: ein Repo, das `Ketho/vscode-wow-api`s 8.000+ Annotations + die Wiki-Migration-Pages + reale Production-Patterns zu einem **task-orientierten Cookbook mit `llms.txt`-Discovery** konsolidiert.

Blizz besetzt diese Nische, ohne mit den bestehenden Wissensquellen zu konkurrieren — es konsolidiert sie und macht sie LLM-tauglich. Validiert wird das ganze durch die Tank-UI: wenn ein Solo-Dev mit Blizz' Cookbook + LLM eine M+-würdige Tank-UI bauen kann, ist die Datenbank gut genug.

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

**Unfair advantage:**
1. **Drei Schichten auf einmal** — niemand sonst hat Cookbook + LLM-Discovery + Reference-Impl in einem Repo. Jeder Konkurrent bedient nur eine Achse.
2. **Reference-Impl ist bereits da** — Blizz' Tank-UI ist nicht zukünftig zu bauen; sie läuft, ist getestet, ist die lebende Validierung.
3. **Upstream-freundlich** — Ketho's Annotations + Wiki-Knowledge werden integriert, nicht dupliziert. Reduziert Wartung und macht uns nicht zum N+1-Wettbewerber.
4. **Sprache:** Repo + Doku auf Deutsch + Englisch (das Cookbook auf Englisch für Reach, einzelne Devs-Notes ggf. zweisprachig). BMAD-Kommunikation auf Deutsch.

## Wer das bedient

**Primary 1: Vibecoder mit LLM-Workflow**
Solo-Devs, die Claude/GPT/Cursor benutzen, um ein WoW-Addon in Stunden statt Wochen zu shippen. Sie wollen den `llms.txt`-Link in ihren System-Prompt packen und vertrauen, dass das LLM danach 12.0-korrekten Code generiert. *Erfolg für sie:* "Ich habe in einem Nachmittag einen Cooldown-Tracker gebaut, der nicht crasht."

**Primary 2: Klassische Addon-Devs auf der Suche nach modernen Patterns**
Maintainer, die ihren Dragonflight-Code auf 12.0 migrieren oder ein Neuprojekt anfangen. Sie lesen Code, keine YouTube-Tutorials. *Erfolg für sie:* "Ich habe das EventBus-Pattern + Secrets-Defense aus Blizz übernommen und meine Migration in 2 Wochen statt 2 Monaten geschafft."

**Primary 3: LLMs selbst (als Training/Context-Konsument)**
LLM-Trainings-Datasets, RAG-Systeme, MCP-Tool-Use-Konsumenten. *Erfolg für sie:* gemessen indirekt — wenn Claude/GPT mit Blizz im Context konsistent korrekten 12.0-Code generiert.

**Tertiary: Kenearos selbst**
Tank-UI muss in M+-Sessions funktionieren. Reference-Impl bleibt nutzbar; sie ist kein Demo-Artefakt das jemals "fertig" gehyped wird, sondern Daily-Driver.

## Erfolgskriterien

| Metrik | M1-Ziel (8 Wochen) | M3-Ziel (6 Monate) |
|---|---|---|
| GitHub-Stars | 25+ | 200+ |
| `llms.txt` von externer LLM-Toolchain referenziert | — | nachweisbar in Cursor/Continue-Setups |
| Anzahl Cookbook-Recipes | 8–12 (Pattern-Recipes aus Existing-Code) | 25+ inkl. Migration + End-to-End |
| MCP-Server-Installationen | — | 10+ (Manifest in MCP-Registry) |
| Fork-Adoption-Beleg | 1–2 abgeleitete Addons öffentlich | 5+ |
| Tank-UI-Stabilität | 0 unbehandelte Production-Errors / Woche | unverändert |
| Test-Coverage Recipes | jedes Recipe hat einen runnable Test-Case | unverändert |

**Was wir nicht messen:** Tutorial-Aufrufe, Discord-Server-Größe, "engagement". Der Erfolg ist binär — wird das Repo von LLMs/Tools konsumiert oder nicht?

## Scope (klare Phasen)

### M1 — v0.4 "Existing-Patterns First" (8 Wochen, MVP)
**Drin:**
- Recipes für die in Blizz schon implementierten Patterns: EventBus, Secrets-Defense, Cooldowns-Wrapper, UnitState-Wrapper, Module-Registration, Position-Persistence, Widget-State-System, headless-Testing-Setup
- `llms.txt` (Wegweiser) + `llms-full.txt` (Cookbook-Dump)
- `AGENTS.md` als Mirror/Generator von `CLAUDE.md`
- BMAD-PRD + Architecture-Doc gemerged
- Tank-UI-Bug-Polish (was anliegt — siehe Backlog)

**Draußen:**
- MCP-Server (M3)
- Migration-Cookbook (M2)
- Wiki-Pages parsen
- Andere Tank-Specs
- Konfigurations-UI

### M2 — v0.5 "Migration-Cookbook" (weitere 6 Wochen)
**Drin:**
- Recipes pro Midnight-12.0-Breaking-Change (Secret-Values, CLEU-Removal, C_Spell-Namespace, Deprecations, etc.)
- Wiki-Migration-Pages als strukturierte Daten parsen
- Diff-Beispiele "vorher / nachher" pro Migration
- Erweitertes `llms-full.txt`

**Draußen:** weiterhin MCP, End-to-End-Demo.

### M3 — v0.6 / v1.0 "MCP + End-to-End" (weitere 8 Wochen)
**Drin:**
- MCP-Server der Ketho's Annotations + Blizz' Cookbook live exposed
- End-to-End-Demo: "Cooldown-Tracker in 30 min" als Video + Repo-Walk-Through
- MCP-Registry-Listing
- v1.0-Launch-Kommunikation

**Draußen:** alles was nicht direkt LLM-Discovery, Migration oder Tank-UI ist.

### Niemals drin (explizit out-of-scope, für immer)
- Andere WoW-Specs oder -Klassen außerhalb der Tank-Reference-Impl
- Raid-Boss-Timer (BigWigs-Territorium)
- Konfigurations-UI à la Ace3 (Position-Persistenz + SavedVars reichen)
- Eigene parallele API-Datenbank (Ketho ist Source of Truth)
- PVP-Features

## Vision (2–3 Jahre)

Wenn Blizz greift, ist es 2028 das **erste Ergebnis**, wenn jemand "WoW addon LLM" googelt oder Cursor/Claude fragt "wie schreibe ich ein WoW-Addon?". Die `llms.txt`-Convention wird Standard, neue Addon-Devs zitieren das Cookbook wie heute MDN Web Docs für JS. Jedes neue WoW-Addon-Boilerplate übernimmt automatisch Blizz' EventBus + Secrets-Pattern, weil es "der Pattern" geworden ist. Die Tank-UI bleibt klein, fokussiert, deine.

Realistisch greifbarer Erfolgsfall: Blizz wird in der WoW-AddOn-Dev-Community zu dem Repo, das jeder vibe-codende Solo-Dev einmal in seinem Setup referenziert hat, und das jedes neue LLM-IDE-Tool out-of-the-box als `wow-addon`-Skill anbietet.

## Technischer Ansatz (High-Level)

- **Runtime:** LuaJIT 2.1 / Lua 5.1 (WoW Midnight 12.0), keine Runtime-Dependencies.
- **Existing Codebase:** 10 Module, EventBus, Secrets-Defense, headless Test-Harness — bleibt wie ist, wird *dokumentiert*, nicht refactored.
- **Cookbook-Format:** Markdown pro Recipe, plus generierter `llms-full.txt` Build-Step.
- **MCP-Server (M3):** Node oder Python, ingestiert Ketho's Annotations (Submodule oder Build-Pull) und Blizz' Cookbook, exposed als MCP-Tools.
- **Build:** weiterhin kein WoW-side Build. Doku-Build = einfaches Cat/Concat-Script in `scripts/`.
- **Planning-Tooling:** BMAD-Method (installiert) für PRD/Architecture/Stories.

---

## Offene Punkte für die nächsten BMAD-Stages

- PRD mit Epic A (Wissensbank) + Epic B (Tank-UI) sharden
- Architecture-Doc: wie binden wir Ketho an? Submodule vs Build-Time-Pull vs MCP-only
- Story-Aufschlüsselung für M1 (Recipes aus Existing-Patterns)
- Entscheidung Cookbook-Sprache: Deutsch, Englisch, oder beides parallel?
