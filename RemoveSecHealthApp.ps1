$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$sids = @('S-1-5-18') # https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
if (Test-Path $store) { $sids += Get-ChildItem $store -ea 0 | %{ $_.PSChildName } | ?{ $_.StartsWith('S-1-5-21') } }

$appx = Get-AppxPackage -AllUsers -Name "Microsoft.Windows.SecHealthUI"
if ($null -eq $appx) { return }
New-Item "$store\Deprovisioned\$($appx.PackageFamilyName)" -Force | Out-Null
foreach ($sid in $sids) { New-Item "$store\EndOfLife\$sid\$($appx.PackageFullName)" -Force | Out-Null }

DISM /Online /Set-NonRemovableAppPolicy /PackageFamily:$appx.PackageFamilyName /NonRemovable:0 | Out-Null
Remove-AppxPackage -AllUsers -Package $appx.PackageFullName | Out-Null
