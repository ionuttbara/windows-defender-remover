DEFENDER REMOVER 13.1 - BACKUP / RESTORE
====================================

Backup location:
  C:\ProgramData\Gallery Inc\Defender Remover\schemas

Each removal run creates a separate timestamped schema folder containing:
  Manifest.json       Operation log and restore status
  Files\              Backups of files/folders successfully removed
  Registry\Keys\     .reg exports of changed/deleted registry keys
  Registry\Values\   .reg snapshots of registry values changed by imports
  Staging\            Temporary pre-operation snapshots

The remover backs up file/folder content before attempting deletion. If the
backup cannot be copied and verified, that item is not deleted. Registry
imports are also snapshotted before they run; only changes confirmed after
the import remain as completed restore entries. A small pre-change journal is
written before each destructive step so an interrupted operation can also be
rolled back safely after a reboot.
Machine-hive (.reg) sections are routed through the elevated PowerRun path;
HKCU/HKCR sections are imported in the interactive user's elevated process so
they are not redirected into the SYSTEM profile.

Use Start Menu > Programs > Defender Remover > Restore Defender. The restore
launcher requests Administrator privileges, restores saved file and registry
data, and marks completed schemas so they are not restored again. A restart
is recommended after restoration. Backup schemas are retained after restore.

IMPORTANT - WINDOWS SECURITY APP
If removal of Windows Security App (SecHealthUI) was selected and confirmed,
its AppX package is NOT backed up. Restore Defender does not reinstall it and
will display this limitation in the schema and restore screen. Do not treat
this restore feature as recovery of the Windows Security App package.

POWERSHELL EXECUTION POLICY
Launchers use -NoProfile -ExecutionPolicy Bypass for the current PowerShell
process only. They do not change the machine-wide or user-wide execution
policy. Group Policy settings (MachinePolicy / UserPolicy) may override this
process-level setting. Use Build.cmd to launch the builder with the same
process-scoped bypass on a fresh Windows installation.

The schemas contain system files and registry data. Do not edit or delete
them unless you intend to discard the corresponding restore point.

VERSION 13.1 - PROCESS CHECK
The main menu performs a read-only check for MsMpEng, NisSrv and
SecurityHealthService. Detected process names and PIDs are saved in the
backup Manifest.json. No Defender process is terminated, suspended or
modified. The menu input uses .NET Console I/O to avoid prompt ordering
issues seen with Read-Host in some PS2EXE console builds.
