<#
  Homestead School - alles-in-een installer / updater (Windows)

  Installeert of updatet in een keer:
    - Fabric voor Minecraft 1.20.1
    - een profiel/instance "Homestead School" (gewone Minecraft Launcher of Prism Launcher)
    - de Homestead 1.3.7-pack (configs, quests, resourcepacks, shaders), rechtstreeks van CurseForge
    - de mods + KubeJS-bestanden uit deze repo (exact gelijk aan de server)
    - de server in je serverlijst

  Gebruik (zie README): download HomesteadSchool-Installer.zip, pak uit en dubbelklik Installeren.cmd

  Opties (meestal niet nodig):
    -Launcher official|prism|folder   launcher kiezen zonder menu
    -InstancePath <map>               (bij "folder") de game-map van je instance
#>
param(
    [ValidateSet('', 'official', 'prism', 'folder')]
    [string]$Launcher = '',
    [string]$InstancePath,
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
$InstallerVersion = 2   # verhogen bij elke wijziging aan dit script (ook in pack.json zetten)

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }
function Save-Url($url, $dest) { Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -UserAgent 'homestead-school-installer' }
function Write-Utf8($path, $text) { [IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false))) }

function Stop-WithPause($code) {
    if (-not $NoPause) { Write-Host ""; Read-Host "Druk op Enter om af te sluiten" | Out-Null }
    exit $code
}

$work = Join-Path $env:TEMP ("homestead-school-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null

try {
    Write-Host ""
    Write-Host "  Homestead School installer" -ForegroundColor Green
    Write-Host ""

    # --- 1. Repo ophalen (mods, KubeJS-bestanden, pack.json) ------------------
    if ($SourceDir) {
        $RepoRoot = $SourceDir
    } else {
        Write-Step "Bestanden downloaden van github.com/$Repo (ca. 570 MB, even geduld)..."
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
        Write-Step "Configs, quests, resourcepacks en shaders uitpakken..."
        $z = [System.IO.Compression.ZipFile]::OpenRead($pz)
        try {
            foreach ($e in $z.Entries) {
                if (-not $e.Name) { continue }                            # mappen
                if ($e.FullName -notlike 'overrides/*') { continue }
                $rel = $e.FullName.Substring('overrides/'.Length)
                if ($rel -like 'mods/*') { continue }                     # mods komen uit de repo
                $dst = Join-Path $GameDir ($rel -replace '/', '\')
                New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dst, $true)
            }
        } finally { $z.Dispose() }
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
