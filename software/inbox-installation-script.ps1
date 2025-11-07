<#
Script Details:
    Name = inbox-installation-script
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