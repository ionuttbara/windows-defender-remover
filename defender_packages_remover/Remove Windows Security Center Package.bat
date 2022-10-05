:: Starting script
echo off
pushd "%CD%"
CD /D "%~dp0"
title [0 percent] Defender Remover , version 11

for /f "tokens=8 delims=\" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" ^| findstr "Microsoft-Windows-SecurityCenter" ^| findstr "~~") do (set "defender_package=%%i")
if defined defender_package (
		echo Removing %defender_package%...
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%" /v Visibility /t REG_DWORD /d 1 /f
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\%defender_package%\Owners" /va /f
		dism /online /Remove-Package /PackageName:%defender_package% /NoRestart
	) else (
		echo The package cannot be found.
	)