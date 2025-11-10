<#
Script Details:
    Name = Inbox Uninstallation Script
    Type = Software Version Action
    Execution Context = User
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
$quninstallString = (Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -Match '^Inbox' } ).QuietUninstallString
cmd.exe /c $quninstallString
Start-Sleep -Seconds 5