<#
Script Details:
    Name = Inbox Custom Detection Script
    Type = Software Detection
    Execution Context = User
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
(Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -Match '^Inbox' } ).DisplayVersion