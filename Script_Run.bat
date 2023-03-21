@echo off
pushd "%CD%"
CD /D "%~dp0" 
:: Arguments Section
IF "%1"== "y" GOTO :removedef
IF "%1"== "Y" GOTO :removedef
IF "%1"== "N" GOTO :tweaksdef
IF "%1"== "n" GOTO :tweaksdef
IF "%1"== "e" GOTO :enabledef
IF "%1"== "E" GOTO :enabledef
IF "%1"== "F" GOTO :addfirewall
IF "%1"== "f" GOTO :addfirewall
IF "%1"== "G" GOTO :removefirewall
IF "%1"== "g" GOTO :removefirewall
IF "%1"== "/y" GOTO :removedef
IF "%1"== "/Y" GOTO :removedef
IF "%1"== "/N" GOTO :tweaksdef
IF "%1"== "/n" GOTO :tweaksdef
IF "%1"== "/e" GOTO :enabledef
IF "%1"== "/E" GOTO :enabledef
IF "%1"== "/F" GOTO :addfirewall
IF "%1"== "/f" GOTO :addfirewall
IF "%1"== "/G" GOTO :removefirewall
IF "%1"== "/g" GOTO :removefirewall
:--------------------------------------    


:--------------------------------------    
::Menu Section
title Windows Defender Remover Script, version 12 (Terminal)
echo Welcome to Defender Remover 12 (terminal). There are the options.
echo If you press Y, it will remove Windows Defender and connected Windows Security Components.
echo If you press N, it will disable Windows Defender Antivirus only.
echo If you press E, it will enable Windows Defender Antivirus only (it works if you press N before).
echo If you press H, it will disable Windows Defender and Security Components.
echo If you press I, it will enable Windows Defender and Security Components.
echo If you press F, it will add Firewall Context Menu.
echo If you press G, it will remove Firewall Context Menu.
echo If you press R, it will create a SystemRestore point.
echo If you press U, it will disable UAC.
echo If you press I, it to manage Defender Remover Status on an install.wim or install.esd file.
echo The PC will reboot after the selected action is finalised.
set /P c=Select one of the option to continue.
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "E" goto :enabledef
if /I "%c%" EQU "H" goto :disabledefsec
if /I "%c%" EQU "I" goto :enabledefsec
if /I "%c%" EQU "F" goto :addfirewall
if /I "%c%" EQU "G" goto :removefirewall
if /I "%c%" EQU "R" goto :restoredef
if /I "%c%" EQU "U" goto :uacdisable 

:--------------------------------------    

:--------------------------------------   




:--------------------------------------   
:addfirewall
regedit /s "Firewall\Add Firewall Menu.reg" & exit
:--------------------------------------   

:--------------------------------------   
:removefirewall
regedit /s "Firewall\Remove Firewall Menu.reg" & exit
:--------------------------------------   

:--------------------------------------   
:restoredef
Wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "This_was_made_by_Defender_Remover_on_%DATE%", 100, 1 & exit
:--------------------------------------   

:--------------------------------------   
:removedef
:: Registry Remove of Windows Defender
FOR /R %%f IN (GalleryInc.MelodyScript.DefenderRemover.DisablerScript\*.reg Remove_defender\*.reg GalleryInc.MelodyScript.DefenderRemover.Extras\*.reg) DO regedit.exe /s "%%f"
FOR /R %%f IN (GalleryInc.MelodyScript.DefenderRemover.DisablerScript\*.reg Remove_defender\*.reg GalleryInc.MelodyScript.DefenderRemover.Extras\*.reg) DO PowerRun.exe regedit.exe /s "%%f"
start /B /wait PowerRun.exe "RemoverCommand.bat"
exit
:--------------------------------------   

:--------------------------------------   
:disabledefsec
taskkill /f /im smartscreen.exe & ren "C:\Windows\System32\smartscreen.exe" "C:\Windows\System32\smartscreen.plm"
FOR /R %%f IN (GalleryInc.MelodyScript.DefenderRemover.DisablerScript\*.reg GalleryInc.MelodyScript.DefenderRemover.Extras\*.reg) DO PowerRun.exe regedit.exe /s "%%f" >nul
FOR /R %%f IN (GalleryInc.MelodyScript.DefenderRemover.DisablerScript\*.reg GalleryInc.MelodyScript.DefenderRemover.Extras\*.reg) DO regedit.exe /s "%%f" >nul
exit
:--------------------------------------   

:--------------------------------------   
:enabledefsec
ren "C:\Windows\System32\smartscreen.plm" "C:\Windows\System32\smartscreen.exe"
FOR /R %%f IN (GalleryInc.MelodyScript.DefenderRemover.EnablerScript\*.reg) DO PowerRun.exe regedit.exe /s "%%f" >nul
FOR /R %%f IN (GalleryInc.MelodyScript.DefenderRemover.EnablerScript\*.reg) DO regedit.exe /s "%%f" >nul
:--------------------------------------   

:--------------------------------------   
:tweaksdef
taskkill /f /im smartscreen.exe & ren "C:\Windows\System32\smartscreen.exe" smartscreen.plm
PowerRun "Disable_defender\Disable_def.bat" & PowerRun regedit.exe /s "Disable_defender\Disable_def.reg" & timeout 3 & exit
:--------------------------------------   


:--------------------------------------   
:enabledef
ren "C:\Windows\System32\smartscreen.plm" smartscreen.exe
PowerRun "Enable_defender\Enable_def.bat" & PowerRun regedit.exe /s "Enable_defender\Enable_def.reg" & timeout 3 & exit
:--------------------------------------   


:--------------------------------------   
:uacdisable
PowerRun regedit.exe /s "GalleryInc.MelodyScript.DefenderRemover.Extras\Disable UAC.reg" & exit
:--------------------------------------   