<#
Script Details:
    Name = Inbox Installation Script
    Type = Software Version Action
    Execution Context = System
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>

#region globals
$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'
$InformationPreference = 'Continue'
$WarningPreference = 'SilentlyContinue'
#endRegion

#region variables
$appName = 'Inbox'
$workingDirectory = '{0}\_Automation\App\{1}' -f $env:ProgramData, $appName
$appPath = '{0}\{1}.exe' -f $workingDirectory, $appName
$arguments = '/S'
$taskName = '{0}_Install' -f $appName
#endRegion

#region working directory
if (-not (Test-Path -Path $workingDirectory)) {
    try {
        New-Item -Path $workingDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    } catch {
        throw ('Failure: Failed to Create working directory {0}. Reason: {1}' -f $workingDirectory, $Error[0].Exception.Message)
    }
}

$acl = Get-Acl -Path $workingDirectory
$hasFullControl = $acl.Access | Where-Object {
    $_.IdentityReference -match 'Everyone' -and $_.FileSystemRights -match 'FullControl'
}
if (-not $hasFullControl) {
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule(
        'Everyone', 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    )
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $workingDirectory -AclObject $acl -ErrorAction SilentlyContinue
}
#endRegion

#region copy installer file
try {
    Copy-Item -Path $InstallerFile -Destination $appPath -Force -ErrorAction Stop
} catch {
    throw ('Failure: Failed to copy installer file to working directory. Reason: {0}' -f $Error[0].Exception.Message)
}
#endRegion

#region initiate installation from scheduled task
try {
    Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName } | Unregister-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
    $action = New-ScheduledTaskAction -Execute $appPath -WorkingDirectory $WorkingDirectory -Argument $arguments -ErrorAction Stop
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5) -ErrorAction Stop
    $setting = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ErrorAction Stop
    $principal = New-ScheduledTaskPrincipal -GroupId ((New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')).Translate([System.Security.Principal.NTAccount]).Value) -RunLevel Highest -ErrorAction Stop
    $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting -Principal $principal -ErrorAction Stop
    Register-ScheduledTask -TaskName $taskName -InputObject $scheduledTask -ErrorAction Stop | Out-Null
    Write-Information ('Scheduled Task {0} created successfully.' -f $taskName)
} catch {
    throw ('Failure: Failed to create scheduled task for installation. Reason: {0}' -f $Error[0].Exception.Message)
}
#endRegion

#region confirm scheduled task execution
Start-Sleep -Seconds 7
$taskRunTime = (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue).LastRunTime
if ($taskRunTime) {
    Write-Information ('Task Initiated at: {0}' -f $taskRunTime)
} else {
    Write-Information 'Initiating the task'
    Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 30
Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName } | Unregister-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
#endRegion
