@echo off
setlocal
title Defender Remover 13.1
set "SCRIPT=%~dp0Script_Run.ps1"
if not exist "%SCRIPT%" (
    echo [ERROR] Script_Run.ps1 was not found next to this launcher.
    pause
    exit /b 1
)
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL%" set "POWERSHELL=powershell.exe"
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %errorlevel%
