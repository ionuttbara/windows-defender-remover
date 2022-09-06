FOR /d %%f IN ("C:\Program Files\WindowsApps\Microsoft.SecHealthUI*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\amd64_security-octagon*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\x86_windows-defender*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\wow64_windows-defender*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\amd64_windows-defender*") DO rmdir  "%%f" /s /q
FOR /d %%f IN ("C:\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest") DO del "%%f"
FOR /d %%f IN ("C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest") DO del "%%f"
FOR /d %%f IN ("C:\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest") DO del "%%f"
powershell "Get-AppxPackage *SecHealth* | Reset-AppxPackage"

:: Removing Services
sc delete SgrmBroker
sc delete SgrmAgent
sc delete SecurityHealthService
sc delete WdBoot
sc delete WdFiltrer
sc delete WdNisSvc
sc delete WdNisDrv
sc delete wscsvc
sc delete Sense
sc delete WinDefend
sc delete MsSecCore
shutdown /r /f /t 0