# Defender Remover 13.1 - backup and restore engine
# Compatible with Windows PowerShell 5.1.

$script:DefenderBackupRoot = Join-Path $env:ProgramData 'Gallery Inc\Defender Remover\schemas'
$script:DefenderEngineRoot = Split-Path -Parent $PSCommandPath

function Test-DefenderAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-DefenderRuntimeProcessSnapshot {
    # Read-only inventory. This deliberately does not stop, suspend, open,
    # or modify the security token of Microsoft Defender processes.
    $processNames = @('MsMpEng', 'NisSrv', 'SecurityHealthService')
    $snapshot = @()
    foreach ($processName in $processNames) {
        foreach ($process in @(Get-Process -Name $processName -ErrorAction SilentlyContinue)) {
            $snapshot += [pscustomobject]@{
                Name = [string]$process.ProcessName
                Pid = [int]$process.Id
            }
        }
    }
    return @($snapshot)
}

function Get-DefenderSystemExe {
    param([Parameter(Mandatory = $true)][string]$Name)
    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
        $sysnativePath = Join-Path $env:windir ("Sysnative\{0}" -f $Name)
        if (Test-Path -LiteralPath $sysnativePath) { return $sysnativePath }
    }
    return (Join-Path $env:windir ("System32\{0}" -f $Name))
}

function Get-DefenderRegExe {
    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
        $sysnative = Join-Path $env:windir 'Sysnative\reg.exe'
        if (Test-Path -LiteralPath $sysnative) { return $sysnative }
    }
    return (Join-Path $env:windir 'System32\reg.exe')
}

function Get-DefenderRegistryPathParts {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = $Path.Trim().TrimStart('\')
    $hiveName = $null
    $subKey = ''

    if ($normalized -match '^(?:HKLM|HKEY_LOCAL_MACHINE)(?:\\(.*))?$') {
        $hiveName = 'LocalMachine'; $subKey = [string]$Matches[1]
    } elseif ($normalized -match '^(?:HKCU|HKEY_CURRENT_USER)(?:\\(.*))?$') {
        $hiveName = 'CurrentUser'; $subKey = [string]$Matches[1]
    } elseif ($normalized -match '^(?:HKCR|HKEY_CLASSES_ROOT)(?:\\(.*))?$') {
        $hiveName = 'ClassesRoot'; $subKey = [string]$Matches[1]
    } elseif ($normalized -match '^(?:HKU|HKEY_USERS)(?:\\(.*))?$') {
        $hiveName = 'Users'; $subKey = [string]$Matches[1]
    } elseif ($normalized -match '^(?:HKCC|HKEY_CURRENT_CONFIG)(?:\\(.*))?$') {
        $hiveName = 'CurrentConfig'; $subKey = [string]$Matches[1]
    } else {
        throw "Unsupported registry hive: $Path"
    }

    $hive = [Enum]::Parse([Microsoft.Win32.RegistryHive], $hiveName)
    return [pscustomobject]@{
        Hive = $hive
        SubKey = $subKey
        Path = $normalized
    }
}

function Open-DefenderRegistryBaseKey {
    param([Parameter(Mandatory = $true)]$PathParts)

    $view = [Microsoft.Win32.RegistryView]::Default
    if ([Environment]::Is64BitOperatingSystem) { $view = [Microsoft.Win32.RegistryView]::Registry64 }
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($PathParts.Hive, $view)
}

function Test-DefenderRegistryKeyExists {
    param([Parameter(Mandatory = $true)][string]$KeyPath)

    $parts = Get-DefenderRegistryPathParts -Path $KeyPath
    $base = $null
    $key = $null
    try {
        $base = Open-DefenderRegistryBaseKey -PathParts $parts
        if ([string]::IsNullOrEmpty($parts.SubKey)) { return $true }
        $key = $base.OpenSubKey($parts.SubKey, $false)
        return ($null -ne $key)
    } finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $base) { $base.Dispose() }
    }
}

function Get-DefenderRegistryValueSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$ValueName
    )

    $parts = Get-DefenderRegistryPathParts -Path $KeyPath
    $base = $null
    $key = $null
    try {
        $base = Open-DefenderRegistryBaseKey -PathParts $parts
        if ([string]::IsNullOrEmpty($parts.SubKey)) { $key = $base } else { $key = $base.OpenSubKey($parts.SubKey, $false) }
        if ($null -eq $key) {
            return [pscustomobject]@{ KeyExists = $false; Present = $false; Kind = $null; Data = $null }
        }

        $names = @($key.GetValueNames())
        $present = $false
        foreach ($name in $names) {
            if ([string]::Equals([string]$name, $ValueName, [StringComparison]::OrdinalIgnoreCase)) { $present = $true; break }
        }
        if (-not $present) {
            return [pscustomobject]@{ KeyExists = $true; Present = $false; Kind = $null; Data = $null }
        }

        $kind = $key.GetValueKind($ValueName)
        $raw = $key.GetValue($ValueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $data = $null
        switch ($kind.ToString()) {
            'String'       { $data = [string]$raw }
            'ExpandString' { $data = [string]$raw }
            'DWord'        { $data = [long]([int]$raw) }
            'QWord'        { $data = [long]$raw }
            'MultiString'  { $data = @([string[]]$raw) }
            'Binary'       { $data = [Convert]::ToBase64String([byte[]]$raw) }
            'None'         { $data = [Convert]::ToBase64String([byte[]]$raw) }
            default        { throw "Unsupported registry value kind '$kind' at $KeyPath\$ValueName" }
        }
        return [pscustomobject]@{ KeyExists = $true; Present = $true; Kind = $kind.ToString(); Data = $data }
    } finally {
        if (($null -ne $key) -and ($null -ne $base) -and -not [object]::ReferenceEquals($key, $base)) { $key.Dispose() }
        if ($null -ne $base) { $base.Dispose() }
    }
}

function Test-DefenderRegistrySnapshotsEqual {
    param($Left, $Right)
    if ([bool]$Left.KeyExists -ne [bool]$Right.KeyExists) { return $false }
    if ([bool]$Left.Present -ne [bool]$Right.Present) { return $false }
    if (-not $Left.Present) { return $true }
    if ([string]$Left.Kind -ne [string]$Right.Kind) { return $false }
    $leftJson = ConvertTo-Json -InputObject $Left.Data -Depth 12 -Compress
    $rightJson = ConvertTo-Json -InputObject $Right.Data -Depth 12 -Compress
    return ($leftJson -ceq $rightJson)
}

function Set-DefenderRegistryValueSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$ValueName,
        [Parameter(Mandatory = $true)]$Snapshot
    )

    $parts = Get-DefenderRegistryPathParts -Path $KeyPath
    $base = $null
    $key = $null
    try {
        $base = Open-DefenderRegistryBaseKey -PathParts $parts
        if (-not $Snapshot.Present) {
            if (-not $Snapshot.KeyExists -and -not [string]::IsNullOrEmpty($parts.SubKey)) {
                $null = & (Get-DefenderRegExe) delete $KeyPath /f 2>$null
                return
            }
            if ([string]::IsNullOrEmpty($parts.SubKey)) { $key = $base } else { $key = $base.OpenSubKey($parts.SubKey, $true) }
            if ($null -ne $key) { $key.DeleteValue($ValueName, $false) }
            return
        }

        if ([string]::IsNullOrEmpty($parts.SubKey)) { $key = $base } else { $key = $base.CreateSubKey($parts.SubKey) }
        if ($null -eq $key) { throw "Could not open registry key for restore: $KeyPath" }
        $kind = [Enum]::Parse([Microsoft.Win32.RegistryValueKind], [string]$Snapshot.Kind)
        $data = $Snapshot.Data
        switch ([string]$Snapshot.Kind) {
            'Binary'      { $data = [Convert]::FromBase64String([string]$Snapshot.Data) }
            'None'        { $data = [Convert]::FromBase64String([string]$Snapshot.Data) }
            'DWord'       { $data = [int]([long]$Snapshot.Data) }
            'QWord'       { $data = [long]$Snapshot.Data }
            'MultiString' { $data = [string[]]@($Snapshot.Data) }
        }
        $key.SetValue($ValueName, $data, $kind)
    } finally {
        if (($null -ne $key) -and ($null -ne $base) -and -not [object]::ReferenceEquals($key, $base)) { $key.Dispose() }
        if ($null -ne $base) { $base.Dispose() }
    }
}

function Export-DefenderRegistryKey {
    param([string]$KeyPath, [string]$Destination)
    $regExe = Get-DefenderRegExe
    $null = & $regExe export $KeyPath $Destination /y 2>$null
    return (($LASTEXITCODE -eq 0) -and (Test-Path -LiteralPath $Destination -PathType Leaf))
}

function Import-DefenderRegistryChunk {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$UsePowerRun
    )

    $regExe = Get-DefenderRegExe
    if ($UsePowerRun) {
        $powerRun = Join-Path $script:DefenderEngineRoot 'PowerRun.exe'
        if (Test-Path -LiteralPath $powerRun -PathType Leaf) {
            try {
                # PowerRun executes as SYSTEM / TrustedInstaller. Use it only for
                # machine-hive sections, never for HKEY_CURRENT_USER.
                $arguments = '"{0}" import "{1}"' -f $regExe, $Path
                $process = Start-Process -FilePath $powerRun -ArgumentList $arguments -WorkingDirectory $script:DefenderEngineRoot -Wait -PassThru -ErrorAction Stop
                if ($process.ExitCode -eq 0) { return $true }
            } catch { }
        }
    }

    # This process is elevated but remains in the interactive user's profile,
    # so HKCU and the merged HKCR view address the correct user context.
    $null = & $regExe import $Path 2>&1
    return ($LASTEXITCODE -eq 0)
}

function Import-DefenderRegistryFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $machineSections = New-Object System.Collections.ArrayList
    $userSections = New-Object System.Collections.ArrayList
    $currentTarget = $null

    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[-?(HKEY_[^\]]+)\]\s*$') {
            $hivePath = [string]$Matches[1]
            if ($hivePath -match '^HKEY_LOCAL_MACHINE(?:\\|$)') {
                $currentTarget = 'Machine'
                [void]$machineSections.Add($line)
            } else {
                $currentTarget = 'User'
                [void]$userSections.Add($line)
            }
            continue
        }

        if ($null -eq $currentTarget) { continue }
        if ($currentTarget -eq 'Machine') { [void]$machineSections.Add($line) }
        else { [void]$userSections.Add($line) }
    }

    if ($machineSections.Count -eq 0 -and $userSections.Count -eq 0) { return $false }

    $tempRoot = Join-Path $env:TEMP ('DefenderRegImport_' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $tempRoot -Force
    $header = 'Windows Registry Editor Version 5.00'
    $machinePath = Join-Path $tempRoot 'Machine.reg'
    $userPath = Join-Path $tempRoot 'User.reg'
    $machineOk = $true
    $userOk = $true

    try {
        if ($machineSections.Count -gt 0) {
            $machineLines = [string[]]($machineSections.ToArray())
            $machineContent = $header + "`r`n`r`n" + [string]::Join("`r`n", $machineLines) + "`r`n"
            [IO.File]::WriteAllText($machinePath, $machineContent, [Text.Encoding]::Unicode)
            $machineOk = Import-DefenderRegistryChunk -Path $machinePath -UsePowerRun
        }
        if ($userSections.Count -gt 0) {
            $userLines = [string[]]($userSections.ToArray())
            $userContent = $header + "`r`n`r`n" + [string]::Join("`r`n", $userLines) + "`r`n"
            [IO.File]::WriteAllText($userPath, $userContent, [Text.Encoding]::Unicode)
            $userOk = Import-DefenderRegistryChunk -Path $userPath
        }
    } finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    return ($machineOk -and $userOk)
}

function Read-DefenderRegOperations {
    param([Parameter(Mandatory = $true)][string]$Path)

    $keyDeletes = New-Object System.Collections.ArrayList
    $valueChanges = New-Object System.Collections.ArrayList
    $currentKey = $null
    $lines = Get-Content -LiteralPath $Path -Raw
    foreach ($line in ($lines -split "`r?`n")) {
        if ($line -match '^\s*\[(-?)(HKEY_[^\]]+)\]\s*$') {
            if ($Matches[1] -eq '-') {
                [void]$keyDeletes.Add([string]$Matches[2])
                $currentKey = $null
            } else {
                $currentKey = [string]$Matches[2]
            }
            continue
        }
        if ([string]::IsNullOrEmpty($currentKey)) { continue }
        if ($line -match '^\s*"((?:[^"\\]|\\.)*)"\s*=') {
            $valueName = $Matches[1].Replace('\\', '\').Replace('\"', '"')
            [void]$valueChanges.Add([pscustomobject]@{ KeyPath = $currentKey; ValueName = $valueName })
        } elseif ($line -match '^\s*@\s*=') {
            [void]$valueChanges.Add([pscustomobject]@{ KeyPath = $currentKey; ValueName = '' })
        }
    }

    return [pscustomobject]@{
        KeyDeletes = @($keyDeletes | Select-Object -Unique)
        ValueChanges = @($valueChanges | Sort-Object KeyPath, ValueName -Unique)
    }
}

function Write-DefenderRegistryValueRegFile {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$ValueName,
        [Parameter(Mandatory = $true)]$Snapshot,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if ([string]::IsNullOrEmpty($ValueName)) { $nameToken = '@' }
    else {
        $slash = [string][char]92
        $quote = [string][char]34
        $nameEscaped = $ValueName.Replace($slash, $slash + $slash).Replace($quote, $slash + $quote)
        $nameToken = $quote + $nameEscaped + $quote
    }

    if (-not $Snapshot.KeyExists -and -not $Snapshot.Present) {
        $content = "Windows Registry Editor Version 5.00`r`n`r`n[-$KeyPath]`r`n"
        [IO.File]::WriteAllText($Destination, $content, [Text.Encoding]::Unicode)
        return
    }

    if (-not $Snapshot.Present) {
        $dataToken = '-'
    } else {
        switch ([string]$Snapshot.Kind) {
            'String' {
                $bytes = [Text.Encoding]::Unicode.GetBytes(([string]$Snapshot.Data) + [char]0)
                $dataToken = 'hex(1):' + (([BitConverter]::ToString($bytes)).Replace('-', ',').ToLowerInvariant())
            }
            'ExpandString' {
                $bytes = [Text.Encoding]::Unicode.GetBytes(([string]$Snapshot.Data) + [char]0)
                $dataToken = 'hex(2):' + (([BitConverter]::ToString($bytes)).Replace('-', ',').ToLowerInvariant())
            }
            'DWord' {
                $signed = [int]([long]$Snapshot.Data)
                $unsigned = [BitConverter]::ToUInt32([BitConverter]::GetBytes($signed), 0)
                $dataToken = 'dword:' + $unsigned.ToString('x8')
            }
            'QWord' {
                $bytes = [BitConverter]::GetBytes([long]$Snapshot.Data)
                $dataToken = 'hex(b):' + (([BitConverter]::ToString($bytes)).Replace('-', ',').ToLowerInvariant())
            }
            'MultiString' {
                $multi = [string]::Join([string][char]0, [string[]]@($Snapshot.Data)) + [char]0 + [char]0
                $bytes = [Text.Encoding]::Unicode.GetBytes($multi)
                $dataToken = 'hex(7):' + (([BitConverter]::ToString($bytes)).Replace('-', ',').ToLowerInvariant())
            }
            'Binary' {
                $bytes = [Convert]::FromBase64String([string]$Snapshot.Data)
                if ($bytes.Length -eq 0) { $dataToken = 'hex:' } else { $dataToken = 'hex:' + (([BitConverter]::ToString($bytes)).Replace('-', ',').ToLowerInvariant()) }
            }
            'None' {
                $bytes = [Convert]::FromBase64String([string]$Snapshot.Data)
                if ($bytes.Length -eq 0) { $dataToken = 'hex(0):' } else { $dataToken = 'hex(0):' + (([BitConverter]::ToString($bytes)).Replace('-', ',').ToLowerInvariant()) }
            }
            default { throw "Cannot serialize registry value kind '$($Snapshot.Kind)' to .reg format." }
        }
    }

    $content = "Windows Registry Editor Version 5.00`r`n`r`n[$KeyPath]`r`n$nameToken=$dataToken`r`n"
    [IO.File]::WriteAllText($Destination, $content, [Text.Encoding]::Unicode)
}

function Write-DefenderManifest {
    param($Session)
    $temporaryPath = $Session.ManifestPath + '.tmp'
    $json = ConvertTo-Json -InputObject $Session.Manifest -Depth 30
    [IO.File]::WriteAllText($temporaryPath, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $Session.ManifestPath -Force
}

function New-DefenderBackupSession {
    param(
        [Parameter(Mandatory = $true)][string]$RemovalMode,
        [switch]$WindowsSecurityAppRequested
    )

    New-Item -ItemType Directory -Path $script:DefenderBackupRoot -Force | Out-Null
    $sessionId = '{0}_{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0, 8))
    $sessionRoot = Join-Path $script:DefenderBackupRoot $sessionId
    $null = New-Item -ItemType Directory -Path $sessionRoot -Force

    # Restrict the schema root before creating child folders so they inherit
    # SYSTEM/Administrators-only access instead of the general ProgramData ACL.
    $icacls = Get-DefenderSystemExe -Name 'icacls.exe'
    if (-not (Test-Path -LiteralPath $icacls -PathType Leaf)) {
        throw 'icacls.exe was not found; the backup folder cannot be secured.'
    }
    & $icacls $sessionRoot '/inheritance:r' '/grant:r' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not restrict access to the backup schema folder. No removal operation was started.'
    }

    $null = New-Item -ItemType Directory -Path (Join-Path $sessionRoot 'Files') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $sessionRoot 'Registry\Keys') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $sessionRoot 'Registry\Values') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $sessionRoot 'Staging') -Force

    $appStatus = 'NotRequested'
    $appReason = 'Windows Security App was not selected for removal.'
    if ($WindowsSecurityAppRequested) {
        $appStatus = 'PendingRemoval_NotRestorable'
        $appReason = 'The Windows Security App package is not backed up. Restore Defender will not attempt to reinstall SecHealthUI.'
    }

    $manifest = [ordered]@{
        SchemaVersion = 1
        SessionId = $sessionId
        CreatedLocal = (Get-Date).ToString('o')
        Product = 'Defender Remover 13.1'
        RemovalMode = $RemovalMode
        Status = 'InProgress'
        RebootRecommended = $false
        WindowsSecurityApp = [ordered]@{ Requested = [bool]$WindowsSecurityAppRequested; Status = $appStatus; Reason = $appReason }
        RuntimeChecks = [ordered]@{
            CapturedLocal = (Get-Date).ToString('o')
            DefenderProcesses = @(Get-DefenderRuntimeProcessSnapshot)
            ProcessHandling = 'Read-only detection only; no Defender process termination or token modification is performed.'
        }
        Files = @()
        RegistryKeys = @()
        RegistryValues = @()
        Warnings = @()
        NextSequence = 0
    }

    if (@($manifest.RuntimeChecks.DefenderProcesses).Count -gt 0) {
        $manifest.Warnings = @('One or more Defender-related processes were running when this schema was created. The tool records their PIDs but does not terminate them or modify their security tokens.')
    }

    $session = [pscustomobject]@{
        Root = $sessionRoot
        ManifestPath = (Join-Path $sessionRoot 'Manifest.json')
        Manifest = $manifest
    }
    Write-DefenderManifest -Session $session
    return $session
}

function Add-DefenderManifestWarning {
    param($Session, [string]$Message)
    $Session.Manifest.Warnings = @($Session.Manifest.Warnings) + @($Message)
    Write-DefenderManifest -Session $Session
}

function Get-DefenderSafeName {
    param([string]$Value)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').Substring(0, 16) }
    finally { $sha.Dispose() }
}

function Invoke-DefenderRegistryFileWithBackup {
    param(
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true)][string]$RegFile,
        [Parameter(Mandatory = $true)][string]$PowerRunPath
    )

    Write-Host "Processing registry file: $(Split-Path -Leaf $RegFile)" -ForegroundColor Cyan
    $operations = Read-DefenderRegOperations -Path $RegFile
    if ((@($operations.KeyDeletes).Count + @($operations.ValueChanges).Count) -eq 0) {
        Add-DefenderManifestWarning -Session $Session -Message "Registry file skipped because no supported operations were recognized: $(Split-Path -Leaf $RegFile)"
        Write-Host 'Skipped registry file: no supported operations were recognized, so no untracked import was attempted.' -ForegroundColor Yellow
        return $false
    }
    $stagingRoot = Join-Path $Session.Root 'Staging'
    $stagedKeyExports = New-Object System.Collections.ArrayList
    $stagedValueStates = New-Object System.Collections.ArrayList
    $captureFailed = $false

    foreach ($keyPath in @($operations.KeyDeletes)) {
        try {
            if (-not (Test-DefenderRegistryKeyExists -KeyPath $keyPath)) { continue }
            $safe = Get-DefenderSafeName -Value $keyPath
            $tempFile = Join-Path $stagingRoot ('key_{0}_{1}.reg' -f $safe, [guid]::NewGuid().ToString('N'))
            if (-not (Export-DefenderRegistryKey -KeyPath $keyPath -Destination $tempFile)) {
                throw "Cannot export registry key before removal: $keyPath"
            }
            [void]$stagedKeyExports.Add([pscustomobject]@{ KeyPath = $keyPath; TempFile = $tempFile })
        } catch {
            $captureFailed = $true
            Add-DefenderManifestWarning -Session $Session -Message "Registry operation skipped because backup failed: $keyPath ($($_.Exception.Message))"
        }
    }

    foreach ($operation in @($operations.ValueChanges)) {
        $coveredByDeletedKey = $false
        foreach ($deletedKey in @($operations.KeyDeletes)) {
            if ($operation.KeyPath.StartsWith($deletedKey + '\', [StringComparison]::OrdinalIgnoreCase) -or
                [string]::Equals($operation.KeyPath, $deletedKey, [StringComparison]::OrdinalIgnoreCase)) {
                $coveredByDeletedKey = $true
                break
            }
        }
        if ($coveredByDeletedKey) { continue }

        $alreadyCaptured = $false
        foreach ($existing in @($Session.Manifest.RegistryValues)) {
            if ([string]::Equals([string]$existing.KeyPath, [string]$operation.KeyPath, [StringComparison]::OrdinalIgnoreCase) -and
                [string]::Equals([string]$existing.ValueName, [string]$operation.ValueName, [StringComparison]::OrdinalIgnoreCase)) {
                $alreadyCaptured = $true
                break
            }
        }
        if (-not $alreadyCaptured) {
            foreach ($staged in @($stagedValueStates)) {
                if ([string]::Equals([string]$staged.KeyPath, [string]$operation.KeyPath, [StringComparison]::OrdinalIgnoreCase) -and
                    [string]::Equals([string]$staged.ValueName, [string]$operation.ValueName, [StringComparison]::OrdinalIgnoreCase)) {
                    $alreadyCaptured = $true
                    break
                }
            }
        }
        if ($alreadyCaptured) { continue }

        try {
            $before = Get-DefenderRegistryValueSnapshot -KeyPath $operation.KeyPath -ValueName $operation.ValueName
            $safe = Get-DefenderSafeName -Value ($operation.KeyPath + '|' + $operation.ValueName)
            $tempFile = Join-Path $stagingRoot ('value_{0}_{1}.reg' -f $safe, [guid]::NewGuid().ToString('N'))
            # Serialize the pre-change state BEFORE importing the destructive .reg file.
            Write-DefenderRegistryValueRegFile -KeyPath $operation.KeyPath -ValueName $operation.ValueName -Snapshot $before -Destination $tempFile
            if (-not (Test-Path -LiteralPath $tempFile -PathType Leaf)) {
                throw 'Registry value snapshot was not written.'
            }
            [void]$stagedValueStates.Add([pscustomobject]@{
                KeyPath = $operation.KeyPath
                ValueName = $operation.ValueName
                Before = $before
                TempFile = $tempFile
            })
        } catch {
            $captureFailed = $true
            Add-DefenderManifestWarning -Session $Session -Message "Registry operation skipped because value backup failed: $($operation.KeyPath)\$($operation.ValueName) ($($_.Exception.Message))"
        }
    }

    if ($captureFailed) {
        foreach ($entry in @($stagedKeyExports)) { Remove-Item -LiteralPath $entry.TempFile -Force -ErrorAction SilentlyContinue }
        foreach ($entry in @($stagedValueStates)) { Remove-Item -LiteralPath $entry.TempFile -Force -ErrorAction SilentlyContinue }
        Write-Host 'Skipped this .reg file: at least one affected registry item could not be backed up.' -ForegroundColor Yellow
        return $false
    }

    # Commit all pre-change snapshots and their manifest records BEFORE the
    # registry import. An unexpected reboot mid-import therefore remains recoverable.
    try {
        foreach ($entry in @($stagedKeyExports)) {
            $Session.Manifest.NextSequence = [int]$Session.Manifest.NextSequence + 1
            $relativeName = 'Registry\Keys\{0}_{1}.reg' -f $Session.Manifest.NextSequence, (Get-DefenderSafeName -Value $entry.KeyPath)
            $destination = Join-Path $Session.Root $relativeName
            Move-Item -LiteralPath $entry.TempFile -Destination $destination -Force -ErrorAction Stop
            $record = [ordered]@{
                Sequence = $Session.Manifest.NextSequence
                KeyPath = $entry.KeyPath
                BackupFile = $relativeName
                SourceRegFile = (Split-Path -Leaf $RegFile)
                Status = 'BackupReady'
            }
            $Session.Manifest.RegistryKeys = @($Session.Manifest.RegistryKeys) + @($record)
            $entry | Add-Member -NotePropertyName BackupFilePath -NotePropertyValue $destination
            $entry | Add-Member -NotePropertyName ManifestEntry -NotePropertyValue $record
        }

        foreach ($entry in @($stagedValueStates)) {
            $Session.Manifest.NextSequence = [int]$Session.Manifest.NextSequence + 1
            $relativeName = 'Registry\Values\{0}_{1}.reg' -f $Session.Manifest.NextSequence, (Get-DefenderSafeName -Value ($entry.KeyPath + '|' + $entry.ValueName))
            $destination = Join-Path $Session.Root $relativeName
            Move-Item -LiteralPath $entry.TempFile -Destination $destination -Force -ErrorAction Stop
            $record = [ordered]@{
                Sequence = $Session.Manifest.NextSequence
                KeyPath = $entry.KeyPath
                ValueName = $entry.ValueName
                KeyExisted = [bool]$entry.Before.KeyExists
                WasPresent = [bool]$entry.Before.Present
                Kind = $entry.Before.Kind
                Data = $entry.Before.Data
                BackupFile = $relativeName
                SourceRegFile = (Split-Path -Leaf $RegFile)
                Status = 'BackupReady'
            }
            $Session.Manifest.RegistryValues = @($Session.Manifest.RegistryValues) + @($record)
            $entry | Add-Member -NotePropertyName BackupFilePath -NotePropertyValue $destination
            $entry | Add-Member -NotePropertyName ManifestEntry -NotePropertyValue $record
        }
        Write-DefenderManifest -Session $Session
    } catch {
        foreach ($entry in @($stagedKeyExports)) {
            if ($entry.PSObject.Properties['BackupFilePath']) { Remove-Item -LiteralPath $entry.BackupFilePath -Force -ErrorAction SilentlyContinue }
            else { Remove-Item -LiteralPath $entry.TempFile -Force -ErrorAction SilentlyContinue }
            if ($entry.PSObject.Properties['ManifestEntry']) {
                $seq = [int]$entry.ManifestEntry.Sequence
                $Session.Manifest.RegistryKeys = @($Session.Manifest.RegistryKeys | Where-Object { [int]$_.Sequence -ne $seq })
            }
        }
        foreach ($entry in @($stagedValueStates)) {
            if ($entry.PSObject.Properties['BackupFilePath']) { Remove-Item -LiteralPath $entry.BackupFilePath -Force -ErrorAction SilentlyContinue }
            else { Remove-Item -LiteralPath $entry.TempFile -Force -ErrorAction SilentlyContinue }
            if ($entry.PSObject.Properties['ManifestEntry']) {
                $seq = [int]$entry.ManifestEntry.Sequence
                $Session.Manifest.RegistryValues = @($Session.Manifest.RegistryValues | Where-Object { [int]$_.Sequence -ne $seq })
            }
        }
        Add-DefenderManifestWarning -Session $Session -Message "Registry file skipped because the restore journal could not be committed: $(Split-Path -Leaf $RegFile) ($($_.Exception.Message))"
        return $false
    }

    try {
        $importSucceeded = Import-DefenderRegistryFile -Path $RegFile
        if (-not $importSucceeded) {
            Add-DefenderManifestWarning -Session $Session -Message "One or more registry hive imports returned an error for $(Split-Path -Leaf $RegFile); actual registry state was checked afterward."
        }
    } catch {
        Add-DefenderManifestWarning -Session $Session -Message "Could not run registry file $(Split-Path -Leaf $RegFile): $($_.Exception.Message)"
    }

    foreach ($entry in @($stagedKeyExports)) {
        $changed = $false
        try {
            if (-not (Test-DefenderRegistryKeyExists -KeyPath $entry.KeyPath)) {
                $changed = $true
            } else {
                $afterFile = $entry.BackupFilePath + '.after.reg'
                if (-not (Export-DefenderRegistryKey -KeyPath $entry.KeyPath -Destination $afterFile)) {
                    $changed = $true
                } else {
                    $beforeHash = (Get-FileHash -LiteralPath $entry.BackupFilePath -Algorithm SHA256).Hash
                    $afterHash = (Get-FileHash -LiteralPath $afterFile -Algorithm SHA256).Hash
                    $changed = ($beforeHash -ne $afterHash)
                }
                Remove-Item -LiteralPath $afterFile -Force -ErrorAction SilentlyContinue
            }
        } catch { $changed = $true }

        if ($changed) {
            $entry.ManifestEntry['Status'] = 'ChangedOrDeleted'
        } else {
            $seq = [int]$entry.ManifestEntry.Sequence
            $Session.Manifest.RegistryKeys = @($Session.Manifest.RegistryKeys | Where-Object { [int]$_.Sequence -ne $seq })
            Remove-Item -LiteralPath $entry.BackupFilePath -Force -ErrorAction SilentlyContinue
        }
    }

    foreach ($entry in @($stagedValueStates)) {
        try {
            $after = Get-DefenderRegistryValueSnapshot -KeyPath $entry.KeyPath -ValueName $entry.ValueName
            $changed = -not (Test-DefenderRegistrySnapshotsEqual -Left $entry.Before -Right $after)
        } catch { $changed = $true }

        if ($changed) {
            $entry.ManifestEntry['Status'] = 'ChangedOrDeleted'
        } else {
            $seq = [int]$entry.ManifestEntry.Sequence
            $Session.Manifest.RegistryValues = @($Session.Manifest.RegistryValues | Where-Object { [int]$_.Sequence -ne $seq })
            Remove-Item -LiteralPath $entry.BackupFilePath -Force -ErrorAction SilentlyContinue
        }
    }

    Write-DefenderManifest -Session $Session
    return $true
}

function Get-DefenderRobocopyExe {
    return (Get-DefenderSystemExe -Name 'robocopy.exe')
}

function Invoke-DefenderRobocopy {
    param([string[]]$Arguments)
    $robocopy = Get-DefenderRobocopyExe
    & $robocopy @Arguments | Out-Null
    return [int]$LASTEXITCODE
}

function Backup-AndRemoveDefenderDirectory {
    param($Session, [Parameter(Mandatory = $true)][string]$SourcePath)

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
        Write-Host "Folder not found (skipping): $SourcePath" -ForegroundColor Yellow
        return $false
    }

    $Session.Manifest.NextSequence = [int]$Session.Manifest.NextSequence + 1
    $backupRelative = 'Files\Directory_{0}_{1}' -f $Session.Manifest.NextSequence, (Get-DefenderSafeName -Value $SourcePath)
    $backupPath = Join-Path $Session.Root $backupRelative
    $null = New-Item -ItemType Directory -Path $backupPath -Force

    Write-Host "Backing up folder before removal: $SourcePath" -ForegroundColor Cyan
    $copyCode = Invoke-DefenderRobocopy -Arguments @(
        $SourcePath, $backupPath, '/E', '/COPYALL', '/DCOPY:DATSOU', '/R:1', '/W:1', '/XJ', '/B', '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
    )
    if ($copyCode -ge 8) {
        Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction SilentlyContinue
        Add-DefenderManifestWarning -Session $Session -Message "Folder was not removed because its backup failed (robocopy exit $copyCode): $SourcePath"
        Write-Host "Backup failed; folder was NOT deleted: $SourcePath" -ForegroundColor Red
        return $false
    }

    # Verify the backup before creating a recovery record or deleting anything.
    try {
        $sourceFiles = @(Get-ChildItem -LiteralPath $SourcePath -File -Recurse -Force -ErrorAction Stop)
        $backupFiles = @(Get-ChildItem -LiteralPath $backupPath -File -Recurse -Force -ErrorAction Stop)
        if ($sourceFiles.Count -ne $backupFiles.Count) { throw 'File count mismatch' }
        $sourceDirectories = @(Get-ChildItem -LiteralPath $SourcePath -Directory -Recurse -Force -ErrorAction Stop)
        $backupDirectories = @(Get-ChildItem -LiteralPath $backupPath -Directory -Recurse -Force -ErrorAction Stop)
        if ($sourceDirectories.Count -ne $backupDirectories.Count) { throw 'Directory count mismatch, including empty folders' }
        foreach ($sourceDirectory in $sourceDirectories) {
            $relativeDirectory = $sourceDirectory.FullName.Substring($SourcePath.TrimEnd('\').Length).TrimStart('\')
            if (-not (Test-Path -LiteralPath (Join-Path $backupPath $relativeDirectory) -PathType Container)) {
                throw "Missing backup directory: $relativeDirectory"
            }
        }
        foreach ($sourceFile in $sourceFiles) {
            $relative = $sourceFile.FullName.Substring($SourcePath.TrimEnd('\').Length).TrimStart('\')
            $backupFile = Join-Path $backupPath $relative
            if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf)) { throw "Missing backup file: $relative" }
            $copied = Get-Item -LiteralPath $backupFile -Force
            if ($copied.Length -ne $sourceFile.Length) { throw "Size mismatch: $relative" }
        }
    } catch {
        Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction SilentlyContinue
        Add-DefenderManifestWarning -Session $Session -Message "Folder was not removed because backup verification failed: $SourcePath ($($_.Exception.Message))"
        Write-Host "Backup verification failed; folder was NOT deleted: $SourcePath" -ForegroundColor Red
        return $false
    }

    # Persist a recovery journal BEFORE the destructive action. If Windows is
    # restarted unexpectedly during deletion, Restore Defender can still recover.
    $fileEntry = [ordered]@{
        Sequence = $Session.Manifest.NextSequence
        Type = 'Directory'
        OriginalPath = $SourcePath
        BackupPath = $backupRelative
        Status = 'BackupReady'
    }
    $Session.Manifest.Files = @($Session.Manifest.Files) + @($fileEntry)
    Write-DefenderManifest -Session $Session

    $null = & (Get-DefenderSystemExe -Name 'takeown.exe') /f $SourcePath /r /d y /a 2>&1
    $null = & (Get-DefenderSystemExe -Name 'icacls.exe') $SourcePath /grant '*S-1-5-32-544:(OI)(CI)F' /t /c 2>&1
    try { Remove-Item -LiteralPath $SourcePath -Recurse -Force -ErrorAction Stop } catch {
        $null = & (Get-DefenderSystemExe -Name 'cmd.exe') /d /c "rd /s /q `"$SourcePath`"" 2>&1
    }

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        $fileEntry['Status'] = 'Deleted'
        Write-DefenderManifest -Session $Session
        Write-Host "Deleted: $SourcePath (backup saved)" -ForegroundColor Green
        return $true
    }

    $missingCount = 0
    foreach ($backupFile in @(Get-ChildItem -LiteralPath $backupPath -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        $relative = $backupFile.FullName.Substring($backupPath.TrimEnd('\').Length).TrimStart('\')
        if (-not (Test-Path -LiteralPath (Join-Path $SourcePath $relative) -PathType Leaf)) { $missingCount++ }
    }
    foreach ($backupDirectory in @(Get-ChildItem -LiteralPath $backupPath -Directory -Recurse -Force -ErrorAction SilentlyContinue)) {
        $relativeDirectory = $backupDirectory.FullName.Substring($backupPath.TrimEnd('\').Length).TrimStart('\')
        if (-not (Test-Path -LiteralPath (Join-Path $SourcePath $relativeDirectory) -PathType Container)) { $missingCount++ }
    }
    if ($missingCount -gt 0) {
        $fileEntry['Status'] = 'PartiallyDeleted'
        Write-DefenderManifest -Session $Session
        Write-Host "PartiallyDeleted: $SourcePath (backup saved)" -ForegroundColor Green
        return $true
    }

    $Session.Manifest.Files = @($Session.Manifest.Files | Where-Object { [int]$_.Sequence -ne [int]$fileEntry.Sequence })
    Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction SilentlyContinue
    Add-DefenderManifestWarning -Session $Session -Message "No deletion was confirmed; no backup entry was retained for $SourcePath"
    Write-Host "No successful deletion detected: $SourcePath" -ForegroundColor Yellow
    return $false
}

function Backup-AndRemoveDefenderFile {
    param($Session, [Parameter(Mandatory = $true)][string]$SourcePath)

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        Write-Host "File not found (skipping): $SourcePath" -ForegroundColor Yellow
        return $false
    }

    $source = Get-Item -LiteralPath $SourcePath -Force
    $parent = Split-Path -Parent $SourcePath
    $leaf = Split-Path -Leaf $SourcePath
    $Session.Manifest.NextSequence = [int]$Session.Manifest.NextSequence + 1
    $backupRelative = 'Files\File_{0}_{1}' -f $Session.Manifest.NextSequence, (Get-DefenderSafeName -Value $SourcePath)
    $backupPath = Join-Path $Session.Root $backupRelative
    $null = New-Item -ItemType Directory -Path $backupPath -Force

    $copyCode = Invoke-DefenderRobocopy -Arguments @(
        $parent, $backupPath, $leaf, '/COPYALL', '/R:1', '/W:1', '/B', '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
    )
    $backupFile = Join-Path $backupPath $leaf
    if (($copyCode -ge 8) -or (-not (Test-Path -LiteralPath $backupFile -PathType Leaf))) {
        Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction SilentlyContinue
        Add-DefenderManifestWarning -Session $Session -Message "File was not removed because its backup failed: $SourcePath"
        Write-Host "Backup failed; file was NOT deleted: $SourcePath" -ForegroundColor Red
        return $false
    }

    $copyItem = Get-Item -LiteralPath $backupFile -Force
    if ($copyItem.Length -ne $source.Length) {
        Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction SilentlyContinue
        Add-DefenderManifestWarning -Session $Session -Message "File was not removed because backup verification failed: $SourcePath"
        return $false
    }

    $fileEntry = [ordered]@{
        Sequence = $Session.Manifest.NextSequence
        Type = 'File'
        OriginalPath = $SourcePath
        BackupPath = $backupRelative
        FileName = $leaf
        Status = 'BackupReady'
    }
    $Session.Manifest.Files = @($Session.Manifest.Files) + @($fileEntry)
    Write-DefenderManifest -Session $Session

    $null = & (Get-DefenderSystemExe -Name 'takeown.exe') /f $SourcePath /a 2>&1
    $null = & (Get-DefenderSystemExe -Name 'icacls.exe') $SourcePath /grant '*S-1-5-32-544:F' 2>&1
    try { Remove-Item -LiteralPath $SourcePath -Force -ErrorAction Stop } catch { }

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        $fileEntry['Status'] = 'Deleted'
        Write-DefenderManifest -Session $Session
        Write-Host "Removed: $SourcePath (backup saved)" -ForegroundColor Green
        return $true
    }

    $Session.Manifest.Files = @($Session.Manifest.Files | Where-Object { [int]$_.Sequence -ne [int]$fileEntry.Sequence })
    Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction SilentlyContinue
    Add-DefenderManifestWarning -Session $Session -Message "File deletion was not successful; no backup entry was retained for $SourcePath"
    Write-Host "Could not remove file: $SourcePath" -ForegroundColor Yellow
    return $false
}

function Complete-DefenderBackupSession {
    param($Session, [bool]$RebootRecommended = $false)
    $Session.Manifest.RebootRecommended = $RebootRecommended
    if (@($Session.Manifest.Files).Count -eq 0 -and @($Session.Manifest.RegistryKeys).Count -eq 0 -and @($Session.Manifest.RegistryValues).Count -eq 0) {
        $Session.Manifest.Status = 'NoRestorableChangesRecorded'
    } else {
        $Session.Manifest.Status = 'PendingRestore'
    }
    $Session.Manifest.CompletedLocal = (Get-Date).ToString('o')
    Write-DefenderManifest -Session $Session
}

function Restore-DefenderFileEntry {
    param($Session, $Entry)

    $backupPath = Join-Path $Session.Root ([string]$Entry.BackupPath)
    if (-not (Test-Path -LiteralPath $backupPath -PathType Container)) {
        throw "File backup folder is missing: $backupPath"
    }

    if ([string]$Entry.Type -eq 'Directory') {
        $null = New-Item -ItemType Directory -Path ([string]$Entry.OriginalPath) -Force
        $code = Invoke-DefenderRobocopy -Arguments @(
            $backupPath, [string]$Entry.OriginalPath, '/E', '/COPYALL', '/DCOPY:DATSOU', '/IS', '/IT', '/R:1', '/W:1', '/XJ', '/B', '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
        )
        if ($code -ge 8) { throw "Robocopy failed (exit $code) restoring $($Entry.OriginalPath)" }
    } elseif ([string]$Entry.Type -eq 'File') {
        $destinationParent = Split-Path -Parent ([string]$Entry.OriginalPath)
        $null = New-Item -ItemType Directory -Path $destinationParent -Force
        $code = Invoke-DefenderRobocopy -Arguments @(
            $backupPath, $destinationParent, [string]$Entry.FileName, '/COPYALL', '/IS', '/IT', '/R:1', '/W:1', '/B', '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
        )
        if ($code -ge 8) { throw "Robocopy failed (exit $code) restoring $($Entry.OriginalPath)" }
    } else {
        throw "Unknown file backup type: $($Entry.Type)"
    }

    if ([string]$Entry.Type -eq 'Directory') {
        if (-not (Test-Path -LiteralPath $Entry.OriginalPath -PathType Container)) {
            throw "Folder was not restored: $($Entry.OriginalPath)"
        }
        foreach ($backupDirectory in @(Get-ChildItem -LiteralPath $backupPath -Directory -Recurse -Force -ErrorAction Stop)) {
            $relativeDirectory = $backupDirectory.FullName.Substring($backupPath.TrimEnd('\').Length).TrimStart('\')
            $restoredDirectory = Join-Path ([string]$Entry.OriginalPath) $relativeDirectory
            if (-not (Test-Path -LiteralPath $restoredDirectory -PathType Container)) { throw "Restored directory is missing: $restoredDirectory" }
        }
        foreach ($backupFile in @(Get-ChildItem -LiteralPath $backupPath -File -Recurse -Force -ErrorAction Stop)) {
            $relative = $backupFile.FullName.Substring($backupPath.TrimEnd('\').Length).TrimStart('\')
            $restoredFile = Join-Path ([string]$Entry.OriginalPath) $relative
            if (-not (Test-Path -LiteralPath $restoredFile -PathType Leaf)) { throw "Restored file is missing: $restoredFile" }
            if ((Get-Item -LiteralPath $restoredFile -Force).Length -ne $backupFile.Length) { throw "Restored file size mismatch: $restoredFile" }
        }
    }
    if ([string]$Entry.Type -eq 'File') {
        if (-not (Test-Path -LiteralPath $Entry.OriginalPath -PathType Leaf)) {
            throw "File was not restored: $($Entry.OriginalPath)"
        }
        $backupFile = Join-Path $backupPath ([string]$Entry.FileName)
        if ((Get-Item -LiteralPath $Entry.OriginalPath -Force).Length -ne (Get-Item -LiteralPath $backupFile -Force).Length) {
            throw "Restored file size mismatch: $($Entry.OriginalPath)"
        }
    }
}

function Restore-DefenderRegistryKeyEntry {
    param($Session, $Entry)
    $backupFile = Join-Path $Session.Root ([string]$Entry.BackupFile)
    if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf)) { throw "Registry backup is missing: $backupFile" }

    # Replace the affected key tree with its exact pre-removal export.
    $deleteFile = Join-Path (Join-Path $Session.Root 'Staging') ('restore_delete_{0}.reg' -f [guid]::NewGuid().ToString('N'))
    $deleteContent = "Windows Registry Editor Version 5.00`r`n`r`n[-$($Entry.KeyPath)]`r`n"
    [IO.File]::WriteAllText($deleteFile, $deleteContent, [Text.Encoding]::Unicode)
    $null = Import-DefenderRegistryFile -Path $deleteFile
    if (Test-DefenderRegistryKeyExists -KeyPath ([string]$Entry.KeyPath)) {
        throw "Could not clear registry key before restore: $($Entry.KeyPath)"
    }
    $imported = Import-DefenderRegistryFile -Path $backupFile
    if (-not $imported -and -not (Test-DefenderRegistryKeyExists -KeyPath ([string]$Entry.KeyPath))) {
        throw "Registry key import failed: $($Entry.KeyPath)"
    }
    if (-not (Test-DefenderRegistryKeyExists -KeyPath ([string]$Entry.KeyPath))) {
        throw "Registry key was not restored: $($Entry.KeyPath)"
    }
    $verifyFile = $deleteFile + '.verify.reg'
    if (-not (Export-DefenderRegistryKey -KeyPath ([string]$Entry.KeyPath) -Destination $verifyFile)) {
        throw "Could not verify restored registry key: $($Entry.KeyPath)"
    }
    $backupHash = (Get-FileHash -LiteralPath $backupFile -Algorithm SHA256).Hash
    $verifyHash = (Get-FileHash -LiteralPath $verifyFile -Algorithm SHA256).Hash
    Remove-Item -LiteralPath $verifyFile -Force -ErrorAction SilentlyContinue
    if ($backupHash -ne $verifyHash) {
        throw "Registry key contents do not match the saved snapshot: $($Entry.KeyPath)"
    }
    Remove-Item -LiteralPath $deleteFile -Force -ErrorAction SilentlyContinue
}

function Restore-DefenderRegistryValueEntry {
    param($Session, $Entry)
    $snapshot = [pscustomobject]@{ KeyExists = [bool]$Entry.KeyExisted; Present = [bool]$Entry.WasPresent; Kind = $Entry.Kind; Data = $Entry.Data }
    if (-not [string]::IsNullOrWhiteSpace([string]$Entry.BackupFile)) {
        $backupFile = Join-Path $Session.Root ([string]$Entry.BackupFile)
        if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf)) { throw "Registry value backup is missing: $backupFile" }
        $null = Import-DefenderRegistryFile -Path $backupFile
    } else {
        Set-DefenderRegistryValueSnapshot -KeyPath ([string]$Entry.KeyPath) -ValueName ([string]$Entry.ValueName) -Snapshot $snapshot
    }
    $actual = Get-DefenderRegistryValueSnapshot -KeyPath ([string]$Entry.KeyPath) -ValueName ([string]$Entry.ValueName)
    if (-not (Test-DefenderRegistrySnapshotsEqual -Left $snapshot -Right $actual)) {
        throw "Registry value was not restored correctly: $($Entry.KeyPath)\$($Entry.ValueName)"
    }
}

function Invoke-DefenderRestore {
    if (-not (Test-DefenderAdministrator)) {
        $scriptPath = Join-Path $script:DefenderEngineRoot 'Restore-Defender.ps1'
        $powershellExe = Get-DefenderSystemExe -Name 'WindowsPowerShell\v1.0\powershell.exe'
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $scriptPath
        Start-Process -FilePath $powershellExe -Verb RunAs -ArgumentList $arguments
        return
    }

    if (-not (Test-Path -LiteralPath $script:DefenderBackupRoot -PathType Container)) {
        Write-Host "No backup schemas were found at: $script:DefenderBackupRoot" -ForegroundColor Yellow
        Read-Host 'Press Enter to close'
        return
    }

    $sessions = @()
    foreach ($directory in @(Get-ChildItem -LiteralPath $script:DefenderBackupRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $manifestPath = Join-Path $directory.FullName 'Manifest.json'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
        try {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            if ($manifest.Status -notin @('Restored', 'RestoredWithWarnings')) {
                $sessions += [pscustomobject]@{ Root = $directory.FullName; ManifestPath = $manifestPath; Manifest = $manifest }
            }
        } catch {
            Write-Host "Ignoring invalid schema: $manifestPath" -ForegroundColor Yellow
        }
    }

    if ($sessions.Count -eq 0) {
        Write-Host 'There are no pending backup schemas to restore.' -ForegroundColor Green
        Read-Host 'Press Enter to close'
        return
    }

    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '                 DEFENDER REMOVER - RESTORE' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host "Backup location: $script:DefenderBackupRoot"
    Write-Host ''
    $totalFiles = 0; $totalKeys = 0; $totalValues = 0
    foreach ($session in $sessions) {
        $fileCount = @($session.Manifest.Files).Count
        $keyCount = @($session.Manifest.RegistryKeys).Count
        $valueCount = @($session.Manifest.RegistryValues).Count
        $totalFiles += $fileCount; $totalKeys += $keyCount; $totalValues += $valueCount
        Write-Host ("{0} | {1} | Files: {2}, registry keys: {3}, registry values: {4}" -f $session.Manifest.SessionId, $session.Manifest.RemovalMode, $fileCount, $keyCount, $valueCount)
        $pendingItems = @($session.Manifest.Files) + @($session.Manifest.RegistryKeys) + @($session.Manifest.RegistryValues)
        $recoveryPending = @($pendingItems | Where-Object { $_.Status -eq 'BackupReady' }).Count
        if ($recoveryPending -gt 0) {
            Write-Host "   WARNING: $recoveryPending operation(s) were interrupted or not finalized; their pre-change snapshots will also be restored." -ForegroundColor Yellow
        }
        if ($session.Manifest.WindowsSecurityApp.Status -in @('RemovedNotRestorable', 'PendingRemoval_NotRestorable')) {
            Write-Host '   WARNING: Windows Security App was removed or its removal was interrupted; it is NOT included in this restore.' -ForegroundColor Yellow
        }
    }
    Write-Host ''
    Write-Host 'This operation restores saved files and registry data only.' -ForegroundColor Yellow
    Write-Host 'It does NOT reinstall the Windows Security App (SecHealthUI) if that package was removed.' -ForegroundColor Yellow
    Write-Host 'A restart will be recommended after restoration.' -ForegroundColor Yellow
    Write-Host ''
    $confirm = Read-Host 'Restore ALL pending schemas shown above? Type RESTORE to continue'
    if ($confirm -cne 'RESTORE') {
        Write-Host 'Restore cancelled.' -ForegroundColor Yellow
        Read-Host 'Press Enter to close'
        return
    }

    $overallFailures = 0
    foreach ($session in $sessions) {
        Write-Host ''
        Write-Host "Restoring schema $($session.Manifest.SessionId)..." -ForegroundColor Cyan
        $failures = New-Object System.Collections.ArrayList

        # Restore file payloads first so service binaries exist before their registry entries return.
        foreach ($entry in @($session.Manifest.Files | Sort-Object Sequence -Descending)) {
            try {
                Restore-DefenderFileEntry -Session $session -Entry $entry
                Write-Host "Restored file item: $($entry.OriginalPath)" -ForegroundColor Green
            } catch {
                [void]$failures.Add($_.Exception.Message)
                Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # Restore registry keys and values together in reverse operation order.
        # They must not be processed in separate groups: a later .reg import may
        # recreate a key that an earlier .reg file deleted.
        $registryActions = @()
        foreach ($entry in @($session.Manifest.RegistryKeys)) {
            $registryActions += [pscustomobject]@{ Sequence = [int]$entry.Sequence; Type = 'Key'; Entry = $entry }
        }
        foreach ($entry in @($session.Manifest.RegistryValues)) {
            $registryActions += [pscustomobject]@{ Sequence = [int]$entry.Sequence; Type = 'Value'; Entry = $entry }
        }
        foreach ($action in @($registryActions | Sort-Object Sequence -Descending)) {
            try {
                if ($action.Type -eq 'Key') {
                    Restore-DefenderRegistryKeyEntry -Session $session -Entry $action.Entry
                    Write-Host "Restored registry key: $($action.Entry.KeyPath)" -ForegroundColor Green
                } else {
                    Restore-DefenderRegistryValueEntry -Session $session -Entry $action.Entry
                    Write-Host "Restored registry value: $($action.Entry.KeyPath)\$($action.Entry.ValueName)" -ForegroundColor Green
                }
            } catch {
                [void]$failures.Add($_.Exception.Message)
                Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        if ($failures.Count -eq 0) {
            if ($session.Manifest.WindowsSecurityApp.Status -in @('RemovedNotRestorable', 'PendingRemoval_NotRestorable')) {
                $session.Manifest.Status = 'RestoredWithWarnings'
            } else {
                $session.Manifest.Status = 'Restored'
            }
            $session.Manifest.RestoredLocal = (Get-Date).ToString('o')
            $session.Manifest.RestoreFailures = @()
            Write-Host "Schema restored: $($session.Manifest.SessionId)" -ForegroundColor Green
        } else {
            $session.Manifest.Status = 'PartiallyRestored'
            $session.Manifest.RestoreFailures = @($failures)
            $overallFailures += $failures.Count
            Write-Host "Schema only partially restored: $($session.Manifest.SessionId)" -ForegroundColor Yellow
        }
        $session.Manifest.NextSequence = [int]$session.Manifest.NextSequence
        $manifestJson = ConvertTo-Json -InputObject $session.Manifest -Depth 30
        [IO.File]::WriteAllText($session.ManifestPath, $manifestJson, [System.Text.UTF8Encoding]::new($false))
    }

    Write-Host ''
    if ($overallFailures -eq 0) {
        Write-Host 'Restore operations completed. Restart Windows to reload restored services and drivers.' -ForegroundColor Green
    } else {
        Write-Host "Restore completed with $overallFailures error(s). Check the messages above and the Manifest.json files." -ForegroundColor Yellow
    }
    if (@($sessions | Where-Object { $_.Manifest.WindowsSecurityApp.Status -in @('RemovedNotRestorable', 'PendingRemoval_NotRestorable') }).Count -gt 0) {
        Write-Host 'IMPORTANT: Windows Security App (SecHealthUI) remains non-restored; this tool does not contain its package.' -ForegroundColor Yellow
    }
    Read-Host 'Press Enter to close'
}
