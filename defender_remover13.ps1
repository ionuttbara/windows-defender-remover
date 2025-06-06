$defenderremoverver = "12.8.2"

# Arguments Section
if ($args[0] -eq "y" -or $args[0] -eq "Y") {
    Remove-Defender
} elseif ($args[0] -eq "a" -or $args[0] -eq "A") {
    Remove-Antivirus
} elseif ($args[0] -eq "S" -or $args[0] -eq "s") {
    Disable-Mitigation
} else {
    Clear-Host
    Write-Host "------ Defender Remover Script , version $defenderremoverver ------"
    Write-Host "Select an option:`n"
    Write-Host "Do you want to remove Windows Defender and alongside components? After this, you'll need to reboot."
    Write-Host "If your PC has a Microsoft Pluton Chip, you can disable it from BIOS anytime. (This script removes the integration of Pluton Chip Support and Processing from Windows.)"
    Write-Host "After confirmation of Removal, your Device will RESTART!!"
    Write-Host "A backup and/or System Restore point is recommended."
    Write-Host "[Y] Remove Windows Defender Antivirus + Disable All Security Mitigations"
    Write-Host "[A] Remove Windows Defender only, but keep UAC Enabled"
    Write-Host "[S] Disable All Security Mitigations"
    $choice = Read-Host "Choose an option"
    
    if ($choice -eq "Y" -or $choice -eq "y") {
        Remove-Defender
    } elseif ($choice -eq "A" -or $choice -eq "a") {
        Remove-Antivirus
    }

    } elseif ($choice -eq "S" -or $choice -eq "s") {
        Disable-Mitigation
    }


function RunAsTI ($cmd,$arg) { $id='RunAsTI'; $key="Registry::HKU\$(((whoami /user)-split' ')[-1])\Volatile Environment"; $code=@'
 $I=[int32]; $M=$I.module.gettype("System.Runtime.Interop`Services.Mar`shal"); $P=$I.module.gettype("System.Int`Ptr"); $S=[string]
 $D=@(); $T=@(); $DM=[AppDomain]::CurrentDomain."DefineDynami`cAssembly"(1,1)."DefineDynami`cModule"(1); $Z=[uintptr]::size
 0..5|% {$D += $DM."Defin`eType"("AveYo_$_",1179913,[ValueType])}; $D += [uintptr]; 4..6|% {$D += $D[$_]."MakeByR`efType"()}
 $F='kernel','advapi','advapi', ($S,$S,$I,$I,$I,$I,$I,$S,$D[7],$D[8]), ([uintptr],$S,$I,$I,$D[9]),([uintptr],$S,$I,$I,[byte[]],$I)
 0..2|% {$9=$D[0]."DefinePInvok`eMethod"(('CreateProcess','RegOpenKeyEx','RegSetValueEx')[$_],$F[$_]+'32',8214,1,$S,$F[$_+3],1,4)}
 $DF=($P,$I,$P),($I,$I,$I,$I,$P,$D[1]),($I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$P,$P,$P,$P),($D[3],$P),($P,$P,$I,$I)
 1..5|% {$k=$_; $n=1; $DF[$_-1]|% {$9=$D[$k]."Defin`eField"('f' + $n++, $_, 6)}}; 0..5|% {$T += $D[$_]."Creat`eType"()}
 0..5|% {nv "A$_" ([Activator]::CreateInstance($T[$_])) -fo}; function F ($1,$2) {$T[0]."G`etMethod"($1).invoke(0,$2)}
 $TI=(whoami /groups)-like'*1-16-16384*'; $As=0; if(!$cmd) {$cmd='control';$arg='admintools'}; if ($cmd-eq'This PC'){$cmd='file:'}
 if (!$TI) {'TrustedInstaller','lsass','winlogon'|% {if (!$As) {$9=sc.exe start $_; $As=@(get-process -name $_ -ea 0|% {$_})[0]}}
 function M ($1,$2,$3) {$M."G`etMethod"($1,[type[]]$2).invoke(0,$3)}; $H=@(); $Z,(4*$Z+16)|% {$H += M "AllocHG`lobal" $I $_}
 M "WriteInt`Ptr" ($P,$P) ($H[0],$As.Handle); $A1.f1=131072; $A1.f2=$Z; $A1.f3=$H[0]; $A2.f1=1; $A2.f2=1; $A2.f3=1; $A2.f4=1
 $A2.f6=$A1; $A3.f1=10*$Z+32; $A4.f1=$A3; $A4.f2=$H[1]; M "StructureTo`Ptr" ($D[2],$P,[boolean]) (($A2 -as $D[2]),$A4.f2,$false)
 $Run=@($null, "powershell -win 1 -nop -c iex `$env:R; # $id", 0, 0, 0, 0x0E080600, 0, $null, ($A4 -as $T[4]), ($A5 -as $T[5]))
 F 'CreateProcess' $Run; return}; $env:R=''; rp $key $id -force; $priv=[diagnostics.process]."GetM`ember"('SetPrivilege',42)[0]
 'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege' |% {$priv.Invoke($null, @("$_",2))}
 $HKU=[uintptr][uint32]2147483651; $NT='S-1-5-18'; $reg=($HKU,$NT,8,2,($HKU -as $D[9])); F 'RegOpenKeyEx' $reg; $LNK=$reg[4]
 function L ($1,$2,$3) {sp 'HKLM:\Software\Classes\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}' 'RunAs' $3 -force -ea 0
  $b=[Text.Encoding]::Unicode.GetBytes("\Registry\User\$1"); F 'RegSetValueEx' @($2,'SymbolicLinkValue',0,6,[byte[]]$b,$b.Length)}
 function Q {[int](gwmi win32_process -filter 'name="explorer.exe"'|?{$_.getownersid().sid-eq$NT}|select -last 1).ProcessId}
 $11bug=($((gwmi Win32_OperatingSystem).BuildNumber)-eq'22000')-AND(($cmd-eq'file:')-OR(test-path -lit $cmd -PathType Container))
 if ($11bug) {'System.Windows.Forms','Microsoft.VisualBasic' |% {[Reflection.Assembly]::LoadWithPartialName("'$_")}}
 if ($11bug) {$path='^(l)'+$($cmd -replace '([\+\^\%\~\(\)\[\]])','{$1}')+'{ENTER}'; $cmd='control.exe'; $arg='admintools'}
 L ($key-split'\\')[1] $LNK ''; $R=[diagnostics.process]::start($cmd,$arg); if ($R) {$R.PriorityClass='High'; $R.WaitForExit()}
 if ($11bug) {$w=0; do {if($w-gt40){break}; sleep -mi 250;$w++} until (Q); [Microsoft.VisualBasic.Interaction]::AppActivate($(Q))}
 if ($11bug) {[Windows.Forms.SendKeys]::SendWait($path)}; do {sleep 7} while(Q); L '.Default' $LNK 'Interactive User'
'@; $V='';'cmd','arg','id','key'|%{$V+="`n`$$_='$($(gv $_ -val)-replace"'","''")';"}; sp $key $id $($V,$code) -type 7 -force -ea 0
 start powershell -args "-win 1 -nop -c `n$V `$env:R=(gi `$key -ea 0).getvalue(`$id)-join''; iex `$env:R" -verb runas
}

function Remove-AppxPackages {
    param (
        [string[]]$RemoveAppx = @("SecHealthUI"),
        [string[]]$Skip = @(),
        [string[]]$Users = @('S-1-5-18')
    )

    $Provisioned = Get-AppxProvisionedPackage -Online
    $AppxPackage = Get-AppxPackage -AllUsers
    $Eol = @()
    $Store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
    if (Test-Path $Store) {
        $Users += $((Dir $Store -Ea 0 | Where-Object { $_ -like '*S-1-5-21*' }).PSChildName)
    }
    foreach ($Choice in $RemoveAppx) {
        if ('' -eq $Choice.Trim()) { continue }
        choice
        foreach ($Appx in $Provisioned | Where-Object { $_.PackageName -like "*$Choice*" }) {
            $Next = $true
            foreach ($No in $Skip) {
                if ($Appx.PackageName -like "*$No*") { $Next = $false }
            }
            if (-not $Next) { continue }
            $PackageName = $Appx.PackageName
            $PackageFamilyName = ($AppxPackage | Where-Object { $_.Name -eq $Appx.DisplayName }).PackageFamilyName
            New-Item "$Store\Deprovisioned\$PackageFamilyName" -Force | Out-Null
            $PackageFamilyName
            foreach ($Sid in $Users) {
                New-Item "$Store\EndOfLife\$Sid\$PackageName" -Force | Out-Null
            }
            $Eol += $PackageName
            dism /Online /Set-NonRemovableAppPolicy /PackageFamily:$PackageFamilyName /NonRemovable:0 | Out-Null
            Remove-AppxProvisionedPackage -PackageName $PackageName -Online -AllUsers | Out-Null
        }
        foreach ($Appx in $AppxPackage | Where-Object { $_.PackageFullName -like "*$Choice*" }) {
            $Next = $true
            foreach ($No in $Skip) {
                if ($Appx.PackageFullName -like "*$No*") { $Next = $false }
            }
            if (-not $Next) { continue }

            $PackageFullName = $Appx.PackageFullName
            New-Item "$Store\Deprovisioned\$Appx.PackageFamilyName" -Force | Out-Null
            $PackageFullName
            foreach ($Sid in $Users) {
                New-Item "$Store\EndOfLife\$Sid\$PackageFullName" -Force | Out-Null
            }
            $Eol += $PackageFullName
            dism /Online /Set-NonRemovableAppPolicy /PackageFamily:$PackageFamilyName /NonRemovable:0 | Out-Null
            Remove-AppxPackage -Package $PackageFullName -AllUsers | Out-Null
        }
    }
    return $Eol
}

function Set-WindowsDefenderPolicies {
    Write-Host "Applying Windows Defender policy changes..." -ForegroundColor Cyan

    # Helper to create key if missing
    function Ensure-Key {
        param ([string]$Path)
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
    }

    # Set registry values
    $settings = @{
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowIOAVProtection"                  = @{"value"=0}
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"                                           = @{
            "PUAProtection"=0; "DisableRoutinelyTakingAction"=1; "ServiceKeepAlive"=0;
            "AllowFastServiceStartup"=0; "DisableLocalAdminMerge"=1; "DisableAntiSpyware"=1;
            "RandomizeScheduleTaskTimes"=0
        }
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowArchiveScanning"                 = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowBehaviorMonitoring"              = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowCloudProtection"                 = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowEmailScanning"                   = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowFullScanOnMappedNetworkDrives"    = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowFullScanRemovableDriveScanning"   = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowIntrusionPreventionSystem"        = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowOnAccessProtection"               = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowRealtimeMonitoring"               = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowScanningNetworkFiles"             = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowScriptScanning"                   = @{"value"=1}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowUserUIAccess"                     = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AvgCPULoadFactor"                      = @{"value"=50}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\CheckForSignaturesBeforeRunningScan"   = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\CloudBlockLevel"                       = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\CloudExtendedTimeout"                  = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\DaysToRetainCleanedMalware"             = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\DisableCatchupFullScan"                 = @{"value"=1}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\DisableCatchupQuickScan"                = @{"value"=1}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\EnableControlledFolderAccess"          = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\EnableLowCPUPriority"                  = @{"value"=1}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\EnableNetworkProtection"               = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\PUAProtection"                         = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\RealTimeScanDirection"                 = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\ScanParameter"                         = @{"value"=2}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\ScheduleScanDay"                        = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\ScheduleScanTime"                       = @{"value"=0}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\SignatureUpdateInterval"               = @{"value"=24}
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\SubmitSamplesConsent"                  = @{"value"=0}

        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions"                                = @{"DisableAutoExclusions"=1}
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine"                                  = @{
            "MpEnablePus"=0; "MpCloudBlockLevel"=0; "MpBafsExtendedTimeout"=0; "EnableFileHashComputation"=0
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\NIS\Consumers\IPS"                         = @{
            "ThrottleDetectionEventsRate"=0; "DisableSignatureRetirement"=1; "DisableProtocolRecognition"=1
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager"                            = @{"DisableScanningNetworkFiles"=1}
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"                      = @{
            "DisableRealtimeMonitoring"=1; "DisableBehaviorMonitoring"=1; "DisableOnAccessProtection"=1;
            "DisableScanOnRealtimeEnable"=1; "DisableIOAVProtection"=1; "RealtimeScanDirection"=2;
            "IOAVMaxSize"=1298; "DisableInformationProtectionControl"=1; "DisableIntrusionPreventionSystem"=1;
            "DisableRawWriteNotification"=1
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan"                                       = @{
            "LowCpuPriority"=1; "DisableRestorePoint"=1; "DisableArchiveScanning"=0;
            "DisableScanningNetworkFiles"=0; "DisableCatchupFullScan"=0; "DisableCatchupQuickScan"=1;
            "DisableEmailScanning"=0; "DisableHeuristics"=1; "DisableReparsePointScanning"=1
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates"                         = @{
            "SignatureDisableNotification"=1; "RealtimeSignatureDelivery"=0; "ForceUpdateFromMU"=0;
            "DisableScheduledSignatureUpdateOnBattery"=1; "UpdateOnStartUp"=0;
            "SignatureUpdateCatchupInterval"=2; "DisableUpdateOnStartupWithoutEngine"=1;
            "ScheduleTime"=5184; "DisableScanOnUpdate"=1
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"                                    = @{
            "DisableBlockAtFirstSeen"=1; "LocalSettingOverrideSpynetReporting"=0;
            "SpynetReporting"=0; "SubmitSamplesConsent"=2
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration"                          = @{"SuppressRebootNotification"=1}
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access" = @{"EnableControlledFolderAccess"=0}
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" = @{"EnableNetworkProtection"=0}
        "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows Defender"                                = @{"DisableRoutinelyTakingAction"=1}
        "HKLM:\SOFTWARE\Policies\Microsoft\Microsoft Antimalware"                                      = @{
            "ServiceKeepAlive"=0; "AllowFastServiceStartup"=0; "DisableRoutinelyTakingAction"=1;
            "DisableAntiSpyware"=1; "DisableAntiVirus"=1
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Microsoft Antimalware\SpyNet"                               = @{
            "SpyNetReporting"=0; "LocalSettingOverrideSpyNetReporting"=0
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting"                                = @{
            "DisableEnhancedNotifications"=1; "DisableGenericRePorts"=1; "WppTracingLevel"=0; "WppTracingComponents"=0
        }
        "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"                                              = @{"VerifiedAndReputablePolicyState"=0}
    }

    foreach ($path in $settings.Keys) {
        Ensure-Key -Path $path
        foreach ($name in $settings[$path].Keys) {
            $value = $settings[$path][$name]
            Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord -Force
        }
    }

    Write-Host "All Defender policies have been updated." -ForegroundColor Green
}

function Disable-WindowsSecurityNotifications {
    Write-Host "Disabling Windows Security and Defender notifications..." -ForegroundColor Cyan

    # Set Registry values
    $registryChanges = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WindowsDefenderSecurityCenter\DisableEnhancedNotifications"; Name = "value"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WindowsDefenderSecurityCenter\DisableNotifications"; Name = "value"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WindowsDefenderSecurityCenter\HideWindowsSecurityNotificationAreaControl"; Name = "value"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications"; Name = "DisableEnhancedNotifications"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications"; Name = "DisableNotifications"; Value = 1 },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"; Name = "Enabled"; Value = 0 }
    )

    foreach ($change in $registryChanges) {
        if (-not (Test-Path $change.Path)) {
            New-Item -Path $change.Path -Force | Out-Null
        }
        New-ItemProperty -Path $change.Path -Name $change.Name -Value $change.Value -PropertyType DWORD -Force | Out-Null
    }

    # Delete and recreate HKLM:\SOFTWARE\Microsoft\Security Center
    $securityCenterKey = "HKLM:\SOFTWARE\Microsoft\Security Center"
    if (Test-Path $securityCenterKey) {
        Remove-Item -Path $securityCenterKey -Recurse -Force
        Start-Sleep -Milliseconds 500
    }
    New-Item -Path $securityCenterKey -Force | Out-Null
    New-ItemProperty -Path $securityCenterKey -Name "FirstRunDisabled" -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $securityCenterKey -Name "AntiVirusOverride" -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $securityCenterKey -Name "FirewallOverride" -Value 1 -PropertyType DWORD -Force | Out-Null

    Write-Host "All changes applied successfully." -ForegroundColor Green
}

function Remove-WindowsDefenderTraces {
    Write-Host "Removing Windows Defender traces from registry..." -ForegroundColor Cyan

    # List of registry keys to delete
    $keysToDelete = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend",
        "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\windowsdefender",
        "HKLM:\SOFTWARE\Classes\AppUserModelId\Windows.Defender",
        "HKLM:\SOFTWARE\Classes\AppUserModelId\Microsoft.Windows.Defender",
        "HKCR:\AppX9kvz3rdv8t7twanaezbwfcdgrbg3bck0",
        "HKCU:\Software\Classes\ms-cxh",
        "HKCR:\Local Settings\MrtCache\C:%5CWindows%5CSystemApps%5CMicrosoft.Windows.AppRep.ChxApp_cw5n1h2txyewy%5Cresources.pri",
        "HKCR:\WindowsDefender",
        "HKCU:\Software\Classes\AppX9kvz3rdv8t7twanaezbwfcdgrbg3bck0",
        "HKLM:\SOFTWARE\Classes\WindowsDefender"
    )

    foreach ($key in $keysToDelete) {
        if (Test-Path $key) {
            try {
                Remove-Item -Path $key -Recurse -Force
                Write-Host "Deleted: $key" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to delete: $key. $_"
            }
        } else {
            Write-Host "Key not found: $key" -ForegroundColor Yellow
        }
    }

    # Remove specific values inside HKLM:\SYSTEM\CurrentControlSet\Control\Ubpm
    $ubpmKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Ubpm"
    $ubpmValues = @("CriticalMaintenance_DefenderCleanup", "CriticalMaintenance_DefenderVerification")

    foreach ($val in $ubpmValues) {
        if (Get-ItemProperty -Path $ubpmKey -Name $val -ErrorAction SilentlyContinue) {
            try {
                Remove-ItemProperty -Path $ubpmKey -Name $val -Force
                Write-Host "Deleted value: $val from Ubpm" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to delete value $val from Ubpm. $_"
            }
        }
    }

    # Remove specific values inside FirewallPolicy\RestrictedServices\Static\System
    $firewallKey = "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System"
    $firewallValues = @("WindowsDefender-1", "WindowsDefender-2", "WindowsDefender-3")

    foreach ($val in $firewallValues) {
        if (Get-ItemProperty -Path $firewallKey -Name $val -ErrorAction SilentlyContinue) {
            try {
                Remove-ItemProperty -Path $firewallKey -Name $val -Force
                Write-Host "Deleted firewall value: $val" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to delete firewall value $val. $_"
            }
        }
    }

    Write-Host "Windows Defender traces removal completed." -ForegroundColor Cyan
}

function Set-DefenderSettings {
    # Registry keys to disable Windows Defender and related settings
    $registryEntries = @(
        @{
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates"
            Values = @{
                "SignatureDisableNotification" = 1
                "RealtimeSignatureDelivery" = 0
                "ForceUpdateFromMU" = 0
                "DisableScheduledSignatureUpdateOnBattery" = 1
                "UpdateOnStartUp" = 0
                "SignatureUpdateCatchupInterval" = 2
                "DisableUpdateOnStartupWithoutEngine" = 1
                "ScheduleTime" = 51840 # 14 hours in minutes
                "DisableScanOnUpdate" = 1
            }
        },
        @{
            Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0ACC9108-2000-46C0-8407-5FD9F89521E8}"
            Values = @{}
            Remove = $true
        },
        @{
            Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{1D77BCC8-1D07-42D0-8C89-3A98674DFB6F}"
            Values = @{}
            Remove = $true
        },
        @{
            Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
            Values = @{
                "SettingsPageVisibility" = "hide:windowsdefender;"
            }
        },
        # More entries can be added here for each registry key you provided...
        
        # Disabling Defender service keys
        @{
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
            Values = @{
                "DisableRoutinelyTakingAction" = 1
                "ServiceKeepAlive" = 0
                "AllowFastServiceStartup" = 0
                "DisableLocalAdminMerge" = 1
            }
        },
        @{
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
            Values = @{
                "LocalSettingOverrideDisableOnAccessProtection" = 0
                "LocalSettingOverrideRealtimeScanDirection" = 0
                "LocalSettingOverrideDisableIOAVProtection" = 0
                "LocalSettingOverrideDisableBehaviorMonitoring" = 0
                "LocalSettingOverrideDisableIntrusionPreventionSystem" = 0
                "LocalSettingOverrideDisableRealtimeMonitoring" = 0
                "DisableIOAVProtection" = 1
                "DisableRealtimeMonitoring" = 1
                "DisableBehaviorMonitoring" = 1
                "DisableOnAccessProtection" = 1
                "DisableScanOnRealtimeEnable" = 1
                "RealtimeScanDirection" = 2
                "DisableInformationProtectionControl" = 1
                "DisableIntrusionPreventionSystem" = 1
                "DisableRawWriteNotification" = 1
            }
        },
        @{
            Key = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowBehaviorMonitoring"
            Values = @{
                "value" = 0
            }
        },
        @{
            Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows Defender"
            Values = @{
                "DisableRoutinelyTakingAction" = 1
            }
        }
    )
    
    # Loop through the registry entries and apply changes
    foreach ($entry in $registryEntries) {
        if ($entry.Remove) {
            # Remove registry key if specified
            Remove-Item -Path $entry.Key -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Removed registry key: $($entry.Key)"
        } else {
            # Set registry values
            foreach ($name in $entry.Values.Keys) {
                Set-ItemProperty -Path $entry.Key -Name $name -Value $entry.Values[$name] -Force
                Write-Host "Set $name to $($entry.Values[$name]) in $($entry.Key)"
            }
        }
    }
}

function Remove-Defenderq {
    Write-Host "Removing Defender-related registry keys and values..." -ForegroundColor Cyan

    # Registry KEYS to remove entirely
    $keys = @(
        # CLSID keys
        'HKCR:\CLSID\{E48B2549-D510-4A76-8A5F-FC126A6215F0}',
        'HKCR:\WOW6432Node\CLSID\{E48B2549-D510-4A76-8A5F-FC126A6215F0}',
        'HKLM:\SOFTWARE\Classes\CLSID\{E48B2549-D510-4A76-8A5F-FC126A6215F0}',
        'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{E48B2549-D510-4A76-8A5F-FC126A6215F0}',

        # WindowsRuntime classes
        'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.Service.UserSessionServiceManager',
        'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.ThreatExperienceManager.ThreatExperienceManager',
        'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.ThreatResponseEngine.ThreatDecisionEngine',
        'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.OneCore.WebThreatDefense.Configuration.WTDUserSettings',

        # Services
        'HKLM:\SYSTEM\CurrentControlSet\Services\MsSecCore',
        'HKLM:\SYSTEM\CurrentControlSet\Services\wscsvc',
        'HKLM:\SYSTEM\CurrentControlSet\Services\WdNisDrv',
        'HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc',
        'HKLM:\SYSTEM\CurrentControlSet\Services\WdFilter',
        'HKLM:\SYSTEM\CurrentControlSet\Services\WdBoot',
        'HKLM:\SYSTEM\CurrentControlSet\Services\SecurityHealthService',
        'HKLM:\SYSTEM\CurrentControlSet\Services\SgrmAgent',
        'HKLM:\SYSTEM\CurrentControlSet\Services\SgrmBroker',
        'HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend',
        'HKLM:\SYSTEM\CurrentControlSet\Services\MsSecFlt',
        'HKLM:\SYSTEM\CurrentControlSet\Services\MsSecWfp',

        # New additions (ShellServiceObjects)
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects\{900c0763-5cad-4a34-bc1f-40cd513679d5}',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects\{900c0763-5cad-4a34-bc1f-40cd513679d5}',

        # Context menu and Windows Defender keys
        'HKLM:\SOFTWARE\Microsoft\Windows Defender',
        'HKCR:\Folder\shell\WindowsDefender',
        'HKCR:\DesktopBackground\Shell\WindowsSecurity',
        'HKCR:\Folder\shell\WindowsDefender\Command'
    )

    foreach ($key in $keys) {
        try {
            if (Test-Path $key) {
                Remove-Item -Path $key -Force -Recurse
                Write-Host "Deleted key: $key" -ForegroundColor Green
            } else {
                Write-Host "Key not found (already deleted?): $key" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Failed to delete key: $key. Error: $_" -ForegroundColor Red
        }
    }

    # Registry VALUES to remove
    $valuesToDelete = @(
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Names = @('Windows Defender', 'SecurityHealth') },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; Names = @('Windows Defender', 'SecurityHealth') },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Names = @('WindowsDefender', 'SecurityHealth') }
    )

    foreach ($entry in $valuesToDelete) {
        $path = $entry.Path
        $names = $entry.Names

        foreach ($name in $names) {
            try {
                if (Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty -Path $path -Name $name -Force
                    Write-Host "Deleted value '$name' from $path" -ForegroundColor Green
                } else {
                    Write-Host "Value '$name' not found in $path" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Failed to delete value '$name' from $path. Error: $_" -ForegroundColor Red
            }
        }
    }

    # Registry VALUES to modify
    try {
        $targetPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection'
        if (-not (Test-Path $targetPath)) {
            New-Item -Path $targetPath -Force | Out-Null
        }
        Set-ItemProperty -Path $targetPath -Name 'DisallowExploitProtectionOverride' -Value 1 -Type DWord
        Write-Host "Set 'DisallowExploitProtectionOverride' to 1 at $targetPath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to set value 'DisallowExploitProtectionOverride'. Error: $_" -ForegroundColor Red
    }

    Write-Host "Registry key and value removal complete." -ForegroundColor Cyan
}

function Disable-Mitigation {
    # Disable Hypervisor
    bcdedit /set hypervisorlaunchtype off

    # Disabling Security Mitigations
    Write-Host "Disabling Security Mitigations..."
    Get-ChildItem "$PSScriptRoot\Remove_SecurityComp" -Recurse -Filter *.reg | ForEach-Object { 
        Start-Process "regedit.exe" -ArgumentList "/s $_.FullName" -Wait 
    }

    # Reboot the system
    Write-Host "Your PC will reboot in 10 seconds..."
    Start-Sleep -Seconds 3
    Restart-Computer -Force
}


function Disable-WebThreatDefense {
    Write-Output "Disabling WebThreatDefense and related services..."

    # Remove specific firewall rules
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" -Name "WebThreatDefSvc_Allow_In" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" -Name "WebThreatDefSvc_Allow_Out" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" -Name "WebThreatDefSvc_Block_In" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" -Name "WebThreatDefSvc_Block_Out" -ErrorAction SilentlyContinue

    # Remove Configurable firewall rules
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Configurable\System" -Name "{2A5FE97D-01A4-4A9C-8241-BB3755B65EE0}" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Configurable\System" -Name "72e33e44-dc4c-40c5-a688-a77b6e988c69" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Configurable\System" -Name "b23879b5-1ef3-45b7-8933-554a4303d2f3" -ErrorAction SilentlyContinue

    # Delete entire services and registry paths
    $pathsToDelete = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\PlutonHsp2",
        "HKLM:\SYSTEM\CurrentControlSet\Services\PlutonHeci",
        "HKLM:\SYSTEM\CurrentControlSet\Services\Hsp",
        "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\Server\WebThreatDefSvc",
        "HKLM:\SYSTEM\CurrentControlSet\Services\webthreatdefsvc",
        "HKLM:\SYSTEM\CurrentControlSet\Services\webthreatdefusersvc",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost\WebThreatDefense",
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS"
    )

    foreach ($path in $pathsToDelete) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Removed $path"
        }
    }

    # Remove value from Svchost
    try {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost" -Name "WebThreatDefense" -ErrorAction SilentlyContinue
        Write-Output "Removed WebThreatDefense from Svchost group."
    } catch {
        Write-Warning "Failed to remove WebThreatDefense value from Svchost."
    }

    # Set policy-related values to 0
    $policyPaths = @(
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\AuditMode",
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\NotifyUnsafeOrReusedPassword",
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\ServiceEnabled",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components"
    )

    foreach ($path in $policyPaths) {
        if (-not (Test-Path $path)) {
            New-Item -Path (Split-Path $path) -Name (Split-Path $path -Leaf) -Force | Out-Null
        }
    }

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\AuditMode" -Name "value" -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\NotifyUnsafeOrReusedPassword" -Name "value" -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\ServiceEnabled" -Name "value" -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components" -Name "NotifyPasswordReuse" -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components" -Name "NotifyMalicious" -Value 0 -Force

    Write-Output "WebThreatDefense successfully disabled."
}


function Disable-SmartScreen {
    Write-Host "Disabling SmartScreen settings..."

    # Disable SmartScreen for Microsoft Edge
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" -Name "EnabledV9" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" -Name "PreventOverride" -Value 0 -Type DWord -Force

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Edge" -Name "SmartScreenEnabled" -Value 0 -Type DWord -Force
    New-Item -Path "HKCU:\Software\Microsoft\Edge\SmartScreenEnabled" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Edge\SmartScreenEnabled" -Name "(default)" -Value 0 -Type DWord

    # Disable SmartScreen in File Explorer and Windows Shell
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "off" -Type String -Force

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -Force
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "ShellSmartScreenLevel" -ErrorAction SilentlyContinue

    # PolicyManager changes
    $policyPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default"
    New-Item -Path "$policyPath\Browser\AllowSmartScreen" -Force | Out-Null
    Set-ItemProperty -Path "$policyPath\Browser\AllowSmartScreen" -Name "value" -Value 0 -Type DWord -Force

    New-Item -Path "$policyPath\SmartScreen\EnableSmartScreenInShell" -Force | Out-Null
    Set-ItemProperty -Path "$policyPath\SmartScreen\EnableSmartScreenInShell" -Name "value" -Value 0 -Type DWord -Force

    New-Item -Path "$policyPath\SmartScreen\EnableAppInstallControl" -Force | Out-Null
    Set-ItemProperty -Path "$policyPath\SmartScreen\EnableAppInstallControl" -Name "value" -Value 0 -Type DWord -Force

    New-Item -Path "$policyPath\SmartScreen\PreventOverrideForFilesInShell" -Force | Out-Null
    Set-ItemProperty -Path "$policyPath\SmartScreen\PreventOverrideForFilesInShell" -Name "value" -Value 0 -Type DWord -Force

    # Disable SmartScreen for Microsoft Store Apps
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" -Name "PreventOverride" -Value 0 -Type DWord -Force

    # Configure App Install Control
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -Name "ConfigureAppInstallControlEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -Name "ConfigureAppInstallControl" -Value "Anywhere" -Type String -Force

    Write-Host "SmartScreen has been disabled successfully."
}


function Disable-SystemMitigations {
    Write-Output "Disabling system mitigations and SmartScreen..."

    # Helper function
    function Set-RegValue {
        param($Path, $Name, $Type, $Value)
        if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force
    }

    function Remove-RegKey {
        param($Path)
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Disable Driver Blocklist
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" "VulnerableDriverBlocklistEnable" DWord 0

    # Disable RunAsPPL
    Set-RegValue "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "RunAsPPL" DWord 0
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "LsaConfigFlags" DWord 0
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPL" DWord 0
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPLBoot" DWord 0

    # UserPreference
    Set-RegValue "HKLM\SOFTWARE\Microsoft\WindowsMitigation" "UserPreference" DWord 2

    # Kernel mitigations
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationAuditOptions" Binary ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x22,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationOptions" Binary ([byte[]](0x00,0x22,0x22,0x20,0x22,0x20,0x22,0x22,0x20,0x00,0x00,0x00,0x00,0x20,0x00,0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "KernelSEHOPEnabled" DWord 0

    # Disable Spectre/Meltdown mitigations
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettings" DWord 1
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" DWord 3
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" DWord 3

    # Disable svchost mitigation
    Set-RegValue "HKLM\SYSTEM\CurrentControlSet\Control\SCMConfig" "EnableSvchostMitigationPolicy" Binary ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))

    # Windows Defender Features
    Set-RegValue "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" "MpPlatformKillbitsFromEngine" Binary ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    Set-RegValue "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" "TamperProtectionSource" DWord 0
    Set-RegValue "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" "MpCapability" Binary ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    Set-RegValue "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" "TamperProtection" DWord 0

    # Exploit Guard
    Set-RegValue "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access" "EnableControlledFolderAccess" DWord 0
    Remove-ItemProperty -Path "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" -Name "EnableNetworkProtection" -ErrorAction SilentlyContinue
    Set-RegValue "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR" "ExploitGuard_ASR_Rules" DWord 0
    Set-RegValue "HKLM\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR" "EnableASRConsumers" DWord 0

    # MpGears settings
    Set-RegValue "HKLM\SOFTWARE\Microsoft\RemovalTools\MpGears" "HeartbeatTrackingIndex" DWord 0
    Set-RegValue "HKLM\SOFTWARE\Microsoft\RemovalTools\MpGears" "SpyNetReportingLocation" String "0"

    # Fault Tolerant Heap
    Set-RegValue "HKLM\SOFTWARE\Microsoft\FTH" "Enabled" DWord 0
    Set-RegValue "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" "DisableAsyncScanOnOpen" Dword 1

    # Security Health reporting
    Remove-RegKey "HKLM\SOFTWARE\Microsoft\Windows Security Health"
    Remove-RegKey "HKCU\Software\Microsoft\Windows Security Health"
    Set-RegValue "HKCU\Software\Microsoft\Windows Security Health\State" "Disabled" DWord 1
    Set-RegValue "HKLM\SOFTWARE\Microsoft\Windows Security Health\Platform" "Registered" DWord 0

    # Remove specific CLSID keys
    $clsid = "{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}"
    $keysToDelete = @(
        "HKCR\CLSID\$clsid",
        "HKCR\WOW6432Node\CLSID\$clsid",
        "HKLM\SOFTWARE\Classes\CLSID\$clsid",
        "HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\$clsid",
        "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\$clsid",
        "HKLM\SOFTWARE\WOW6432Node\Classes\CLSID\$clsid",
        "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\$clsid"
    )

    foreach ($key in $keysToDelete) {
        Remove-RegKey $key
    }

    Write-Output "System mitigations disabled successfully."
}


function Remove-Defender {
    RunAsTI $args[0] $args[1..11]

    # Reboot the system
    Write-Host "Your PC will reboot in 10 seconds..."
    Start-Sleep -Seconds 3
    Restart-Computer -Force
}


function Remove-FilesAndFolders {
    Write-Output "Removing Windows Defender-related files and directories..."

    # File patterns to delete
    $filesToDelete = @(
        "C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest",
        "C:\Windows\System32\*SecurityHealth*",
        "C:\Windows\System32\drivers\*Wd*",
        "C:\Windows\System32\smartscreen.dll",
        "C:\Windows\System32\wscsvc.dll",
        "C:\Windows\System32\wscproxystub.dll",
        "C:\Windows\SysWOW64\*smartscreen*",
        "C:\Windows\System32\drivers\msseccore.sys"
    )

    foreach ($file in $filesToDelete) {
        Get-ChildItem -Path $file -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Directories to delete
    $dirsToDelete = @(
        "C:\ProgramData\Microsoft\Windows Defender",
        "C:\Program Files\Windows Defender",
        "C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender",
        "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender"
    )

    foreach ($dir in $dirsToDelete) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Output "Removal of Defender components completed."
}


function Remove-Antivirus {
    # Disable Hypervisor
    bcdedit /set hypervisorlaunchtype off
    RunAsTI $args[0] $args[1..10]
    # Reboot the system
    Write-Host "Your PC will reboot in 10 seconds..."
    Start-Sleep -Seconds 3
    Restart-Computer -Force
}


write-host args: $args
Set-WindowsDefenderPolicies
Disable-WindowsSecurityNotifications
Remove-WindowsDefenderTraces
Set-DefenderSettings
Remove-Defenderq
Disable-WebThreatDefense
Disable-Mitigation
Disable-WebThreatDefense
Disable-SmartScreen
Remove-FilesAndFolders
Disable-SystemMitigations
