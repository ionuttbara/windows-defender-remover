# ❌️ Defender Remover / Defender Disabler 
![logo of the application](https://user-images.githubusercontent.com/76656855/174484372-75292819-c33f-472e-8250-753519455ad1.png)
[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)
![ci-tests](https://github.com/dragonflydb/dragonfly/actions/workflows/ci.yml/badge.svg)

## ❓️ What is the app do?
This application is removing / disables Windows Defender , including the Windows Security App, Windows Virtualization-Based Security (VBS) , Windows Smart-Screen, Windows Security Services , Windows Web-Threat Service and Windows File Virtualization (UAC) and Microsoft Defender App Guard.

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


# KNOWN ISSUES SECTION!
## Version 12 Remover
At the moment is no known issues! 🚩

# Source Code (version 0.99)
This section of source code includes the GUI of Defender Remover, Registry and Commands which must be USED separately if you want.
 
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
Defender.Remover.12.exe /e
```
OR
```
Defender.Remover.12.exe /E
```
OR
```
Defender.Remover.12.exe e or E (without backslash)  
```

__DISABLE DEFENDER WITH ARGUMENTS__  
```
Defender.Remover.12.exe /D
```
OR
```
Defender.Remover.12.exe /d
```
OR
```
Defender.Remover.12.exe d or D (without backslash)  
```

__REMOVE DEFENDER WITH ARGUMENTS__  
ATTENTION! AFTER APPLYING THE PART, YOUR DEVICE WILL REBOOT AUTOMATICLY.
```
Defender.Remover.12.exe /R
```
OR
```
Defender.Remover.12.exe /r
```
OR
```
Defender.Remover.12.exe R or r (without backslash)  
```
# Frequent questions
1️⃣. How to use the package remover without downloading the executable from release?  
__RESPONSE:__ Run the desired ".bat" file from cmd with PowerRun (by dragging to the executable). You must to reboot to take effect of the removal.  

2️⃣. Why i used .NET 4.7.2 to realize the GUI of the Defender Remover?
__RESPONSE:__ I've using .NET 4.7.2 to realize the GUI because i want the app to be light.
# 📄🗝 Components License 
 🧳 PowerRun is created by Sordum. 
