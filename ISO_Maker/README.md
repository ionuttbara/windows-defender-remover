#  ISO Maker / Unattended Installation

This module allows you to create a Windows ISO with Windows Defender and Security Services disabled right from the start. 

**Benefits:**
* Defender never runs, even during the first boot.
* Prevents Windows Update from reinstalling components during setup.
* Ideal for creating a Defender free, installation media.

## Instructions (If you're working on Windows DVD)

To integrate Defender Remover into your Windows Installation media, follow these steps:

1.  **Extract the ISO:** Mount your Windows ISO and extract its contents to a folder on your PC.
2.  **Create the Folder Structure:**
    Navigate to the `sources` folder inside your extracted ISO and create the following nested directory structure:
    ```text
    sources
    └── $OEM$
        └── $$
            └── Panther
    ```
    *Full path example:* `C:\ISOFolder\sources\$OEM$\$$\Panther\`

3.  **Copy the XML:**
    * Download the `unattend.xml` (or `autounattend.xml`) file from this folder.
    * Place it inside the newly created `Panther` folder.

4.  **Rebuild the ISO:**
    Save the folder contents back as a bootable ISO using tools like AnyBurn or ImgBurn.


## Instructions (if you're working on Windows USB Flash Drive)

1. **Make USB bootable with Rufus.**  
2. **Create the Folder Structure:**
    Navigate to the `sources` folder inside your extracted ISO and create the following nested directory structure:
    ```text
    sources
    └── $OEM$
        └── $$
            └── Panther
    ```
    *Full path example:* `C:\ISOFolder\sources\$OEM$\$$\Panther\`

3.  **Copy the XML:**
    * Download the `unattend.xml` (or `autounattend.xml`) file from this folder.
    * Place it inside the newly created `Panther` folder.
    * Copy the autounattend.xml file to main folder of USB. (This will block to make in-place upgrades.)  


## Important Note
This method utilizes the `unattend.xml` mechanism of Windows Setup. Ensure you do not have conflicting unattended files if you are using other customization tools.