[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$codexHome = Join-Path $env:USERPROFILE '.codex'
$configPath = Join-Path $codexHome 'config.toml'
$backupPath = Join-Path $codexHome 'config.toml.codex-windows-system-proxy.bak'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false, $true)

function Find-CodexCli {
    $command = Get-Command codex.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $binRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if (Test-Path -LiteralPath $binRoot) {
        $candidate = Get-ChildItem -LiteralPath $binRoot -Filter 'codex.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($candidate) { return $candidate.FullName }
    }
    return $null
}

if ($env:OS -ne 'Windows_NT') {
    throw 'This skill supports Windows only.'
}

$codexCli = Find-CodexCli
if (-not $codexCli) {
    throw 'Codex CLI was not found. Install or update the Windows Codex app first.'
}

$featureOutput = & $codexCli features list 2>&1 | Out-String
if ($featureOutput -notmatch '(?m)^respect_system_proxy\s+') {
    throw 'This Codex version does not support features.respect_system_proxy. Update Codex and run this script again.'
}

New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
if (Test-Path -LiteralPath $configPath) {
    if (-not (Test-Path -LiteralPath $backupPath)) {
        Copy-Item -LiteralPath $configPath -Destination $backupPath
    }
    $lines = [System.Collections.ArrayList]@([System.IO.File]::ReadAllLines($configPath, $utf8NoBom))
} else {
    $lines = New-Object System.Collections.ArrayList
}
$configChanged = $false

$featuresIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*\[features\]\s*$') {
        $featuresIndex = $i
        break
    }
}

if ($featuresIndex -lt 0) {
    if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
        [void]$lines.Add('')
    }
    [void]$lines.Add('[features]')
    [void]$lines.Add('respect_system_proxy = true')
    $configChanged = $true
} else {
    $nextSection = $lines.Count
    for ($i = $featuresIndex + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[') {
            $nextSection = $i
            break
        }
    }

    $settingIndex = -1
    for ($i = $featuresIndex + 1; $i -lt $nextSection; $i++) {
        if ($lines[$i] -match '^\s*respect_system_proxy\s*=') {
            $settingIndex = $i
            break
        }
    }

    if ($settingIndex -ge 0) {
        if ($lines[$settingIndex] -notmatch '^\s*respect_system_proxy\s*=\s*true\s*$') {
            $lines[$settingIndex] = 'respect_system_proxy = true'
            $configChanged = $true
        }
    } else {
        $lines.Insert($nextSection, 'respect_system_proxy = true')
        $configChanged = $true
    }
}

if ($configChanged) {
    [System.IO.File]::WriteAllLines($configPath, [string[]]$lines, $utf8NoBom)
}

$enabledOutput = & $codexCli features list 2>&1 | Out-String
if ($enabledOutput -notmatch '(?m)^respect_system_proxy\s+.+\strue\s*$') {
    throw 'The setting was written, but Codex did not report it as enabled.'
}

Write-Host 'Enabled Codex native system-proxy support.'
Write-Host 'Your original desktop, Start menu, and taskbar Codex entries will work normally.'
Write-Host 'Fully exit Codex once, then reopen it.'
