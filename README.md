# ❌️ Defender Remover / Defender Disabler 
![logo of the application](https://user-images.githubusercontent.com/76656855/174484372-75292819-c33f-472e-8250-753519455ad1.png)

## ❓️ What is the app do?
This application is removing / disables Windows Defender , including the Windows Security App, Windows Virtualization-Based Security (VBS) , Windows SmartScreen, Windows Security Services , Windows Web-Threat Service and Windows File Virtualization (UAC) and Microsoft Defender App Guard.

## 🖍 System Requirements
Windows 7,8.x ,10 and 11  (all versions)
A system restore point is recommended before you apply the script (if you expect problems , you can write details in Issues Section).

## 📃 Instructions of the (*.exe) Version

Dwnload the application script from Release Section. Opening with admin rights and a window is showing the options.
# GUI (>Version 13)
Starting with Version 13, the app will move into GUI with Selection of application of Tweaks. Also this will keep the arguments section.
![image](https://user-images.githubusercontent.com/76656855/211152792-01e5a233-3c71-41fa-a81b-5a7f2be1f3dd.png)

# Terminal GUI (<Version 13)
The options are to remove, disable and enable Windows Defender by pressing 3 different buttons.  
1️⃣. Pressing "Y", Windows Defender will be REMOVED.  
2️⃣. Pressing "N", Windows Defender will be DISABLED.  
3️⃣. Pressing "E", Windows Defender will be ENABLED.   
4️⃣. Pressing "R" to create a System Restore Point. After creating the app will exit and re-launch the script to apply selected modifications.  

# Remove Windows Defender from an ISO Image of Windows (needed an Windows 8/10/11 ISO Image) (>Version 13)

1️⃣. Extract from ISO or download or extract an valid install.wim from Windows 8 or newer Windows versions.  
2️⃣. After selecting the .wim file, you can press ```"Y"```, ```"N"```, ```"E"``` by following section.  
3️⃣. After the settings was applied, you can save changes into ```install.wim``` or into ```ISO Image Disc```.  
4️⃣. Or you can do into single command 
``` 
Defender.Remover installwimmount (option to disable/enable/remove defender from .wim image) export_iso
```

# Disabling / Removing Defender for a install.wim/install.esd file
Needs and Windows ISO Image mounted or from a CD/DVD drive or from USB Flash Drive. (The letter of drive is detected automaticly by the script)
__!Attention__ It takes 8 - 16 GB of space in C:\ (it creates a folder named MountedDefenderRemover in C:\ and mounts Windows Image in that folder)
__!Attention__ If the disc image contains install.esd source file, the script will convert into .wim file before to take the disabler/remover process.
After the process is configured , the ISO Image will be saved in ``` c:\defenderRemovedISO\WindowsDefenderRemovedImage.iso ```
![terminal_gui](https://user-images.githubusercontent.com/76656855/217674225-554e2c4c-da51-498f-9e62-533f311196c6.png)
After Applying the script with desired option, the device will reboot automaticly.  
Before to start the script, an automatic system restore point is created. If something fails, can be restored easily.  

## 🛑 Why this downloaded app/script is taked as virus?
The app is false positive. Some Security Apps it take this app as a virus because the inclusion of IoBit Unlocker, or the way of the .exe creation.
Also , you can download the (*.zip) version.  
The Antiviruses which this script as a virus : MalwareBytes and BitDefender (as Heuristic), maybe the way which was created the exe file.

## 📃 Instructions for the (*.zip) version of the Defender Remover  
1️⃣. Download lastest version of the Script from __Releases__ section.  
2️⃣. Extract into an location.  
3️⃣. Open run,bat and choose the menu.  
4️⃣. Like the (*.exe) version, wait until the device reboots.  

## 📃 Automation of the script
Starting with version  12, you can disable, remove or enable Windows Defender with arguments.  
__ENABLE DEFENDER WITH ARGUMENTS__
```
Defender.Removerexe /e
```
OR
```
Defender.Remover.exe /E
```
OR
```
Defender.Remover.exe E
```
OR
```
Defender.Remover.exe e
```

__DISABLE DEFENDER WITH ARGUMENTS__  
```
Defender.Remover.exe /D
```
OR
```
Defender.Remover.exe /d
```
OR
```
Defender.Remover.exe D
```
OR
```
Defender.Remover.exe d
```

__REMOVE DEFENDER WITH ARGUMENTS__  
ATTENTION! AFTER APPLYING THE PART, YOUR DEVICE WILL REBOOT AUTOMATICLY.
```
Defender.Remover.exe /R
```
OR
```
Defender.Remover.exe /r
```
OR
```
Defender.Remover.12 r
```
OR
```
Defender.Remover.exe R
```
# Disable and/or Remove Windows Defender Application Guard Policies (deeper)
If you have some problems when open an app (extreme rare) and it will saying "The App it can not run because of Device Guard" or "Windows Defender Application Guard Blocked this app" you must remove 4 files (with same name , from 4 different locations).

The location of the file are:

a. In EFI Partition
```
<EFI System Partition>\Microsoft\Boot\WiSiPolicy.p7b
```
b. In Code Integrity Location

```
<OS Volume>\Windows\System32\CodeIntegrity\WiSiPolicy.p7b
```

c. In Windows Folder

```
C:\Windows\Boot\EFI\wisipolicy.p7b
```
d. In WinSxS Folder

This model is not added into script because the implementation of the removal the file from EFI partition it is impossible (for me) to implement.

1. Go to "C:\Windows\WinSxS" and Search for __winsipolicy.p7b__
# Frequent questions
1️⃣. How to use the package remover without downloading the executable from release?  
__RESPONSE:__ Run the desired ".bat" file from cmd with PowerRun (by dragging to the executable). You must to reboot to take effect of the removal.  

2️⃣. Why i used .NET 4.7.2 to realize the GUI of the Defender Remover?
__RESPONSE:__ I've using .NET 4.7.2 to realize the GUI because i want the app to be lighter in size.
 
3️⃣. What are ideal conditions of Applying the remover version of the script?
__RESPONSE:__ The "ideal" conditions of Applying the Remnover Version of the script, is needed an Clean Installation of Windows. Why I recommend that? Because the "Windows Intelligence Update" will be not installed when the defender package is not exist.

# 📄🗝 Components License 
 🧳 PowerRun is created by Sordum. PowerRun is used for applying some settings as SYSTEM User.
 🧳 OSCDIMG is a tool created by Microsoft Corp. This is used for creation ISO files which is including Windows Operating System.
