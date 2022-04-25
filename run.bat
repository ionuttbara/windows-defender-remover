pushd "%CD%"
CD /D "%~dp0"
CLS
@echo off
title Windows Defender Remover
:choice
@echo off
echo Are you want to remove Windows Defender?
echo If you press Y, we will remove Windows Defender.
echo If you press N, we will appling Tweaks for Defender.
echo If you press E, we will enable Windows Defender (it works if you press N before)
set /P c=Press Y,N or E to continue
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "E" goto :enabledef
goto :choice


:removedef
"delete_def.bat"
exit

:tweaksdef
regedit /s "defender_registry.reg"
shutdown /r /f /t 0

:tweaksdef
regedit /s "defender_registry_e.reg"
shutdown /r /f /t 0
