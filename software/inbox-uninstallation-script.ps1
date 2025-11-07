<#
Script Details:
    Name = inbox-uninstallation-script
    Type = Software Version Action
    Execution Context = User
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
$quninstallString = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\dfc9f961-94d9-5e1d-9a8e-e1c16464d416' -Name QuietUninstallString -ErrorAction SilentlyContinue).QuietUninstallString
cmd.exe /c $quninstallString
Start-Sleep -Seconds 5