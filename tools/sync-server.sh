#!/usr/bin/env bash
# Zet de mods van de AMP-server gelijk aan deze repo (zonder de client-only mods).
# Draai op de AMP-server als gebruiker "amp", met de Minecraft-server GESTOPT:
#   curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/tools/sync-server.sh | bash
# Weggehaalde/oude jars gaan naar mods-backup/<datum>/ in de instance.
set -euo pipefail

REPO="weggos2000/modded_server_repo"
BRANCH="main"
INSTANCE="${1:-$HOME/.ampdata/instances/HomesteadSchool01/Minecraft}"
MODS="$INSTANCE/mods"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "==> Repo downloaden..."
curl -fsSL -o "$WORK/repo.zip" "https://codeload.github.com/$REPO/zip/refs/heads/$BRANCH"
unzip -q "$WORK/repo.zip" -d "$WORK/x"
ROOT="$(find "$WORK/x" -mindepth 1 -maxdepth 1 -type d | head -1)"
SRC="$ROOT/mods"
tr -d '\r' < "$ROOT/client-only.txt" | grep -v '^\s*$' > "$WORK/client-only"

is_client_only() { grep -qxF "$1" "$WORK/client-only"; }

BACKUP="$INSTANCE/mods-backup/$(date +%Y%m%d-%H%M%S)"
added=0; updated=0; removed=0; same=0
for f in "$MODS"/*.jar; do
  [ -e "$f" ] || continue
  n="$(basename "$f")"
  if [ ! -e "$SRC/$n" ] || is_client_only "$n"; then mkdir -p "$BACKUP"; mv "$f" "$BACKUP/"; removed=$((removed+1)); fi
done
for f in "$SRC"/*.jar; do
  n="$(basename "$f")"
  is_client_only "$n" && continue
  if [ -e "$MODS/$n" ]; then
    if cmp -s "$f" "$MODS/$n"; then same=$((same+1)); continue; fi
    mkdir -p "$BACKUP"; mv "$MODS/$n" "$BACKUP/"; updated=$((updated+1))
  else
    added=$((added+1))
  fi
  cp "$f" "$MODS/$n"
done
echo "Server-mods klaar: nieuw $added, bijgewerkt $updated, ongewijzigd $same, weggehaald $removed"
[ $((removed+updated)) -gt 0 ] && echo "Backup: $BACKUP"
echo "Start de server nu opnieuw in AMP."
