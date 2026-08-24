@set defenderremoverver=13.0
@setlocal DisableDelayedExpansion
@echo off
color 0A
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
pushd "%CD%"
CD /D "%~dp0"
taskkill /f /im smartscreen.exe >nul 2>&1
taskkill /f /im SecHealthUI.exe >nul 2>&1

:: Arguments Section
IF /I "%1"=="y" GOTO :removedef
IF /I "%1"=="a" GOTO :removeantivirus
IF /I "%1"=="s" GOTO :removalfiles

:menu
echo ------ Defender Remover Script , version %defenderremoverver% ------
echo Select an option:
echo.
echo Do you want to remove Windows Defender and alongside components? After this you'll need to reboot.
echo A backup and/or System Restore point is recommended.
echo [Y] Remove Windows Defender Antivirus + Windows Security App
echo [A] Remove Windows Defender Antivirus App (keeps Windows Security App, it will be back if you update)
echo [S] Remove Defender Files (if you removed antivirus first)
choice /C:yas /N
if errorlevel==3 goto removalfiles
if errorlevel==2 goto removeantivirus
if errorlevel==1 goto removedef

:removalfiles
PowerRun cmd.exe /k files_removal.bat
pause
goto :eof

:removedef
echo Removing Windows Security UWP App...
PowerRun powershell.exe -noprofile -executionpolicy bypass -file "RemoveSecHealthApp.ps1"

echo Unregister Windows Defender Security Components...
FOR /R %%f IN (Remove_defender\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
FOR /R %%f IN (Remove_SecurityComp\*.reg) DO PowerRun.exe regedit.exe /s "%%f"

:: remove smart screen
takeown /f "%windir%\System32\smartscreen.exe" /a >nul 2>&1
icacls "%windir%\System32\smartscreen.exe" /grant administrators:F >nul 2>&1
del /f /q "%windir%\System32\smartscreen.exe" >nul 2>&1

takeown /f "%windir%\System32\smartscreen.dll" /a >nul 2>&1
icacls "%windir%\System32\smartscreen.dll" /grant administrators:F >nul 2>&1
del /f /q "%windir%\System32\smartscreen.dll" >nul 2>&1

takeown /f "%windir%\System32\smartscreenps.dll" /a >nul 2>&1
icacls "%windir%\System32\smartscreenps.dll" /grant administrators:F >nul 2>&1
del /f /q "%windir%\System32\smartscreenps.dll" >nul 2>&1

call :setup_verification

timeout 3
shutdown /r /f /t 10
exit

:removeantivirus
echo Removing Windows Defender Antivirus Components...
FOR /R %%f IN (Remove_defender\*.reg) DO PowerRun.exe regedit.exe /s "%%f"

call :setup_verification

timeout 3
shutdown /r /f /t 10
exit

:setup_verification
echo Staging verification script for post-reboot...
if not exist "C:\ProgramData\Gallery Inc\Defender Remover" mkdir "C:\ProgramData\Gallery Inc\Defender Remover" >nul 2>&1
copy /y "%~dp0verify.bat" "C:\ProgramData\Gallery Inc\Defender Remover\verify.bat" >nul 2>&1
schtasks /create /tn "DefenderRemoverVerify" /tr "\"C:\ProgramData\Gallery Inc\Defender Remover\verify.bat\"" /sc onlogon /rl highest /f >nul 2>&1
exit /b