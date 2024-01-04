@echo off & pushd "%CD%" & CD /D "%~dp0"
:--------------------------------------
:: Arguments Section
IF "%1"== NUL GOTO :menu
IF "%1"== "/y" GOTO :removedef
IF "%1"== "/Y" GOTO :removedef
IF "%1"== "/N" GOTO :tweaksdef
IF "%1"== "/n" GOTO :tweaksdef
:--------------------------------------

:--------------------------------------
:menu
cls
echo ------Defender Remover Script , version 12.6.4------
echo Select an option:
echo.
 echo Press (Y) for removing Defender and Security Components (old method, breaking Windows Updates/UWP in some version of Windows, removes files and unregisters classes) (working for new method)
echo Press (N) for toggle Defender and Security Components with Safe Method.
set /P c=Select one of the options to continue: 

:: Check if the input is one of the valid keys
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef

:: If none of the valid keys are pressed, do nothing
goto :eof
:--------------------------------------
:--------------------------------------
:removedef
cls
echo Killing Tasks...
for /f "delims=" %%i in (Remover\TKL.txt) do (GetTrustedInstaller.exe "C:\Windows\System32\taskkill.exe /f /im ""%%i""") >nul
cls
echo Applying Registry Files...
for /r %%k in (Remover\REGS\*.reg) do (GetTrustedInstaller.exe "C:\Windows\regedit.exe /s ""%%k""") >nul
cls
echo Removing Windows Defender/Security Components Files...
for /f "delims=" %%i in (Remover\FDL.txt) do (GetTrustedInstaller.exe "C:\Windows\System32\cmd.exe /c del /f /q ""%%i""") >nul
for /f "delims=" %%i in (Remover\DDL.txt) do (GetTrustedInstaller.exe "C:\Windows\System32\cmd.exe /c rmdir /s /q ""%%i""") >nul
timeout /t 5 /nobreak
shutdown /r /f /t 0
goto :eof
:--------------------------------------

:--------------------------------------

:tweaksdef
"Safe_Method.bat"

:--------------------------------------
:eof
:: End of script, do nothing
exit
:--------------------------------------
