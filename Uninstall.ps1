[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

foreach ($path in @(
    (Join-Path $desktop 'Codex (Proxy).lnk'),
    (Join-Path $startMenuDir 'Codex (Proxy).lnk')
)) {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}

$defaultLink = Join-Path $desktop 'Codex.lnk'
$backupLink = Join-Path $desktop 'Codex (Original).lnk'
if (Test-Path -LiteralPath $backupLink) {
    if (Test-Path -LiteralPath $defaultLink) { Remove-Item -LiteralPath $defaultLink -Force }
    Move-Item -LiteralPath $backupLink -Destination $defaultLink
}

$installDir = Join-Path $env:LOCALAPPDATA 'CodexProxyLauncher'
if (Test-Path -LiteralPath $installDir) {
    Remove-Item -LiteralPath $installDir -Recurse -Force
}

Write-Host 'Codex Proxy Launcher was removed. System proxy settings were not changed.'
