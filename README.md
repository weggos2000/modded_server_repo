# Homestead School – mods

Alles voor onze Minecraft-server **Homestead School**. Met één command installeer je de hele modpack,
exact gelijk aan de server, ook als we later mods toevoegen of weghalen.

| | |
|---|---|
| **Server** | `jakarta-tvs.tun.ply.gg` |
| **Modpack** | Homestead – A Cozy Survival Experience **1.3.7** (Fabric, Minecraft 1.20.1) |
| **Voice chat** | Simple Voice Chat, werkt automatisch (toets **V** voor het menu) |
| **Geld & shops** | Create: Numismatics: munten, bank en **Vendors** (je eigen winkel) |

## Installeren en updaten (Windows)

Je hebt alleen Minecraft Java nodig (gekocht, met de gewone launcher of Prism). Verder niets.

1. **Sluit Minecraft en je launcher.**
2. Download **[HomesteadSchool-Installer.zip](https://github.com/weggos2000/modded_server_repo/raw/main/HomesteadSchool-Installer.zip)**,
   pak hem uit (rechtsklik → *Alles uitpakken*) en dubbelklik op **Installeren.cmd**.
   Zie je *"Windows heeft uw pc beschermd"*? Klik dan op **Meer informatie** → **Toch uitvoeren**.
3. Kies je launcher:
   - **1 – Gewone Minecraft Launcher:** je krijgt een profiel **Homestead School**.
   - **2 – Prism Launcher:** je krijgt een instance **Homestead School**.
   - **3 – Andere launcher** (Modrinth App, ATLauncher, CurseForge, …): maak zelf een instance met
     Minecraft **1.20.1** + Fabric **0.18.4** en plak de map ervan.
   - **4 – Lunar Client:** Lunar kan geen modpacks laden. Het script biedt aan om alles in de gewone
     Minecraft Launcher te zetten; daar log je in met hetzelfde Microsoft-account.
4. Wacht tot er **Klaar!** staat (de eerste keer ±700 MB downloaden).
5. Start het profiel/de instance **Homestead School**. De eerste keer opstarten duurt een paar minuten.
   De server staat al in je **Multiplayer**-lijst.

**Updaten:** dubbelklik gewoon opnieuw op **Installeren.cmd**. Alleen wat veranderd is, wordt opnieuw gezet.

> Plak **nooit** commando's van internet in Win + R of PowerShell. Zo werkt echte malware ("ClickFix"),
> en Windows Defender blokkeert dat terecht. Daarom gebruiken we een gewoon bestand.

### Wat doet het script?

- Zet **Fabric** voor Minecraft 1.20.1 klaar en maakt het profiel/de instance aan (met genoeg RAM).
- Haalt de officiële **Homestead 1.3.7**-pack van CurseForge (configs, quests, resourcepacks, shaders).
  Dat gebeurt maar één keer; daarna blijven jouw instellingen staan.
- Zet de **mods** uit deze repo erin, exact gelijk aan de server. Mods die er niet meer bij horen,
  gaan naar `mods-backup/<datum>/`. Er wordt dus nooit iets definitief verwijderd.
- Zet de server in je serverlijst.

De gewone launcher installeert alles in `%APPDATA%\.homestead-school`, los van je normale Minecraft.

### macOS / Linux

Hier synct het script alleen de mods. Installeer eerst Homestead 1.3.7 via Prism of de CurseForge-app,
en draai daarna:

```bash
curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/install.sh | bash -s -- "/pad/naar/je/instance"
```

## Voor de beheerder: mods aanpassen

1. Zet de nieuwe `.jar` in `mods/` (of haal er een weg). Gebruik altijd de **Fabric 1.20.1**-versie.
2. Is de mod alleen voor de client (minimap, shaders, geluid, …)? Zet de bestandsnaam dan in `client-only.txt`.
   Bestanden die alleen op de server moeten (zoals KubeJS-recepten) zet je in `server/`. Bestanden die op client
   **én** server moeten (zoals KubeJS-items en textures) zet je in `shared/`. Gebruik in beide dezelfde mappenstructuur als de instance.
3. Werk de modlijst hieronder bij:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\update-modlist.ps1
   ```
4. Commit en push.
5. Server: stop Homestead School in AMP en draai op de server als `amp`:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/tools/sync-server.sh | bash
   ```
   Daarna de server opnieuw starten. Laat iedereen ook opnieuw **Installeren.cmd** draaien.
6. `install.ps1` aangepast? Verhoog `$InstallerVersion` in het script **en** `installerVersion` in `pack.json`,
   en bouw de zip opnieuw: `powershell -ExecutionPolicy Bypass -File tools\build-installer.ps1`.
   Wie een oude installer gebruikt, krijgt dan een melding om de nieuwe te downloaden.
7. Andere Homestead-versie? Pas `packVersion`/`packUrl` in `pack.json` aan. Bij de volgende run
   zet het install-script dan bij iedereen de nieuwe configs neer.

## Modlijst

<!-- MODLIST:START -->
**374 mods** (67 daarvan alleen voor de client).

| Mod | Versie | Bestand | Alleen client |
|---|---|---|---|
| [Let's Do Addon] Compat | 2.2.4 | `letsdocompat-fabric-2.2.4.jar` |  |
| [Let's Do Addon] Structures | 1.7.2 | `letsdo-addon-structures-1.7.2.jar` |  |
| [Let's Do] API | 1.2.15 | `letsdo-API-fabric-1.2.15-fabric.jar` |  |
| [Let's Do] Beachparty | 2.0.3 | `letsdo-beachparty-fabric-2.0.3.jar` |  |
| [Let's Do] Brewery | 2.0.6 | `letsdo-brewery-fabric-2.0.6.jar` |  |
| [Let's Do] Candlelight | 2.0.5 | `letsdo-candlelight-fabric-2.0.5.jar` |  |
| [Let's Do] Farm & Charm | 1.0.14 | `letsdo-farm_and_charm-fabric-1.0.14.jar` |  |
| [Let's Do] HerbalBrews | 1.0.12 | `letsdo-herbalbrews-fabric-1.0.12.jar` |  |
| [Let's Do] Meadow | 1.3.25 | `letsdo-meadow-fabric-1.3.25.jar` |  |
| [Let's Do] Vinery | 1.4.41 | `letsdo-vinery-fabric-1.4.41.jar` |  |
| [Let's Do] WilderNature | 1.0.6 | `letsdo-wildernature-fabric-1.0.6.jar` |  |
| 3d-Skin-Layers | 1.11.1 | `skinlayers3d-fabric-1.11.1-mc1.20.1.jar` |  |
| Accelerated Decay | 3.0.1+mc1.20.1 | `accelerated-decay-fabric-3.0.1+mc1.20.1.jar` |  |
| Accessories | 1.0.0-beta.48+1.20.1 | `accessories-fabric-1.0.0-beta.48+1.20.1.jar` |  |
| Advanced Netherite | 2.1.3-1.20.1 | `advancednetherite-fabric-2.1.3-1.20.1.jar` |  |
| Advancement Plaques | 1.6.7 | `AdvancementPlaques-1.20.1-fabric-1.6.7.jar` | ja |
| AdvancementInfo | 1.20-fabric0.83.0-1.4 | `advancementinfo-1.20-fabric0.83.0-1.4.jar` | ja |
| AlcoCraft+ | 2.1.0 | `alcocraftplus-1.20-2.1.0-fabric.jar` |  |
| Almanac | 1.0.2 | `almanac-1.20.x-fabric-1.0.2.jar` |  |
| AmbientSounds | 6.3.8 | `AmbientSounds_FABRIC_v6.3.8_mc1.20.1.jar` | ja |
| Amendments | 1.20-2.2.5 | `amendments-1.20-2.2.5-fabric.jar` |  |
| Animal Feeding Trough | 1.1.0+1.20.1 | `animal_feeding_trough-1.1.0+1.20.1.jar` |  |
| AppleSkin | 2.5.2+mc1.20.1 | `appleskin-fabric-mc1.20.1-2.5.2.jar` |  |
| Architectury | 9.2.14 | `architectury-9.2.14-fabric.jar` |  |
| Armor Statues | 8.0.6 | `ArmorStatues-v8.0.6-1.20.1-Fabric.jar` |  |
| Athena | 3.1.2 | `athena-fabric-1.20.1-3.1.2.jar` |  |
| AzureLib | 3.0.27 | `azurelib-fabric-1.20.1-3.0.27.jar` |  |
| Balm | 7.3.38 | `balm-fabric-1.20.1-7.3.38.jar` |  |
| Beautify | 2.0.0+1.20.1 | `beautify-2.0.0+1.20.1.jar` |  |
| Better Climbing | 3 | `better_climbing-fabric-3.jar` |  |
| Better Mount HUD | 1.2.2 | `bettermounthud-1.2.2.jar` | ja |
| BetterThanMending | 1.3.0 | `betterthanmending-1.3.0.jar` |  |
| BHMenu-Fabric | 2.4.2 | `BHMenu-Fabric-1.20.1-2.4.2.jar` | ja |
| Blåhaj | 0.3.2 | `blahaj-fabric-1.20.0-0.3.2.jar` |  |
| Block Runner | 8.0.4 | `BlockRunner-v8.0.4-1.20.1-Fabric.jar` |  |
| Boat Item View Fabric | 0.0.5 | `Boat-Item-View-Fabric-1.20.1-0.0.5.jar` | ja |
| Bookshelf | 20.2.15 | `Bookshelf-Fabric-1.20.1-20.2.15.jar` |  |
| Bridging Mod | 2.5.1+1.20.1 | `BridgingMod-2.5.1+1.20.1.fabric-release.jar` |  |
| Camerapture | 1.10.12 | `Camerapture-1.10.12+mc1.20.1-fabric.jar` |  |
| Carrascon Lib | 1.20.1-0.1 | `carrasconlib-fabric-1.20.1-0.1.jar` |  |
| Carry On | 2.1.2.7 | `carryon-fabric-1.20.1-2.1.2.7.jar` |  |
| Celestial Configuration | 1.1.1 | `Celestial Configuration-fabric-1.20.1-1.1.1.jar` |  |
| Chat Heads | 0.15.1 | `chat_heads-0.15.1-fabric-1.20.jar` | ja |
| Chef's Delight | 1.0.4-fabric-1.20.1 | `chefs-delight-1.0.4-fabric-1.20.1.jar` |  |
| Chipped | 3.0.7 | `chipped-fabric-1.20.1-3.0.7.jar` |  |
| Chunky | 1.3.146 | `Chunky-1.3.146.jar` |  |
| CICADA | 0.14.3+1.20.1 | `cicada-lib-0.14.3+1.20.1.jar` |  |
| CIT Resewn | 1.2.2+1.20.1 | `citresewn-1.2.2+1.20.1.jar` | ja |
| Cloth Config v11 | 11.1.136 | `cloth-config-11.1.136-fabric.jar` |  |
| Clumps | 12.0.0.4 | `Clumps-fabric-1.20.1-12.0.0.4.jar` |  |
| Clutter | 1.20-0.6.2 | `clutter-1.20-0.6.2.jar` |  |
| Cluttered | 2.1.0+1.20.1 | `Cluttered-2.1.0-1.20.1[Fabric].jar` |  |
| Collective | 8.22 | `collective-1.20.1-8.22.jar` |  |
| Colorwheel | 1.2.6+mc1.20.1 | `colorwheel-fabric-1.2.6+mc1.20.1.jar` | ja |
| Colorwheel Patcher | 1.0.5+mc1.20.1 | `colorwheel_patcher-fabric-1.0.5+mc1.20.1.jar` | ja |
| Comforts | 6.4.0+1.20.1 | `comforts-fabric-6.4.0+1.20.1.jar` |  |
| Common Network | 1.0.5-1.20.1 | `common-networking-fabric-1.0.5-1.20.1.jar` |  |
| Concurrent Chunk Management Engine | 0.2.0+alpha.11.16 | `c2me-fabric-mc1.20.1-0.2.0+alpha.11.16.jar` |  |
| Configurable | 2.2.3 | `Configurable-2.2.3-fabric-yarn+1.20.1.jar` |  |
| Configured | 2.2.3 | `configured-fabric-1.20.1-2.2.3.jar` | ja |
| Configured | 1.3.1 | `Configurable-mc1.20.1-v1.3.1.jar` |  |
| Connectible Chains | 2.5.5+1.20.1 | `connectiblechains-2.5.5+1.20.1.jar` |  |
| Construction Wand (Fabric) | 2.1.2 | `constructionwand-2.1.2+1.20.1.jar` |  |
| Continuity | 3.0.0+1.20.1 | `continuity-3.0.0+1.20.1.jar` | ja |
| Convenient Name Tags | 1.1.0 | `convenientnametags-1.1.0.jar` |  |
| CoolRain | 1.4.0-1.20.1 | `coolrain-1.4.0-1.20.1.jar` | ja |
| Copper-Age-Backport | 0.1.4 | `copperagebackport-fabric-1.20.1-0.1.4.jar` |  |
| CorgiLib | 4.0.3.4 | `Corgilib-Fabric-1.20.1-4.0.3.4.jar` |  |
| CoroUtil | 1.20.1-1.3.7 | `coroutil-fabric-1.20.1-1.3.7.jar` |  |
| Cozy Studios Core | 1.4-1.20.1 | `cozystudioscore-1.4-1.20.1.jar` |  |
| Crafting Pad | 1.0.12 | `CraftingPad-fabric-1.20.1-1.0.12.jar` |  |
| CraftTweaker | 14.0.60 | `CraftTweaker-fabric-1.20.1-14.0.60.jar` |  |
| Crate Delight | 25.09.22-1.20-fabric | `cratedelight-25.09.22-1.20-fabric.jar` |  |
| CraterLib | 3.1.1 | `CraterLib-Fabric-1.20-3.1.1.jar` |  |
| Create | 6.0.8.1+build.1744-mc1.20.1 | `create-fabric-6.0.8.1+build.1744-mc1.20.1.jar` |  |
| Create Contraption Terminals | 1.2.0 | `createcontraptionterminals-fabric-1.20-1.2.0.jar` |  |
| Create Deco | 2.1.1-1.20.1-fabric | `createdeco-2.1.1-1.20.1-fabric.jar` |  |
| Create Slice & Dice | 3.5.2-fabric | `sliceanddice-fabric-3.5.2.jar` |  |
| Create: Copycats+ | 3.0.7+mc.1.20.1-fabric | `copycats-3.0.7+mc.1.20.1-fabric.jar` |  |
| Create: Numismatics | 1.1.0+fabric-mc1.20.1 | `CreateNumismatics-1.1.0+fabric-mc1.20.1.jar` |  |
| Create: Oxidized | 0.1.1+1.20.1 | `create_oxidized-0.1.1+1.20.1.jar` |  |
| Create: Steam 'n' Rails | 1.7.2+fabric-mc1.20.1 | `Steam_Rails-1.7.2+fabric-mc1.20.1.jar` |  |
| CreativeCore | 2.12.36 | `CreativeCore_FABRIC_v2.12.36_mc1.20.1.jar` |  |
| Cristel Lib | 1.1.5 | `cristellib-1.1.5-fabric.jar` |  |
| Crops Love Rain | 1.4.0 | `crops_love_rain-1.4.0.jar` |  |
| Cubes Without Borders | 3.0.0+mc1.20 | `cwb-fabric-3.0.0+mc1.20.jar` | ja |
| DarkPaintings | 17.0.6 | `DarkPaintings-Fabric-1.20.1-17.0.6.jar` |  |
| DarkSmelting - Smelt Armor and Tools | 1.0.6 | `darksmelting-fabric-1.20.1-1.0.6.jar` |  |
| Data Anchor | 1.0.0.20 | `Data_Anchor-fabric-1.20.1-1.0.0.20.jar` |  |
| Debugify | 1.20.1+2.0 | `Debugify-1.20.1+2.0.jar` |  |
| Decorative Lamps | 1.20.1-1.7.4 | `Decorative Lamps-1.20.1-1.7.4.jar` |  |
| Deeper and Darker | 1.3.3-plus-b | `deeperdarker-fabric-1.20-1.3.3-plus-b.jar` |  |
| Default Options | 18.0.4 | `defaultoptions-fabric-1.20.1-18.0.4.jar` | ja |
| Deimos | 2.4 | `deimos-1.20.1-fabric-2.4.jar` |  |
| Deltabox Lib | 2.2.0 | `deltaboxlib-fabric-2.2.0+1.20.1.jar` |  |
| Detail Armor Bar | 2.6.3+1.20.1-fabric | `DetailArmorBar-2.6.3+1.20.1-fabric.jar` | ja |
| Diagonal Walls | 8.0.4 | `DiagonalWalls-v8.0.4-1.20.1-Fabric.jar` |  |
| Diagonal Windows | 8.1.5 | `DiagonalWindows-v8.1.5-1.20.1-Fabric.jar` |  |
| Double Doors | 7.2 | `doubledoors-1.20.1-7.2.jar` |  |
| Drippy Loading Screen | 3.1.0 | `drippyloadingscreen_fabric_3.1.0_MC_1.20.1.jar` | ja |
| Duckling | 4.0.0 | `duckling-fabric-1.20.4-4.0.0.jar` |  |
| Dusty Decorations Refabricated | 1.1-1.20.1+1.20.2 | `DustyDecoRefabricated-1.1-1.20.1+1.20.2.jar` |  |
| Easy Magic | 8.0.1 | `EasyMagic-v8.0.1-1.20.1-Fabric.jar` |  |
| Eating Animation | 1.20+1.9.61 | `eating-animation-1.20+1.9.61.jar` | ja |
| Eldritch End | 0.3.4 | `Eldritch_End-FABRIC-MC1.20.1-0.3.4.jar` |  |
| Elytra Slot | 6.4.4+1.20.1 | `elytraslot-fabric-6.4.4+1.20.1.jar` |  |
| Emojiful | 4.2.0 | `Emojiful-Fabric-1.20.1-4.2.0.jar` |  |
| Enchanter Fix | 1.8 | `enchanter_fix-1.8+mc1.20-1.21.11.jar` |  |
| EnchantmentDescriptions | 17.1.21 | `EnchantmentDescriptions-Fabric-1.20.1-17.1.21.jar` | ja |
| End's Delight | refabricated-1.20.1-2.5 | `ends_delight-refabricated-1.20.1-2.5.jar` |  |
| Enhanced Block Entities | 0.9+1.20 | `enhancedblockentities-0.9+1.20.jar` | ja |
| EntityCulling | 1.10.2 | `entityculling-fabric-1.10.2-mc1.20.1.jar` | ja |
| Euphoria Patcher | 1.8.6-r5.7.1-fabric | `EuphoriaPatcher-1.8.6-r5.7.1-fabric.jar` | ja |
| Expanded Delight | 0.3.2 | `expandeddelight-0.3.2.jar` |  |
| Explorer's Compass | 1.20.1-2.6.0-fabric | `ExplorersCompass-1.20.1-2.6.0-fabric.jar` |  |
| Extra Thicc Packets | 1.17-1.19+ | `extra_thicc_packets-1.0.jar` |  |
| Extreme sound muffler | 3.51 | `ExtremeSoundMuffler-3.51-fabric-1.20.1.jar` |  |
| Fabric API | 0.92.8+1.20.1 | `fabric-api-0.92.8+1.20.1.jar` |  |
| Fabric Language Kotlin | 1.13.11+kotlin.2.3.21 | `fabric-language-kotlin-1.13.11+kotlin.2.3.21.jar` |  |
| FabricSkyBoxes | 0.7.3+mc1.20.1 | `fabricskyboxes-0.7.3+mc1.20.1.jar` | ja |
| FabricSkyBoxes Interop | 1.3.6+mc1.20.1-build.50 | `fsb-interop-1.3.6+mc1.20.1-build.50.jar` | ja |
| Fadeless | 1.0.1 | `fadeless-1.0.1.jar` | ja |
| Fairy Lights | 1.1.4_fabric | `fairylights-1.1.4_fabric.jar` |  |
| FancyMenu | 3.8.1 | `fancymenu_fabric_3.8.1_MC_1.20.1.jar` | ja |
| Farmer's Delight | 1.20.1-1.4.3 | `farmers-delight-fabric-1.4.3.jar` |  |
| Farmer's Delight | 1.20.1-2.4.1+refabricated | `FarmersDelight-1.20.1-2.4.1+refabricated.jar` |  |
| Farmer's Knives | 3.2 | `farmersknives-3.2.jar` |  |
| FastBoot | 1.2-fabric | `fastboot-1.20.x-1.2fabric.jar` |  |
| Faster Random | 5.1.0 | `fasterrandom-5.1.0.jar` |  |
| FastQuit | 3.0.0+1.20+ | `fastquit-3.0.0+1.20+.jar` | ja |
| Faux-Custom-Entity-Data | 6.0.1 | `FauxCustomEntityData-fabric-1.20.1-6.0.1.jar` |  |
| FerriteCore | 6.0.1 | `ferritecore-6.0.1-fabric.jar` |  |
| Fetzi's Asian Decoration | 1.7.3 | `fetzisasiandeco-fabric-1.7.3-1.20.1.jar` |  |
| Flower Tweaks | 1 | `flower-tweaks-1.jar` |  |
| Forge Config API Port | 8.0.3 | `ForgeConfigAPIPort-v8.0.3-1.20.1-Fabric.jar` |  |
| Friends For Life | 1.2.0 | `friendsforlife-1.2.0.jar` |  |
| Friends&Foes | 3.0.9 | `friendsandfoes-fabric-mc1.20.1-3.0.9.jar` |  |
| FroglightsReimagined | 0.3-1.20.1 | `froglightsreimagined-0.3-1.20.1.jar` |  |
| FrozenLib | 1.9.3-mc1.20.1 | `FrozenLib-1.9.3-mc1.20.1.jar` |  |
| FTB Essentials | 2001.2.3 | `ftb-essentials-fabric-2001.2.3.jar` |  |
| FTB Filter System | 20.0.1 | `ftb-filter-system-fabric-20.0.1.jar` |  |
| FTB Library | 2001.2.9 | `ftb-library-fabric-2001.2.9.jar` |  |
| FTB Quests | 2001.4.13 | `ftb-quests-fabric-2001.4.13.jar` |  |
| FTB Teams | 2001.3.1 | `ftb-teams-fabric-2001.3.1.jar` |  |
| FTB XMod Compat | 2.1.3 | `ftb-xmod-compat-fabric-2.1.3.jar` |  |
| Fzzy Config | 0.7.6+1.20.1 | `fzzy_config-0.7.6+1.20.1.jar` |  |
| GeckoLib 4 | 4.8.2 | `geckolib-fabric-1.20.1-4.8.2.jar` |  |
| GeckoLibIrisCompat | 1.0.0 | `GeckoLibIrisCompat-Fabric-1.0.0.jar` | ja |
| Geophilic | 3.5 | `Geophilic v3.5.mod.jar` |  |
| Gliders | 1.2.0 | `gliders-fabric-1.2.0.jar` |  |
| Go Fish | 1.6.3+1.20.1 | `go-fish-1.6.3+1.20.1.jar` |  |
| Grass Seeds | 3.4 | `grassseeds-1.20.1-3.4.jar` |  |
| Grind Enchantments | 3.1.4+1.20.1 | `grind-enchantments-3.1.4+1.20.1.jar` |  |
| Handcrafted | 3.0.6 | `handcrafted-fabric-1.20.1-3.0.6.jar` |  |
| Harvestable Flowers | 1.1.0+1.20.1 | `harvestableflowers-1.1.0+1.20.1.jar` |  |
| Hearth & Home | 1.20.1-2.0.3 | `hearth_and_home-fabric-1.20.1-2.0.3.jar` |  |
| Hexalia | 1.3.2-1.20.1+fabric | `hexalia-1.3.2-1.20.1+fabric.jar` |  |
| Iceberg | 1.1.25 | `Iceberg-1.20.1-fabric-1.1.25.jar` |  |
| Icterine | 1.3.0 | `Icterine-fabric-1.20.0-1-1.3.0.jar` |  |
| ImmediatelyFast | 1.5.4+1.20.4 | `ImmediatelyFast-Fabric-1.5.4+1.20.4.jar` | ja |
| Immersive Furniture | 0.1.3+1.20.1 | `immersive_furniture-fabric-0.1.3+1.20.1.jar` |  |
| Incendium | 5.3.5 | `Incendium_1.20.x_v5.3.5.jar` |  |
| Indium | 1.0.36+mc1.20.1 | `indium-1.0.36+mc1.20.1.jar` | ja |
| Inventory HUD + | 3.4.26 | `inventoryhud.fabric.1.20.1-3.4.26.jar` | ja |
| Inventory Totem | 3.4 | `inventorytotem-1.20.1-3.4.jar` |  |
| Invisible Frames | 1.1.0 | `invisibleframes-1.1.0+1.20.jar` |  |
| Iris | 1.7.6+mc1.20.1 | `iris-1.7.6+mc1.20.1.jar` |  |
| Iron Chests: Restocked | 5.0.2 | `ironchests-5.0.2-fabric.jar` |  |
| Item Obliterator | 2.3.0 | `Item_Obliterator-MC1.20.1-Fabric_Quilt-2.3.0.jar` |  |
| Jade | 11.13.1+fabric | `Jade-1.20-Fabric-11.13.1.jar` |  |
| Jade Addons | 5.5.1+fabric | `JadeAddons-1.20.1-Fabric-5.5.1.jar` |  |
| JamLib | 1.3.6+1.20.1 | `jamlib-fabric-1.3.6+1.20.1.jar` |  |
| Jump Over Fences | 1.3.1 | `jumpoverfences-fabric-1.20.1-1.3.1.jar` | ja |
| Just Enough Breeding | 3.0.0 | `justenoughbreeding-fabric-1.20.1-3.0.0.jar` |  |
| Just Enough Items | 15.20.0.130 | `jei-1.20.1-fabric-15.20.0.130.jar` |  |
| Just Enough Professions (JEP) | 3.0.1 | `JustEnoughProfessions-fabric-1.20.1-3.0.1.jar` | ja |
| Just Hammers | 20.1.5+mc1.20.1 | `justhammers-fabric-20.1.5+mc1.20.1.jar` |  |
| Just Outdoor Stuffs | 1.0.2 | `JustOutdoorStuffs-1.20.1-fabric-v1.0.2.jar` |  |
| kennytv's epic force close loading screen mod for Fabric | 2.1.1 | `forcecloseloadingscreen-2.1.1.jar` | ja |
| Keybind Fix | 1.0.0 | `keybind_fix-1.0.0.jar` |  |
| Kiwi Library | 11.10.2+fabric | `Kiwi-1.20.1-Fabric-11.10.2.jar` |  |
| Konkrete | 1.8.1 | `konkrete_fabric_1.8.1_MC_1.20.1.jar` |  |
| Ksyxis | 1.4.3 | `Ksyxis-1.4.3.jar` |  |
| KubeJS | 2001.6.5-build.26 | `kubejs-fabric-2001.6.5-build.26.jar` |  |
| labels | 1.20-2.0.0 | `labels-1.20-2.0.0-fabric.jar` |  |
| LambDynamicLights | 4.4.0+1.20.1 | `lambdynamiclights-4.4.0+1.20.1.jar` | ja |
| Lavender | 0.1.9+1.20 | `lavender-0.1.9+1.20.jar` |  |
| LazyDFU | 0.1.3 | `lazydfu-0.1.3.jar` | ja |
| Let Me Despawn | 1.5.0 | `letmedespawn-1.20.x-fabric-1.5.0.jar` |  |
| Library ferret | 4.0.0 | `libraryferret-fabric-1.20.1-4.0.0.jar` |  |
| Lithium | 0.11.4 | `lithium-fabric-mc1.20.1-0.11.4.jar` |  |
| Lithostitched | 1.4.11 | `lithostitched-fabric-1.20.1-1.4.11.jar` |  |
| Load My F***ing Tags | 1.0.2+1.20 | `lmft-1.0.2+1.20-fabric.jar` |  |
| Log Begone | 1.0.8 | `Log-Begone-Fabric-1.20.1-1.0.8.jar` |  |
| Log Cleaner | 1.0.0 | `logcleaner-1.0.0.jar` |  |
| Lootr | 0.7.35.86 | `lootr-fabric-1.20-0.7.35.86.jar` |  |
| Macaw's Holidays | 1.1.2 | `mcw-holidays-1.1.2-mc1.20.1fabric.jar` |  |
| Macaw's Paintings | 1.1.0 | `mcw-paintings-1.1.0-mc1.20.1fabric.jar` |  |
| Macaw's Paths and Pavings | 1.1.1 | `mcw-mcwpaths-1.1.1-mc1.20.1fabric.jar` |  |
| MaLiLib | 0.16.3 | `malilib-fabric-1.20.1-0.16.3.jar` | ja |
| MasterCutter | 1.1 | `mastercutter-1.1.jar` |  |
| MCPitanLib | 3.6.8-1.20.1-fabric | `mcpitanlib-3.6.8-1.20.1-fabric.jar` |  |
| Melody | 1.0.3 | `melody_fabric_1.0.4_MC_1.20.1-1.20.4.jar` |  |
| Memory Leak Fix | 1.1.5 | `memoryleakfix-fabric-1.17+-1.1.5.jar` |  |
| MidnightLib | 1.9.3 | `midnightlib-fabric-1.9.3+1.20.1.jar` |  |
| Minecraft Accelerated | 1.0.0 | `pumpkinsAccelerated-1.20.1.jar` |  |
| Mixin Conflict Helper | 1.2.0 | `MixinConflictHelper-1.2.0.jar` |  |
| MixinTrace | 1.1.1+1.17 | `mixintrace-1.1.1+1.17.jar` |  |
| MmmMmmMmmMmm | 1.20-2.0.12 | `dummmmmmy-1.20-2.0.12-fabric.jar` |  |
| Mo Glass | 1.7-MC1.20.1 | `Mo-Glass-1.7-MC1.20.1.jar` |  |
| Mob Explosion Griefing Gamerule | 1.1.0_1.20.x | `mob_explosion_griefing-1.1.0_1.20.x.jar` |  |
| Mod Menu | 7.2.2 | `modmenu-7.2.2.jar` | ja |
| Modern World Creation | 2.0.1 | `modernworldcreation_fabric_2.0.1_MC_1.20.1.jar` | ja |
| ModernFix | 5.25.2+mc1.20.1 | `modernfix-fabric-5.25.2+mc1.20.1.jar` |  |
| ModMenu Badges Lib | 2023.6.1 | `modmenu-badges-lib-2023.6.1.jar` | ja |
| Modrinth Logo Mod | 1.3.4 | `Modrinth Logo Mod 1.3.4.jar` |  |
| Moonlight | 1.20-2.16.32 | `moonlight-1.20-2.16.32-fabric.jar` |  |
| More Axolotl Variants API | 1.1.4 | `mavapi-1.1.4-mc1.20.1.jar` |  |
| More Axolotl Variants Mod | 1.2.6 | `mavm-1.2.6-mc1.20.1.jar` |  |
| More Chat History | 1.3.0 | `morechathistory-1.3.0.jar` | ja |
| More Culling | 1.20.1-0.24.5 | `moreculling-1.20.1-0.24.5.jar` | ja |
| More Enchantment Info | 0.2.0 | `more-enchantment-info-0.2.0.jar` |  |
| Mouse Tweaks | 2.26 | `MouseTweaks-fabric-mc1.20-2.26.jar` | ja |
| Mouse Wheelie | 1.15.1+mc1.20.1 | `mouse-wheelie-1.15.1+mc1.20.1.jar` |  |
| Mythic Upgrades | 4.2.0+mc1.20.1 | `mythicupgrades-4.2.0+mc1.20.1.jar` |  |
| Nature's Compass | 1.20.1-2.6.0-fabric | `NaturesCompass-1.20.1-2.6.0-fabric.jar` |  |
| Nature's Delight | 1.12-1.20.1 | `naturesdelight-1.12-1.20.1.jar` |  |
| Nature's Spirit | 2.2.5-1.20.1 | `naturespirit-2.2.5-1.20.1.jar` |  |
| Necronomicon | 1.6.0 | `Necronomicon-Fabric-1.6.0+1.20.1.jar` |  |
| Neruina | 3.3.1 | `neruina-3.3.1+1.20.1-fabric.jar` |  |
| Nether's Delight Refabricated | 1.20.1-4.1.1 | `NethersDelight-Refabricated-1.20.1-4.1.1.jar` |  |
| NiftyCarts | 20.1.5 | `niftycarts-20.1.5.jar` |  |
| No Animal Tempt Delay | 1.2 | `noanimaltemptdelay-1.20.1-1.2.jar` |  |
| No Chat Reports | 1.20.1-v2.2.2 | `NoChatReports-FABRIC-1.20.1-v2.2.2.jar` |  |
| No Resource Pack Warnings | 1.3.1 | `no-resource-pack-warnings-1.3.1.jar` |  |
| Not Enough Crashes | 4.4.9+1.20.1 | `notenoughcrashes-4.4.9+1.20.1-fabric.jar` |  |
| Not Enough Recipe Book | 0.4.1 | `Not Enough Recipe Book-FABRIC-0.4.1+1.20.1.jar` |  |
| NotEnoughAnimations | 1.11.3 | `notenoughanimations-fabric-1.11.3-mc1.20.1.jar` | ja |
| Obsidian Equipment Reworked | 0.2 | `obsidianequipmentrework-fabric-0.4+mc1.20.1.jar` |  |
| Ocean's Delight | fdrf-fabric-1.0.2-1.20 | `oceansdelight-fdrf-fabric-1.0.2-1.20.jar` |  |
| OctoLib | 0.5.0.1 | `OctoLib-FABRIC-0.5.0.1+1.20.1.jar` |  |
| Oh The Biomes We've Gone | 1.7.5 | `Oh-The-Biomes-Weve-Gone-Fabric-1.7.5.jar` |  |
| Oh The Trees You'll Grow | 1.6.0 | `Oh-The-Trees-Youll-Grow-fabric-1.20.1-1.6.0.jar` |  |
| Omnilib | 0.1.4 | `omnilib-0.1.4+1.20.1.jar` |  |
| Open Parties and Claims | 0.26.2 | `open-parties-and-claims-fabric-1.20.1-0.26.2.jar` |  |
| OpenLoader | 19.0.5 | `OpenLoader-Fabric-1.20.1-19.0.5.jar` |  |
| oωo | 0.11.2+1.20 | `owo-lib-0.11.2+1.20.jar` |  |
| Packet Fixer | 3.3.2 | `packetfixer-3.3.2-1.18-1.20.4-merged.jar` |  |
| PandaLib | 0.5.2 | `pandalib-fabric-mc1.20-0.5.2-SNAPSHOT.jar` |  |
| Panda's Falling Tree's | 0.13.2 | `fallingtrees-fabric-mc1.20-0.13.2-SNAPSHOT.jar` |  |
| Particle Rain | 4.0.0-beta.10 | `particlerain-4.0.0-beta.10+1.20.1-fabric.jar` | ja |
| Patchouli | 1.20.1-85-FABRIC | `Patchouli-1.20.1-85-FABRIC.jar` |  |
| Peaceful Hunger | 2.2.0 | `peaceful_hunger-fabric-1.20.1-2.2.0.jar` |  |
| Pehkui | 3.8.2+1.14.4-1.20.6 | `Pehkui-3.8.2+1.14.4-1.20.6.jar` |  |
| Perfect Homestead Plushies | 1.1.0 | `phomesteadplushies-fabric-1.20.1-1.1.0.jar` |  |
| Perfect Plushies | 1.13.3 | `perfectplushies-fabric-1.20.1-1.13.3.jar` |  |
| Platform | 1.3.3 | `Platform-fabric-1.20.1-1.3.3.jar` |  |
| PneumonoCore | 1.2.1 | `pneumonocore-1.2.1+1.20+A.jar` |  |
| Polymorph | 0.49.10+1.20.1 | `polymorph-fabric-0.49.10+1.20.1.jar` |  |
| Polymorphic Tom | 1.0.4 | `polymorphic-tom-1.0.4.jar` |  |
| Preferred Gamerules | 1.1.1+1.19.4 | `preferred-gamerules-1.1.1+1.19.4.jar` |  |
| Presence Footsteps | 1.10.1+1.20.1 | `PresenceFootsteps-1.10.1+1.20.1.jar` | ja |
| Prism | 1.0.5 | `Prism-1.20.1-fabric-1.0.5.jar` | ja |
| Puzzle | 2.2.0 | `puzzle-fabric-2.2.0+1.20.1.jar` | ja |
| Puzzles Lib | 8.1.33 | `PuzzlesLib-v8.1.33-1.20.1-Fabric.jar` |  |
| Quests Additions | 1.4.6 | `questsadditions-fabric-1.20.1-1.4.6.jar` |  |
| Radiant Gear | 2.1.6+1.20.1 | `radiantgear-fabric-2.1.6+1.20.1.jar` |  |
| Realistic Bees | 4.2 | `realisticbees-1.20.1-4.2.jar` |  |
| Rebind Narrator | 2025.10.21 | `rebind_narrator-1.20.1-fabric-2025.10.21.jar` | ja |
| Reese's Sodium Options | 1.7.2+mc1.20.1-build.101 | `reeses_sodium_options-1.7.2+mc1.20.1-build.101.jar` | ja |
| Regions Unexplored | 0.5.6+1.20.1 | `RegionsUnexploredFabric-0.5.6+1.20.1.jar` |  |
| Remove Reloading Screen | 4.0.6.1+mc1.20.1-fabric | `rrls-4.0.6.1+mc1.20.1-fabric.jar` | ja |
| Repurposed Structures | 7.1.23+1.20.1-fabric | `repurposed_structures-7.1.23+1.20.1-fabric.jar` |  |
| Resourceful Lib | 2.1.29 | `resourcefullib-fabric-1.20.1-2.1.29.jar` |  |
| Resourcefulconfig | 2.1.3 | `resourcefulconfig-fabric-1.20.1-2.1.3.jar` |  |
| Respect My Trims | 1.0.0+mc1.20 | `respectmytrims-1.0.0+mc1.20.jar` |  |
| Rhino | 2001.2.3-build.10 | `rhino-fabric-2001.2.3-build.10.jar` |  |
| Ribbits | 1.20.1-Fabric-3.0.5 | `Ribbits-1.20.1-Fabric-3.0.5.jar` |  |
| Riding Mouse Fix | 1.0.0 | `ridingmousefix-1.0.0.jar` | ja |
| Right Click Harvest | 4.6.1+1.20.1 | `rightclickharvest-fabric-4.6.1+1.20.1.jar` |  |
| Screenshot Viewer | 1.3.1-fabric-mc1.20 | `screenshot_viewer-1.3.1-fabric-mc1.20.jar` | ja |
| ScreenshotToClipboard | 1.0.0-1.18.2~1.20.4-release | `screenshottoclipboard-1.0.0-1.18.2.1.20.4-release.jar` |  |
| Searchables | 1.0.3 | `Searchables-fabric-1.20.1-1.0.3.jar` | ja |
| Secure Crops | 2.0.0 | `securecrops-2.0.0+1.20.x.jar` |  |
| Serene Shrubbery | 1.0.0 | `serene_shrubbery-fabric-1.0.0+mc1.20.1.jar` |  |
| Show Me What You Got | 1.1.1 | `ShowMeWhatYouGot-1.20-1.1.1.jar` |  |
| Show Me Your Skin! | 1.9.0+1.20 | `show-me-your-skin-1.9.0+1.20.jar` |  |
| Shulker Drops Two | 3.5 | `shulkerdropstwo-1.20.1-3.5.jar` |  |
| SignCopy | 1.1.1 | `SignCopy-Fabric-1.20.1-1.1.1.jar` | ja |
| Simple Copper Pipes | 2.0.3 | `SimpleCopperPipes-mc1.20.1-2.0.3.jar` |  |
| Simple RPC | 4.1.0+hotfix.1 | `SimpleRPC-4.1.0+hotfix.1.jar` |  |
| Simple Voice Chat | 1.20.1-2.6.17 | `voicechat-fabric-1.20.1-2.6.17.jar` |  |
| SimpleHats | 0.4.0a | `simplehats-fabric-1.20.1-0.4.0a.jar` |  |
| Sit | 1.20.1-27 | `sit-1.20.1-27.jar` |  |
| SmartBrainLib | 1.15 | `SmartBrainLib-fabric-1.20.1-1.15.jar` |  |
| Smarter Farmers | 1.20-2.1.2 | `smarterfarmers-1.20-2.1.2-fabric.jar` |  |
| Smooth Scroll | 2.2.3.1 | `smoothscroll-2.2.3.1+1.20.1.jar` | ja |
| Sodium | 0.5.13+mc1.20.1 | `sodium-fabric-0.5.13+mc1.20.1.jar` | ja |
| Sodium Extra | 0.5.9+mc1.20.1 | `sodium-extra-0.5.9+mc1.20.1.jar` | ja |
| Sodium Extras | 1.0.6 | `sodiumextras-fabric-1.0.7-1.20.1.jar` | ja |
| Sodium Options API | 1.0.10 | `sodiumoptionsapi-fabric-1.0.10-1.20.1.jar` | ja |
| Sodium Options Mod Compat | 1.0.0 | `sodiumoptionsmodcompat-fabric-1.0.0-1.20.1.jar` | ja |
| Sooty Chimneys | 1.3.4 | `sootychimneys-fabric-1.20.1-1.3.4.jar` |  |
| Sophisticated Backpacks | 1.20.1-3.23.4.5.110 | `sophisticatedbackpacks-1.20.1-3.23.4.5.110.jar` |  |
| Sophisticated Core | 1.20.1-1.2.7.15.166 | `sophisticatedcore-1.20.1-1.2.7.15.166.jar` |  |
| Sophisticated Storage | 1.20.1-1.3.5.11.142 | `sophisticatedstorage-1.20.1-1.3.5.11.142.jar` |  |
| Sound Physics Remastered | 1.20.1-1.5.1 | `sound-physics-remastered-fabric-1.20.1-1.5.1.jar` |  |
| spark | 1.10.53 | `spark-1.10.53-fabric.jar` |  |
| SparseStructures | 3.0 | `sparsestructures-fabric-1.20.1-3.0.jar` |  |
| Spawn | 1.0.3-fabric | `spawn-1.0.3-fabric.jar` |  |
| Spelunkery | 1.20.1-0.3.16 | `spelunkery-1.20.1-0.3.16-fabric.jar` |  |
| Squish | 0.3-1.20.1 | `squish-0.3-1.20.1.jar` |  |
| Stack Refill | 4.9 | `stackrefill-1.20.1-4.9.jar` |  |
| StackDeobfuscator | 1.4.3+08e71cc | `StackDeobfuscatorFabric-1.4.3+08e71cc.jar` |  |
| Starter Kit | 8.0 | `starterkit-1.20.1-8.0.jar` |  |
| Stfu | 1.2.3 | `Stfu-1.2.3.jar` | ja |
| Storage Drawers | 12.14.3 | `StorageDrawers-fabric-1.20.1-12.14.3.jar` |  |
| Structure Layout Optimizer | 1.0.10 | `structure_layout_optimizer-fabric-1.0.10.jar` |  |
| StutterFix | mc1.20.1-0.2.0 | `stutterfix-mc1.20.1-0.2.0.jar` |  |
| Subtle Effects | 1.14.3 | `SubtleEffects-fabric-1.20.1-1.14.3.jar` |  |
| SuperMartijn642's Core Lib | 1.1.18+a | `supermartijn642corelib-1.1.18a-fabric-mc1.20.1.jar` |  |
| Supplementaries | 1.20-3.1.43 | `supplementaries-1.20-3.1.43-fabric.jar` |  |
| Supplementaries Squared | 1.20-1.1.29 | `suppsquared-1.20-1.1.29.jar` |  |
| SwingThrough | 1.0.6+1.20 | `swingthrough-1.0.6+1.20.jar` |  |
| Tameable Ribbits | 1.0.0 | `tameableribbits-1.0.0.jar` |  |
| TameableMinisheep | 1.0 | `tameableminisheep-1.0.jar` |  |
| TameableMossbloom | 1.0 | `TameableMossbloom-1.0.jar` |  |
| Tectonic | 3.0.17 | `tectonic-3.0.17-fabric-1.20.1.jar` |  |
| TerraBlender | 3.0.1.10 | `TerraBlender-fabric-1.20.1-3.0.1.10.jar` |  |
| Things | 0.3.3+1.20 | `things-0.3.3+1.20.jar` |  |
| Tidal Towns | 1.3.4 | `tidal-towns-1.3.4.jar` |  |
| Tiny Item Animations | 1.20-1.1 | `tia-1.20-1.1-fabric.jar` | ja |
| Tokimi's Toolshed | 1.3 | `tokimistoolshed-fabric-1.3+mc1.20.1.jar` |  |
| Tom's Simple Storage Mod | 1.7.1 | `toms_storage_fabric-1.20-1.7.1.jar` |  |
| Too Cheap! | 1.4.0+mc1.20 | `too-cheap-1.4.0+mc1.20.jar` |  |
| ToolStats | 16.0.10 | `ToolStats-Fabric-1.20.1-16.0.10.jar` |  |
| Tooltip Overhaul | 1.4.3 | `tooltipoverhaul-fabric-1.20.1-1.4.3.jar` |  |
| Towns and Towers | 1.12 | `Towns-and-Towers-1.12-Fabric+Forge.jar` |  |
| Trade Cycling | 1.20.1-1.0.18 | `trade-cycling-fabric-1.20.1-1.0.18.jar` |  |
| Trash Cans | 1.0.18 | `trashcans-1.0.18-fabric-mc1.20.jar` |  |
| TrashSlot | 15.1.5 | `trashslot-fabric-1.20.1-15.1.5.jar` |  |
| Traveler's Titles | 1.20-Fabric-4.0.2 | `TravelersTitles-1.20-Fabric-4.0.2.jar` | ja |
| Trinkets | 3.7.2 | `trinkets-3.7.2.jar` |  |
| Twigs | 3.1.0 | `twigs-3.1.0-fabric.jar` |  |
| TxniLib | 1.0.24 | `txnilib-fabric-1.0.24-1.20.1.jar` |  |
| Typewriter Daycounter | 1.0 | `vr_typewriter_daycounter_v1.jar` |  |
| Umbrellas | 1.4.2 | `umbrellas-1.4.2+1.20+A.jar` |  |
| Universal Bone Meal | 8.0.1 | `UniversalBoneMeal-v8.0.1-1.20.1-Fabric.jar` |  |
| Universal Graves | 3.0.3+1.20.1 | `graves-3.0.3+1.20.1.jar` |  |
| Universal Sawmill | 1.20-1.4.10 | `sawmill-1.20-1.4.10-fabric.jar` |  |
| VanillaBackport | 1.1.7.4 | `VanillaBackport-fabric-1.20.1-1.1.7.4.jar` |  |
| Vein Mining | 1.5.0+1.20.1 | `veinmining-fabric-1.5.0+1.20.1.jar` |  |
| Via Romana | 2.2.2+1.20.1-fabric | `via_romana-2.2.2+1.20.1-fabric.jar` |  |
| Villagers Plus | 3.1 | `VillagersPlus_3.1_(FABRIC)_for_1.20.1.jar` |  |
| Villages & Pillages | 1.0.2 | `villagesandpillages-fabric-mc1.20.1-1.0.2.jar` |  |
| Visuality | 0.7.1+1.20 | `visuality-0.7.1+1.20.jar` | ja |
| Wearable lanterns | 1.0.1 | `trinketlantern-1.0.1.jar` |  |
| Welcome Screen | 1.0.0 | `welcomescreen-fabric-1.0.0-1.20.1.jar` | ja |
| What Are They Up To | 1.20.1-1.2.3 | `watut-fabric-1.20.1-1.2.3.jar` |  |
| Wireless Redstone | 1.20.1-1.1.2 | `wirelessredstone-fabric-1.20.1-1.1.2.jar` |  |
| Xaero's Minimap | 25.3.12 | `xaerominimap-fabric-1.20.1-25.3.12.jar` |  |
| Xaero's World Map | 1.40.16 | `xaeroworldmap-fabric-1.20.1-1.40.16.jar` |  |
| YetAnotherConfigLib | 3.6.6+1.20.1-fabric | `yet_another_config_lib_v3-3.6.6+1.20.1-fabric.jar` |  |
| YOSBR | 0.1.2 | `yosbr-0.1.2.jar` |  |
| You Shall Not Spawn | 2.0.2 | `YouShallNotSpawn-fabric-1.20.x-2.0.2.jar` |  |
| YUNG's API | 1.20-Fabric-4.0.6 | `YungsApi-1.20-Fabric-4.0.6.jar` |  |
| YUNG's Better Dungeons | 1.20-Fabric-4.0.4 | `YungsBetterDungeons-1.20-Fabric-4.0.4.jar` |  |
| YUNG's Better End Island | 1.20-Fabric-2.0.6 | `YungsBetterEndIsland-1.20-Fabric-2.0.6.jar` |  |
| YUNG's Better Mineshafts | 1.20-Fabric-4.0.4 | `YungsBetterMineshafts-1.20-Fabric-4.0.4.jar` |  |
| YUNG's Better Nether Fortresses | 1.20-Fabric-2.0.6 | `YungsBetterNetherFortresses-1.20-Fabric-2.0.6.jar` |  |
| YUNG's Better Strongholds | 1.20-Fabric-4.0.3 | `YungsBetterStrongholds-1.20-Fabric-4.0.3.jar` |  |
| YUNG's Bridges | 1.20-Fabric-4.0.3 | `YungsBridges-1.20-Fabric-4.0.3.jar` |  |
| YUNG's Extras | 1.20-Fabric-4.0.3 | `YungsExtras-1.20-Fabric-4.0.3.jar` |  |
| Zoomify | 2.15.1+1.20.1 | `zoomify-2.15.1+1.20.1.jar` | ja |
<!-- MODLIST:END -->
