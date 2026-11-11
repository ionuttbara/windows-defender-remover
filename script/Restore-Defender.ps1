$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DefenderBackupRestore.ps1')
Invoke-DefenderRestore
