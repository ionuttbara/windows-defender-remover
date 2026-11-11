@echo off
setlocal EnableExtensions
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL%" set "POWERSHELL=powershell.exe"
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build.ps1" %*
exit /b %errorlevel%
