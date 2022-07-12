pushd "%CD%"
CD /D "%~dp0"
CLS
@echo off
title Windows Defender Remover Script
echo Are you want to remove Windows Defender?
echo If you press Y, we will remove Windows Defender and connected Windows Security Components.
echo If you press N, we will disable Windows Defender and Security Components.
echo If you press E, we will enable Windows Defender (it works if you press N before)
echo ! Attention Selecting one of option, Windows SmartScreen and Windows Virtualization will be disabled to increase performance in Windows 10/11 PCs.
set /P c=Press Y,N or E to continue
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "E" goto :enabledef
goto :choice

:removedef
"run2.bat"
exit

:tweaksdef
PowerRun.exe regedit.exe /s "disabler\Antivirus_d.reg"
PowerRun.exe regedit.exe /s "disabler\Defender Anti-Phishing_d.reg"
PowerRun.exe regedit.exe /s "disabler\Security Health_d.reg"
PowerRun.exe regedit.exe /s "disabler\Windows Security Center_d.reg"
PowerRun.exe regedit.exe /s "disabler\SmartScreen.reg"
PowerRun.exe regedit.exe /s "disabler\Virtualization.reg"
regedit.exe /s "disabler\Antivirus_d.reg"
regedit.exe /s "disabler\Defender Anti-Phishing_d.reg"
regedit.exe /s "disabler\Security Health_d.reg"
regedit.exe /s "disabler\Windows Security Center_d.reg"
regedit.exe /s "disabler\SmartScreen.reg"
regedit.exe /s "disabler\Virtualization.reg"
shutdown /r /f /t 0

:enabledef
PowerRun.exe 
PowerRun.exe regedit.exe /s "disabler\Antivirus_e.reg"
PowerRun.exe regedit.exe /s "disabler\Defender Anti-Phishing_e.reg"
PowerRun.exe regedit.exe /s "disabler\Security Health_e.reg"
PowerRun.exe regedit.exe /s "disabler\Windows Security Center_e.reg"
PowerRun.exe regedit.exe /s "disabler\SmartScreen.reg"
PowerRun.exe regedit.exe /s "disabler\Virtualization.reg"
regedit.exe /s "disabler\Antivirus_e.reg"
regedit.exe /s "disabler\Defender Anti-Phishing_e.reg"
regedit.exe /s "disabler\Security Health_e.reg"
regedit.exe /s "disabler\Windows Security Center_e.reg"
regedit.exe /s "disabler\SmartScreen.reg"
regedit.exe /s "disabler\Virtualization.reg"
shutdown /r /f /t 0

