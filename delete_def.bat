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
shutdown /r /f /t 0