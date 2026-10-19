<#
  Zet de modlijst in README.md opnieuw (tussen de MODLIST-markers), op basis van de jars in mods/.
  Draai dit na elke wijziging in mods/:   powershell -ExecutionPolicy Bypass -File tools\update-modlist.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root       = Split-Path $PSScriptRoot -Parent
$modsDir    = Join-Path $root 'mods'
$readme     = Join-Path $root 'README.md'
$clientOnly = @(Get-Content -LiteralPath (Join-Path $root 'client-only.txt') -ErrorAction SilentlyContinue | Where-Object { $_.Trim() })

function Get-ModInfo($jar) {
    $info = @{ Name = $null; Version = $null }
    $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
    try {
        $entry = $zip.Entries | Where-Object { $_.FullName -in 'fabric.mod.json', 'quilt.mod.json' } | Select-Object -First 1
        if ($entry) {
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $text = $reader.ReadToEnd(); $reader.Close()
            # Regex i.p.v. ConvertFrom-Json: sommige mods hebben ongeldige JSON (commentaar, tabs in strings)
            if ($text -match '"name"\s*:\s*"((?:[^"\\]|\\.)*)"')    { $info.Name = [regex]::Unescape($Matches[1]) }
            if ($text -match '"version"\s*:\s*"((?:[^"\\]|\\.)*)"') { $info.Version = [regex]::Unescape($Matches[1]) }
        }
    } finally { $zip.Dispose() }
    if (-not $info.Name) { $info.Name = [IO.Path]::GetFileNameWithoutExtension($jar.Name) }
    if (-not $info.Version -or $info.Version -like '*${*') { $info.Version = '-' }
    $info
}

$rows = foreach ($jar in Get-ChildItem -LiteralPath $modsDir -Filter *.jar) {
    $i = Get-ModInfo $jar
    [pscustomobject]@{
        Name    = ($i.Name -replace '\|', '\|')
        Version = ($i.Version -replace '\|', '\|')
        File    = $jar.Name
        Client  = if ($clientOnly -contains $jar.Name) { 'ja' } else { '' }
    }
}
$rows = $rows | Sort-Object Name

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("**$($rows.Count) mods** ($(@($rows | Where-Object Client).Count) daarvan alleen voor de client).")
[void]$sb.AppendLine()
[void]$sb.AppendLine('| Mod | Versie | Bestand | Alleen client |')
[void]$sb.AppendLine('|---|---|---|---|')
foreach ($r in $rows) { [void]$sb.AppendLine("| $($r.Name) | $($r.Version) | ``$($r.File)`` | $($r.Client) |") }

$content = [IO.File]::ReadAllText($readme)
$pattern = '(?s)(<!-- MODLIST:START -->).*?(<!-- MODLIST:END -->)'
if ($content -notmatch $pattern) { throw "MODLIST-markers niet gevonden in README.md" }
$content = [regex]::Replace($content, $pattern, { param($m) $m.Groups[1].Value + "`r`n" + $sb.ToString() + $m.Groups[2].Value })
[IO.File]::WriteAllText($readme, $content, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "README.md bijgewerkt: $($rows.Count) mods."
