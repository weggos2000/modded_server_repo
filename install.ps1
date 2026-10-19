<#
  Homestead School - mods synchroniseren (Windows)

  Zet de mods-map van je Homestead-instance exact gelijk aan de mods/ map in deze repo:
    - nieuwe en gewijzigde mods worden gekopieerd
    - mods die niet (meer) in de repo staan worden verplaatst naar een backup-map
  Er wordt dus nooit iets definitief verwijderd.

  Gebruik (zie README):
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/OWNER/REPO/main/install.ps1')))"

  Optioneel zelf het pad opgeven:
    ... -Command "& ([scriptblock]::Create((irm '<url>'))) -InstancePath 'C:\pad\naar\instance'"
#>
param(
    [string]$InstancePath,
    [string]$SourceDir    # optioneel: lokale mods-map gebruiken i.p.v. downloaden (offline / testen)
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # maakt downloaden in PowerShell 5.1 veel sneller
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo   = 'OWNER/REPO'
$Branch = 'main'

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# --- 1. Instance zoeken ------------------------------------------------------
function Find-Instances {
    $roots = @(
        "$env:USERPROFILE\curseforge\minecraft\Instances",
        "$env:APPDATA\PrismLauncher\instances",
        "$env:APPDATA\ModrinthApp\profiles"
    )
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Get-ChildItem -LiteralPath $root -Directory | Where-Object { $_.Name -like '*Homestead*' } | ForEach-Object {
            # Prism zet de game-bestanden in een submap "minecraft" of ".minecraft"
            $dir = $_.FullName
            foreach ($sub in 'minecraft', '.minecraft') {
                if (Test-Path -LiteralPath (Join-Path $dir $sub)) { $dir = Join-Path $dir $sub; break }
            }
            $dir
        }
    }
}

if (-not $InstancePath) {
    $found = @(Find-Instances)
    if ($found.Count -eq 1) {
        $InstancePath = $found[0]
    } elseif ($found.Count -gt 1) {
        Write-Host "Meerdere Homestead-instances gevonden:"
        for ($i = 0; $i -lt $found.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i + 1), $found[$i]) }
        $choice = Read-Host "Welke wil je gebruiken? (nummer)"
        $InstancePath = $found[[int]$choice - 1]
    } else {
        Write-Host "Geen Homestead-instance gevonden in CurseForge, Prism of Modrinth." -ForegroundColor Yellow
        $InstancePath = Read-Host "Plak het pad naar je instance-map (de map waar 'mods' in staat)"
    }
}

$InstancePath = $InstancePath.Trim('"', ' ')
if ((Split-Path $InstancePath -Leaf) -eq 'mods') { $InstancePath = Split-Path $InstancePath -Parent }
$ModsDir = Join-Path $InstancePath 'mods'
if (-not (Test-Path -LiteralPath $InstancePath)) { throw "Map bestaat niet: $InstancePath" }
if (-not (Test-Path -LiteralPath $ModsDir)) { New-Item -ItemType Directory -Path $ModsDir | Out-Null }
Write-Step "Instance: $InstancePath"

# --- 2. Minecraft mag niet draaien -------------------------------------------
if (Get-Process -Name javaw, java -ErrorAction SilentlyContinue) {
    Write-Host "Let op: er draait Java (Minecraft?). Sluit Minecraft eerst af." -ForegroundColor Yellow
    $go = Read-Host "Toch doorgaan? (j/n)"
    if ($go -notmatch '^[jJyY]') { return }
}

# --- 3. Repo downloaden ------------------------------------------------------
$work = Join-Path $env:TEMP ("homestead-mods-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    if ($SourceDir) {
        $SrcDir = $SourceDir
    } else {
        $zip = Join-Path $work 'repo.zip'
        Write-Step "Mods downloaden van github.com/$Repo (±570 MB, even geduld)..."
        Invoke-WebRequest -Uri "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" -OutFile $zip -UseBasicParsing

        Write-Step "Uitpakken..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $extract = Join-Path $work 'x'
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $extract)
        $SrcDir = Join-Path (Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1).FullName 'mods'
    }
    if (-not (Test-Path -LiteralPath $SrcDir)) { throw "Geen mods-map gevonden: $SrcDir" }

    # --- 4. Synchroniseren ---------------------------------------------------
    Write-Step "Synchroniseren..."
    $backupDir = Join-Path $InstancePath ("mods-backup\" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
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
        $target = Join-Path $ModsDir $name
        if ($dest.ContainsKey($name)) {
            $d = $dest[$name]
            if ($d.Length -eq $s.Length -and
                (Get-FileHash -LiteralPath $d.FullName -Algorithm SHA1).Hash -eq (Get-FileHash -LiteralPath $s.FullName -Algorithm SHA1).Hash) {
                $same++; continue
            }
            Backup-File $d; $updated++
        } else {
            $added++
        }
        Copy-Item -LiteralPath $s.FullName -Destination $target -Force
    }

    Write-Host ""
    Write-Host "Klaar! $($src.Count) mods in je mods-map." -ForegroundColor Green
    Write-Host "  nieuw: $added   bijgewerkt: $updated   ongewijzigd: $same   weggehaald: $removed"
    if ($removed + $updated -gt 0) { Write-Host "  Oude/weggehaalde mods staan in: $backupDir" }
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
