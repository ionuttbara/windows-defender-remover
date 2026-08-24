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
        echo FINAL RESULT: everything appears to have been removed correctly.
    ) else (
        echo FINAL RESULT: removal was probably successful, but some secondary checks should be reviewed.
    )
) else (
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