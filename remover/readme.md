# This is Defender Remover Section!
Those are register files which are applied when you press "Y" in Remover Section.
This section it includes registry files for unregistering Defender. This is apply only when are ran with PowerRun. 
So, unregistering components it will affect Windows Updates (if Microsoft includes updates for Defender Services / Components).

The components which are unregistered by the registry files are:
  - connections of Defender with Windows CBS Package (__!!Affecting Updates__)
  - Windows Defender Registered IDs
  - Windows Security UWP App (all Windows 10 Version, 1703 or later)
  - Windows Services (such as Defender Security Center, Antivirus Service, etc.)
  - Windows Exploit Guard (another component of Windows Security Service)
  - removes MSSecCore Service, and disables Microsoft Pluton Support, if the PC is having one
  - shell association, context menus of Windows Defender
  - removes Windows Action Center and Maintance Section from Control Panel
