:: Starting script
echo off
pushd "%CD%"
CD /D "%~dp0"
title [0 percent] Defender Remover , version 11 

:: Package Remover
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Nis-Group-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-Powershell-Group-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-MDM-Group-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-Group-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

title [25 percent] Defender Remover , version 11 
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Group-Policy-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Core-Group-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Client-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-WOW64-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AppLayer-Group-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)


for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AM-Default-Definitions-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-OneCore-VirtualizationBasedSecurity-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

title [50 percent] Defender Remover , version 11 

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-DeviceGuard-GPEXT-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-SecurityCenter" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-SenseClient-Package" ^| findstr "~"') do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

title [60 percent] Defender Remover , version 11 
:: Removing from WinSxS
FOR /d %%f IN ("C:\Windows\WinSxS\amd64_security-octagon*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\x86_windows-defender*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\wow64_windows-defender*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\amd64_windows-defender*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest") DO del "%%f"
FOR /d %%f IN ("C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest") DO del "%%f"
FOR /d %%f IN ("C:\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest") DO del "%%f"

title [80 percent] Defender Remover , version 11 
:: Removing Windows Security Application 
FOR /d %%f IN ("C:\Program Files\WindowsApps\Microsoft.SecHealthUI*") DO rmdir  "%%f" /s /q
powershell "Get-AppxPackage *SecHealth* | Reset-AppxPackage"

:: Removing Services
sc delete SgrmBroker
sc delete SgrmAgent
sc delete SecurityHealthService
sc delete WdBoot
sc delete WdFiltrer
sc delete WdNisSvc
sc delete WdNisDrv
sc delete wscsvc
sc delete Sense
sc delete WinDefend
sc delete MsSecCore
shutdown /r /f /t 0
