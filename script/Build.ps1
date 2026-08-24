# Build.ps1

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

# Instaleaza PS2EXE daca lipseste
if (-not (Get-Module -ListAvailable PS2EXE)) {
    Install-Module PS2EXE -Scope CurrentUser -Force
}

Import-Module PS2EXE

$Launcher = Join-Path $Root "_Launcher.ps1"
$OutputExe = Join-Path $Root "Defender Remover 13.exe"

# Fisiere care NU trebuie incluse
$Exclude = @(
    "Build.ps1",
    "_Launcher.ps1",
    "Script_Run.exe",
    "app_icon.ico"
)

$Files = Get-ChildItem -Recurse -File |
    Where-Object { $Exclude -notcontains $_.Name }

$Builder = New-Object System.Text.StringBuilder

$null = $Builder.AppendLine('$ErrorActionPreference = "Stop"')
$null = $Builder.AppendLine('$WorkDir = Join-Path $env:TEMP "Script_Run_Payload"')
$null = $Builder.AppendLine('if(Test-Path $WorkDir){Remove-Item $WorkDir -Recurse -Force}')
$null = $Builder.AppendLine('New-Item -ItemType Directory -Path $WorkDir | Out-Null')
$null = $Builder.AppendLine('$Files=@{}')

foreach($File in $Files){

    $Relative = Resolve-Path -Relative $File.FullName
    $Relative = $Relative.TrimStart(".\")
    $Relative = $Relative -replace "\\","/"

    $Bytes = [IO.File]::ReadAllBytes($File.FullName)
    $Base64 = [Convert]::ToBase64String($Bytes)

    $null = $Builder.AppendLine('$Files["' + $Relative + '"]="' + $Base64 + '"')
}

$Runtime = @'
foreach($item in $Files.GetEnumerator()){

    $dest = Join-Path $WorkDir ($item.Key -replace "/","\")
    $dir = Split-Path $dest -Parent

    if(!(Test-Path $dir)){
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    [IO.File]::WriteAllBytes(
        $dest,
        [Convert]::FromBase64String($item.Value)
    )
}

Set-Location $WorkDir

# Porneste scriptul principal
& "$WorkDir\Script_Run.ps1"

exit $LASTEXITCODE
'@

$null = $Builder.AppendLine($Runtime)

Set-Content -Path $Launcher -Value $Builder.ToString() -Encoding UTF8

Invoke-ps2exe `
    -InputFile $Launcher `
    -OutputFile $OutputExe `
    -Company "ionuttbara" `
    -Copyright "Gallery Inc" `
    -Description "Defender Remover" `
    -Product "Defender Remover" `
    -Version "13.0.0.0" `
    -IconFile "$Root\app_icon.ico" `
    -ConHost

Remove-Item $Launcher -Force

Write-Host ""
Write-Host "Build finalizat:"
Write-Host "  $OutputExe"