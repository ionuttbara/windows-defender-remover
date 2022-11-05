@echo off
pushd "%CD%"
CD /D "%~dp0"
title Windows Defender Remover Script, version 11
echo Welcome to Defender Remover. There are the options.
echo If you press Y, we will remove Windows Defender and connected Windows Security Components.
echo If you press N, we will disable Windows Defender and Security Components.
echo If you press E, we will enable Windows Defender (it works if you press N before)
echo If you press R, we will create a SystemRestore point.
echo The PC will reboot after the selected action is finalised.
set /P c=Select one of the option to continue.
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "E" goto :enabledef
if /I "%c%" EQU "R" goto :restoredef

:restoredef
Wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "This_was_made_by_Defender_Remover_on_%DATE%", 100, 1
exit

:removedef
:: Registry Remove of Windows Defender
set /P c=If you use the remover, Windows Defender and Windows Security Components will be removed, and some features such as Virtualization-Based Security , Defender Smart Screen and Windows Update (1) will not work after that. Do this if you want to remove Windows Defender to your System. The Operating System will reboot after that! [Y/N]?
if /I "%c%" EQU "Y" goto :remove
if /I "%c%" EQU "N" goto :end
:remove
regedit.exe /s "remover\Antivirus.reg"
PowerRun regedit.exe /s "remover\Antivirus.reg"
regedit.exe /s "remover\Defender Anti-Phishing.reg"
PowerRun regedit.exe /s "remover\Defender Anti-Phishing.reg"
regedit.exe /s "remover\Exploit Guard.reg"
PowerRun regedit.exe /s "remover\Exploit Guard.reg"
regedit.exe /s "remover\firewall_menu.reg"
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
PowerRun cmd.exe /c "remover.bat"
pause


:tweaksdef
regedit.exe /s "disabler\Antivirus_d.reg"
PowerRun.exe regedit.exe /s "disabler\Antivirus_d.reg"
regedit.exe /s "disabler\Defender Anti-Phishing_d.reg"
PowerRun.exe regedit.exe /s "disabler\Defender Anti-Phishing_d.reg"
regedit.exe /s "disabler\Security Health_d.reg"
PowerRun.exe regedit.exe /s "disabler\Security Health_d.reg"
regedit.exe /s "disabler\Windows Security Center_d.reg"
PowerRun.exe regedit.exe /s "disabler\Windows Security Center_d.reg"
regedit.exe /s "disabler\SmartScreen.reg"
PowerRun.exe regedit.exe /s "disabler\SmartScreen.reg"
regedit.exe /s "disabler\Virtualization.reg"
PowerRun.exe regedit.exe /s "disabler\Virtualization.reg"
shutdown /r /f /t 0

:enabledef
regedit.exe /s "disabler\Antivirus_e.reg"
PowerRun.exe regedit.exe /s "disabler\Antivirus_e.reg"
regedit.exe /s "disabler\Defender Anti-Phishing_e.reg"
PowerRun.exe regedit.exe /s "disabler\Defender Anti-Phishing_e.reg"
regedit.exe /s "disabler\Security Health_e.reg"
PowerRun.exe regedit.exe /s "disabler\Security Health_e.reg"
regedit.exe /s "disabler\Windows Security Center_e.reg"
PowerRun.exe regedit.exe /s "disabler\Windows Security Center_e.reg"
shutdown /r /f /t 0

