pushd "%CD%"
CD /D "%~dp0"
echo off 


::start using Fidelity to remove packages

fidelity /o /c Microsoft-Windows-SecurityCenter /r
fidelity /o /c Windows-Defender /r
fidelity /o /c Microsoft-Windows-HVSI /r
fidelity /o /c Microsoft-Windows-SecureStartup /r
fidelity /o /c Microsoft-Windows-Killbits /r

:: start using Fidelity for removing services


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

::import some registry


PowerRun.exe Regedit.exe /S def.reg
Regedit /S def.reg

::tweaking boot, disable elam and VBS with LSA
bcdedit /set {current} disableelamdrivers yes
bcdedit /set nointegritychecks on
bcdedit /set hypervisorlaunchtype off
bcdedit /set useplatformclock No
bcdedit /set {current} bootmenupolicy Legacy
bcdedit /set tpmbootentropy ForceDisable
bcdedit /create {0cb3b571-2f2e-4343-a879-d86a476d7215} /d
bcdedit /set {bootmgr} bootsequence {0cb3b571-2f2e-4343-a879-d86a476d7215}
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} loadoptions DISABLE-LSA-ISO,,DISABLE-VBS
bcdedit /set {current} bootstatuspolicy ignoreallfailures


::removing Crusters

unl /delete /Advanced "C:\Windows\System32\Tasks\Microsoft\Windows\TPM\*","C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender\*","C:\Windows\System32\Tasks\Microsoft\Windows\ExploitGuard*\*","C:\ProgramData\Microsoft\Windows Defender","C:\WINDOWS\System32\drivers\wd","C:\Program Files\Windows Defender","C:\Program Files (x86)\Windows Defender","C:\Program Files\Windows Defender Advanced Threat Protection","C:\Program Files (x86)\Windows Defender Advanced Threat Protection","C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy","C:\ProgramData\Microsoft\Windows Defender","C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection","C:\ProgramData\Microsoft\Windows Security Health","C:\ProgramData\Microsoft\Storage","C:\ProgramData\Microsoft\Storage Health","C:\Windows\System32\drivers\wd","C:\Windows\System32\drivers\WdNisDrv.sys","C:\Windows\System32\drivers\WdFilter.sys","C:\Windows\System32\drivers\WdBoot.sys","C:\Windows\System32\drivers\WdDevFlt.sys","C:\Windows\System32\drivers\mssecflt.sys","C:\Windows\System32\drivers\SgrmAgent.sys","C:\Windows\System32\drivers\Ndu.sys","C:\Windows\System32\drivers\winhv.sys","C:\Windows\System32\drivers\winhvr.sys"


rmdir /s /q "C:\Windows\SystemApps\Microsoft.SecHealthUI*"

::reboot the system
wmic os where Primary='TRUE' reboot