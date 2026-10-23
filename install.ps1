<#
  Homestead School - alles-in-een installer / updater (Windows)

  Installeert of updatet in een keer:
    - Fabric voor Minecraft 1.20.1
    - een profiel/instance "Homestead School" (gewone Minecraft Launcher of Prism Launcher)
    - de Homestead 2.0-pack (configs, quests, resourcepacks, shaders), rechtstreeks van CurseForge
    - de mods + KubeJS-bestanden uit deze repo (exact gelijk aan de server)
    - de server in je serverlijst

  Gebruik (zie README): download HomesteadSchool-Installer.zip, pak uit en dubbelklik Installeren.cmd

  Opties (meestal niet nodig):
    -Launcher official|prism|folder   launcher kiezen zonder menu
    -InstancePath <map>               (bij "folder") de game-map van je instance
    -Mode normal|performance          modus kiezen zonder menu
    -SetMode normal|performance       alleen snel wisselen van modus (geen download)
#>
param(
    [ValidateSet('', 'official', 'prism', 'folder')]
    [string]$Launcher = '',
    [string]$InstancePath,
    [ValidateSet('', 'normal', 'performance')]
    [string]$Mode = '',
    [ValidateSet('', 'normal', 'performance')]
    [string]$SetMode = '',
    [string]$InstallsFile = "$env:LOCALAPPDATA\HomesteadSchool\installs.txt",
    # --- voor testen / gevorderden ---
    [string]$MinecraftDir = "$env:APPDATA\.minecraft",
    [string]$PrismDir = "$env:APPDATA\PrismLauncher",
    [string]$OfficialGameDir = "$env:APPDATA\.homestead-school",
    [string]$SourceDir,      # lokale repo-map i.p.v. downloaden
    [string]$PackZip,        # lokale Homestead-zip i.p.v. downloaden
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # maakt downloaden in PowerShell 5.1 veel sneller
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Repo   = 'weggos2000/modded_server_repo'
$Branch = 'main'
$InstallerVersion = 5   # verhogen bij elke wijziging aan dit script (ook in pack.json zetten)

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }
function Save-Url($url, $dest) { Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -UserAgent 'homestead-school-installer' }
function Write-Utf8($path, $text) { [IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false))) }

function Stop-WithPause($code) {
    if (-not $NoPause) { Write-Host ""; Read-Host "Druk op Enter om af te sluiten" | Out-Null }
    exit $code
}

# --- Performance-modus -------------------------------------------------------
# Alles staat in <game>\.homestead :
#   mode.txt               normal / performance
#   remove.txt             mods die in performance-modus weg moeten
#   perf-mods\*.jar        extra FPS-mods voor performance-modus
#   perf-options.txt       lichtere grafische instellingen
#   disabled-mods\         hier staan de weggehaalde mods tijdens performance-modus
#   options-backup-*.txt   jouw eigen instellingen, om terug te zetten bij normaal
#   iris-backup.txt        jouw shaders aan/uit, om terug te zetten bij normaal
function Get-StateDir($game) { Join-Path $game '.homestead' }

function Get-CurrentMode($game) {
    $f = Join-Path (Get-StateDir $game) 'mode.txt'
    if (Test-Path -LiteralPath $f) { (Get-Content -LiteralPath $f -Raw).Trim() } else { 'normal' }
}

function Set-ModeMarker($game, $m) {
    $st = Get-StateDir $game
    New-Item -ItemType Directory -Force -Path $st | Out-Null
    Write-Utf8 (Join-Path $st 'mode.txt') $m
}

function Get-OptionFiles($game) {
    @(
        @{ File = Join-Path $game 'options.txt'; Backup = 'options-backup-main.txt' },
        @{ File = Join-Path $game 'config\defaultoptions\options.txt'; Backup = 'options-backup-default.txt' }
    )
}

function Read-Lines($path) { if (Test-Path -LiteralPath $path) { @(Get-Content -LiteralPath $path) } else { @() } }

function Restore-PerfMods($game) {
    # mods uit performance-modus terugzetten en de extra FPS-mods weghalen
    $st = Get-StateDir $game
    $mods = Join-Path $game 'mods'
    $dis = Join-Path $st 'disabled-mods'
    if (Test-Path -LiteralPath $dis) {
        Get-ChildItem -LiteralPath $dis -Filter *.jar | ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination (Join-Path $mods $_.Name) -Force
        }
    }
    $perf = Join-Path $st 'perf-mods'
    if (Test-Path -LiteralPath $perf) {
        Get-ChildItem -LiteralPath $perf -Filter *.jar | ForEach-Object {
            $p = Join-Path $mods $_.Name
            if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
        }
    }
}

function Apply-PerfMods($game) {
    $st = Get-StateDir $game
    $mods = Join-Path $game 'mods'
    $dis = Join-Path $st 'disabled-mods'
    New-Item -ItemType Directory -Force -Path $dis | Out-Null
    $n = 0
    foreach ($name in (Read-Lines (Join-Path $st 'remove.txt'))) {
        $name = $name.Trim()
        if (-not $name -or $name.StartsWith('#')) { continue }
        $p = Join-Path $mods $name
        if (Test-Path -LiteralPath $p) { Move-Item -LiteralPath $p -Destination (Join-Path $dis $name) -Force; $n++ }
    }
    $perf = Join-Path $st 'perf-mods'
    if (Test-Path -LiteralPath $perf) {
        Get-ChildItem -LiteralPath $perf -Filter *.jar | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $mods $_.Name) -Force
        }
    }
    Write-Host "    $n zware mods uitgezet, FPS-mods aangezet."
}

function Apply-PerfOptions($game) {
    # lichtere instellingen zetten; eigen waarden eerst bewaren (alleen als er nog geen backup is)
    $st = Get-StateDir $game
    $patch = [ordered]@{}
    foreach ($l in (Read-Lines (Join-Path $st 'perf-options.txt'))) {
        $i = $l.IndexOf(':'); if ($i -gt 0) { $patch[$l.Substring(0, $i)] = $l.Substring($i + 1) }
    }
    foreach ($o in (Get-OptionFiles $game)) {
        if (-not (Test-Path -LiteralPath $o.File)) { continue }
        $lines = [System.Collections.ArrayList]@(Read-Lines $o.File)
        $backup = Join-Path $st $o.Backup
        $orig = New-Object System.Collections.ArrayList
        foreach ($key in $patch.Keys) {
            $idx = -1
            for ($k = 0; $k -lt $lines.Count; $k++) { if ($lines[$k].StartsWith("$($key):")) { $idx = $k; break } }
            if ($idx -ge 0) { [void]$orig.Add($lines[$idx]); $lines[$idx] = "$($key):$($patch[$key])" }
            else { [void]$orig.Add("$($key):<absent>"); [void]$lines.Add("$($key):$($patch[$key])") }
        }
        if (-not (Test-Path -LiteralPath $backup)) { Write-Utf8 $backup (($orig -join "`n") + "`n") }
        Write-Utf8 $o.File (($lines -join "`n") + "`n")
    }
    Set-ShadersOff $game
}

function Get-IrisFile($game) { Join-Path $game 'config\iris.properties' }

function Set-IrisShaders($path, $value) {
    $lines = @(Read-Lines $path | Where-Object { -not $_.StartsWith('enableShaders=') }) + "enableShaders=$value"
    Write-Utf8 $path (($lines -join "`n") + "`n")
}

function Set-ShadersOff($game) {
    # shaders uit; de eigen keuze bewaren in iris-backup.txt (alleen als er nog geen backup is)
    $path = Get-IrisFile $game
    $backup = Join-Path (Get-StateDir $game) 'iris-backup.txt'
    if (-not (Test-Path -LiteralPath $path)) { return }   # nog nooit gestart: YOSBR zet de standaard (shaders uit) zelf neer
    $cur = 'false'
    foreach ($l in (Read-Lines $path)) { if ($l.StartsWith('enableShaders=')) { $cur = $l.Substring(14).Trim() } }
    if (-not (Test-Path -LiteralPath $backup)) { Write-Utf8 $backup "$cur`n" }
    Set-IrisShaders $path 'false'
}

function Restore-Shaders($game) {
    $path = Get-IrisFile $game
    $backup = Join-Path (Get-StateDir $game) 'iris-backup.txt'
    if (-not (Test-Path -LiteralPath $backup)) { return }
    if (Test-Path -LiteralPath $path) {
        $v = @(Read-Lines $backup)
        Set-IrisShaders $path $(if ($v.Count -gt 0) { $v[0].Trim() } else { 'false' })
    }
    Remove-Item -LiteralPath $backup -Force
}

function Restore-Options($game) {
    $st = Get-StateDir $game
    $defaultBackup = Join-Path $st 'options-backup-default.txt'
    foreach ($o in (Get-OptionFiles $game)) {
        $backup = Join-Path $st $o.Backup
        $delete = $true
        # options.txt bestond nog niet bij het aanzetten (Minecraft nog nooit gestart)? Dan de standaardwaarden gebruiken.
        if (-not (Test-Path -LiteralPath $backup) -and $o.Backup -eq 'options-backup-main.txt' -and (Test-Path -LiteralPath $defaultBackup)) {
            $backup = $defaultBackup; $delete = $false
        }
        if (-not (Test-Path -LiteralPath $backup) -or -not (Test-Path -LiteralPath $o.File)) { continue }
        $lines = [System.Collections.ArrayList]@(Read-Lines $o.File)
        foreach ($b in (Read-Lines $backup)) {
            $i = $b.IndexOf(':'); if ($i -le 0) { continue }
            $key = $b.Substring(0, $i)
            for ($k = $lines.Count - 1; $k -ge 0; $k--) { if ($lines[$k].StartsWith("$($key):")) { $lines.RemoveAt($k) } }
            if ($b.Substring($i + 1) -ne '<absent>') { [void]$lines.Add($b) }
        }
        Write-Utf8 $o.File (($lines -join "`n") + "`n")
        if ($delete) { Remove-Item -LiteralPath $backup -Force }
    }
    Restore-Shaders $game
}

function Register-Install($game) {
    New-Item -ItemType Directory -Force -Path (Split-Path $InstallsFile -Parent) | Out-Null
    $list = @(Read-Lines $InstallsFile | Where-Object { $_ -and (Test-Path -LiteralPath $_) })
    if ($list -notcontains $game) { $list += $game }
    Write-Utf8 $InstallsFile (($list -join "`r`n") + "`r`n")
}

$work = Join-Path $env:TEMP ("homestead-school-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null

try {
    Write-Host ""
    Write-Host "  Homestead School installer" -ForegroundColor Green
    Write-Host ""

    # --- 0. Alleen wisselen van modus (geen download) ---------------------------
    if ($SetMode) {
        $games = @(Read-Lines $InstallsFile | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ '.homestead')) })
        if ($InstancePath) { $games = @($InstancePath.Trim('"', ' ')) }
        if ($games.Count -eq 0) {
            Write-Warn "Homestead School is nog niet geinstalleerd. Dubbelklik eerst op Installeren.cmd."
            Stop-WithPause 1
        }
        $game = $games[0]
        if ($games.Count -gt 1) {
            Write-Host "Welke installatie?"
            for ($i = 0; $i -lt $games.Count; $i++) { Write-Host ("  [{0}] {1}  ({2})" -f ($i + 1), $games[$i], (Get-CurrentMode $games[$i])) }
            do { $c = Read-Host "Kies een nummer" } while (-not ($c -as [int]) -or [int]$c -lt 1 -or [int]$c -gt $games.Count)
            $game = $games[[int]$c - 1]
        }
        if (Get-Process -Name javaw -ErrorAction SilentlyContinue) {
            Write-Warn "Sluit Minecraft eerst af."
            Read-Host "Druk op Enter als Minecraft dicht is" | Out-Null
        }
        $cur = Get-CurrentMode $game
        if ($cur -eq $SetMode) {
            Write-Host "Performance-modus staat al $(if ($SetMode -eq 'performance') { 'AAN' } else { 'UIT' }) in $game." -ForegroundColor Green
            Stop-WithPause 0
        }
        if ($SetMode -eq 'performance') {
            Write-Step "Performance-modus aanzetten in $game ..."
            Apply-PerfMods $game; Apply-PerfOptions $game
        } else {
            Write-Step "Terug naar normale modus in $game ..."
            Restore-PerfMods $game; Restore-Options $game
            Write-Host "    Alle mods en je eigen instellingen staan terug."
        }
        Set-ModeMarker $game $SetMode
        Write-Host ""
        Write-Host "Klaar! Start Homestead School opnieuw in je launcher." -ForegroundColor Green
        Stop-WithPause 0
    }

    # --- 1. Repo ophalen (mods, KubeJS-bestanden, pack.json) ------------------
    if ($SourceDir) {
        $RepoRoot = $SourceDir
    } else {
        Write-Step "Bestanden downloaden van github.com/$Repo (ca. 700 MB, even geduld)..."
        $zip = Join-Path $work 'repo.zip'
        Save-Url "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" $zip
        $extract = Join-Path $work 'repo'
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $extract)
        $RepoRoot = (Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1).FullName
        Remove-Item -LiteralPath $zip -Force
    }
    $Pack = Get-Content -LiteralPath (Join-Path $RepoRoot 'pack.json') -Raw | ConvertFrom-Json
    $FabricId = "fabric-loader-$($Pack.fabricLoader)-$($Pack.minecraft)"
    if ([int]$Pack.installerVersion -gt $InstallerVersion) {
        Write-Warn "Er is een nieuwere installer. Download HomesteadSchool-Installer.zip opnieuw van:"
        Write-Warn "https://github.com/$Repo"
        Write-Warn "(Deze versie gaat nu gewoon verder.)"
    }

    # --- 2. Launcher kiezen ---------------------------------------------------
    if (-not $Launcher) {
        if ($InstancePath) { $Launcher = 'folder' }
        else {
            $hasPrism = Test-Path -LiteralPath $PrismDir
            Write-Host "Welke launcher gebruik je?"
            Write-Host "  [1] Gewone Minecraft Launcher"
            Write-Host ("  [2] Prism Launcher" + $(if ($hasPrism) { "   (gevonden op deze pc)" } else { "" }))
            Write-Host "  [3] Andere launcher (Modrinth App, ATLauncher, CurseForge, ...) - jij kiest de map"
            Write-Host "  [4] Lunar Client"
            do { $choice = Read-Host "Kies 1, 2, 3 of 4" } while ($choice -notin '1', '2', '3', '4')
            if ($choice -eq '4') {
                Write-Host ""
                Write-Warn "Lunar Client kan geen modpacks laden (alleen zijn eigen mods), dus Homestead werkt daar niet."
                Write-Warn "Je kan het wel in de gewone Minecraft Launcher zetten: daar log je in met hetzelfde Microsoft-account."
                $ok = Read-Host "Installeren in de gewone Minecraft Launcher? (j/n)"
                if ($ok -notmatch '^[jJyY]') { Write-Host "Oke, er is niets geinstalleerd."; Stop-WithPause 0 }
                $choice = '1'
            }
            $Launcher = @{ '1' = 'official'; '2' = 'prism'; '3' = 'folder' }[$choice]
        }
    }

    # RAM voor Minecraft: afhankelijk van hoeveel geheugen de pc heeft
    $totalGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $ramMB = if ($totalGB -ge 16) { 8192 } elseif ($totalGB -ge 12) { 6144 } else { 4096 }
    if ($totalGB -lt 12) { Write-Warn "Je pc heeft maar ca. $totalGB GB RAM. Homestead is zwaar; zet shaders uit als het hapert." }

    switch ($Launcher) {
        'official' {
            if (-not (Test-Path -LiteralPath (Join-Path $MinecraftDir 'launcher_profiles.json'))) {
                Write-Warn "De Minecraft Launcher is nog niet (goed) geinstalleerd."
                Write-Warn "Installeer hem via https://www.minecraft.net/download, start hem een keer, sluit hem en draai dit opnieuw."
                Stop-WithPause 1
            }
            if (Get-Process -Name 'MinecraftLauncher', 'Minecraft' -ErrorAction SilentlyContinue) {
                Write-Warn "Sluit eerst de Minecraft Launcher (anders overschrijft hij het nieuwe profiel)."
                Read-Host "Druk op Enter als de launcher dicht is" | Out-Null
            }
            $GameDir = $OfficialGameDir
        }
        'prism' {
            if (-not (Test-Path -LiteralPath $PrismDir)) {
                Write-Warn "Prism Launcher niet gevonden in $PrismDir."
                Write-Warn "Installeer Prism (https://prismlauncher.org), start hem een keer, sluit hem en draai dit opnieuw."
                Stop-WithPause 1
            }
            if (Get-Process -Name 'prismlauncher' -ErrorAction SilentlyContinue) {
                Write-Warn "Sluit eerst Prism Launcher."
                Read-Host "Druk op Enter als Prism dicht is" | Out-Null
            }
            # Prism kan een eigen instances-map ingesteld hebben
            $instRoot = Join-Path $PrismDir 'instances'
            $cfg = Join-Path $PrismDir 'prismlauncher.cfg'
            if (Test-Path -LiteralPath $cfg) {
                $line = Get-Content -LiteralPath $cfg | Where-Object { $_ -like 'InstanceDir=*' } | Select-Object -First 1
                if ($line) {
                    $dir = $line.Substring('InstanceDir='.Length).Trim()
                    if ($dir) { $instRoot = if ([IO.Path]::IsPathRooted($dir)) { $dir } else { Join-Path $PrismDir $dir } }
                }
            }
            $PrismInstance = Join-Path $instRoot 'Homestead School'
            $GameDir = Join-Path $PrismInstance 'minecraft'
        }
        'folder' {
            if (-not $InstancePath) {
                Write-Host ""
                Write-Host "Maak in je launcher eerst een instance aan met Minecraft $($Pack.minecraft) + Fabric $($Pack.fabricLoader)."
                $InstancePath = Read-Host "Plak het pad naar de game-map van die instance (de map waar 'mods' in staat of komt)"
            }
            $GameDir = $InstancePath.Trim('"', ' ')
            if ((Split-Path $GameDir -Leaf) -eq 'mods') { $GameDir = Split-Path $GameDir -Parent }
            if (-not (Test-Path -LiteralPath $GameDir)) { throw "Map bestaat niet: $GameDir" }
        }
    }
    New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
    Write-Step "Installeren in: $GameDir"

    # Modus kiezen (onthoudt de vorige keuze)
    $PrevMode = Get-CurrentMode $GameDir
    if (-not $Mode) {
        $def = if ($PrevMode -eq 'performance') { '2' } else { '1' }
        Write-Host ""
        Write-Host "Welke versie wil je?"
        Write-Host "  [1] Normaal       - alle effecten, voor een goede pc"
        Write-Host "  [2] Performance   - meer FPS, voor laptops (minder sfeer-effecten, lichtere instellingen)"
        Write-Host "  (Later wisselen kan met 'Performance aan.cmd' / 'Performance uit.cmd')"
        $c = Read-Host "Kies 1 of 2 [Enter = $def]"
        if (-not $c) { $c = $def }
        $Mode = if ($c -eq '2') { 'performance' } else { 'normal' }
    }

    # --- 3. Launcher instellen ------------------------------------------------
    if ($Launcher -eq 'official') {
        Write-Step "Fabric $($Pack.fabricLoader) voor Minecraft $($Pack.minecraft) instellen..."
        $verDir = Join-Path $MinecraftDir "versions\$FabricId"
        New-Item -ItemType Directory -Force -Path $verDir | Out-Null
        Save-Url "https://meta.fabricmc.net/v2/versions/loader/$($Pack.minecraft)/$($Pack.fabricLoader)/profile/json" (Join-Path $verDir "$FabricId.json")

        $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        foreach ($pf in 'launcher_profiles.json', 'launcher_profiles_microsoft_store.json') {
            $path = Join-Path $MinecraftDir $pf
            if (-not (Test-Path -LiteralPath $path)) { continue }
            Copy-Item -LiteralPath $path -Destination "$path.homestead-backup" -Force
            $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            if (-not $json.profiles) { $json | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{}) -Force }
            $profile = [pscustomobject]@{
                name          = 'Homestead School'
                type          = 'custom'
                created       = $now
                lastUsed      = $now
                icon          = 'Grass'
                lastVersionId = $FabricId
                gameDir       = $GameDir
                javaArgs      = "-Xmx$($ramMB)M -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200"
            }
            $json.profiles | Add-Member -NotePropertyName 'homestead-school' -NotePropertyValue $profile -Force
            Write-Utf8 $path ($json | ConvertTo-Json -Depth 32)
        }
        Write-Host "    Profiel 'Homestead School' staat in de launcher ($([math]::Round($ramMB/1024)) GB RAM)."
    }
    elseif ($Launcher -eq 'prism') {
        Write-Step "Prism-instance 'Homestead School' instellen..."
        $mmc = [ordered]@{
            formatVersion = 1
            components    = @(
                [ordered]@{ uid = 'net.minecraft'; version = $Pack.minecraft; important = $true },
                [ordered]@{ uid = 'net.fabricmc.intermediary'; version = $Pack.minecraft; dependencyOnly = $true },
                [ordered]@{ uid = 'net.fabricmc.fabric-loader'; version = $Pack.fabricLoader }
            )
        }
        Write-Utf8 (Join-Path $PrismInstance 'mmc-pack.json') ($mmc | ConvertTo-Json -Depth 8)
        $cfgPath = Join-Path $PrismInstance 'instance.cfg'
        if (-not (Test-Path -LiteralPath $cfgPath)) {
            Write-Utf8 $cfgPath (@(
                '[General]', 'ConfigVersion=1.2', 'InstanceType=OneSix', 'name=Homestead School', 'iconKey=default',
                'OverrideMemory=true', "MaxMemAlloc=$ramMB", 'MinMemAlloc=2048'
            ) -join "`r`n")
        }
        Write-Host "    Instance staat in Prism ($([math]::Round($ramMB/1024)) GB RAM)."
    }

    # --- 4. Homestead-pack (configs, quests, resourcepacks, shaders) ---------
    $marker = Join-Path $GameDir '.homestead-pack'
    $installed = if (Test-Path -LiteralPath $marker) { (Get-Content -LiteralPath $marker -Raw).Trim() } else { '' }
    if ($installed -ne $Pack.packVersion) {
        Write-Step "Homestead $($Pack.packVersion) ophalen van CurseForge (ca. 110 MB)..."
        $pz = $PackZip
        if (-not $pz) { $pz = Join-Path $work 'homestead.zip'; Save-Url $Pack.packUrl $pz }
        if ($installed) {
            # Andere pack-versie: scripts en datapacks van de oude versie weghalen, anders blijven
            # er recepten/items hangen die de server niet meer heeft. Onze eigen KubeJS-bestanden komen in stap 6 terug.
            Write-Step "Scripts van Homestead $installed opruimen..."
            foreach ($d in 'kubejs\startup_scripts', 'kubejs\server_scripts', 'kubejs\client_scripts', 'scripts', 'config\openloader') {
                $p = Join-Path $GameDir $d
                if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force }
            }
        }
        Write-Step "Configs, quests, resourcepacks en shaders uitpakken..."
        $z = [System.IO.Compression.ZipFile]::OpenRead($pz)
        $skipped = @()
        try {
            foreach ($e in $z.Entries) {
                if (-not $e.Name) { continue }                            # mappen
                if ($e.FullName -notlike 'overrides/*') { continue }
                $rel = $e.FullName.Substring('overrides/'.Length)
                if ($rel -like 'mods/*') { continue }                     # mods komen uit de repo
                $dst = Join-Path $GameDir ($rel -replace '/', '\')
                # Een shader in 2.0 heeft heel diepe mappen: bij een te lang pad dat ene bestand overslaan i.p.v. stoppen
                try {
                    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dst, $true)
                } catch { $skipped += $rel }
            }
        } finally { $z.Dispose() }
        if ($skipped) {
            Write-Warn "$($skipped.Count) bestand(en) overgeslagen (pad te lang), bv. $($skipped[0])"
            Write-Warn "Niet erg als het om een shader gaat; anders: stuur een screenshot naar de beheerder."
        }
        Write-Utf8 $marker $Pack.packVersion
    } else {
        Write-Step "Homestead $($Pack.packVersion) staat er al (configs blijven zoals ze zijn)."
    }

    foreach ($x in $Pack.extras) {
        $dir = Join-Path $GameDir $x.dir
        $dst = Join-Path $dir $x.file
        if (Test-Path -LiteralPath $dst) { continue }
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "    $($x.dir)\$($x.file) downloaden..."
        try { Save-Url $x.url $dst } catch { Write-Warn "Kon $($x.file) niet downloaden (niet erg, alleen een resource/shaderpack)." }
    }

    # --- 5. Mods synchroniseren ----------------------------------------------
    # Eerst performance-wijzigingen aan de mods terugdraaien, dan synchroniseren, daarna de modus opnieuw toepassen.
    if ($PrevMode -eq 'performance') { Restore-PerfMods $GameDir }
    $state = Get-StateDir $GameDir
    $perfSrc = Join-Path $RepoRoot 'performance'
    if (Test-Path -LiteralPath $perfSrc) {
        New-Item -ItemType Directory -Force -Path $state | Out-Null
        Copy-Item -LiteralPath (Join-Path $perfSrc 'remove.txt') -Destination (Join-Path $state 'remove.txt') -Force
        Copy-Item -LiteralPath (Join-Path $perfSrc 'options.txt') -Destination (Join-Path $state 'perf-options.txt') -Force
        $pm = Join-Path $state 'perf-mods'
        if (Test-Path -LiteralPath $pm) { Remove-Item -LiteralPath $pm -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $pm | Out-Null
        Get-ChildItem -LiteralPath (Join-Path $perfSrc 'mods') -Filter *.jar | Copy-Item -Destination $pm -Force
    }

    Write-Step "Mods synchroniseren..."
    $SrcDir  = Join-Path $RepoRoot 'mods'
    $ModsDir = Join-Path $GameDir 'mods'
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    $backupDir = Join-Path $GameDir ("mods-backup\" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $src  = @{}; Get-ChildItem -LiteralPath $SrcDir -Filter *.jar | ForEach-Object { $src[$_.Name] = $_ }
    $dest = @{}; Get-ChildItem -LiteralPath $ModsDir -Filter *.jar | ForEach-Object { $dest[$_.Name] = $_ }

    function Backup-File($file) {
        if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        Move-Item -LiteralPath $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force
    }

    $removed = 0; $added = 0; $updated = 0; $same = 0
    foreach ($name in @($dest.Keys)) {
        if (-not $src.ContainsKey($name)) { Backup-File $dest[$name]; $removed++ }
    }
    foreach ($name in $src.Keys) {
        $s = $src[$name]
        if ($dest.ContainsKey($name)) {
            $d = $dest[$name]
            if ($d.Length -eq $s.Length -and
                (Get-FileHash -LiteralPath $d.FullName -Algorithm SHA1).Hash -eq (Get-FileHash -LiteralPath $s.FullName -Algorithm SHA1).Hash) {
                $same++; continue
            }
            Backup-File $d; $updated++
        } else { $added++ }
        Copy-Item -LiteralPath $s.FullName -Destination (Join-Path $ModsDir $name) -Force
    }

    # --- 6. Gedeelde bestanden (KubeJS-items + textures) ---------------------
    $sharedDir = Join-Path $RepoRoot 'shared'
    if (Test-Path -LiteralPath $sharedDir) {
        Get-ChildItem -LiteralPath $sharedDir -Recurse -File | ForEach-Object {
            $dst = Join-Path $GameDir $_.FullName.Substring($sharedDir.Length).TrimStart('\', '/')
            New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
        }
    }

    # --- 6b. Modus toepassen --------------------------------------------------
    if ($Mode -eq 'performance') {
        Write-Step "Performance-modus toepassen..."
        Apply-PerfMods $GameDir
        if ($PrevMode -ne 'performance') { Apply-PerfOptions $GameDir }   # eigen bijregelingen niet elke update overschrijven
    } elseif ($PrevMode -eq 'performance') {
        Write-Step "Terug naar normale modus..."
        Restore-Options $GameDir
    }
    Set-ModeMarker $GameDir $Mode
    Register-Install $GameDir

    # --- 7. Server in de serverlijst -----------------------------------------
    $serversDat = Join-Path $GameDir 'servers.dat'
    if (-not (Test-Path -LiteralPath $serversDat)) {
        # Minimale NBT: { servers: [ { name: "...", ip: "..." } ] }
        $ms = New-Object IO.MemoryStream
        $bw = New-Object IO.BinaryWriter($ms)
        function W-Short([int]$v) { $bw.Write([byte](($v -shr 8) -band 0xFF)); $bw.Write([byte]($v -band 0xFF)) }
        function W-Int([int]$v) { foreach ($sh in 24, 16, 8, 0) { $bw.Write([byte](($v -shr $sh) -band 0xFF)) } }
        function W-Str([string]$s) { $b = [Text.Encoding]::UTF8.GetBytes($s); W-Short $b.Length; $bw.Write($b) }
        $bw.Write([byte]10); W-Str ''                       # root compound
        $bw.Write([byte]9);  W-Str 'servers'                # list
        $bw.Write([byte]10); W-Int 1                        # 1 compound
        $bw.Write([byte]8);  W-Str 'name'; W-Str $Pack.name
        $bw.Write([byte]8);  W-Str 'ip';   W-Str $Pack.server
        $bw.Write([byte]0)                                  # einde server-compound
        $bw.Write([byte]0)                                  # einde root
        $bw.Flush(); [IO.File]::WriteAllBytes($serversDat, $ms.ToArray()); $bw.Dispose()
        Write-Host "    Server '$($Pack.name)' toegevoegd aan je serverlijst."
    }

    # --- Klaar ----------------------------------------------------------------
    Write-Host ""
    Write-Host "Klaar!" -ForegroundColor Green
    Write-Host "  Mods: $($src.Count)  (nieuw $added, bijgewerkt $updated, ongewijzigd $same, weggehaald $removed)"
    if ($removed + $updated -gt 0) { Write-Host "  Oude mods staan in: $backupDir" }
    if ($Mode -eq 'performance') { Write-Host "  Modus: PERFORMANCE (uitzetten: 'Performance uit.cmd')" }
    else { Write-Host "  Modus: normaal (laptop? 'Performance aan.cmd')" }
    switch ($Launcher) {
        'official' { Write-Host "  Open de Minecraft Launcher, kies het profiel 'Homestead School' en druk op Spelen." }
        'prism'    { Write-Host "  Open Prism Launcher en start de instance 'Homestead School'." }
        'folder'   { Write-Host "  Start je instance (Minecraft $($Pack.minecraft) + Fabric $($Pack.fabricLoader))." }
    }
    Write-Host "  De eerste keer opstarten duurt een paar minuten. Join daarna '$($Pack.name)' in Multiplayer."
    Stop-WithPause 0
}
catch {
    Write-Host ""
    Write-Host "Er ging iets mis: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Maak een screenshot van dit venster en stuur het naar de beheerder."
    Stop-WithPause 1
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
