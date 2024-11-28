@set defenderremoverver=12.8.2
@setlocal DisableDelayedExpansion
@echo off
pushd "%CD%"
CD /D "%~dp0"

:: Arguments Section
IF "%1"== "y" GOTO :removedef
IF "%1"== "Y" GOTO :removedef
IF "%1"== "a" GOTO :removeantivirus
IF "%1"== "A" GOTO :removeantivirus
IF "%1"== "S" GOTO :disablemitigations
IF "%1"== "s" GOTO :disablemitigations
:--------------------------------------


:--------------------------------------
cls
echo ------ Defender Remover Script , version %defenderremoverver% ------
echo Select an option:
echo.
echo Do you want to remove Windows Defender and alongside components? After this you'll need to reboot.
echo If you PC have a Microsoft Pluton Chip, you can disable from BIOS anytime. (This script removes the integration of Pluton Chip Support and Processing from Windows.)
echo After confirmation of Removal, your Device will RESTART!!
echo A backup and/or System Restore point is recommended.
echo [Y] Remove Windows Defender Antivirus + Disable All Security Mitigations
echo [A] Remove Windows Defender only, but keep UAC Enabled
echo [S] Disable All Security Mitigations
choice /C:yas /N
if errorlevel==3 goto disablemitigations
if errorlevel==2 goto removeantivirus
if errorlevel==1 goto removedef
:--------------------------------------


:--------------------------------------
goto :eof
:--------------------------------------

:--------------------------------------
:removedef
CLS
bcdedit /set hypervisorlaunchtype off

CLS
echo Removing Windows Security UWP App...
Powershell -noprofile -executionpolicy bypass -file "%~dp0\RemoveSecHealthApp.ps1"

CLS
echo Unregister Windows Defender Security Components...
FOR /R %%f IN (Remove_defender\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
FOR /R %%f IN (Remove_defender\*.reg) DO regedit.exe /s "%%f"
FOR /R %%f IN (Remove_SecurityComp\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
CLS
for %%d in ("C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest" "C:\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest" "C:\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest" "C:\Windows\System32\SecurityAndMaintenance_Error.png" "C:\Windows\System32\SecurityAndMaintenance.png" "C:\Windows\System32\SecurityHealthSystray.exe" "C:\Windows\System32\SecurityHealthService.exe" "C:\Windows\System32\SecurityHealthHost.exe" "C:\Windows\System32\drivers\SgrmAgent.sys" "C:\Windows\System32\drivers\WdDevFlt.sys" "C:\Windows\System32\drivers\WdBoot.sys" "C:\Windows\System32\drivers\WdFilter.sys" "C:\Windows\System32\wscsvc.dll" "C:\Windows\System32\drivers\WdNisDrv.sys" "C:\Windows\System32\wscsvc.dll" "C:\Windows\System32\wscproxystub.dll" "C:\Windows\System32\wscisvif.dll" "C:\Windows\System32\SecurityHealthProxyStub.dll" "C:\Windows\System32\smartscreen.dll" "C:\Windows\SysWOW64\smartscreen.dll" "C:\Windows\System32\smartscreen.exe" "C:\Windows\SysWOW64\smartscreen.exe" "C:\Windows\System32\DWWIN.EXE" "C:\Windows\SysWOW64\smartscreenps.dll" "C:\Windows\System32\smartscreenps.dll" "C:\Windows\System32\SecurityHealthCore.dll" "C:\Windows\System32\SecurityHealthSsoUdk.dll" "C:\Windows\System32\SecurityHealthUdk.dll" "C:\Windows\System32\SecurityHealthAgent.dll" "C:\Windows\System32\wscapi.dll" "C:\Windows\System32\wscadminui.exe" "C:\Windows\SysWOW64\GameBarPresenceWriter.exe" "C:\Windows\System32\GameBarPresenceWriter.exe" "C:\Windows\SysWOW64\DeviceCensus.exe" "C:\Windows\SysWOW64\CompatTelRunner.exe" "C:\Windows\system32\drivers\msseccore.sys" "C:\Windows\system32\drivers\MsSecFltWfp.sys" "C:\Windows\system32\drivers\MsSecFlt.sys") DO PowerRun cmd.exe /c del /f "%%d"
:: part 2
for %%d in ("C:\Windows\WinSxS\amd64_security-octagon*" "C:\Windows\WinSxS\x86_windows-defender*" "C:\Windows\WinSxS\wow64_windows-defender*" "C:\Windows\WinSxS\amd64_windows-defender*" "C:\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy" "C:\ProgramData\Microsoft\Windows Defender" "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection" "C:\Program Files (x86)\Windows Defender Advanced Threat Protection" "C:\Program Files\Windows Defender Advanced Threat Protection" "C:\ProgramData\Microsoft\Windows Security Health" "C:\ProgramData\Microsoft\Storage Health" "C:\WINDOWS\System32\drivers\wd" "C:\Program Files (x86)\Windows Defender" "C:\Program Files\Windows Defender" "C:\Windows\System32\SecurityHealth" "C:\Windows\System32\WebThreatDefSvc" "C:\Windows\System32\Sgrm" "C:\Windows\Containers\WindowsDefenderApplicationGuard.wim" "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Defender" "C:\Windows\System32\Tasks_Migrated\Microsoft\Windows\Windows Defender" "C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender" "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender" "C:\Windows\System32\HealthAttestationClient" "C:\Windows\GameBarPresenceWriter" "C:\Windows\bcastdvr" "C:\Windows\Containers\serviced\WindowsDefenderApplicationGuard.wim") do PowerRun cmd.exe /c rmdir "%%~d" /s /q
echo Your PC will reboot in 10 seconds..
timeout 3
shutdown /r /f /t 10
exit
:--------------------------------------


:--------------------------------------
:removeantivirus
CLS
bcdedit /set hypervisorlaunchtype off

CLS
echo Removing Windows Security UWP App...
Powershell -noprofile -executionpolicy bypass -file "%~dp0\RemoveSecHealthApp.ps1"

CLS
echo Unregister Windows Defender Security Components...
FOR /R %%f IN (Remove_defender\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
FOR /R %%f IN (Remove_defender\*.reg) DO regedit.exe /s "%%f"
CLS
for %%d in ("C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest" "C:\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest" "C:\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest" "C:\Windows\System32\SecurityAndMaintenance_Error.png" "C:\Windows\System32\SecurityAndMaintenance.png" "C:\Windows\System32\SecurityHealthSystray.exe" "C:\Windows\System32\SecurityHealthService.exe" "C:\Windows\System32\SecurityHealthHost.exe" "C:\Windows\System32\drivers\SgrmAgent.sys" "C:\Windows\System32\drivers\WdDevFlt.sys" "C:\Windows\System32\drivers\WdBoot.sys" "C:\Windows\System32\drivers\WdFilter.sys" "C:\Windows\System32\wscsvc.dll" "C:\Windows\System32\drivers\WdNisDrv.sys" "C:\Windows\System32\wscsvc.dll" "C:\Windows\System32\wscproxystub.dll" "C:\Windows\System32\wscisvif.dll" "C:\Windows\System32\SecurityHealthProxyStub.dll" "C:\Windows\System32\smartscreen.dll" "C:\Windows\SysWOW64\smartscreen.dll" "C:\Windows\System32\smartscreen.exe" "C:\Windows\SysWOW64\smartscreen.exe" "C:\Windows\System32\DWWIN.EXE" "C:\Windows\SysWOW64\smartscreenps.dll" "C:\Windows\System32\smartscreenps.dll" "C:\Windows\System32\SecurityHealthCore.dll" "C:\Windows\System32\SecurityHealthSsoUdk.dll" "C:\Windows\System32\SecurityHealthUdk.dll" "C:\Windows\System32\SecurityHealthAgent.dll" "C:\Windows\System32\wscapi.dll" "C:\Windows\System32\wscadminui.exe" "C:\Windows\SysWOW64\GameBarPresenceWriter.exe" "C:\Windows\System32\GameBarPresenceWriter.exe" "C:\Windows\SysWOW64\DeviceCensus.exe" "C:\Windows\SysWOW64\CompatTelRunner.exe" "C:\Windows\system32\drivers\msseccore.sys" "C:\Windows\system32\drivers\MsSecFltWfp.sys" "C:\Windows\system32\drivers\MsSecFlt.sys") DO PowerRun cmd.exe /c del /f "%%d"
:: part 2
for %%d in ("C:\Windows\WinSxS\amd64_security-octagon*" "C:\Windows\WinSxS\x86_windows-defender*" "C:\Windows\WinSxS\wow64_windows-defender*" "C:\Windows\WinSxS\amd64_windows-defender*" "C:\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy" "C:\ProgramData\Microsoft\Windows Defender" "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection" "C:\Program Files (x86)\Windows Defender Advanced Threat Protection" "C:\Program Files\Windows Defender Advanced Threat Protection" "C:\ProgramData\Microsoft\Windows Security Health" "C:\ProgramData\Microsoft\Storage Health" "C:\WINDOWS\System32\drivers\wd" "C:\Program Files (x86)\Windows Defender" "C:\Program Files\Windows Defender" "C:\Windows\System32\SecurityHealth" "C:\Windows\System32\WebThreatDefSvc" "C:\Windows\System32\Sgrm" "C:\Windows\Containers\WindowsDefenderApplicationGuard.wim" "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Defender" "C:\Windows\System32\Tasks_Migrated\Microsoft\Windows\Windows Defender" "C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender" "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender" "C:\Windows\System32\HealthAttestationClient" "C:\Windows\GameBarPresenceWriter" "C:\Windows\bcastdvr" "C:\Windows\Containers\serviced\WindowsDefenderApplicationGuard.wim") do PowerRun cmd.exe /c rmdir "%%~d" /s /q
echo Your PC will reboot in 10 seconds..
timeout 3
shutdown /r /f /t 10
exit
:--------------------------------------

:--------------------------------------
:disablemitigations
CLS
bcdedit /set hypervisorlaunchtype off

CLS
echo Disabling Security Mitigations...
FOR /R %%f IN (Remove_SecurityComp\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
CLS
echo Your PC will reboot in 10 seconds..
timeout 3
shutdown /r /f /t 10
exit
:--------------------------------------