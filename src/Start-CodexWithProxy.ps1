[CmdletBinding()]
param(
    [string]$Proxy,
    [ValidateRange(0, 300)]
    [int]$WaitSeconds = 60,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$script:LogFile = Join-Path $env:LOCALAPPDATA 'CodexProxyLauncher\launcher.log'

function Write-LauncherLog {
    param([string]$Message)
    $directory = Split-Path -Parent $script:LogFile
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Add-Content -LiteralPath $script:LogFile -Encoding UTF8
}

function Show-LauncherError {
    param([string]$Message)
    Write-LauncherLog "ERROR: $Message"
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($Message, 'Codex Proxy Launcher', 'OK', 'Error') | Out-Null
}

function ConvertTo-ProxyUri {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $candidate = $Value.Trim()
    if ($candidate -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        $candidate = "http://$candidate"
    }
    try {
        $uri = [Uri]$candidate
        if (-not $uri.Host -or $uri.Port -le 0) { return $null }
        return $uri.AbsoluteUri.TrimEnd('/')
    } catch {
        return $null
    }
}

function Get-SystemProxyCandidates {
    $results = New-Object System.Collections.Generic.List[string]
    try {
        $settings = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        if ($settings.ProxyEnable -eq 1 -and $settings.ProxyServer) {
            $raw = [string]$settings.ProxyServer
            if ($raw -match '=') {
                $map = @{}
                foreach ($part in ($raw -split ';')) {
                    if ($part -match '^\s*([^=]+)=(.+)$') { $map[$matches[1].ToLowerInvariant()] = $matches[2] }
                }
                foreach ($key in @('https', 'http', 'socks', 'socks5')) {
                    if ($map.ContainsKey($key)) {
                        $scheme = if ($key -like 'socks*') { 'socks5' } else { 'http' }
                        $results.Add("${scheme}://$($map[$key])")
                    }
                }
            } else {
                $results.Add($raw)
            }
        }
    } catch {
        Write-LauncherLog "Could not read Windows proxy settings: $($_.Exception.Message)"
    }
    return $results
}

function Get-ProxyCandidates {
    $values = New-Object System.Collections.Generic.List[string]
    if ($Proxy) { $values.Add($Proxy) }
    foreach ($name in @('HTTPS_PROXY', 'HTTP_PROXY', 'ALL_PROXY')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'Process')
        if ($value) { $values.Add($value) }
    }
    foreach ($value in (Get-SystemProxyCandidates)) { $values.Add($value) }
    foreach ($value in @('127.0.0.1:7890', '127.0.0.1:7897', '127.0.0.1:10809', '127.0.0.1:10808')) {
        $values.Add($value)
    }

    $seen = @{}
    foreach ($value in $values) {
        $uri = ConvertTo-ProxyUri $value
        if ($uri -and -not $seen.ContainsKey($uri)) {
            $seen[$uri] = $true
            $uri
        }
    }
}

function Test-ProxyPort {
    param([string]$ProxyUri)
    $uri = [Uri]$ProxyUri
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($uri.Host, $uri.Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(800)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Test-ProxyRoute {
    param([string]$ProxyUri)
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) { return Test-ProxyPort $ProxyUri }
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'SilentlyContinue'
        & $curl.Source --silent --output NUL --connect-timeout 5 --max-time 10 --proxy $ProxyUri 'https://chatgpt.com/' 2>$null
        $curlExitCode = $LASTEXITCODE
        return ($curlExitCode -eq 0)
    } finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Resolve-WorkingProxy {
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    do {
        foreach ($candidate in (Get-ProxyCandidates)) {
            if ((Test-ProxyPort $candidate) -and (Test-ProxyRoute $candidate)) {
                return $candidate
            }
        }
        if ((Get-Date) -ge $deadline) { break }
        Start-Sleep -Milliseconds 1000
    } while ($true)
    return $null
}

function Get-CodexExecutable {
    $package = Get-AppxPackage -Name 'OpenAI.Codex' | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $package) { throw 'Codex Windows app is not installed for this user.' }
    $path = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
    if (-not (Test-Path -LiteralPath $path)) { throw "Codex executable was not found at $path" }
    return $path
}

try {
    $workingProxy = Resolve-WorkingProxy
    if (-not $workingProxy) {
        throw "No working local proxy was found within $WaitSeconds seconds. Start your proxy app, then try again."
    }

    $exe = Get-CodexExecutable
    if ($ValidateOnly) {
        [pscustomobject]@{
            Success = $true
            Proxy = $workingProxy
            CodexExecutable = $exe
        }
        return
    }

    $running = Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.ExecutablePath -match 'OpenAI\.Codex_' }
    if ($running) {
        throw 'Codex is already running. Fully exit Codex from the system tray, then launch it from the proxy shortcut.'
    }

    $env:HTTP_PROXY = $workingProxy
    $env:HTTPS_PROXY = $workingProxy
    $env:ALL_PROXY = $workingProxy
    $env:NO_PROXY = 'localhost,127.0.0.1,::1'

    Write-LauncherLog "Launching Codex with proxy $workingProxy"
    Start-Process -FilePath $exe -ArgumentList @(
        "--proxy-server=$workingProxy",
        '--proxy-bypass-list=localhost;127.0.0.1;::1'
    )
} catch {
    Show-LauncherError $_.Exception.Message
    exit 1
}
