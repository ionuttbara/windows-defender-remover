#️ Remove Core Defender (Engine & Services)

This directory contains registry files and scripts specifically designed to neutralize the backend of Windows Defender.

## What gets removed?

Running the scripts in this section will forcibly remove or disable:

* **Antivirus Service:** The main engine preventing file execution.
* **Windows Defender Drivers:** Including rootkit scanners and file system filters.
* **SmartScreen:** The filter that blocks "unrecognized" apps.
* **SpyNet Telemetry:** Prevents sending data to Microsoft.
* **Scheduled Tasks:** Disables automatic scanning and maintenance tasks.
* **Context Menu:** Removes "Scan with Windows Defender" from the right-click menu.

## Usage

These files are typically executed automatically by the main `Script_Run.bat`, but can be used individually for troubleshooting or specific needs.

* **Registry Tweaks (.reg):** Double-click to merge into the registry.
* **Disabling Mitigation:** Use `Disable Mitigation.reg` to turn off exploit protection features.

> **Note:** Removing these files usually keeps the "Windows Security" app visible, but the antivirus protection inside it will be broken/disabled. If you want to remove the App UI as well, see the [Remove_SecurityComp](../Remove_SecurityComp/README.md) module.