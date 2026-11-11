# Windows Defender Remover - PowerShell version
$defenderremoverver = "13.1"

# -----------------------------------------------------------------------------
# Admin rights check and elevation
# -----------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($args -join ' ')"
    exit
}

Set-Location $PSScriptRoot

# Kill processes that may interfere
Stop-Process -Name smartscreen -Force -ErrorAction SilentlyContinue

# -----------------------------------------------------------------------------
# Persistent Start Menu shortcuts and backup/restore engine
# -----------------------------------------------------------------------------
. (Join-Path $PSScriptRoot 'DefenderBackupRestore.ps1')

function Install-DefenderStartMenuShortcuts {
    $programDataRoot = Join-Path $env:ProgramData 'Gallery Inc\Defender Remover'
    $vbsInstallDir = Join-Path $programDataRoot 'VBS'
    $programsDir = [Environment]::GetFolderPath('CommonPrograms')
    if ([string]::IsNullOrWhiteSpace($programsDir)) {
        $programsDir = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
    }
    $shortcutDir = Join-Path $programsDir 'Defender Remover'

    $requiredFiles = @(
        @{ Source = (Join-Path $PSScriptRoot 'VBS\Enable VBS.bat'); Destination = (Join-Path $vbsInstallDir 'Enable VBS.bat') },
        @{ Source = (Join-Path $PSScriptRoot 'VBS\Disable VBS.bat'); Destination = (Join-Path $vbsInstallDir 'Disable VBS.bat') },
        @{ Source = (Join-Path $PSScriptRoot 'VBS\Run-VBSAction.ps1'); Destination = (Join-Path $vbsInstallDir 'Run-VBSAction.ps1') },
        @{ Source = (Join-Path $PSScriptRoot 'DefenderBackupRestore.ps1'); Destination = (Join-Path $programDataRoot 'DefenderBackupRestore.ps1') },
        @{ Source = (Join-Path $PSScriptRoot 'Restore-Defender.ps1'); Destination = (Join-Path $programDataRoot 'Restore-Defender.ps1') },
        @{ Source = (Join-Path $PSScriptRoot 'PowerRun.exe'); Destination = (Join-Path $programDataRoot 'PowerRun.exe') }
    )

    foreach ($item in $requiredFiles) {
        if (-not (Test-Path -LiteralPath $item.Source -PathType Leaf)) {
            throw "Required support file is missing: $($item.Source)"
        }
    }

    New-Item -ItemType Directory -Path $vbsInstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path $shortcutDir -Force | Out-Null
    foreach ($item in $requiredFiles) {
        Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force
    }

    $powershellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (-not (Test-Path -LiteralPath $powershellExe)) { $powershellExe = 'powershell.exe' }
    $vbsLauncherPath = Join-Path $vbsInstallDir 'Run-VBSAction.ps1'
    $restoreLauncherPath = Join-Path $programDataRoot 'Restore-Defender.ps1'
    $shell = New-Object -ComObject WScript.Shell

    $shortcuts = @(
        @{ Name = 'Enable VBS'; Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$vbsLauncherPath`" -Action Enable"; Description = 'Enable Virtualization-Based Security and Credential Guard'; Icon = "$env:SystemRoot\System32\shell32.dll,44" },
        @{ Name = 'Disable VBS'; Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$vbsLauncherPath`" -Action Disable"; Description = 'Disable Virtualization-Based Security and Credential Guard'; Icon = "$env:SystemRoot\System32\shell32.dll,44" },
        @{ Name = 'Restore Defender'; Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$restoreLauncherPath`""; Description = 'Restore Defender files and registry data from saved schemas; Windows Security App may be non-restorable'; Icon = "$env:SystemRoot\System32\imageres.dll,73" }
    )

    foreach ($item in $shortcuts) {
        $shortcutPath = Join-Path $shortcutDir ($item.Name + '.lnk')
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $powershellExe
        $shortcut.Arguments = $item.Arguments
        $shortcut.WorkingDirectory = $programDataRoot
        $shortcut.Description = $item.Description
        $shortcut.IconLocation = $item.Icon
        $shortcut.Save()
    }
}

# -----------------------------------------------------------------------------
# Function definitions
# -----------------------------------------------------------------------------
function Setup-Verification {
    Write-Host "Staging verification script for post-reboot..." -ForegroundColor Cyan
    $targetDir = "C:\ProgramData\Gallery Inc\Defender Remover"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # Conținutul fișierului batch (verify.bat)
    $batchScript = @'
@echo off
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Windows Defender Remover Verification
color 0A

:: =========================================================
:: Windows Defender Remover - Verification Script
:: ---------------------------------------------------------
:: Purpose:
::   Verifies whether the main Windows Defender / Windows
::   Security components appear to have been removed after
::   running the remover and rebooting.
::
:: Notes:
::   - Run as Administrator
::   - Run AFTER the final reboot
::   - This script does NOT remove anything
::   - It only checks and reports results
:: =========================================================

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo [ERROR] Please run this file as Administrator.
    echo.
    pause
    exit /b 1
)

set /a OK=0
set /a WARN=0
set /a KO=0

cls
echo =========================================================
echo   WINDOWS DEFENDER REMOVER - VERIFICATION
echo =========================================================
echo.
echo Run this check AFTER the final reboot.
echo.

call :section "1) Leftover folders removed by S"
call :check_folder_missing "C:\ProgramData\Microsoft\Windows Defender" "ProgramData\Microsoft\Windows Defender"
call :check_folder_missing "C:\Program Files\Windows Defender" "Program Files\Windows Defender"
call :check_folder_missing "C:\Program Files (x86)\Windows Defender" "Program Files (x86)\Windows Defender"
call :check_folder_missing "C:\Program Files\Windows Defender Advanced Threat Protection" "Program Files\Windows Defender Advanced Threat Protection"

call :section "2) Services / drivers the tool is supposed to remove"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" "WinDefend service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" "WdFilter driver"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" "WdBoot driver"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" "WdNisSvc service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" "WdNisDrv driver"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\wscsvc" "wscsvc service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" "SecurityHealthService"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" "SgrmBroker service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\SgrmAgent" "SgrmAgent service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\MsSecCore" "MsSecCore service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\MsSecFlt" "MsSecFlt driver"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\MsSecWfp" "MsSecWfp service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\webthreatdefsvc" "webthreatdefsvc service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\webthreatdefusersvc" "webthreatdefusersvc service"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\whesvc" "whesvc service"

call :section "3) Windows Security App (SecHealthUI)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = Get-AppxPackage -AllUsers *SecHealthUI* -ErrorAction SilentlyContinue; $p = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; $found = $false; foreach ($item in $p) { if ($item.PackageName -like '*SecHealthUI*') { $found = $true } }; if (($null -ne $a) -or $found) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    call :ko "SecHealthUI is still present"
) else (
    call :ok "SecHealthUI is absent"
)

call :section "4) Windows Defender scheduled tasks"
schtasks /query /fo list /v 2>nul | findstr /I /C:"\Microsoft\Windows\Windows Defender\" >nul
if errorlevel 1 (
    call :ok "No Windows Defender scheduled tasks found"
) else (
    call :warn "Windows Defender scheduled tasks are still present"
)

call :section "5) Consistency checks (WARN if they do not match)"
call :check_reg_contains_warn "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "SettingsPageVisibility" "hide:windowsdefender;" "Windows Security page is hidden"
call :check_reg_contains_warn "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" "off" "Explorer SmartScreen is set to off"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" "0x0" "EnableSmartScreen = 0"
call :check_reg_contains_warn "HKLM\SOFTWARE\Microsoft\Windows Security Health\Platform" "Registered" "0x0" "Windows Security Health Registered = 0"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" "0x1" "DisableAntiSpyware = 1"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" "0x1" "DisableRealtimeMonitoring = 1"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpynetReporting" "0x0" "SpynetReporting = 0"

echo.
echo =========================================================
echo                         SUMMARY
echo =========================================================
echo OK   : %OK%
echo WARN : %WARN%
echo KO   : %KO%
echo.

if %KO% EQU 0 (
    if %WARN% EQU 0 (
        schtasks /delete /tn "DefenderRemoverVerify" /f >nul 2>&1
        echo FINAL RESULT: everything appears to have been removed correctly.
    ) else (
        schtasks /delete /tn "DefenderRemoverVerify" /f >nul 2>&1
        echo FINAL RESULT: removal was probably successful, but some secondary checks should be reviewed.
    )
) else (
    schtasks /delete /tn "DefenderRemoverVerify" /f >nul 2>&1
    echo FINAL RESULT: something still appears to be present or not fully removed.
)

echo.
echo Press any key to close...
pause >nul
exit /b

:section
echo.
echo ---------------------------------------------------------
echo %~1
echo ---------------------------------------------------------
exit /b

:check_folder_missing
if exist "%~1" (
    call :ko "%~2 PRESENT"
) else (
    call :ok "%~2 ABSENT"
)
exit /b

:check_reg_missing
reg query "%~1" >nul 2>&1
if errorlevel 1 (
    call :ok "%~2 ABSENT"
) else (
    call :ko "%~2 PRESENT"
)
exit /b

:check_reg_contains_warn
reg query "%~1" /v "%~2" 2>nul | findstr /I /C:"%~3" >nul
if errorlevel 1 (
    call :warn "%~4 not found / different than expected"
) else (
    call :ok "%~4"
)
exit /b

:ok
set /a OK+=1
echo [OK]   %~1
exit /b

:warn
set /a WARN+=1
echo [WARN] %~1
exit /b

:ko
set /a KO+=1
echo [KO]   %~1
exit /b
'@
    $batchPath = "$targetDir\verify.bat"
    $batchScript | Out-File -FilePath $batchPath -Encoding ASCII -Force

    $taskName = "DefenderRemoverVerify"
    $currentUser = "$env:USERDOMAIN\$env:USERNAME"
     try {
        # Action: run cmd.exe /c with the batch file path
        $action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c `"$batchPath`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest

        # Register the task (overwrite if exists)
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force -ErrorAction Stop
        Write-Host "Task created successfully (ScheduledTasks module)." -ForegroundColor Green
    } catch {
        Write-Host "Error creating task: $_" -ForegroundColor Red
        Write-Host "Trying fallback with schtasks..." -ForegroundColor Yellow
        $cmdLine = "cmd.exe /c `"$batchPath`""
        $escapedCmd = $cmdLine -replace '"', '\"'
        $output = schtasks /Create /TN $taskName /TR "`"$escapedCmd`"" /SC ONLOGON /RL HIGHEST /RU "$currentUser" /F 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error creating task (schtasks): $output" -ForegroundColor Red
        } else {
            Write-Host "Task created successfully (schtasks)." -ForegroundColor Green
        }
    }
}

function Remove-Files {
    Write-Host 'Removing Defender files...' -ForegroundColor Cyan
    $session = New-DefenderBackupSession -RemovalMode 'FilesOnly'
    $folders = @(
        'C:\ProgramData\Microsoft\Windows Defender',
        'C:\Program Files\Windows Defender',
        'C:\Program Files (x86)\Windows Defender',
        'C:\Program Files\Windows Defender Advanced Threat Protection'
    )

    foreach ($folder in $folders) {
        Backup-AndRemoveDefenderDirectory -Session $session -SourcePath $folder | Out-Null
    }

    Complete-DefenderBackupSession -Session $session -RebootRecommended $true
    Write-Host "Backup schema: $($session.Root)" -ForegroundColor Green
    Write-Host 'A restart is recommended after the file operation.' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit
}

function Test-WindowsSecurityAppPresent {
    try {
        $installed = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*SecHealthUI*' -or $_.PackageFullName -like '*SecHealthUI*' })
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like '*SecHealthUI*' })
        return (($installed.Count -gt 0) -or ($provisioned.Count -gt 0))
    } catch {
        return $true
    }
}

function Confirm-IrreversibleSecurityAppRemoval {
    Write-Host ''
    Write-Host '!!! IRREVERSIBLE ACTION !!!' -ForegroundColor Red
    Write-Host 'The Windows Security App (SecHealthUI) package will be removed for all users and deprovisioned.' -ForegroundColor Yellow
    Write-Host 'Restore Defender can restore saved files and registry data, but it cannot reinstall this app package.' -ForegroundColor Yellow
    Write-Host 'The package will be explicitly marked as NOT RESTORABLE in the backup schema.' -ForegroundColor Yellow
    Write-Host ''
    $confirmation = Read-Host 'Type REMOVE SECURITY APP to continue'
    return ($confirmation -ceq 'REMOVE SECURITY APP')
}

function Remove-Defender {
    if (-not (Confirm-IrreversibleSecurityAppRemoval)) {
        Write-Host 'Removal cancelled. No Defender components were changed.' -ForegroundColor Yellow
        return
    }

    $session = New-DefenderBackupSession -RemovalMode 'DefenderAndWindowsSecurityApp' -WindowsSecurityAppRequested

    Write-Host 'Removing Windows Security UWP App (this part is not restorable by this tool)...' -ForegroundColor Cyan
    try {
        $appWasPresentBeforeRemoval = Test-WindowsSecurityAppPresent
        $session.Manifest.WindowsSecurityApp.DetectedBefore = [bool]$appWasPresentBeforeRemoval
        Write-DefenderManifest -Session $session
        $appRemovalScript = Join-Path $PSScriptRoot 'RemoveSecHealthApp.ps1'
        $powerRun = Join-Path $PSScriptRoot 'PowerRun.exe'
        $appPowerShell = if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { Join-Path $env:windir 'Sysnative\WindowsPowerShell\v1.0\powershell.exe' } else { Join-Path $env:windir 'System32\WindowsPowerShell\v1.0\powershell.exe' }
        if (-not (Test-Path -LiteralPath $appPowerShell)) { $appPowerShell = 'powershell.exe' }
        if (Test-Path -LiteralPath $powerRun -PathType Leaf) {
            $arguments = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}"' -f $appPowerShell, $appRemovalScript
            Start-Process -FilePath $powerRun -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop | Out-Null
        } else {
            Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$appRemovalScript`"" -Verb RunAs -Wait -PassThru -ErrorAction Stop | Out-Null
        }
        if (Test-WindowsSecurityAppPresent) {
            $session.Manifest.WindowsSecurityApp.Status = 'RemovalFailedOrStillPresent'
            $session.Manifest.WindowsSecurityApp.Reason = 'Removal was requested, but the AppX package or provisioned package is still detected.'
            Add-DefenderManifestWarning -Session $session -Message 'Windows Security App removal could not be confirmed.'
            Write-Host 'WARNING: Windows Security App is still detected; review the AppX removal output.' -ForegroundColor Yellow
        } elseif ($appWasPresentBeforeRemoval) {
            $session.Manifest.WindowsSecurityApp.Status = 'RemovedNotRestorable'
            $session.Manifest.WindowsSecurityApp.Reason = 'SecHealthUI was present before removal and is now absent. Restore Defender will not attempt to reinstall this package.'
            Write-Host 'Windows Security App removal confirmed. This component is not restorable by Restore Defender.' -ForegroundColor Yellow
        } else {
            $session.Manifest.WindowsSecurityApp.Status = 'AlreadyAbsent'
            $session.Manifest.WindowsSecurityApp.Reason = 'SecHealthUI was not detected before removal. No AppX package was available to back up or restore.'
            Write-Host 'Windows Security App was already absent; no AppX package removal was required.' -ForegroundColor Yellow
        }
        Write-DefenderManifest -Session $session
    } catch {
        $session.Manifest.WindowsSecurityApp.Status = 'RemovalFailed'
        $session.Manifest.WindowsSecurityApp.Reason = $_.Exception.Message
        Add-DefenderManifestWarning -Session $session -Message "Windows Security App removal failed: $($_.Exception.Message)"
        Write-Host "ERROR removing Windows Security App: $_" -ForegroundColor Red
    }

    Write-Host 'Backing up and unregistering Windows Defender registry components...' -ForegroundColor Cyan
    $powerRunPath = Join-Path $PSScriptRoot 'PowerRun.exe'
    $regFiles = @(
        Get-ChildItem -Path (Join-Path $PSScriptRoot 'Remove_Defender') -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue
        Get-ChildItem -Path (Join-Path $PSScriptRoot 'Remove_SecurityComp') -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue
    )
    foreach ($regFile in $regFiles) {
        Invoke-DefenderRegistryFileWithBackup -Session $session -RegFile $regFile.FullName -PowerRunPath $powerRunPath | Out-Null
    }

    Write-Host 'Backing up and removing SmartScreen files...' -ForegroundColor Cyan
    $smartscreenFiles = @(
        "$env:windir\System32\smartscreen.exe",
        "$env:windir\System32\smartscreen.dll",
        "$env:windir\System32\smartscreenps.dll"
    )
    foreach ($file in $smartscreenFiles) {
        Backup-AndRemoveDefenderFile -Session $session -SourcePath $file | Out-Null
    }

    Complete-DefenderBackupSession -Session $session -RebootRecommended $true
    Write-Host "Backup schema saved: $($session.Root)" -ForegroundColor Green
    Setup-Verification
    Write-Host 'Restarting Windows in 10 seconds...' -ForegroundColor Yellow
    shutdown /r /f /t 10
    exit
}

function Remove-Antivirus {
    Write-Host 'Removing Windows Defender Antivirus components...' -ForegroundColor Cyan
    $session = New-DefenderBackupSession -RemovalMode 'AntivirusOnly'
    $powerRunPath = Join-Path $PSScriptRoot 'PowerRun.exe'
    $regFiles = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Remove_Defender') -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue)
    foreach ($regFile in $regFiles) {
        Invoke-DefenderRegistryFileWithBackup -Session $session -RegFile $regFile.FullName -PowerRunPath $powerRunPath | Out-Null
    }

    Complete-DefenderBackupSession -Session $session -RebootRecommended $true
    Write-Host "Backup schema saved: $($session.Root)" -ForegroundColor Green
    Setup-Verification
    Write-Host 'Restarting Windows in 5 minutes...' -ForegroundColor Yellow
    Start-Sleep -Seconds 300
    shutdown /r /f /t 10
    exit
}

# Install/update the Defender Remover shortcuts in the all-users Start Menu.
try {
    Install-DefenderStartMenuShortcuts
} catch {
    Write-Warning "Could not create Defender Remover Start Menu shortcuts: $_"
}

# -----------------------------------------------------------------------------
# Argument / menu handling
# -----------------------------------------------------------------------------
$arg = $args[0]
if ($arg -eq 'y') {
    Remove-Defender
} elseif ($arg -eq 'a') {
    Remove-Antivirus
} elseif ($arg -eq 's') {
    Remove-Files
} else {
    # Display menu. Use Console I/O for the final prompt because Read-Host can
    # render out of order in some PS2EXE -ConHost builds.
    Clear-Host
    $runtimeProcesses = @(Get-DefenderRuntimeProcessSnapshot)
    if ($runtimeProcesses.Count -gt 0) {
        Write-Host '[NOTICE] Defender-related processes detected:' -ForegroundColor Yellow
        foreach ($runtimeProcess in $runtimeProcesses) {
            Write-Host ("  {0}.exe (PID {1})" -f $runtimeProcess.Name, $runtimeProcess.Pid) -ForegroundColor Yellow
        }
        Write-Host 'No Defender process will be terminated or have its security token modified.' -ForegroundColor Yellow
        Write-Host ''
    } else {
        Write-Host 'Defender process check: no core Defender process detected at startup.' -ForegroundColor DarkGray
        Write-Host ''
    }
    Write-Host "------ Defender Remover Script , version $defenderremoverver ------" -ForegroundColor Green
    Write-Host ""
    Write-Host "Do you want to remove Windows Defender and alongside components? After this you'll need to reboot."
    Write-Host "A backup schema is created for files and registry changes. Windows Security App is NOT restorable if removed." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[Y] Remove Windows Defender Antivirus + Windows Security App (IRREVERSIBLE APP REMOVAL)" -ForegroundColor Yellow
    Write-Host "[A] Remove Windows Defender Antivirus components (keeps Windows Security App)"
    Write-Host "[S] Remove Defender Files (if you removed antivirus first)"
    Write-Host ""
    [Console]::Out.Flush()
    [Console]::Write('Enter choice (Y/A/S): ')
    [Console]::Out.Flush()
    $choice = [Console]::ReadLine()
    if ($null -eq $choice) { $choice = '' }
    switch ($choice.Trim().ToUpperInvariant()) {
        'Y' { Remove-Defender }
        'A' { Remove-Antivirus }
        'S' { Remove-Files }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit 1
        }
    }
}