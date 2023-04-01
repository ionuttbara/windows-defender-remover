@echo off
pushd "%CD%"
CD /D "%~dp0" 
setlocal EnableExtensions EnableDelayedExpansion
set DriveLetter=
set /p DriveLetter=Please enter the drive letter for the Windows image: 
set "DriveLetter=%DriveLetter%:"
echo.
if not exist "%DriveLetter%\sources\boot.wim" (
	echo Can't find Windows OS Installation files in the specified drive Letter..
	echo Restart the script and re-type the correct letter.
	timeout 5
)

if not exist "%DriveLetter%\sources\install.wim"  (
		if  exist "%DriveLetter%\sources\install.esd" (
 echo The Windows image has an install.esd file.. so it need to copy and convert into .wim before to start the work.
 	timeout 4
)
)

if  exist "%DriveLetter%\sources\boot.wim" (
	echo Found boot.wim. Great!
)
md c:\defenderRemoverImage
echo Copying Windows image...
xcopy.exe /E /I /H /R /Y /J %DriveLetter% c:\defenderRemoverImage >nul
echo Copy complete!
sleep 2
cls
echo Getting image information:
dism /Get-WimInfo /wimfile:c:\defenderRemoverImage\sources\install.wim
set index=
set /p index=Please enter the image index:
set "index=%index%"
echo Mounting Windows image. This may take a while.
md c:\defenderRemoverWork

dism /mount-image /imagefile:c:\defenderRemoverImage\sources\install.wim /index:%index% /mountdir:c:\defenderRemoverWork
echo Mounting complete!
CLS & echo Mounting Registry Paths...
:: loading registry from mounted image
reg load HKLM\dCOMPONENTS "c:\defenderRemoverWork\Windows\System32\config\COMPONENTS" >nul
reg load HKLM\dDEFAULT "c:\defenderRemoverWork\Windows\System32\config\default" >nul
reg load HKLM\dDEFAULT "c:\defenderRemoverWork\Users\Default\ntuser.dat" >nul
reg load HKLM\dSOFTWARE "c:\defenderRemoverWork\Windows\System32\config\SOFTWARE" >nul
reg load HKLM\dSYSTEM "c:\defenderRemoverWork\Windows\System32\config\SYSTEM" >nul
echo Registry Mounting Complete!

:: as a bonus, enabling creation of offline account in mounted Windows Image (using for faster testing the script)
reg add "HKLM\dSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" /t REG_DWORD /d "1" /f >nul

cls
:--------------------------------------
::Menu Section
title Windows Defender Remover Script, version 12 (Terminal), install.wim (mounted)
echo Welcome to Defender Remover 12 (terminal). Select an option for modifying the desired image.
echo If you press Y, it will remove Windows Defender and connected Windows Security Components from mounted image.
echo If you press N, it will disable Windows Defender Antivirus only from mounted image.
echo If you press H, it will disable Windows Defender and Security Components from mounted image.
echo If you press I, it will enable Windows Defender and Security Components from mounted image.
echo If you press F, it will add Firewall Context Menu from mounted image..
echo If you press U, it will disable UAC from mounted image.
echo If you press J, it to unmount image and export into bootable ISO.
echo The image will automaticly be unmounted when a option was finished.
set /P c=Select one of the option to continue.
if /I "%c%" EQU "Y" goto :removedef
if /I "%c%" EQU "N" goto :tweaksdef
if /I "%c%" EQU "H" goto :disabledefsec
if /I "%c%" EQU "I" goto :enabledefsec
if /I "%c%" EQU "F" goto :addfirewall
if /I "%c%" EQU "G" goto :removefirewall
if /I "%c%" EQU "R" goto :restoredef
if /I "%c%" EQU "U" goto :uacdisable 
if /I "%c%" EQU "J" goto :unmount-image 
:--------------------------------------


:--------------------------------------
:: Remove Defender from image
:removedef
cls & echo Removing Defender from mounted image
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\MsSecCore" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\wscsvc" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\WdNisDrv" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\WdNisSvc" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\WdFiltrer" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\SecurityHealthService" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\WdBoot" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\SgrmAgent" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\SgrmBroker" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\WinDefend" /f
reg delete "HKEY_LOCAL_MACHINE\dSYSTEM\CurrentControlSet\Services\DiagTrack" /f
 
:: saves into registry
reg unload HKLM\dCOMPONENTS >nul
reg unload HKLM\dDEFAULT >nul
reg unload HKLM\dDEFAULT >nul
reg unload HKLM\dSOFTWARE >nul
reg unload HKLM\dSYSTEM >nul
echo Cleaning up image...
dism /image:c:\defenderRemoverWork /Cleanup-Image /StartComponentCleanup /ResetBase
echo Unmounting image...
dism /unmount-image /mountdir:c:\defenderRemoverWork /commit
echo Exporting Image with Defender Removed
Dism /Export-Image /SourceImageFile:c:\defenderRemoverImage\sources\install.wim /SourceIndex:%index% /DestinationImageFile:c:\defenderRemoverImage\sources\install2.wim /compress:max
del c:\defenderRemoverImage\install.wim
ren c:\defenderRemoverImage\install2.wim install.wim
echo Image completed, Preparing to export into iso image.
oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,bc:\defenderRemoverImage\boot\etfsboot.com#pEF,e,bc:\defenderRemoverImage\efi\microsoft\boot\efisys.bin c:\defenderRemoverImage c:\defenderRemovedISO\WindowsDefenderRemovedImage.iso

:--------------------------------------
:: Unmounting the image
:unmount-image 
dism /unmount-image /mountdir:c:\defenderRemoverWork /commit
echo Performing Cleanup...
rd c:\defenderRemoverImage /s /q 
rd c:\defenderRemoverWork /s /q 
:--------------------------------------