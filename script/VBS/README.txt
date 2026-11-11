Defender Remover - VBS Start Menu actions

When Defender Remover starts with administrator rights, it copies the two VBS
batch scripts and their launcher to:
  %ProgramData%\Gallery Inc\Defender Remover\VBS

It creates all-users Start Menu shortcuts under:
  Start Menu > Programs > Defender Remover
    - Enable VBS
    - Disable VBS

The shortcuts start the bundled batch files through a UAC-elevated launcher.
Both actions change boot configuration and restart Windows after confirmation.
A firmware confirmation may be required at startup. If BitLocker is enabled,
suspend protection before changing EFI boot settings and keep the recovery key
available. Microsoft notes that BCD changes can cause BitLocker recovery.

Credential Guard note: LsaCfgFlags is set to 1 when enabling with UEFI lock and
set to 0 in both the system and policy registry locations when disabling.
Microsoft documents that deleting LsaCfgFlags alone may not disable Credential
Guard; setting it to 0 is required for the registry-based disable path.
