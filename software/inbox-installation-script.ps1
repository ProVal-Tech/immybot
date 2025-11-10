<#
Script Details:
    Name = Inbox Installation Script
    Type = Software Version Action
    Execution Context = User
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
$Arguments = @"
/S
"@
$Process = Start-Process -Wait $InstallerFile -ArgumentList $Arguments -Passthru
Write-Host "ExitCode: $($Process.ExitCode)"