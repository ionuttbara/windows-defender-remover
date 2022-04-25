
::removing Crusters
del /F /Q "C:\Windows\System32\SecurityAndMaintenance_Error.png"
takeown /f "C:\Windows\System32\SecurityAndMaintenance.png"
del /F /Q "C:\Windows\System32\SecurityAndMaintenance.png"
del /F /Q "C:\Windows\System32\SecurityHealthSystray.exe"
del /F /Q "C:\Windows\System32\SecurityHealthService.exe"
del /F /Q "C:\Windows\System32\SecurityHealthHost.exe"
del /F /Q "C:\Windows\System32\drivers\SgrmAgent.sys"
del /F /Q "C:\Windows\System32\drivers\WdDevFlt.sys"
del /F /Q "C:\Windows\System32\drivers\WdBoot.sys"
del /F /Q "C:\Windows\System32\drivers\WdFilter.sys"
del /F /Q "C:\Windows\System32\drivers\WdNisDrv.sys"
rmdir /s /q "C:\Windows\System32\drivers\wd"
rmdir /s /q "C:\ProgramData\Microsoft\Storage Health"
rmdir /s /q "C:\ProgramData\Microsoft\Storage"
rmdir /s /q "C:\ProgramData\Microsoft\Windows Security Health"
rmdir /s /q "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection"
rmdir /s /q "C:\ProgramData\Microsoft\Windows Defender"
rmdir /s /q "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy"
rmdir /s /q "C:\Program Files (x86)\Windows Defender Advanced Threat Protection"
rmdir /s /q "C:\Program Files\Windows Defender Advanced Threat Protection"
rmdir /s /q "C:\Program Files (x86)\Windows Defender"
rmdir /s /q "C:\Program Files\Windows Defender"
rmdir /s /q "C:\WINDOWS\System32\drivers\wd"
rmdir /s /q "C:\ProgramData\Microsoft\Windows Defender"
del /F /Q  "C:\Windows\System32\wscsvc.dll"
del /F /Q  "C:\Windows\System32\wscproxystub.dll"
del /F /Q "C:\Windows\System32\wscisvif.dll"
del /F /Q "C:\Windows\System32\SecurityHealthProxyStub.dll"
del /F /Q "C:\Windows\System32\DWWIN.EXE"
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.SecurityCenter.SecurityAppBroker" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.SecurityCenter.WscBrokerManager" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.SecurityCenter.WscCloudBackupProvider" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.SecurityCenter.WscDataProtection" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.Configuration.WTDUserSettings" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.Service.UserSessionServiceManager" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.ThreatExperienceManager.ThreatExperienceManager" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.ThreatResponseEngine.ThreatDecisionEngine" /f

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
