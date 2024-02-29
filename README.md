# ❌️ Defender Remover / Defender Disabler

<a href="https://github.com/ionuttbara/windows-defender-remover">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/drunkwinter/windows-defender-remover/assets/38593134/8072a566-5bf0-4f05-9994-808145406bdc">
        <img alt="Defender Remover" src="https://user-images.githubusercontent.com/79479952/239704528-c017473e-1d2a-4d4a-a215-bf71d137b86a.png">
    </picture>
</a>

## ❓️ What does the app do?

This application removes / disables Windows Defender, including the Windows Security App, Windows Virtualization-Based Security (VBS), Windows SmartScreen, Windows Security Services, Windows Web-Threat Service, Windows File Virtualization (UAC), Microsoft Defender App Guard, Microsoft Driver Block List, System Mitigations and the Windows Defender page in the Settings App on Windows 10 or later.


## ❓️ What components are removing?

### Removing Security Components
    This script removes/disables following security components:
        - support for Windows Security Center including Windows Security Center Service (wscsvc), Windows Security Service (SgrmBroker, Sgrm Drivers) which are needed to run Windows Security App.
        - virtualization support.
            - Hypervisor startup (this fixes disablation of Virtualization Based Security, this will auto enable if you use Hyper-V and/or WSL (Windows Subsystem for Linux), WSA (Windows Subsystem for Android))
            - LUA (disables File Virtualization and User Account Control, which will run all apps as administrator priviliges (also fixes old app errors))
            - Exploit Guard (something about Exploits)
            - Windows Smart Control
            - Tamper Protection (for Windows 11 21H2 or earlier)
        - SecHealthUI (Windows Security UWP App)
        - SmartScreen
        - Pluton Support and Pluton Services Support
        - System Mitigations
          - "Services Mitigations" (search on admx.help for more informations, its policy)
          - Spectre and Meltdown Mitigation (for get +30% performance on old Intel CPUs)
        - Windows Security Section from Settings App.

### Removing Antivirus Components
    This script forcily removes following antivirus components:
      - Windows Defender Definition Update List (this will disable updating definitions of Defender because its removed)
      - Windows Defender SpyNet Telemetry
      - Antivirus Service
      - Windows Defender Antivirus filter and windows defender rootkit scanner drivers
      - Antivirus Scanning Tasks
      - Shell Associations (Context Menu)
      - Hides Antivirus Protection section from Windows Security App.

## 📃 Instructions

> [!NOTE]
> A system restore point is recommended before you run the script. (if you don't know what are you doing)

1. Download the packed script from [Releases](https://github.com/ionuttbara/windows-defender-remover/releases)
2. Run the ".exe" as administrator
3. Follow the instructions displayed

OR

you can use git

```
git clone https://github.com/ionuttbara/windows-defender-remover.git
cd windows-defender-remover
Script_Run.bat
```


OR

you can use download entire source code
1. Download the source code from [Releases](https://github.com/jbara2002/windows-defender-remover/releases).
2. Choose the file **Source Code(.zip)** from last version and download it.
3. Unarchive the file into a folder and run the Script_Run.bat.

![cli](https://github.com/drunkwinter/windows-defender-remover/assets/38593134/46007191-0a65-43c2-b451-a993ff90e00e)

You can file an [issue](https://github.com/ionuttbara/windows-defender-remover/issues) if you experience any problems.

## 📃 Automation of the script

You can remove Defender with arguments.

#### Removing

```PowerShell
# Removal
Defender.Remover.exe /r <# or /R #>
```


## Disable or Remove Windows Defender *Application Guard Policies* (advanced)

If you have any problems when opening an app (*extremely rare*) and get the message "The app can not run because Device Guard" or "Windows Defender Application Guard Blocked this app", you have to remove 4 files with the same name, from different locations.


- In EFI Partition

```PowerShell
Remove-Item -LiteralPath "$((Get-Partition | ? IsSystem).AccessPaths[0])Microsoft\Boot\WiSiPolicy.p7b"
```

- In Code Integrity Folder

```PowerShell
Remove-Item -LiteralPath "$env:windir\System32\CodeIntegrity\WiSiPolicy.p7b"
```

- In Windows Folder

```PowerShell
Remove-Item -LiteralPath "$env:windir\Boot\EFI\wisipolicy.p7b"
```

- In WinSxS Folder

```PowerShell
Remove-Item -Path "$env:windir\WinSxS" -Include *winsipolicy.p7b* -Recurse
```

## Creating an ISO with Windows Defender and Services disabled

You can create an ISO with Windoows Defender and Security Services Disabled. It's easy, so this is a fiie which it can helps you.
Here are the rules:
1. Mount the ISO and extract it into location.
2. Open the **sources** folder and create the **$OEM$** folder. (this is needed to run the DefenderRemover part in OOBE).
3. Open the **$OEM$** folder and create the folder with **$$** name.
4. Open the **$$** folder and create the folder with **Panther** name.
5. Open the **Panther** folder.
   The path it shown like to
    **%location of extracted ISO%\sources\$OEM$\$$\Panther\**
6. Download the unnatended.xml file from repo in ISO_Maker folder and put it in Panther folder.
7. Save this as bootable ISO. (for now the script can't do this automaticly, but it will do in next version).
    

## ❓ Frequently Asked Questions
#### ⭕ How to remove Windows Security Center / Windows SecurityApp from PC without downloading Script?
Paste this code into a powershell file and after **Run as Administrator**.
```
$remove_appx = @("SecHealthUI"); $provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers; $eol = @()
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store -ea 0 |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageName = $appx.PackageName; $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName 
    ni "$store\Deprovisioned\$PackageFamilyName" -force >''; $PackageFamilyName  
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageName" -force >''} ; $eol += $PackageName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxprovisionedpackage -packagename $PackageName -online -allusers >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageFullName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageFullName = $appx.PackageFullName; 
    ni "$store\Deprovisioned\$appx.PackageFamilyName" -force >''; $PackageFullName
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageFullName" -force >''} ; $eol += $PackageFullName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxpackage -package $PackageFullName -allusers >''
  }
}
```

#### ⭕ Why is the downloaded executable being flagged as a virus?

That is a false positive.

Some security apps flag this app as a virus because of the way the ".exe" files are created. Download with **git** or source code .zip will indicate virus-free.
Starting with Defender 12.6.x , some versions are considered as virus, some are not (its a bug from me, so do not file for this).

#### ⭕ Why is the patch not working when Windows is updated?

Windows Update includes a ```Intelligence Update``` which blocks certain actions and modifies Windows Defender/Security policies.
If the script is not working for you, check if you have the Windows Security Intelligence Update installed. If you do, disable tamper protection, and re-run the script.

#### ⭕ How to use the package remover without downloading the executable from the release?

Run the desired ".bat" file from cmd with PowerRun (by dragging to the executable). You must reboot for the changes to take effect.

#### ⭕ How to disable VBS if the removal script does not work

Disable with this command and reboot.

```
bcdedit /set hypervisorlaunchtype off
```
