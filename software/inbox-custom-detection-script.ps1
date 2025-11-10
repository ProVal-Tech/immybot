<#
Script Details:
    Name = Inbox Custom Detection Script
    Type = Software Detection
    Execution Context = User
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
(Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\dfc9f961-94d9-5e1d-9a8e-e1c16464d416' -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion