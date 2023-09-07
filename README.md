# ❌️ Defender Remover / Defender Disabler

![logo of the application](https://user-images.githubusercontent.com/79479952/239704528-c017473e-1d2a-4d4a-a215-bf71d137b86a.png)

## ❓️ What does the app do?

This application removes / disables Windows Defender, including the Windows Security App, Windows Virtualization-Based Security (VBS) , Windows SmartScreen, Windows Security Services , Windows Web-Threat Service and Windows File Virtualization (UAC) , Microsoft Defender App Guard, Microsoft Driver Block List, System Mitigations and Windows Defender's Settings Page (in Settings App , Winodws 10 or newer).

## Temporary message!
During the adding of #85 issue, some parts of code in github project can be modified. I want to learn how to work with Sublime Merge.
When the code will be synced, the message will be removed.


## 🖍 System Requirements

* Windows `8.x`, `10` and `11`  (all versions).
  
A system restore point is recommended before you apply the script.
  
  If you meet any problems, you can write details in Issues Section.

## 📃 Instructions for the (*.exe) Version

Download the compiled script from [Releases](https://github.com/jbara2002/windows-defender-remover/releases) Section.

Open with admin rights and follow the window showing menu options.****

## GUI
![terminal_gui](https://github.com/jbara2002/windows-defender-remover/assets/76656855/c0823459-8894-42bc-a3bc-ada6945a6b40)

The options are to remove, disable and enable Windows Defender by pressing 3 different buttons.  
1️⃣. Pressing "Y", Windows Defender will be REMOVED.  
2️⃣. Pressing "N", Windows Defender will be DISABLED.  
3️⃣. Pressing "R", Windows Defender will be ENABLED.

## Remove Windows Defender from a Windows ISO

>Requires a Windows 8/10/11 ISO Image
>
1️⃣. Extract from ISO or download or extract an valid install.wim from Windows 8 or newer Windows versions.  
2️⃣. After the settings was applied, you can save changes into ```install.wim``` or into ```ISO Image Disc```. 

```PowerShell
DefenderRemover.exe installwimmount <#(Option to disable/enable/remove defender from .wim image)#> export.iso
```

## Disabling / Removing Defender for a install.wim/install.esd file

Needs and Windows ISO Image mounted or from a CD/DVD drive or from USB Flash Drive.

(The letter of drive is detected automaticly by the script)

**!Attention**  This requires 8 - 16 GB of space in C:\ (it creates a folder named MountedDefenderRemover in C:\ and mounts Windows Image in that folder)

After the process is configured , the ISO Image will be saved in ``` c:\defenderRemovedISO\WindowsDefenderRemovedImage.iso ```
After Applying the script with desired option, the device will reboot automaticly.  
Before to start the script, an automatic system restore point is created. If something fails, can be restored easily.  

## 🛑 Why is this downloaded app/script being flagged as a virus?

That is a false positive.

Some Security apps flag this app as a virus because  of the way the .exe files are created.

## 🛑 If i have a clean installed Windows with no updates the script is works, why in updated Windows the script is not working?

Updated Windows includes a ``` Windows Intelligence Update ``` this is designed for blocking actions , modifying Windows defender/Security Polocies, and so on. 
If the script is not work for you, first check if you have the Windows Security Intelligence Update installed. If you have, disable tamper protection, and re-apply the script.
  
## 📃 Automation of the script

Starting with version  12, you can disable, remove or enable Windows Defender with arguments.  

### **ENABLE DEFENDER WITH ARGUMENTS**

```PowerShell
Defender.Remover.exe /R
```

OR

```PowerShell
Defender.Remover.exe /r
```

### **DISABLE DEFENDER WITH ARGUMENTS**  

```PowerShell
Defender.Remover.exe /N
```

OR

```PowerShell
Defender.Remover.exe /n
```

### **REMOVE DEFENDER WITH ARGUMENTS**  

ATTENTION! AFTER APPLYING THIS PART, YOUR DEVICE WILL REBOOT AUTOMATICALLY.

```PowerShell
Defender.Remover.exe /Y
```

OR

```PowerShell
Defender.Remover.exe /y
```

## Disable and/or Remove Windows Defender *Application Guard Policies* (deeper)

If you have some problems when opening an app (*extremely rare*) and it will be saying "The app can not run because Device Guard" or "Windows Defender Application Guard Blocked this app" you must remove 4 files (with the same name, from 4 different locations).

The location of the files are:

a. In EFI Partition

```PowerShell
$Path_To_EFI_System_Partition\Microsoft\Boot\WiSiPolicy.p7b
```

b. In Code Integrity Location

```PowerShell
$env:windir\System32\CodeIntegrity\WiSiPolicy.p7b
```

c. In Windows Folder

```PowerShell
$env:windir\Boot\EFI\wisipolicy.p7b
```

d. In WinSxS Folder

This module is not added to the script because implementing the removal of the file from the EFI partition is impossible (for now) to implement.

 Manually removal: Go to "C:\Windows\WinSxS" and Search for **winsipolicy.p7b** then delete the file.

i.e:

```PowerShell
[IO.DirectoryInfo]::New("$env:windir\WinSxS").GetFiles("*", [IO.SearchOption]::AllDirectories).Where({ $_.Name -eq "winsipolicy.p7b" }) | Remove-Item -Force
```

## **Frequent questions**

1️⃣. How to use the package remover without downloading the executable from the release?

**RESPONSE:** Run the desired ".bat" file from cmd with PowerRun (by dragging to the executable). You must reboot to take effect of the removal.

2️⃣.  What are the ideal conditions for running the remover version of the script?

**RESPONSE:** The "ideal" condition is to run the Remover Version of the script on a Clean Installation of Windows. Why do I recommend that? Because the "Windows Intelligence Update" would not be installed and thus no defender package.

## 📄🗝 Components License