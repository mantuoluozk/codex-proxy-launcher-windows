[CmdletBinding()]
param()

& (Join-Path $PSScriptRoot 'scripts\disable-system-proxy.ps1')
exit $LASTEXITCODE
