[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$codexHome = Join-Path $env:USERPROFILE '.codex'
$configPath = Join-Path $codexHome 'config.toml'

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

$internetSettings = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$codexCli = Find-CodexCli
$featureSupported = $false
$featureEnabled = $false
if ($codexCli) {
    $featureLine = & $codexCli features list 2>&1 | Select-String -Pattern '^respect_system_proxy\s+' | Select-Object -First 1
    $featureSupported = $null -ne $featureLine
    $featureEnabled = $featureSupported -and $featureLine.Line -match '\strue\s*$'
}

$mainProcess = Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -match 'OpenAI\.Codex_' -and $_.CommandLine -notmatch '--type=' } |
    Select-Object -First 1

$processStart = $null
if ($mainProcess) {
    $processStart = (Get-Process -Id $mainProcess.ProcessId).StartTime
}
$configWrite = if (Test-Path -LiteralPath $configPath) { (Get-Item -LiteralPath $configPath).LastWriteTime } else { $null }
$restartRequired = $null -ne $processStart -and $null -ne $configWrite -and $configWrite -gt $processStart

[pscustomobject]@{
    WindowsProxyEnabled = $internetSettings.ProxyEnable -eq 1
    WindowsProxyServer = [string]$internetSettings.ProxyServer
    FeatureSupported = $featureSupported
    FeatureEnabled = $featureEnabled
    CodexRunning = $null -ne $mainProcess
    CodexProcessStart = $processStart
    ConfigLastWrite = $configWrite
    RestartRequired = $restartRequired
    ReadyAfterRestart = ($internetSettings.ProxyEnable -eq 1) -and $featureEnabled
}
