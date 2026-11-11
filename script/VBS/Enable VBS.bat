@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Defender Remover - Enable VBS

fltmc >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrator privileges are required.
    echo Please launch this action from Start Menu or run it as Administrator.
    pause
    exit /b 1
)

cls
echo ============================================================
echo   DEFENDER REMOVER - ENABLE VBS / CREDENTIAL GUARD
echo ============================================================
echo.
echo This action enables VBS and Credential Guard, stages SecConfig.efi,
echo and schedules a one-time EFI confirmation step.
echo.
echo IMPORTANT:
echo - If BitLocker is enabled, suspend protection before running this action.
echo - Keep your BitLocker / Device Encryption recovery key available.
echo - A firmware confirmation may be required during the next boot.
echo - Confirm using the key shown on screen (the key varies by device).
echo.
choice /C YN /N /M "Continue and schedule a restart? [Y/N]: "
if errorlevel 2 goto :Cancelled

set "EFI_GUID={0cb3b571-2f2e-4343-a879-d86a476d7215}"
set "EFI_DRIVE="
set "EFI_MOUNTED="
set "BOOT_ENTRY_CREATED="
set "BOOT_SEQUENCE_SET="
for %%D in (S T U V W X Y Z R Q P O N M L K J I H G F E D) do (
    if not exist "%%D:\." (
        set "EFI_DRIVE=%%D:"
        goto :DriveFound
    )
)

echo [ERROR] No free drive letter is available for the EFI partition.
goto :Failed

:DriveFound
if not exist "%WINDIR%\System32\SecConfig.efi" (
    echo [ERROR] SecConfig.efi was not found in %WINDIR%\System32.
    goto :Failed
)

 echo [1/5] Configuring VBS and Credential Guard registry values...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "LsaCfgFlags" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed

 echo [2/5] Mounting the EFI System Partition on %EFI_DRIVE%...
mountvol %EFI_DRIVE% /s
if errorlevel 1 goto :Failed
set "EFI_MOUNTED=1"

if not exist "%EFI_DRIVE%\EFI\Microsoft\Boot" mkdir "%EFI_DRIVE%\EFI\Microsoft\Boot" >nul 2>&1
copy /Y "%WINDIR%\System32\SecConfig.efi" "%EFI_DRIVE%\EFI\Microsoft\Boot\SecConfig.efi" >nul
if errorlevel 1 goto :Failed

 echo [3/5] Creating the one-time EFI boot entry...
bcdedit /delete %EFI_GUID% /f >nul 2>&1
bcdedit /create %EFI_GUID% /d "DebugTool" /application osloader >nul
if errorlevel 1 goto :Failed
set "BOOT_ENTRY_CREATED=1"
bcdedit /set %EFI_GUID% path "\EFI\Microsoft\Boot\SecConfig.efi" >nul
if errorlevel 1 goto :Failed
bcdedit /set %EFI_GUID% device partition=%EFI_DRIVE% >nul
if errorlevel 1 goto :Failed
bcdedit /set %EFI_GUID% loadoptions ENABLE-LSA-ISO,ENABLE-VBS >nul
if errorlevel 1 goto :Failed
bcdedit /set vsmlaunchtype Auto >nul
if errorlevel 1 goto :Failed
bcdedit /set {bootmgr} bootsequence %EFI_GUID% >nul
if errorlevel 1 goto :Failed
set "BOOT_SEQUENCE_SET=1"

 echo [4/5] Unmounting the EFI System Partition...
mountvol %EFI_DRIVE% /d
if errorlevel 1 goto :Failed
set "EFI_MOUNTED="

 echo [5/5] Configuration completed.
echo The computer will restart in 15 seconds.
echo During startup, approve the firmware change if prompted.
shutdown /r /t 15 /c "Defender Remover: VBS and Credential Guard activation is pending EFI confirmation."
exit /b 0

:Cancelled
echo Operation cancelled. No changes were made.
exit /b 0

:Failed
if defined EFI_MOUNTED mountvol %EFI_DRIVE% /d >nul 2>&1
if defined BOOT_SEQUENCE_SET bcdedit /deletevalue {bootmgr} bootsequence >nul 2>&1
if defined BOOT_ENTRY_CREATED bcdedit /delete %EFI_GUID% /f >nul 2>&1
echo.
echo [ERROR] The operation did not complete. Review the messages above.
echo If registry settings were already written, they may need to be reviewed before retrying.
pause
exit /b 1
