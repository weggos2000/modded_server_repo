# Munten maken

Munten maken gaat in twee stappen, net als in de mod *Create: Numismatics Crafting*:

1. **Persen:** leg de ingrediënten in een **Basin** met een **Mechanical Press** erboven (Create *Compacting*).
   Je krijgt een **Unpolished**-munt.
2. **Polijsten:** blaas de unpolished munt met een **Encased Fan** door **water** (Create *Washing*),
   bijvoorbeeld op een depot of mechanical belt voor de fan. Dan krijg je de echte munt.

| Munt | Ingrediënten (stap 1) |
|---|---|
| Spur | koperklompje + tandwiel |
| Bevel | crushed raw zinc + tandwiel |
| Sprocket | ijzeren plaat (iron sheet) + groot tandwiel |
| Cog | messing staaf (brass ingot) + groot tandwiel |
| Crown | goudblok + groot tandwiel |
| Sun | crown + netherite sheet + groot tandwiel |

## Technisch

- De unpolished munten zijn eigen items (`kubejs:unpolished_<munt>`), geregistreerd in
  `shared/kubejs/startup_scripts/numismatics_unpolished.js`, met textures in `shared/kubejs/assets/`.
  Die moeten op client **en** server staan; de installer en `tools/sync-server.sh` zetten ze neer.
  Zonder die bestanden kan je niet joinen.
- De recepten staan in `server/kubejs/server_scripts/numismatics_crafting.js` en draaien alleen op de server.
