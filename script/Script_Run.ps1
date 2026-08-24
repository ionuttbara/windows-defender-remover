# Windows Defender Remover - PowerShell version
$defenderremoverver = "13.0"

# -----------------------------------------------------------------------------
# Admin rights check and elevation
# -----------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($args -join ' ')"
    exit
}

Set-Location $PSScriptRoot

# Kill processes that may interfere
Stop-Process -Name smartscreen -Force -ErrorAction SilentlyContinue
Stop-Process -Name SecHealthUI -Force -ErrorAction SilentlyContinue

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
    Write-Host "Removing Defender files..." -ForegroundColor Cyan
    Start-Process -FilePath "$PSScriptRoot\PowerRun.exe" -ArgumentList "cmd.exe /k files_removal.bat" -Wait
    Read-Host "Press Enter to continue"
    exit
}

function Remove-Defender {
    Write-Host "Removing Windows Security UWP App..." -ForegroundColor Cyan
    Start-Process -FilePath "$PSScriptRoot\PowerRun.exe" -ArgumentList "powershell.exe -noprofile -executionpolicy bypass -file `"$PSScriptRoot\RemoveSecHealthApp.ps1`"" -Wait

    Write-Host "Unregister Windows Defender Security Components..." -ForegroundColor Cyan
    # Import all .reg files from Remove_defender and Remove_SecurityComp
    Get-ChildItem -Path "$PSScriptRoot\Remove_defender\*.reg" -Recurse | ForEach-Object {
        Start-Process -FilePath "$PSScriptRoot\PowerRun.exe" -ArgumentList "regedit.exe /s `"$($_.FullName)`"" -Wait
    }
    Get-ChildItem -Path "$PSScriptRoot\Remove_SecurityComp\*.reg" -Recurse | ForEach-Object {
        Start-Process -FilePath "$PSScriptRoot\PowerRun.exe" -ArgumentList "regedit.exe /s `"$($_.FullName)`"" -Wait
    }

    # Remove SmartScreen files
    Write-Host "Removing SmartScreen files..." -ForegroundColor Cyan
    $smartscreenFiles = @(
        "$env:windir\System32\smartscreen.exe",
        "$env:windir\System32\smartscreen.dll",
        "$env:windir\System32\smartscreenps.dll"
    )
    foreach ($file in $smartscreenFiles) {
        if (Test-Path $file) {
            try {
                # Use cmd /c to run takeown and icacls (more reliable in compiled environment)
                $null = cmd /c "takeown /f `"$file`" /a 2>&1"
                if ($LASTEXITCODE -ne 0) { 
                    Write-Host "WARNING: takeown failed for $file (exit code: $LASTEXITCODE)" -ForegroundColor Yellow 
                }
                $null = cmd /c "icacls `"$file`" /grant administrators:F 2>&1"
                if ($LASTEXITCODE -ne 0) { 
                    Write-Host "WARNING: icacls failed for $file (exit code: $LASTEXITCODE)" -ForegroundColor Yellow 
                }
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Host "Removed: $file" -ForegroundColor Green
            } catch {
                Write-Host "ERROR removing $file : $_" -ForegroundColor Red
            }
        } else {
            Write-Host "File not found: $file (skipping)" -ForegroundColor Yellow
        }
    }
    Setup-Verification
    shutdown /r /f /t 10
    exit
}

function Remove-Antivirus {
    Write-Host "Removing Windows Defender Antivirus Components..." -ForegroundColor Cyan
    Get-ChildItem -Path "$PSScriptRoot\Remove_defender\*.reg" -Recurse | ForEach-Object {
        Start-Process -FilePath "$PSScriptRoot\PowerRun.exe" -ArgumentList "regedit.exe /s `"$($_.FullName)`"" -Wait
    }

    Setup-Verification
    Start-Sleep -Seconds 300
    shutdown /r /f /t 10
    exit
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
    # Display menu
    Clear-Host
    Write-Host "------ Defender Remover Script , version $defenderremoverver ------" -ForegroundColor Green
    Write-Host ""
    Write-Host "Do you want to remove Windows Defender and alongside components? After this you'll need to reboot."
    Write-Host "A backup and/or System Restore point is recommended."
    Write-Host ""
    Write-Host "[Y] Remove Windows Defender Antivirus + Windows Security App"
    Write-Host "[A] Remove Windows Defender Antivirus App (keeps Windows Security App, it will be back if you update)"
    Write-Host "[S] Remove Defender Files (if you removed antivirus first)"
    Write-Host ""
    $choice = Read-Host "Enter choice (Y/A/S)"
    switch ($choice.ToUpper()) {
        'Y' { Remove-Defender }
        'A' { Remove-Antivirus }
        'S' { Remove-Files }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit 1
        }
    }
}