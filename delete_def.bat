pushd "%CD%"
CD /D "%~dp0"
echo off 

::import some registry
PowerRun.exe Regedit.exe /S defender_registry.reg
PowerRun.exe rem.cmd
Regedit.exe /S defender_registry.reg

::start using Melody to remove packages

melody /o /c Microsoft-Windows-SecurityCenter /r
melody /o /c Windows-Defender /r
melody /o /c Microsoft-Windows-HVSI /r
melody /o /c Microsoft-Windows-SecureStartup /r
melody /o /c Microsoft-Windows-Killbits /r
melody /o /c Microsoft-Windows-SenseClient /r
melody /o /c Microsoft-Windows-DeviceGuard /r
melody /o /c Microsoft-OneCore-VirtualizationBasedSecurity /r

::tweaking boot, disable elam and VBS with LSA
bcdedit /set {current} disableelamdrivers yes

::Disable Windows Defender Exploit Thing
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0.\exploit_removal.ps1""' -Verb RunAs}"
shutdown /r /f /t 0