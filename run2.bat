:: Starting script
pushd "%CD%"
CD /D "%~dp0"
echo off
CLS
title Windows Defender Remover Script Version 10.0

:: Firewall Context Menu
OneClickFirewall-1.0.0.2.exe /S

:: Exploit Protection
PowerShell "".\exploit_removal.ps1""

:: Registry Remove of Windows Defender 
regedit.exe /s "remover\Antivirus.reg"
PowerRun regedit.exe /s "remover\Antivirus.reg"
regedit.exe /s "remover\Defender Anti-Phishing.reg"
PowerRun regedit.exe /s "remover\Defender Anti-Phishing.reg"
regedit.exe /s "remover\Exploit Guard.reg"
PowerRun regedit.exe /s "remover\Exploit Guard.reg"
regedit.exe /s "remover\Firewall Contextual Menu Implementation.reg"
regedit.exe /s "remover\Rumtime IDs.reg"
PowerRun regedit.exe /s "remover\Rumtime IDs.reg"
regedit.exe /s "remover\Security Health.reg"
PowerRun regedit.exe /s "remover\Security Health.reg"
regedit.exe /s "disabler\Smartscreen.reg"
PowerRun regedit.exe /s "disabler\Smartscreen.reg"
regedit.exe /s "disabler\Virtualization.reg"
PowerRun regedit.exe /s "disabler\Virtualization.reg"
regedit.exe /s "remover\Windows Security Center.reg"
PowerRun regedit.exe /s "remover\Windows Security Center.reg"

::Remove all the packages with Melody API

melody /o /c Microsoft-Windows-SecurityCenter /r
melody /o /c Windows-Defender /r
melody /o /c Microsoft-Windows-HVSI /r
melody /o /c Microsoft-Windows-SecureStartup /r
melody /o /c Microsoft-Windows-Killbits /r
melody /o /c Microsoft-Windows-SenseClient /r
melody /o /c Microsoft-Windows-DeviceGuard /r
melody /o /c Microsoft-OneCore-VirtualizationBasedSecurity /r
bcdedit.exe /set disableelamdrivers yes
PowerRun cmd.exe /c "Remover.bat"
PowerRun cmd.exe /c rem.cmd
timeout 4
