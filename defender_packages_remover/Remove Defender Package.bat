:: Starting script
echo off
pushd "%CD%"
CD /D "%~dp0"
title [0 percent] Defender Remover , version 11 

:: Package Remover
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Nis-Group-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-Powershell-Group-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-MDM-Group-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Management-Group-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

title [25 percent] Defender Remover , version 11
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Group-Policy-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Core-Group-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Client-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-WOW64-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AppLayer-Group-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AM-Default-Definitions-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-AM-Default-Definitions-OptionalWrapper-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-ApplicationGuard-Inbox-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Windows-Defender-Group-Policy-Package" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)
