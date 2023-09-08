@echo off & pushd "%CD%" & CD /D "%~dp0"
:--------------------------------------
:: Arguments Section
IF "%1"== NUL GOTO :menu
IF "%1"== "/y" GOTO :removedef
IF "%1"== "/Y" GOTO :removedef
IF "%1"== "/N" GOTO :tweaksdef
IF "%1"== "/n" GOTO :tweaksdef
IF "%1"== "/e" GOTO :enabledefanti
IF "%1"== "/E" GOTO :enabledefanti
IF "%1"== "/M" GOTO :tweaksdefanti
IF "%1"== "/m" GOTO :tweaksdefanti
IF "%1"== "/R" GOTO :enabledef
IF "%1"== "/r" GOTO :enabledef
:--------------------------------------

:--------------------------------------
:menu
 echo ------Defender Remover Script , version 12.5 ------
echo Select an option:
 echo.
:: echo Press (Y) for removing Defender and Security Components (old method, breaking Windows Updates/UWP in some version of Windows, removes files and unregisters classes)
echo Press (N) for disabling Defender and Security Components (safe)
echo Press (M) for disabling Defender Antivirus only (safe)
echo Press (E) for enabling Defender (restore actions where M is pressed)
echo Press (R) for enabling Defender and Security Components (restore actions where N is pressed)
::echo Press (J) for modifying an Windows ISO by removing Defender Services.
set /P c=Select one of the option to continue.
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "E" goto :enabledefanti
if /I "%c%" EQU "M" goto :tweaksdefanti
if /I "%c%" EQU "R" goto :enabledef
if /I "%c%" EQU "J" goto :image
:--------------------------------------

:--------------------------------------
:removedef
cls & echo Killing Tasks...
for /f "delims=" %%i in (Remover\TKL.txt) do (taskkill.exe /f /im "%%i") >nul
cls & echo Removing Windows Security UWP...
for /d %%f in ("C:\Program Files\WindowsApps\Microsoft.SecHealthUI*") do (PowerRun.exe  cmd.exe /c rmdir /s /q "%%f") >nul
cls & echo Applying Registry Files...
for /r %%k in (Remover\REGS\*.reg) do (PowerRun.exe  regedit.exe /s "%%k") >nul
cls & echo Removing Windows Defender/Security Components Files...
for /f "delims=" %%i in (Remover\FDL.txt) do (PowerRun.exe  cmd.exe /c del /f /q "%%i") 1>nul
for /f "delims=" %%i in (Remover\DDL.txt) do (PowerRun.exe  cmd.exe /c rmdir /s /q "%%i") >nul
timeout /t 5 /nobreak
shutdown /r /f /t 0
:--------------------------------------

:--------------------------------------
:image
start /wait ISOCreator.cmd
:--------------------------------------

:--------------------------------------

:tweaksdef
CLS & echo Disable Defender and Security Components...
:: Disable Defender's Scheduled Tasks
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable
PowerRun.exe regedit.exe /s "DisablerS\Disable.reg" >nul
taskkill /f /im smartscreen.exe
PowerRun.exe cmd.exe /c move /y "C:\Windows\System32\smartscreen.exe" "C:\Windows\System32\smartscreen.plm"
cls & echo Antivirus and Security Components Disabled. A reboot is needed!
timeout /t 5 /nobreak
shutdown /r /f /t 0
:--------------------------------------

:--------------------------------------
:enabledef
CLS & echo Enable Defender and Security Components...
:: Enable Defender's Scheduled Tasks
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable
PowerRun.exe regedit.exe /s "DisablerS\Enable.reg"
PowerRun.exe cmd.exe /c move /y "C:\Windows\System32\smartscreen.plm" "C:\Windows\System32\smartscreen.exe"
cls & echo Antivirus and Windows Security Components Enabled. A reboot is needed!
timeout /t 5 /nobreak
shutdown /r /f /t 0
:--------------------------------------

:tweaksdefanti
CLS & echo Disabling Defender...
:: Disable Defender's Scheduled Tasks
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable
PowerRun.exe regedit.exe /s "Disabler\Disable.reg" >nul
taskkill /f /im smartscreen.exe
PowerRun.exe cmd.exe /c move /y "C:\Windows\System32\smartscreen.exe" "C:\Windows\System32\smartscreen.plm"
cls & echo Antivirus disabled. A reboot is needed!
timeout /t 5 /nobreak
shutdown /r /f /t 0
:--------------------------------------

:--------------------------------------
:enabledefanti
CLS & echo Enable Defender...
:: Enable Defender's Scheduled Tasks
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable
PowerRun.exe regedit.exe /s "Disabler\Enable.reg"
taskkill /f /im smartscreen.exe
PowerRun.exe cmd.exe /c move /y "C:\Windows\System32\smartscreen.plm" "C:\Windows\System32\smartscreen.exe"
cls & echo Antivirus Enabled. A reboot is needed!
timeout /t 5 /nobreak
shutdown /r /f /t 0
:--------------------------------------