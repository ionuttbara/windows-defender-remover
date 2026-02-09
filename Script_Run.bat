@set defenderremoverver=13.0
@setlocal DisableDelayedExpansion
@echo off

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
pushd "%CD%"
CD /D "%~dp0"



:: Arguments Section
IF "%1"== "y" GOTO :removedef
IF "%1"== "Y" GOTO :removedef
IF "%1"== "a" GOTO :removeantivirus
IF "%1"== "A" GOTO :removeantivirus
:--------------------------------------


:--------------------------------------
cls
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
:--------------------------------------

:--------------------------------------
:removalfiles
PowerRun cmd.exe /k files_removal.bat
pause
:--------------------------------------




:--------------------------------------
goto :eof
:--------------------------------------

:--------------------------------------
:removedef
CLS

CLS
echo Removing Windows Security UWP App...

Powerrun powershell.exe -noprofile -executionpolicy bypass -file "RemoveSecHealthApp.ps1"
CLS
echo Unregister Windows Defender Security Components...
FOR /R %%f IN (Remove_defender\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
FOR /R %%f IN (Remove_defender\*.reg) DO regedit.exe /s "%%f"
FOR /R %%f IN (Remove_SecurityComp\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
timeout 3
shutdown /r /f /t 10
exit
:--------------------------------------


:--------------------------------------
:removeantivirus
CLS
echo Removing Windows Security UWP App...
FOR /R %%f IN (Remove_defender\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
FOR /R %%f IN (Remove_defender\*.reg) DO regedit.exe /s "%%f"
CLS
timeout 3
shutdown /r /f /t 10
exit
:--------------------------------------
