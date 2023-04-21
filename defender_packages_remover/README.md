# This is the removal of Windows Security and Windows Defender CBS Packages.

_Attention!_ The script (.exe file) is not removing Windows Virtualization Security from System (VBS) because is producing problem with virtualization software such Hyper-V and VirtualBox.  
If you __DON'T USE__ Hyper-V and VirtualBox, this can be removed safetly.

_Attention2!_ The removal of Windows-Defender CBS Package (Component Base System) is not work in lastest Windows 10 22H2, Windows 11 2xH2 after Octomber '22 Quality Updates. It gets an error about permission, so 
the app can do that automaticly modular remover (in Defender Remover 12.4 or newer) to remove the registry and files without affecting Windows Updates. 

__Indexed list of CBS Packages can be found in ``` C:\Windows\System32\CatRoot ``` (one of folder) maybe will be ``` {F750E6C3-38EE-11D1-85E5-00C04FC295EE} ``` or idk. The name of package is listed in next format__

```nameofpackage-Package~31bf3856ad364e35~amd64~~buildnumber_.cat ```  
(name file of security catalog, indicates the name of the package, for Windows Defender are 8 or 24 , depends what version of Windows 10 or Windows 11 you have.)
