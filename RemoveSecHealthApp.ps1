$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$sids = @('S-1-5-18') # https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
if (Test-Path $store) { $sids += Get-ChildItem $store -ea 0 | %{ $_.PSChildName } | ?{ $_.StartsWith('S-1-5-21') } }

if ((Get-CimInstance -Class Win32_OperatingSystem).Caption -Match "Windows 11") { 
	$name = "Microsoft.SecHealthUI" 
} else { 
	$name = "Microsoft.Windows.SecHealthUI" 
}
$appx = Get-AppxPackage -AllUsers -Name $name
if ($null -eq $appx) { return Write-Host "WindowsDefender Appx Package not found." -ForegroundColor Red }
New-Item "$store\Deprovisioned\$($appx.PackageFamilyName)" -Force | Out-Null
foreach ($sid in $sids) { New-Item "$store\EndOfLife\$sid\$($appx.PackageFullName)" -Force | Out-Null }

DISM /Online /Set-NonRemovableAppPolicy /PackageFamily:$appx.PackageFamilyName /NonRemovable:0 | Out-Null
$appx | Remove-AppxPackage -AllUsers
