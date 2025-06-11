<#
    Name: johnson-controls-launcher-installation-script
    Type: Software Version Action
    Execution Context: System
    Language: PowerShell
    Override Timeout: false
    Access Level: All
#>

$argumentList = @(
    '/i',
    "$InstallerFile",
    '/qn',
    '/norestart'
)

$proc = Start-Process Msiexec -ArgumentList $ArgumentList -NoNewWindow -PassThru -Wait
return 'Process Exit Code: {0}' -f $proc.ExitCode