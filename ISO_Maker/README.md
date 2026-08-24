# Windows Defender Remover – ISO Maker

This module allows you to build a Windows installation image (ISO or USB) with **Windows Defender and all related security services disabled from the very first boot**.  
No traces of Defender run during setup, after the first logon, or during Windows Update.

---

## Two Integration Methods

| Method | Best for | What it does |
|--------|----------|--------------|
| **UUP Converter** | Users who build custom ISOs from UUP (using `uupintegrator.cmd`) | Adds a command to `autounattend.xml` that disables Defender services during Windows Setup. Also includes optional aggressive registry/file cleanups directly in `install.wim`. |
| **Classic ISO/USB** | Users who have a standard Windows ISO (or USB) and want to add an `unattend.xml` | Places an answer file inside `$OEM$` folders; the file runs a command that disables Defender services during the Out‑of‑Box Experience (OOBE). |

Both methods achieve the same goal: **Defender never starts**, even during the first boot.

---

## Method 1 – Using UUP Converter (`uupintegrator.cmd`)

If you build your Windows ISO from UUP files using the well‑known [UUP dump](https://uupdump.net/) script (`uupintegrator.cmd`), follow these steps.

### Step 1 – Prepare your `autounattend.xml`

You can either:
- **Use an online generator** like [Schneegans’ Unattend Generator](https://schneegans.de/windows/unattend-generator/) to create a full answer file with your preferred settings (language, edition, partitioning, etc.).
- **Start from a minimal template** and add the code below.

### Step 2 – Add the Defender‑disabling command

Inside the `<settings pass="oobeSystem">` section (or `specialize`, but `oobeSystem` works fine), insert a `<SynchronousCommand>` that runs a small script.  
**Copy‑paste the following XML block** into your answer file:

```xml
<FirstLogonCommands>
    <SynchronousCommand wcm:action="add">
        <CommandLine>cmd.exe /c for %s in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend) do reg.exe ADD HKLM\SYSTEM\ControlSet001\Services\%s /v Start /t REG_DWORD /d 4 /f &amp; reg.exe UNLOAD HKLM\SYSTEM</CommandLine>
        <Description>Disable Defender Services</Description>
        <Order>1</Order>
        <RequiresUserInput>false</RequiresUserInput>
    </SynchronousCommand>
</FirstLogonCommands>
```

> 
> **Note:** The command runs in the **WinPE environment** during setup, before the first boot of the installed OS. It mounts the offline SYSTEM hive, sets each service’s `Start` value to `4` (disabled), and unloads the hive.

### Step 3 – Place the answer file

* Copy your `autounattend.xml` to the root of the **UUP output folder** (where `uupintegrator.cmd` resides).
* The UUP script will automatically pick it up and embed it into the final ISO.

### Step 4 – (Optional) Modify `uupintegrator.cmd` for extra aggressive cleaning

The UUP converter already accepts custom commands. If you want to **delete Defender folders and tweak the registry offline** (as shown in the script snippet you provided), you can add that logic inside the `uupintegrator.cmd` after the image is mounted.
Below is a ready‑to‑use block that you can insert (e.g., after the driver injection section):

``` cmd

if %_runDRV% equ 1 (
    set mumtarget=%_mount%
    set dismtarget=/Image:"%_mount%"
    goto :doDrivers
)
if %WimRE% equ 1 goto :doupdt

:: === AGGRESSIVE DEFENDER REMOVAL ===
call :dk_color1 %Gray% "=== Removing HelpPane, OneDrive and OOBE/Defender registry tweaks ..." 4

if exist "%_mount%\PerfLogs" (
    takeown /f "%_mount%\PerfLogs" /r /d y %_Nul3%
    icacls "%_mount%\PerfLogs" /grant administrators:F /t %_Nul3%
    rmdir /s /q "%_mount%\PerfLogs" %_Nul3%
)

if exist "%_mount%\Program Files\Windows Defender" (
    takeown /f "%_mount%\Program Files\Windows Defender" /r /d y %_Nul3%
    icacls "%_mount%\Program Files\Windows Defender" /grant administrators:F /t %_Nul3%
    rmdir /s /q "%_mount%\Program Files\Windows Defender" %_Nul3%
    mkdir "%_mount%\Program Files\Windows Defender" %_Nul3%
)

if exist "%_mount%\Program Files\Windows Defender Advanced Threat Protection" (
    takeown /f "%_mount%\Program Files\Windows Defender Advanced Threat Protection" /r /d y %_Nul3%
    icacls "%_mount%\Program Files\Windows Defender Advanced Threat Protection" /grant administrators:F /t %_Nul3%
    rmdir /s /q "%_mount%\Program Files\Windows Defender Advanced Threat Protection" %_Nul3%
    mkdir "%_mount%\Program Files\Windows Defender Advanced Threat Protection" %_Nul3%
)

:: Registry offline tweaks
reg load HKLM\OfflineSOFTWARE "%_mount%\Windows\System32\config\SOFTWARE" %_Nul3%
if not errorlevel 1 (
    reg add HKLM\OfflineSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f %_Nul3%
    reg add HKLM\OfflineSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersion /t REG_DWORD /d 1 /f %_Nul3%
    reg add HKLM\OfflineSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersionInfo /t REG_SZ /d 25H1 /f %_Nul3%
    reg add HKLM\OfflineSOFTWARE\Policies\Microsoft\Windows\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 /f %_Nul3%
    reg add HKLM\OfflineSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v ProtectYourPC /t REG_DWORD /d 3 /f %_Nul3%
    reg unload HKLM\OfflineSOFTWARE %_Nul3%
)

reg load HKLM\OfflineDEFAULT "%_mount%\Users\Default\NTUSER.DAT" %_Nul3%
if not errorlevel 1 (
    reg add "HKLM\OfflineDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v SV1 /t REG_DWORD /d 0 /f %_Nul3%
    reg add "HKLM\OfflineDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v SV2 /t REG_DWORD /d 0 /f %_Nul3%
    reg unload HKLM\OfflineDEFAULT %_Nul3%
)

reg load HKLM\OfflineSYSTEM "%_mount%\Windows\System32\config\SYSTEM" %_Nul3%
if not errorlevel 1 (
    for %%s in (WinDefend whesvc SecurityHealthService wscsvc MDCoreSvc webthreatdefsvc webthreatdefusersvc WdFilter WdNisDrv WdNisSvc Sense) do (
        reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\%%s /f %_Nul3% 2>nul
    )
    reg unload HKLM\OfflineSYSTEM %_Nul3%
)

```

> 
> This is optional; the XML command alone is sufficient to disable Defender. The extra steps remove the binaries and some registry keys for a cleaner image.

* * *

## Method 2 – Classic ISO / USB (without UUP)

Use this if you already have a standard Windows ISO (e.g., from Microsoft) or a bootable USB drive.

### Step 1 – Extract or mount the ISO

Mount the ISO and copy all its contents to a folder (e.g., `C:\ISOFolder`).

### Step 2 – Create the folder structure

Inside the `sources` folder, create the following nested directories:

``` text
sources
└── $OEM$
    └── $$
        └── Panther
```

Full path example: `C:\ISOFolder\sources\$OEM$\$$\Panther\`

### Step 3 – Place the answer file

* **For DVD/ISO builds**: Place an `unattend.xml` file inside the `Panther` folder.
* **For USB drives**: Place an `autounattend.xml` inside the `Panther` folder **and also copy the same file to the root of the USB drive** (this prevents in‑place upgrades from using it).

You can obtain the answer file in two ways:

* **Use the online generator**: Visit https://schneegans.de/windows/unattend-generator/ and configure your settings. Download the generated `autounattend.xml` (or rename it to `unattend.xml`).
* **Manually create it**: Start from a minimal template and add the same `<SynchronousCommand>` shown in **Method 1, Step 2** inside the `<FirstLogonCommands>` section (or inside a `<RunSynchronousCommand>` in the `oobeSystem` pass).

Make sure the command is exactly:
``` xml
      <FirstLogonCommands>
    <SynchronousCommand wcm:action="add">
        <CommandLine>cmd.exe /c for %s in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend) do reg.exe ADD HKLM\SYSTEM\ControlSet001\Services\%s /v Start /t REG_DWORD /d 4 /f &amp; reg.exe UNLOAD HKLM\SYSTEM</CommandLine>
        <Description>Disable Defender Services</Description>
        <Order>1</Order>
        <RequiresUserInput>false</RequiresUserInput>
    </SynchronousCommand>
</FirstLogonCommands>
```
### Step 4 – Rebuild the ISO

Use any ISO‑building tool (AnyBurn, ImgBurn, or the `oscdimg` command) to pack the folder back into a bootable ISO.
For USB, simply copy the modified folder contents to the drive (preserving the boot sector if you used Rufus).

* * *

## Important Notes

* The answer file method does **not** delete Defender binaries; it only sets the services to `Disabled` (Start = 4). This is enough to prevent Defender from ever starting.
* If you use the aggressive `uupintegrator.cmd` modifications, you also remove the physical files – which makes the image even cleaner.
* The `BypassNRO` tweak (skipping network requirement during OOBE) is included in the optional registry block.
* Ensure you do **not** have conflicting unattend files in multiple locations (e.g., both in `Panther` and the root of the USB) unless you intend that.
* This method works for Windows 10 / 11 (all recent builds).

* * *

## Final Result

After following either method, your Windows installation will have **no active Defender components** from the very first boot.
Windows Update will also not reinstall Defender because the services are permanently disabled.
