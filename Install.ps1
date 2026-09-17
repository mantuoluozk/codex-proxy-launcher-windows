[CmdletBinding()]
param(
    [string]$Proxy,
    [switch]$ReplaceDesktopShortcut
)

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'CodexProxyLauncher'
$sourceDir = Join-Path $PSScriptRoot 'src'
$launcherSource = Join-Path $sourceDir 'Start-CodexWithProxy.ps1'
$uninstallerSource = Join-Path $PSScriptRoot 'Uninstall.ps1'

if (-not (Test-Path -LiteralPath $launcherSource)) {
    throw "Missing launcher: $launcherSource"
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Copy-Item -LiteralPath $launcherSource -Destination (Join-Path $installDir 'Start-CodexWithProxy.ps1') -Force
Copy-Item -LiteralPath $uninstallerSource -Destination (Join-Path $installDir 'Uninstall.ps1') -Force

$package = Get-AppxPackage -Name 'OpenAI.Codex' | Sort-Object Version -Descending | Select-Object -First 1
if (-not $package) { throw 'Codex Windows app is not installed for this user.' }
$iconPath = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
$powershell = Join-Path $PSHOME 'powershell.exe'
$launcher = Join-Path $installDir 'Start-CodexWithProxy.ps1'
$proxyArgument = if ($Proxy) { " -Proxy `"$Proxy`"" } else { '' }
$arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`"$proxyArgument"

function New-LauncherShortcut {
    param([string]$Path)
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $powershell
    $shortcut.Arguments = $arguments
    $shortcut.WorkingDirectory = $env:USERPROFILE
    $shortcut.IconLocation = "$iconPath,0"
    $shortcut.Description = 'Launch Codex with an isolated, auto-detected local proxy'
    $shortcut.Save()
}

$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
New-LauncherShortcut (Join-Path $startMenuDir 'Codex (Proxy).lnk')

$desktop = [Environment]::GetFolderPath('Desktop')
$desktopProxyLink = Join-Path $desktop 'Codex (Proxy).lnk'
New-LauncherShortcut $desktopProxyLink

if ($ReplaceDesktopShortcut) {
    $defaultLink = Join-Path $desktop 'Codex.lnk'
    $backupLink = Join-Path $desktop 'Codex (Original).lnk'
    if ((Test-Path -LiteralPath $defaultLink) -and -not (Test-Path -LiteralPath $backupLink)) {
        Move-Item -LiteralPath $defaultLink -Destination $backupLink
    }
    New-LauncherShortcut $defaultLink
}

Write-Host "Installed Codex Proxy Launcher to $installDir"
Write-Host 'Use the Codex (Proxy) shortcut. It detects Windows proxy settings and common local ports each time.'
