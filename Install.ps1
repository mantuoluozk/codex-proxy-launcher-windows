[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts\enable-system-proxy.ps1')
& (Join-Path $PSScriptRoot 'scripts\check-readiness.ps1') | Format-List
