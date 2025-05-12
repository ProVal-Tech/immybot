<#
Script Details:
    Name = intel-driver-and-support-assistant-uninstall
    Type = Software Version Action
    Execution Context = System
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
$uninstallPaths = @(
	'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
	'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$quietUninstallString = (Get-ChildItem -Path $uninstallPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match 'Intel\S Driver & Support Assistant' }).QuietUninstallString
cmd.exe /c $quietUninstallString