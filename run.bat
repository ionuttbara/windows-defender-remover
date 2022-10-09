pushd "%CD%"
CD /D "%~dp0"
CLS
@echo off
title Windows Defender Remover Script, version 11
set checkc=%1
set reboot=%2
if /I [%checkc%] NEQ [] goto :checkc
:prompt
echo Welcome to Defender Remover. There are the options.
echo If you press Y, we will remove Windows Defender and connected Windows Security Components.
echo If you press N, we will disable Windows Defender and Security Components.
echo If you press E, we will enable Windows Defender (it works if you press N before)
echo The PC will reboot after the selected action is finalised.

set /P c=Select one of the option to continue. 
:checkc
if /I "%c%" EQU "/NOREBOOT" set reboot=%c%
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "E" goto :enabledef
if /I "%c%" EQU "/Y" goto :removedef
if /I "%c%" EQU "/N" goto :tweaksdef
if /I "%c%" EQU "/E" goto :enabledef
:checkwrong
if /I ["%c%"] EQU [""] goto :prompt
if /I ["%c%"] NQU [""] goto :prompt

:removedef
:: Registry Remove of Windows Defender 
Wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Applied Defender Remover v11, Remover Part at_%DATE%", 100, 1
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
:: Exploit Protection
PowerShell "".\exploit_removal.ps1""
bcdedit.exe /set disableelamdrivers yes
:: Firewall Context Menu
OneClickFirewall-1.0.0.2.exe /S
PowerRun run2.bat %reboot%
PowerRun cmd.exe /c "Remover.bat"
:norebootwait
timeout 2
set running=
for /F "tokens=2 delims=: USEBACKQ" %%F in (`tasklist /M cmd* /FI "WINDOWTITLE EQ Administrator:  [*"  /FI "STATUS eq running" /FO list ^| findstr /i "cmd.exe"`) DO ( SET running=%%F)
if /I ["%running%"] NEQ [""] goto :norebootwait
if /I [%reboot%] NEQ [] goto :rebootcheck
pause
shutdown /r /f /t 0



:tweaksdef
Wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Applied Defender Remover v11, Disabler Part at_%DATE%", 100, 1
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
:: check if noreboot flag is empty or not
if /I [%reboot%] NEQ [] goto :rebootcheck
pause
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
regedit.exe /s "disabler\SmartScreen.reg"
PowerRun.exe regedit.exe /s "disabler\SmartScreen.reg"
regedit.exe /s "disabler\Virtualization.reg"
PowerRun.exe regedit.exe /s "disabler\Virtualization.reg"
:: check if noreboot flag is empty or not
if /I [%reboot%] NEQ [] goto :rebootcheck
pause
shutdown /r /f /t 0

:rebootcheck
:: check that the noreboot flag matches /noreboot
:: if not /noreboot just reboot
if /I "%reboot%" EQU "/NOREBOOT" goto :noreboot
pause
shutdown /r /f /t 0
:noreboot
exit 0