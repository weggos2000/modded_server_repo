#!/usr/bin/env bash
# Homestead School - installer / updater voor Linux en macOS
#
# Installeert Fabric, een profiel/instance "Homestead School" (gewone launcher of Prism),
# de Homestead-pack, de mods uit deze repo en de server in je serverlijst.
# Het echte werk zit in install.py (Python 3); dit script zoekt Python en start het.
#
# Gebruik:
#   curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/install.sh | bash
# Performance-modus wisselen (zonder opnieuw te downloaden):
#   curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/install.sh | bash -s -- --set-mode performance
#   curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/install.sh | bash -s -- --set-mode normal
set -euo pipefail

REPO="weggos2000/modded_server_repo"
BRANCH="main"

PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 7) else 1)' 2>/dev/null; then
    PY="$c"; break
  fi
done
if [ -z "$PY" ]; then
  echo "Python 3 is nodig maar niet gevonden." >&2
  if [ "$(uname)" = "Darwin" ]; then
    echo "Installeer het met:  xcode-select --install   (of via https://www.python.org/downloads/)" >&2
  else
    echo "Installeer het met je pakketbeheerder, bv.:  sudo apt install python3   /   sudo dnf install python3" >&2
  fi
  exit 1
fi

# install.py naast dit script (uitgepakte installer of repo-map), anders van GitHub halen
HERE=""
case "${BASH_SOURCE[0]:-}" in
  */*) HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" ;;
  ?*)  HERE="$(pwd)" ;;
esac
TMP=""
if [ -n "$HERE" ] && [ -f "$HERE/install.py" ]; then
  SCRIPT="$HERE/install.py"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  SCRIPT="$TMP/install.py"
  curl -fsSL -o "$SCRIPT" "https://raw.githubusercontent.com/$REPO/$BRANCH/install.py"
fi

# Bij "curl | bash" is stdin de pipe: vragen moeten via de terminal zelf
if [ ! -t 0 ] && { : </dev/tty; } 2>/dev/null; then
  "$PY" "$SCRIPT" "$@" </dev/tty
else
  "$PY" "$SCRIPT" "$@"
fi
