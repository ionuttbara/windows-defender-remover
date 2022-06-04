
# Windows Defender Remover / Windows Defender Disabler

![Defender](https://kuhika.com/wp-content/uploads/2022/01/How-to-Remove-Scan-Folder-in-Windows-Defender-%E2%80%93-Antivirus.jpg)

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)
![ci-tests](https://github.com/dragonflydb/dragonfly/actions/workflows/ci.yml/badge.svg)

Melody Windows Defender (Remover/Disabler)  is helping you to remove/disable Windows Defender.

- Removes Windows Defender from Windows System.
- Removes Windows Security App for Windows 10 (10586+) and Windows 11 Insider Builds.
- If you want to use Windows Security App or Windows Update , you can use the provided registry file to disable Windows Defender.

## Features

- The Fidelity/Melody Technology is used for removing Windows Defender System Packages (this is affecting Windows Updates in Windows 10, but in Windows 11 is not causing any problems)

## System Requiments

 - Windows 7 (Service Pack 1), Windows 8.x , Windows 10 (all versions)
- A system restore point before appling (if don't like the effect of the app).
- If the antivirus says the file is a virus, because i've include "PowerRun.exe" (PowerRun by Sordum) To force remove the services, and unregister Windows Defender and Widnows Defender Security Center from the PC. It's false positive.

## How to use the script?

Just run the app. It show an terminal window with 3 options.
The options are to remove, disable and enable Windows Defender by pressing 3 different buttons.
1. Pressing "Y" , Windows Defender will be REMOVED. This means , a system restore point is recommended.
2. Pressing "N", Windows Defender will be DISABLED. To restore that, re-apply the script and press "E". (It doesn't need creation of Restore Point from Windows System Restore Settings).
![DefenderRemoverDisablerWindow](https://i.imgur.com/2BvT5QJ.png)

After Applying the PC  will reboot automaticly.
