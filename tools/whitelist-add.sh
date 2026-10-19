#!/usr/bin/env bash
# Spelers aan de whitelist toevoegen met hun OFFLINE-UUID (de server draait in offline-mode).
# Gebruik NIET "/whitelist add" in het spel: dat zoekt de naam op bij Mojang en zet dan het
# premium-UUID op de lijst, waardoor de speler toch geweigerd wordt.
#
# Draai op de AMP-server als "amp":   bash whitelist-add.sh Naam1 Naam2 ...
# Zonder namen: controleert en herstelt alleen de bestaande lijst.
# Typ daarna in de AMP-console:        whitelist reload
set -euo pipefail
WL="${WHITELIST:-$HOME/.ampdata/instances/HomesteadSchool01/Minecraft/whitelist.json}"
cp "$WL" "$WL.bak-$(date +%Y%m%d-%H%M%S)"
python3 -I - "$WL" "$@" <<'EOF'
import hashlib, json, sys, uuid
path, names = sys.argv[1], sys.argv[2:]
def offline(n):
    h = bytearray(hashlib.md5(("OfflinePlayer:" + n).encode()).digest())
    h[6] = (h[6] & 0x0f) | 0x30
    h[8] = (h[8] & 0x3f) | 0x80
    return str(uuid.UUID(bytes=bytes(h)))
wl = json.load(open(path))
for n in names:
    if not any(e["name"] == n for e in wl):
        wl.append({"uuid": offline(n), "name": n})
        print("toegevoegd:", n)
for e in wl:
    want = offline(e["name"])
    if e["uuid"] != want:
        print("ID hersteld:", e["name"], e["uuid"], "->", want)
        e["uuid"] = want
json.dump(wl, open(path, "w"), indent=2)
print("whitelist:", ", ".join(e["name"] for e in wl))
print("Typ nu in de AMP-console: whitelist reload")
EOF
