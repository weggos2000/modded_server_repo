<#
  Bouwt HomesteadSchool-Installer.zip (Installeren.cmd + install.ps1 + LEESMIJ.txt) in de root van de repo.
  Draai dit na elke wijziging aan install.ps1:   powershell -ExecutionPolicy Bypass -File tools\build-installer.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path $PSScriptRoot -Parent
$out  = Join-Path $root 'HomesteadSchool-Installer.zip'
$files = @(
    @{ Src = Join-Path $root 'installer\Installeren.cmd'; Name = 'HomesteadSchool-Installer/Installeren.cmd' },
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
