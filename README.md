
# Windows Defender Remover / Windows Defender Disabler
![logo of the application](https://user-images.githubusercontent.com/76656855/174484372-75292819-c33f-472e-8250-753519455ad1.png)
[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)
![ci-tests](https://github.com/dragonflydb/dragonfly/actions/workflows/ci.yml/badge.svg)

Windows Defender (Remover/Disabler)  Script is helping you to remove/disable Windows Defender.  
- Removes Windows Defender from Windows System.
- Removes Windows Security App for Windows 10  and Windows 11 Insider Builds.  

## Features

- You can Remove Windows Defender (and connected Windows Security features) in one click!  
- Also, if you don't want to remove defender, you can disable or enable it.  

## System Requiments

 - Windows 10 , version 1703 or newer 
 __ATTENTION!__ This version of Script works at Windows 8.x and Windows 10 1507/1511/1607, but after applying you can't open UWP Apps.  
 __Last version of Defender Script for Windows 7, 8.x and 10 (1507/1607/1511) is 4.5. (search for version 4.5 in Release Section).__  
__A system restore point before appling (if don't like the effect of the app).__
- If the antivirus says the file is a virus, because i've include "PowerRun.exe" (PowerRun by Sordum) To force remove the services, and unregister Windows Defender and Widnows Defender Security Center from the PC. It's false positive.

## How to use the script?

Just run the app. It show an terminal window with 3 options.
The options are to remove, disable and enable Windows Defender by pressing 3 different buttons.
1. Pressing "Y" , Windows Defender will be REMOVED. This means , a system restore point is recommended.
2. Pressing "N", Windows Defender will be DISABLED. To restore that, re-apply the script and press "E". (It doesn't need creation of Restore Point from Windows System Restore Settings).
3. Pressing "E", Windows Defender will be ENABLED.
![DefenderRemoverDisablerWindow](https://i.imgur.com/2BvT5QJ.png)  
After Applying the script with desired option, the device will reboot automaticly.
