@echo off
setlocal enabledelayedexpansion
title Windows Defender Remover - Batch version
set "defenderremoverver=13.0"

:: -----------------------------------------------------------------------------
:: Admin rights check and elevation
:: -----------------------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"%~f0\" %*'"
    exit /b
)

:: Change to script directory
pushd "%~dp0"

:: Kill processes that may interfere
taskkill /f /im smartscreen.exe >nul 2>&1
taskkill /f /im SecHealthUI.exe >nul 2>&1

:: -----------------------------------------------------------------------------
:: Function definitions (subroutines)
:: -----------------------------------------------------------------------------
goto :main

:SetupVerification
    echo Staging verification script for post-reboot...
    set "targetDir=C:\ProgramData\Gallery Inc\Defender Remover"
    if not exist "%targetDir%" mkdir "%targetDir%" 2>nul

    :: Create verify.bat from embedded content
    echo Extracting verify.bat...
    (
        for /f "delims=" %%i in ('findstr /n "^" "%~f0"') do (
            set "line=%%i"
            set "line=!line:*:=!"
            if "!line!"=="::VERIFY_BAT_BEGIN" set extract=1
            if "!line!"=="::VERIFY_BAT_END" set extract=
            if defined extract (
                if not "!line!"=="::VERIFY_BAT_BEGIN" (
                    echo(!line!
                )
            )
        )
    ) > "%targetDir%\verify.bat"

    :: Create scheduled task to run verify.bat at logon
    set "taskName=DefenderRemoverVerify"
    set "currentUser=%USERDOMAIN%\%USERNAME%"
    schtasks /Create /TN "%taskName%" /TR "\"%targetDir%\verify.bat\"" /SC ONLOGON /RL HIGHEST /RU "%currentUser%" /F >nul 2>&1
    if errorlevel 1 (
        echo WARNING: Failed to create scheduled task via schtasks.
    ) else (
        echo Verification task created.
    )
exit /b

:RemoveFiles
    echo Removing Defender files...
    start /wait "" PowerRun.exe cmd.exe /k files_removal.bat
    echo Press any key to continue...
    pause >nul
    exit

:RemoveDefender
    echo Removing Windows Security UWP App...
    start /wait "" PowerRun.exe powershell.exe -noprofile -executionpolicy bypass -file "%CD%\RemoveSecHealthApp.ps1"

    echo Unregister Windows Defender Security Components...
    for /r "%CD%\Remove_defender" %%f in (*.reg) do (
        start /wait "" PowerRun.exe regedit.exe /s "%%f"
    )
    for /r "%CD%\Remove_SecurityComp" %%f in (*.reg) do (
        start /wait "" PowerRun.exe regedit.exe /s "%%f"
    )

    echo Removing SmartScreen files...
    set "smartscreenFiles=%windir%\System32\smartscreen.exe %windir%\System32\smartscreen.dll %windir%\System32\smartscreenps.dll"
    for %%f in (%smartscreenFiles%) do (
        if exist "%%f" (
            echo Taking ownership of %%f...
            takeown /f "%%f" /a >nul 2>&1
            icacls "%%f" /grant administrators:F >nul 2>&1
            del /f /q "%%f" 2>nul
            if exist "%%f" (
                echo ERROR: Failed to delete %%f
            ) else (
                echo Removed: %%f
            )
        ) else (
            echo File not found: %%f (skipping)
        )
    )

    call :SetupVerification
    shutdown /r /f /t 10
    exit

:RemoveAntivirus
    echo Removing Windows Defender Antivirus Components...
    for /r "%CD%\Remove_defender" %%f in (*.reg) do (
        start /wait "" PowerRun.exe regedit.exe /s "%%f"
    )

    call :SetupVerification
    timeout /t 300 /nobreak >nul
    shutdown /r /f /t 10
    exit

:main
:: -----------------------------------------------------------------------------
:: Argument / menu handling
:: -----------------------------------------------------------------------------
if /i "%~1"=="y" goto :RemoveDefender
if /i "%~1"=="a" goto :RemoveAntivirus
if /i "%~1"=="s" goto :RemoveFiles

:: Display menu
cls
echo ------ Defender Remover Script , version %defenderremoverver% ------
echo.
echo Do you want to remove Windows Defender and alongside components? After this you'll need to reboot.
echo A backup and/or System Restore point is recommended.
echo.
echo [Y] Remove Windows Defender Antivirus + Windows Security App
echo [A] Remove Windows Defender Antivirus App (keeps Windows Security App, it will be back if you update)
echo [S] Remove Defender Files (if you removed antivirus first)
echo.
set /p choice="Enter choice (Y/A/S): "
if /i "%choice%"=="Y" goto :RemoveDefender
if /i "%choice%"=="A" goto :RemoveAntivirus
if /i "%choice%"=="S" goto :RemoveFiles
echo Invalid choice. Exiting.
exit /b 1

:: -----------------------------------------------------------------------------
:: Embedded verify.bat content (extracted by SetupVerification)
:: -----------------------------------------------------------------------------
goto :EOF

::VERIFY_BAT_BEGIN
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
::VERIFY_BAT_END