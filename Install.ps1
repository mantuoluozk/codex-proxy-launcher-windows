[CmdletBinding()]
param()

& (Join-Path $PSScriptRoot 'scripts\enable-system-proxy.ps1')
exit $LASTEXITCODE
