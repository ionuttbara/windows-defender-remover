pushd "%CD%"
CD /D "%~dp0"
echo off 

::import some registry
PowerRun.exe Regedit.exe /S def.reg
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Security and Maintenance" /f

::start using Melody to remove packages

fidelity /o /c Microsoft-Windows-SecurityCenter /r
fidelity /o /c Windows-Defender /r
fidelity /o /c Microsoft-Windows-HVSI /r
fidelity /o /c Microsoft-Windows-SecureStartup /r
fidelity /o /c Microsoft-Windows-Killbits /r
fidelity /o /c Microsoft-Windows-SenseClient /r

:: start using Melody for removing services

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

::tweaking boot, disable elam and VBS with LSA
bcdedit /set {current} disableelamdrivers yes

::removing Crusters

takeown /f "C:\Windows\System32\SecurityAndMaintenance_Error.png"
cacls "C:\Windows\System32\SecurityAndMaintenance_Error.png" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityAndMaintenance_Error.png"
takeown /f "C:\Windows\System32\SecurityAndMaintenance_Alert.png"
cacls "C:\Windows\System32\SecurityAndMaintenance_Alert.png" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityAndMaintenance_Alert.png"
takeown /f "C:\Windows\System32\SecurityAndMaintenance.png"
cacls "C:\Windows\System32\SecurityAndMaintenance.png" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityAndMaintenance.png"
takeown /f C:\Windows\System32\SecurityHealthSystray.exe
cacls "C:\Windows\System32\SecurityHealthSystray.exe" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityHealthSystray.exe"
takeown /f C:\Windows\System32\SecurityHealthService.exe
cacls "C:\Windows\System32\SecurityHealthService.exe" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityHealthService.exe"
takeown /f C:\Windows\System32\SecurityHealthHost.exe
cacls "C:\Windows\System32\SecurityHealthHost.exe" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityHealthHost.exe"
takeown /f C:\Windows\System32\drivers\SgrmAgent.sys
cacls "C:\Windows\System32\drivers\SgrmAgent.sys" /E /P %username%:F
del /F /Q "C:\Windows\System32\drivers\SgrmAgent.sys"
takeown /f C:\Windows\System32\drivers\WdDevFlt.sys
cacls "C:\Windows\System32\drivers\WdDevFlt.sys" /E /P %username%:F
del /F /Q "C:\Windows\System32\drivers\WdDevFlt.sys"
takeown /f C:\Windows\System32\drivers\WdBoot.sys
cacls "C:\Windows\System32\drivers\WdBoot.sys" /E /P %username%:F
del /F /Q "C:\Windows\System32\drivers\WdBoot.sys"
takeown /f C:\Windows\System32\drivers\WdFilter.sys
cacls "C:\Windows\System32\drivers\WdFilter.sys" /E /P %username%:F
del /F /Q "C:\Windows\System32\drivers\WdFilter.sys"
takeown /f C:\Windows\System32\drivers\WdNisDrv.sys
cacls "C:\Windows\System32\drivers\WdNisDrv.sys" /E /P %username%:F
del /F /Q "C:\Windows\System32\drivers\WdNisDrv.sys"
takeown /f C:\Windows\System32\drivers\wd
cacls "C:\Windows\System32\drivers\wd" /E /P %username%:F
rmdir /s /q "C:\Windows\System32\drivers\wd"
takeown /f "C:\ProgramData\Microsoft\Storage Health"
cacls "C:\ProgramData\Microsoft\Storage Health" /E /P %username%:F
rmdir /s /q "C:\ProgramData\Microsoft\Storage Health"
takeown /f "C:\ProgramData\Microsoft\Storage"
cacls "C:\ProgramData\Microsoft\Storage" /E /P %username%:F
rmdir /s /q "C:\ProgramData\Microsoft\Storage"
takeown /f "C:\ProgramData\Microsoft\Windows Security Health"
cacls "C:\ProgramData\Microsoft\Windows Security Health" /E /P %username%:F
rmdir /s /q "C:\ProgramData\Microsoft\Windows Security Health"
takeown /f "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection"
cacls "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection" /E /P %username%:F
rmdir /s /q "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection"
takeown /f "C:\ProgramData\Microsoft\Windows Defender"
cacls "C:\ProgramData\Microsoft\Windows Defender" /E /P %username%:F
rmdir /s /q "C:\ProgramData\Microsoft\Windows Defender"
takeown /f "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy"
cacls "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy" /E /P %username%:F
rmdir /s /q "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy"
takeown /f "C:\Program Files (x86)\Windows Defender Advanced Threat Protection"
cacls "C:\Program Files (x86)\Windows Defender Advanced Threat Protection" /E /P %username%:F
rmdir /s /q "C:\Program Files (x86)\Windows Defender Advanced Threat Protection"
takeown /f "C:\Program Files\Windows Defender Advanced Threat Protection"
cacls "C:\Program Files\Windows Defender Advanced Threat Protection" /E /P %username%:F
rmdir /s /q "C:\Program Files\Windows Defender Advanced Threat Protection"
takeown /f "C:\Program Files (x86)\Windows Defender"
cacls "C:\Program Files (x86)\Windows Defender" /E /P %username%:F
rmdir /s /q "C:\Program Files (x86)\Windows Defender"
takeown /f "C:\Program Files\Windows Defender"
cacls "C:\Program Files\Windows Defender" /E /P %username%:F
rmdir /s /q "C:\Program Files\Windows Defender"
takeown /f "C:\WINDOWS\System32\drivers\wd"
cacls "C:\WINDOWS\System32\drivers\wd" /E /P %username%:F
rmdir /s /q "C:\WINDOWS\System32\drivers\wd"
takeown /f "C:\ProgramData\Microsoft\Windows Defender"
cacls "C:\ProgramData\Microsoft\Windows Defender" /E /P %username%:F
rmdir /s /q "C:\ProgramData\Microsoft\Windows Defender"
takeown /f "C:\Windows\System32\wscsvc.dll"
cacls "C:\Windows\System32\wscsvc.dll" /E /P %username%:F
del /F /Q  "C:\Windows\System32\wscsvc.dll"
takeown /f "C:\Windows\System32\wscproxystub.dll"
cacls "C:\Windows\System32\wscproxystub.dll" /E /P %username%:F
del /F /Q  "C:\Windows\System32\wscproxystub.dll"
takeown /f "C:\Windows\System32\wscisvif.dll"
cacls "C:\Windows\System32\wscisvif.dll" /E /P %username%:F
del /F /Q "C:\Windows\System32\wscisvif.dll"
takeown /f "C:\Windows\System32\SecurityHealthProxyStub.dll"
cacls "C:\Windows\System32\SecurityHealthProxyStub.dll" /E /P %username%:F
del /F /Q "C:\Windows\System32\SecurityHealthProxyStub.dll"
takeown /f "C:\Windows\System32\DWWIN.EXE"
cacls "C:\Windows\System32\DWWIN.EXE" /E /P %username%:F
del /F /Q "C:\Windows\System32\DWWIN.EXE"

shutdown /r /f /t 0