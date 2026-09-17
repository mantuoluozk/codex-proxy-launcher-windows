[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$codexHome = Join-Path $env:USERPROFILE '.codex'
$configPath = Join-Path $codexHome 'config.toml'
$backupPath = Join-Path $codexHome 'config.toml.codex-windows-system-proxy.bak'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false, $true)

if (Test-Path -LiteralPath $configPath) {
    $lines = @([System.IO.File]::ReadAllLines($configPath, $utf8NoBom) | Where-Object {
        $_ -notmatch '^\s*respect_system_proxy\s*='
    })
    [System.IO.File]::WriteAllLines($configPath, [string[]]$lines, $utf8NoBom)
}

if (Test-Path -LiteralPath $backupPath) {
    Remove-Item -LiteralPath $backupPath -Force
}

Write-Host 'Removed the Codex system-proxy setting.'
Write-Host 'No shortcuts, Windows proxy settings, or environment variables were changed.'
