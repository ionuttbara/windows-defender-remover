[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Enable', 'Disable')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'
$batchName = if ($Action -eq 'Enable') { 'Enable VBS.bat' } else { 'Disable VBS.bat' }
$batchPath = Join-Path $PSScriptRoot $batchName

if (-not (Test-Path -LiteralPath $batchPath -PathType Leaf)) {
    Write-Host "Required script not found: $batchPath" -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

$cmdExe = Join-Path $env:SystemRoot 'System32\cmd.exe'
$cmdArguments = "/d /c `"$batchPath`""

try {
    # The UAC prompt is shown here; the batch file itself runs in the elevated console.
    $process = Start-Process -FilePath $cmdExe -ArgumentList $cmdArguments -Verb RunAs -Wait -PassThru -ErrorAction Stop
    exit $process.ExitCode
}
catch {
    Write-Host "Unable to start the selected action: $_" -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}
