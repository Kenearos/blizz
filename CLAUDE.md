# Blizz

WoW UI Addon Experiment. Lua 5.1 (WoW Client Runtime, kein Standard-Lua 5.1).

## Toolchain

- Format: `stylua .` — Tabs, Breite 4, bevorzugt doppelte Anführungszeichen, 100 Spalten (siehe `stylua.toml`)
- Lint/Typecheck: lua-language-server via `.luarc.json` (WoW API Annotations unter `/home/deck/.local/share/wow-api/Annotations`)
- Test: im Spiel `/reload` nach Änderungen — kein Headless-Test-Runner

## Addon-Aufbau

- `Blizz.toc` — Manifest. **Jede neue `.lua`-Datei muss hier in Ladereihenfolge eingetragen werden**, sonst lädt WoW sie nicht.
- `src/` — Lua-Quellen (aktuell leer; Addon-Gerüst noch nicht angelegt).
- SavedVariables: `BlizzDB` (Per-Account-Persistenz, geschrieben bei Logout/Reload).
- Slash-Command: `SLASH_BLIZZ1` (als LSP-Global deklariert; noch nicht verdrahtet).

## Stolperfallen

- Interface-Version `120005` in der TOC muss zum Ziel-WoW-Client passen; bei Patch-Tagen hochziehen, sonst lädt das Addon nicht (oder zeigt "Out of Date").
- WoW-Lua ist 5.1 mit Blizzard-spezifischen Globals — keine 5.3+ Features (kein `//`, keine `goto`-continue-Idiome, kein Integer-Division-Operator). Bitwise-Ops liegen unter `bit.*`.
- `LibStub` ist als Global in `.luarc.json` deklariert — Ace3/LibStub-Libs unter z.B. `src/libs/` einbetten und vor ihren Consumern in die TOC eintragen.
- Neue Globals (z.B. weitere `SLASH_*` Slashes oder Addon-weite Tables) in `.luarc.json` unter `diagnostics.globals` ergänzen, sonst meckert lua-language-server.

## Planungs-Workflow

GSD v1 liegt unter `.claude/`. Für nicht-triviale Arbeit `gsd:*` Skills nutzen (`plan-phase`, `execute-phase`, …).
