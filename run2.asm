:: Starting script
pushd "%CD%"
CD /D "%~dp0"
echo off
CLS
title Windows Defender Remover Script Version 10.0

:: Firewall Context Menu
OneClickFirewall-1.0.0.2.exe /S

:: Exploit Protection
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0.\exploit_removal.ps1""' -Verb RunAs}"

:: Registry Remove of Windows Defender 
regedit.exe /s "registry\Antivirus.reg"
regedit.exe /s "registry\Defender Anti-Phishing.reg"
regedit.exe /s "registry\Exploit Guard.reg"
regedit.exe /s "registry\Firewall Contextual Menu Implementation.reg"
regedit.exe /s "registry\Rumtime IDs.reg"
regedit.exe /s "registry\Security Health.reg"
regedit.exe /s "registry\Smartscreen.reg"
regedit.exe /s "registry\Virtualization.reg"
regedit.exe /s "registry\Windows Security Center.reg"
PowerRun regedit.exe /s "registry\Antivirus.reg"
PowerRun regedit.exe /s "registry\Exploit Guard.reg"
PowerRun regedit.exe /s "registry\Runtime IDs.reg"
PowerRun regedit.exe /s "registry\Security Health.reg"
PowerRun regedit.exe /s "registry\Smartscreen.reg"
PowerRun regedit.exe /s "registry\Virtualization.reg"
PowerRun regedit.exe /s "registry\Windows Security Center.reg"
PowerRun regedit.exe /s "registry\Defender Anti-Phishing.reg"

::Remove all the packages with Melody API

melody /o /c Microsoft-Windows-SecurityCenter /r
melody /o /c Windows-Defender /r
melody /o /c Microsoft-Windows-HVSI /r
melody /o /c Microsoft-Windows-SecureStartup /r
melody /o /c Microsoft-Windows-Killbits /r
melody /o /c Microsoft-Windows-SenseClient /r
melody /o /c Microsoft-Windows-DeviceGuard /r
melody /o /c Microsoft-OneCore-VirtualizationBasedSecurity /r
melody /o /c Containers /r
melody /o /c Microsoft-OneCore-Containers /r
melody /o /c Microsoft-OneCore-UtilityVM-Containers /r
melody /o /c Microsoft-UtilityVM-Containers /r
melody /o /c Microsoft-Windows-OneCore-Containers-Client-Opt-Package /r
melody /o /c HyperV-Compute-Host-Containers /r
melody /o /c HyperV-Feature-Containers /r
melody /o /c HyperV-Feature-ApplicationGuard /r
melody /o /c HyperV-HypervisorPlatform /r
melody /o /c HyperV-Networking-Containers /r
melody /o /c Microsoft-Hyper-V-Hypervisor /r
melody /o /c Microsoft-Windows-ApiSetSchemaExtension-HyperV-DeviceVirtualization /r

::tweaking boot, disable elam and VBS with LSA
bcdedit /set {current} disableelamdrivers yes
PowerRun cmd.exe /c "Remover.bat"
PowerRun cmd.exe /c rem.cmd
timeout 4
