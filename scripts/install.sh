#!/usr/bin/env bash
# scripts/install.sh
# Verlinkt das Blizz-Projekt in den WoW-AddOns-Ordner.
# Symlink → Code-Änderungen landen direkt nach /reload im Spiel.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Standard-Pfade pro Distribution / Launcher
CANDIDATES=(
	"/home/deck/Games/battlenet/World of Warcraft/_retail_/Interface/AddOns"
	"$HOME/Games/battlenet/World of Warcraft/_retail_/Interface/AddOns"
	"$HOME/.local/share/lutris/runners/wine/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"
)

# CLI-Override: scripts/install.sh /custom/path/Interface/AddOns
if [[ "${1:-}" != "" ]]; then
	CANDIDATES=("$1")
fi

ADDONS=""
for c in "${CANDIDATES[@]}"; do
	if [[ -d "$c" ]]; then
		ADDONS="$c"
		break
	fi
done

if [[ -z "$ADDONS" ]]; then
	echo "Konnte kein WoW-AddOns-Verzeichnis finden."
	echo "Suche manuell:"
	echo "  find \$HOME -name 'AddOns' -type d -path '*World of Warcraft*' 2>/dev/null"
	echo "Dann: $0 /pfad/zum/Interface/AddOns"
	exit 1
fi

TARGET="$ADDONS/Blizz"

if [[ -L "$TARGET" ]]; then
	existing="$(readlink "$TARGET")"
	if [[ "$existing" == "$PROJECT_ROOT" ]]; then
		echo "✓ Symlink existiert bereits und zeigt korrekt auf $PROJECT_ROOT"
	else
		echo "Symlink existiert, zeigt aber auf $existing — überschreibe."
		ln -sfn "$PROJECT_ROOT" "$TARGET"
	fi
elif [[ -e "$TARGET" ]]; then
	echo "FEHLER: $TARGET existiert und ist KEIN Symlink. Manuell prüfen/sichern."
	exit 2
else
	ln -s "$PROJECT_ROOT" "$TARGET"
	echo "✓ Symlink angelegt: $TARGET → $PROJECT_ROOT"
fi

# TOC-Sanity: alle Lua-Files in der TOC vorhanden?
missing=0
while IFS= read -r f; do
	if [[ ! -f "$TARGET/$f" ]]; then
		echo "FEHLT: $f"
		missing=$((missing + 1))
	fi
done < <(awk '/\.lua$/ {print $1}' "$TARGET/Blizz.toc")

if [[ $missing -gt 0 ]]; then
	echo "TOC verweist auf $missing fehlende Files — Build unvollständig."
	exit 3
fi

echo "✓ Alle TOC-Files vorhanden"
echo ""
echo "Im Spiel:"
echo "  /reload"
echo "  /blizz status"
echo ""
echo "Bei Lua-Errors:"
echo "  /console scriptErrors 1"
