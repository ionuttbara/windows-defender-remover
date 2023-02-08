:: Starting script
@echo off
pushd "%CD%"
CD /D "%~dp0"
title [0 percent] Defender Remover , version 11
:: Removing Windows Security Application
rmdir /s /q "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy"
FOR /d %%f IN ("C:\Program Files\WindowsApps\Microsoft.SecHealthUI*") DO rmdir /s /q "%%f"
powershell "Get-AppxPackage *SecHealth* | Reset-AppxPackage"
title [5 percent] Defender Remover , version 11
bcdedit /set disableelamdrivers yes
:: Package Remover
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Nis-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.
)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-Powershell-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.
)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-MDM-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.
)

title [25 percent] Defender Remover , version 11
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Group-Policy-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Core-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Client-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.
)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-WOW64-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)


for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-CodeIntegrity-Diagnostics-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AM-Default-Definitions-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-SecurityCenter" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-SenseClient-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AM-Default-Definitions-OptionalWrapper-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-SystemMaintenance-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-ReliabilityAnalysisServices-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-Killbits-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Nis-Group-Package" ^| findstr "~~"') do (set "defender_package=%%i")
if defined defender_package (
echo Removing %defender_package%...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
dism /online /Remove-Package /PackageName:%defender_package% /NoRestart >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /va /f
) else (
echo The package cannot be found.
)
title [60 percent] Defender Remover , version 11
taskkill /f /im explorer.exe
taskkill /f /im smartscreen.exe
taskkill /f /im SecurityHealthSystray.exe
taskkill /f /im SecurityHealthHost.exe
taskkill /f /im SecurityHealthService.exe
taskkill /f /im SecurityHealthHost.exe
taskkill /f /im DWWIN.EXE
taskkill /f /im CompatTelRunner.exe
taskkill /f /im GameBarPresenceWriter.exe
taskkill /f /im DeviceCensus.exe
:: Removing folders
for %%d in ("C:\Windows\WinSxS\amd64_security-octagon*" "C:\Windows\WinSxS\x86_windows-defender*" "C:\Windows\WinSxS\wow64_windows-defender*" "C:\Windows\WinSxS\amd64_windows-defender*" "C:\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy" "C:\ProgramData\Microsoft\Windows Defender" "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection" "C:\Program Files (x86)\Windows Defender Advanced Threat Protection" "C:\Program Files\Windows Defender Advanced Threat Protection" "C:\ProgramData\Microsoft\Windows Security Health" "C:\ProgramData\Microsoft\Storage Health" "C:\WINDOWS\System32\drivers\wd" "C:\Program Files (x86)\Windows Defender" "C:\Program Files\Windows Defender" "C:\Windows\System32\SecurityHealth" "C:\Windows\System32\WebThreatDefSvc" "C:\Windows\System32\Sgrm" "C:\Windows\Containers" "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Defender" "C:\Windows\System32\Tasks_Migrated\Microsoft\Windows\Windows Defender" "C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender" "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender" "C:\Windows\System32\HealthAttestationClient" "C:\Windows\GameBarPresenceWriter" "C:\Windows\bcastdvr") do rmdir "%%~d" /s /q
:: Removing Files
for %%d in ("C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest" "C:\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest" "C:\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest" "C:\Windows\System32\SecurityAndMaintenance_Error.png" "C:\Windows\System32\SecurityAndMaintenance.png" "C:\Windows\System32\SecurityHealthSystray.exe" "C:\Windows\System32\SecurityHealthService.exe" "C:\Windows\System32\SecurityHealthHost.exe" "C:\Windows\System32\drivers\SgrmAgent.sys" "C:\Windows\System32\drivers\WdDevFlt.sys" "C:\Windows\System32\drivers\WdBoot.sys" "C:\Windows\System32\drivers\WdFilter.sys" "C:\Windows\System32\wscsvc.dll" "C:\Windows\System32\drivers\WdNisDrv.sys" "C:\Windows\System32\wscsvc.dll" "C:\Windows\System32\wscproxystub.dll" "C:\Windows\System32\wscisvif.dll" "C:\Windows\System32\SecurityHealthProxyStub.dll" "C:\Windows\System32\smartscreen.dll" "C:\Windows\SysWOW64\smartscreen.dll" "C:\Windows\System32\smartscreen.exe" "C:\Windows\SysWOW64\smartscreen.exe" "C:\Windows\System32\DWWIN.EXE" "C:\Windows\SysWOW64\smartscreenps.dll" "C:\Windows\System32\smartscreenps.dll" "C:\Windows\System32\SecurityHealthCore.dll" "C:\Windows\System32\SecurityHealthSsoUdk.dll" "C:\Windows\System32\SecurityHealthUdk.dll" "C:\Windows\System32\SecurityHealthAgent.dll" "C:\Windows\System32\wscapi.dll" "C:\Windows\System32\wscadminui.exe" "C:\Windows\SysWOW64\GameBarPresenceWriter.exe" "C:\Windows\System32\GameBarPresenceWriter.exe" "C:\Windows\SysWOW64\DeviceCensus.exe" "C:\Windows\SysWOW64\CompatTelRunner.exe" "C:\Windows\system32\drivers\msseccore.sys") DO del /f "%%d"
shutdown /r /f /t 0