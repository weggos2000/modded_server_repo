#!/usr/bin/env bash
# Wissel welke Homestead-server "live" is, zonder iets aan de tunnels te veranderen.
# De live server krijgt de poorten waar playit en Tailscale Funnel al naar wijzen
# (Minecraft 25565, voice chat 24455, BlueMap 8100); de andere krijgt de testpoorten
# (25566, 24456, 8101) en kan dan gewoon lokaal blijven draaien.
# Draai op de AMP-server als gebruiker "amp":
#   bash homestead-switch.sh 2          Homestead 2 live, oude server op de testpoorten
#   bash homestead-switch.sh 1          terug naar de oude server
#   bash homestead-switch.sh status     toon welke server welke poorten heeft
#   --dry-run                           alleen tonen wat er zou veranderen
# Beide instances worden gestopt; daarna start de live instance (AMP). De Minecraft-server
# zelf start AMP niet vanzelf: druk daarna op Start in het panel.
set -euo pipefail

INST1="HomesteadSchool01"
INST2="Homestead201"
BASE="$HOME/.ampdata/instances"

LIVE_MC=25565;  LIVE_VOICE=24455;  LIVE_MAP=8100
TEST_MC=25566;  TEST_VOICE=24456;  TEST_MAP=8101
# playit voice-tunnel (traded-unsocial.tun.ply.gg:10249 -> 127.0.0.1:24455)
LIVE_VOICE_HOST="traded-unsocial.tun.ply.gg:10249"

DRY=0
ARGS=()
for a in "$@"; do
  if [ "$a" = "--dry-run" ]; then DRY=1; else ARGS+=("$a"); fi
done
WHICH="${ARGS[0]:-}"

get() { grep -E "^\s*$2\s*[=:]" "$1" 2>/dev/null | head -1 | sed -E "s/^\s*$2\s*[=:]\s*//; s/\"//g"; }

show() {
  local i="$1" d="$BASE/$1"
  printf '%-18s minecraft %-6s voice %-6s bluemap %-5s voice_host %s\n' "$i" \
    "$(get "$d/MinecraftModule.kvp" 'Minecraft\.PortNumber')" \
    "$(get "$d/Minecraft/config/voicechat/voicechat-server.properties" port)" \
    "$(get "$d/Minecraft/config/bluemap/webserver.conf" port)" \
    "$(get "$d/Minecraft/config/voicechat/voicechat-server.properties" voice_host)"
}

# set_ports <instance> <mc> <voice> <bluemap> <voice_host>
set_ports() {
  local d="$BASE/$1" mc="$2" voice="$3" map="$4" vhost="$5"
  echo "==> $1: minecraft $mc, voice $voice, bluemap $map, voice_host '${vhost}'"
  [ "$DRY" = 1 ] && return
  sed -i -E "s|^Minecraft\.PortNumber=.*|Minecraft.PortNumber=$mc|" "$d/MinecraftModule.kvp"
  sed -i -E "s|^server-port=.*|server-port=$mc|" "$d/Minecraft/server.properties"
  sed -i -E -e "s|^port=.*|port=$voice|" -e "s|^voice_host=.*|voice_host=$vhost|" \
    "$d/Minecraft/config/voicechat/voicechat-server.properties"
  sed -i -E "s|^(\s*)port:.*|\1port: $map|" "$d/Minecraft/config/bluemap/webserver.conf"
}

case "$WHICH" in
  status) show "$INST1"; show "$INST2"; exit 0 ;;
  1) LIVE="$INST1"; OTHER="$INST2" ;;
  2) LIVE="$INST2"; OTHER="$INST1" ;;
  *) echo "Gebruik: bash $0 1|2|status [--dry-run]"; exit 1 ;;
esac

echo "Nu:"; show "$INST1"; show "$INST2"; echo

if [ "$DRY" = 0 ]; then
  echo "==> Beide instances stoppen (de wereld wordt eerst opgeslagen)..."
  ampinstmgr --StopInstance "$INST1" || true
  ampinstmgr --StopInstance "$INST2" || true
  for i in "$INST1" "$INST2"; do
    cp "$BASE/$i/MinecraftModule.kvp" "$BASE/$i/MinecraftModule.kvp.bak-switch"
  done
fi

set_ports "$OTHER" "$TEST_MC" "$TEST_VOICE" "$TEST_MAP" ""
set_ports "$LIVE" "$LIVE_MC" "$LIVE_VOICE" "$LIVE_MAP" "$LIVE_VOICE_HOST"

if [ "$DRY" = 1 ]; then echo; echo "(dry-run: niets veranderd)"; exit 0; fi

echo; echo "Daarna:"; show "$INST1"; show "$INST2"; echo
echo "==> $LIVE starten..."
ampinstmgr --StartInstance "$LIVE"
echo
echo "Klaar. Druk in het AMP-panel op Start bij $LIVE."
echo "Wil je $OTHER ook laten draaien (op de testpoorten)? Start die dan ook in het panel."
