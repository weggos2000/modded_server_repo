<#
  Bouwt de installers in de root van de repo:
    HomesteadSchool-Installer.zip            (Windows: Installeren.cmd + install.ps1 + LEESMIJ.txt)
    HomesteadSchool-Installer-Linux-Mac.tar.gz (install.sh + install.py + .sh/.command-bestanden, uitvoerbaar)
  Draai dit na elke wijziging aan de installers:   powershell -ExecutionPolicy Bypass -File tools\build-installer.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path $PSScriptRoot -Parent

# --- Windows: zip ---------------------------------------------------------------
$out  = Join-Path $root 'HomesteadSchool-Installer.zip'
$files = @(
    @{ Src = Join-Path $root 'installer\Installeren.cmd'; Name = 'HomesteadSchool-Installer/Installeren.cmd' },
    @{ Src = Join-Path $root 'installer\Performance aan.cmd'; Name = 'HomesteadSchool-Installer/Performance aan.cmd' },
    @{ Src = Join-Path $root 'installer\Performance uit.cmd'; Name = 'HomesteadSchool-Installer/Performance uit.cmd' },
    @{ Src = Join-Path $root 'install.ps1';               Name = 'HomesteadSchool-Installer/install.ps1' },
    @{ Src = Join-Path $root 'installer\LEESMIJ.txt';     Name = 'HomesteadSchool-Installer/LEESMIJ.txt' }
)

if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
$zip = [System.IO.Compression.ZipFile]::Open($out, 'Create')
try {
    foreach ($f in $files) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.Src, $f.Name, 'Optimal') | Out-Null
    }
} finally { $zip.Dispose() }
Write-Host "Gemaakt: $out ($([math]::Round((Get-Item $out).Length / 1KB)) KB)"

# --- Linux / macOS: tar.gz (zip bewaart geen uitvoerrechten, tar wel) ------------
$unix = Join-Path $root 'installer\unix'
$tfiles = @(
    @{ Src = Join-Path $root 'install.sh'; Name = 'install.sh'; Exec = $true },
    @{ Src = Join-Path $root 'install.py'; Name = 'install.py'; Exec = $true }
)
Get-ChildItem -LiteralPath $unix -File | ForEach-Object {
    $tfiles += @{ Src = $_.FullName; Name = $_.Name; Exec = ($_.Extension -in '.sh', '.command') }
}

function Get-TarHeader([string]$name, [long]$size, [int]$mode, [long]$mtime) {
    # ustar-header van 512 bytes (namen < 100 tekens, alleen ASCII)
    $h = New-Object byte[] 512
    $put = { param($text, $off, $len) $b = [Text.Encoding]::ASCII.GetBytes($text); [Array]::Copy($b, 0, $h, $off, [math]::Min($b.Length, $len)) }
    & $put $name 0 100
    & $put ([Convert]::ToString($mode, 8).PadLeft(7, '0')) 100 7
    & $put '0000000' 108 7; & $put '0000000' 116 7                 # uid / gid
    & $put ([Convert]::ToString($size, 8).PadLeft(11, '0')) 124 11
    & $put ([Convert]::ToString($mtime, 8).PadLeft(11, '0')) 136 11
    & $put '        ' 148 8                                         # checksum-veld telt als spaties
    $h[156] = [byte][char]'0'                                       # gewoon bestand
    & $put 'ustar' 257 5; & $put '00' 263 2
    $sum = 0; foreach ($x in $h) { $sum += $x }
    & $put ([Convert]::ToString($sum, 8).PadLeft(6, '0')) 148 6; $h[154] = 0; $h[155] = 32
    $h
}

$tout = Join-Path $root 'HomesteadSchool-Installer-Linux-Mac.tar.gz'
if (Test-Path -LiteralPath $tout) { Remove-Item -LiteralPath $tout -Force }
$fs = [IO.File]::Create($tout)
$gz = New-Object IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Compress)
try {
    $mtime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 86400   # iets in het verleden: geen "time stamp in the future"
    foreach ($f in $tfiles) {
        # LF-regeleinden, anders weigert bash het script
        $text = [IO.File]::ReadAllText($f.Src) -replace "`r`n", "`n"
        $data = (New-Object Text.UTF8Encoding($false)).GetBytes($text)
        $hdr = Get-TarHeader "HomesteadSchool-Installer/$($f.Name)" $data.Length $(if ($f.Exec) { 0x1ED } else { 0x1A4 }) $mtime
        $gz.Write($hdr, 0, 512); $gz.Write($data, 0, $data.Length)
        $pad = (512 - ($data.Length % 512)) % 512
        if ($pad) { $gz.Write((New-Object byte[] $pad), 0, $pad) }
    }
    $gz.Write((New-Object byte[] 1024), 0, 1024)                    # twee lege blokken = einde
} finally { $gz.Dispose(); $fs.Dispose() }
Write-Host "Gemaakt: $tout ($([math]::Round((Get-Item $tout).Length / 1KB)) KB)"
