#!/usr/bin/env bash
# Homestead School - mods synchroniseren (macOS / Linux)
#
# Zet de mods-map van je Homestead-instance exact gelijk aan mods/ in deze repo.
# Mods die niet meer in de repo staan gaan naar mods-backup/<datum>/ (niets wordt gewist).
#
# Gebruik:
#   curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/install.sh | bash -s -- "/pad/naar/instance"
set -euo pipefail

REPO="weggos2000/modded_server_repo"
BRANCH="main"

INSTANCE="${1:-}"
if [ -z "$INSTANCE" ]; then
  for root in "$HOME/Documents/curseforge/minecraft/Instances" "$HOME/curseforge/minecraft/Instances" \
              "$HOME/Library/Application Support/PrismLauncher/instances" "$HOME/.local/share/PrismLauncher/instances"; do
    [ -d "$root" ] || continue
    for d in "$root"/*Homestead*; do
      [ -d "$d" ] || continue
      if [ -d "$d/minecraft" ]; then d="$d/minecraft"; elif [ -d "$d/.minecraft" ]; then d="$d/.minecraft"; fi
      INSTANCE="$d"; break 2
    done
  done
fi
if [ -z "$INSTANCE" ]; then
  echo "Geen Homestead-instance gevonden. Geef het pad mee:  ... | bash -s -- \"/pad/naar/instance\"" >&2
  exit 1
fi
[ "$(basename "$INSTANCE")" = "mods" ] && INSTANCE="$(dirname "$INSTANCE")"
MODS="$INSTANCE/mods"
mkdir -p "$MODS"
echo "==> Instance: $INSTANCE"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "==> Mods downloaden van github.com/$REPO (±570 MB)..."
curl -fL --progress-bar -o "$WORK/repo.zip" "https://codeload.github.com/$REPO/zip/refs/heads/$BRANCH"
unzip -q "$WORK/repo.zip" -d "$WORK/x"
SRC="$(find "$WORK/x" -mindepth 1 -maxdepth 1 -type d | head -1)/mods"

BACKUP="$INSTANCE/mods-backup/$(date +%Y%m%d-%H%M%S)"
added=0; updated=0; removed=0; same=0
for f in "$MODS"/*.jar; do
  [ -e "$f" ] || continue
  n="$(basename "$f")"
  if [ ! -e "$SRC/$n" ]; then mkdir -p "$BACKUP"; mv "$f" "$BACKUP/"; removed=$((removed+1)); fi
done
for f in "$SRC"/*.jar; do
  n="$(basename "$f")"
  if [ -e "$MODS/$n" ]; then
    if cmp -s "$f" "$MODS/$n"; then same=$((same+1)); continue; fi
    mkdir -p "$BACKUP"; mv "$MODS/$n" "$BACKUP/"; updated=$((updated+1))
  else
    added=$((added+1))
  fi
  cp "$f" "$MODS/$n"
done
SHARED="$(dirname "$SRC")/shared"
if [ -d "$SHARED" ]; then cp -R "$SHARED/." "$INSTANCE/"; echo "Extra bestanden (KubeJS) bijgewerkt."; fi
echo "Klaar! nieuw: $added  bijgewerkt: $updated  ongewijzigd: $same  weggehaald: $removed"
[ $((removed+updated)) -gt 0 ] && echo "Oude mods staan in: $BACKUP"
exit 0
