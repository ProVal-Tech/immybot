<#
    Name: install-windows-11-feature-update-combined-script
    Type: Task
    Execution Context: Metascript
    Language: PowerShell
    Timeout: 7200
    Override timeout: Yes
    Access Level: All
#>
Switch ($Method) {
    'Get' {
        Invoke-ImmyCommand -ScriptBlock {
            (Get-CimInstance -ClassName Win32_OperatingSystem).Version
        }
    }
    'Test' {
        Invoke-ImmyCommand -ScriptBlock {
            #region Variables
            $osVersionCheckUrl = 'https://content.provaltech.com/attachments/windows-os-support.json'
            #endRegion
            #region Test
            try {
                $iwr = Invoke-WebRequest -Uri $osVersionCheckUrl -UseBasicParsing -ErrorAction Stop
                $json = $iwr.content -replace "$([char]0x201C)|$([char]0x201D)", '"' -replace "$([char]0x2018)|$([char]0x2019)", '''' -replace '&#x2014;', ' ' -replace '&nbsp;', ''
                $rows = ($json | ConvertFrom-Json).rows
                $osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
                $latestVersion = $rows | Where-Object { $_.BaseOS -eq 'Windows 11' -and [Version]$_.Build -gt [Version]$osVersion } | Sort-Object -Property Build -Descending | Select-Object -First 1
                if (!$latestVersion) {
                    return $true
                } else {
                    return $false
                }
            } catch {
                return $false
            }
            #endRegion
        }
    }
    'Set' {
        Invoke-ImmyCommand -ScriptBlock {
            #region Globals
            $ProgressPreference = 'SilentlyContinue'
            $ConfirmPreference = 'None'
            [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
            #endRegion
            #region Initial Verification
            if ((Get-CimInstance -ClassName win32_battery).BatteryStatus -eq 1) {
                throw 'The Computer battery is not charging please plug in the charger.'
                exit 1
            }
            if ([System.Environment]::OSVersion.Version.Major -ne 10) {
                throw 'Unsupported Operating System. The script is designed to work for Windows 10 and Windows 11.'
                exit 1
            }
            #endRegion

            #region Variables
            $projectName = 'Install-Windows11FeatureUpdate'
            $workingDirectory = '{0}\_automation\script\{1}' -f $env:ProgramData, $projectName
            $baseUrl = 'https://file.provaltech.com/repo'
            $ps1Url = '{0}/script/{1}.ps1' -f $baseUrl, $projectName
            $ps1Path = '{0}\{1}.ps1' -f $workingDirectory, $projectName
            $taskName = 'Initiate - {0}' -f $projectName
            $compatibilityCheckScriptDownloadUrl = 'https://download.microsoft.com/download/e/1/e/e1e682c2-a2ee-46c7-ad1e-d0e38714a795/HardwareReadiness.ps1'
            $compatibilityCheckScriptPath = '{0}\HardwareReadiness.ps1' -f $workingDirectory
            #endRegion

            #region Working Directory
            Remove-Item -Path $workingDirectory -Force -Cofirm:$false -ErrorAction SilentlyContinue
            if ( !(Test-Path -Path $workingDirectory) ) {
                try {
                    New-Item -Path $workingDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
                } catch {
                    throw 'Failed to Create ''{0}''. Reason: {1}' -f $workingDirectory, $($Error[0].Exception.Message)
                    exit 1
                }
            }

            if (-not ((( Get-Acl -Path $workingDirectory).Access | Where-Object { $_.IdentityReference -Match 'EveryOne' }).FileSystemRights -Match 'FullControl')) {
                $Acl = Get-Acl -Path $workingDirectory
                $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone', 'FullControl', 'ContainerInherit, ObjectInherit', 'none', 'Allow')
                $Acl.AddAccessRule($AccessRule)
                Set-Acl -Path $workingDirectory -AclObject $Acl
            }
            #endRegion

            #region Drive Space Check
            $systemVolume = Get-Volume -DriveLetter $env:SystemDrive[0]
            if ($systemVolume.SizeRemaining -le 64GB) {
                throw @"
Error: The Drive Space health check failed. The drive must have 64GB of free space to perform a Feature Update.
Current available space on $($env:SystemDrive[0]): $([math]::round($systemVolume.SizeRemaining / 1GB, 2))
For more information: https://learn.microsoft.com/en-us/troubleshoot/windows-client/deployment/windows-10-upgrade-quick-fixes?toc=%2Fwindows%2Fdeployment%2Ftoc.json&bc=%2Fwindows%2Fdeployment%2Fbreadcrumb%2Ftoc.json#verify-disk-space
"@
            }
            #endRegion

            #region Compatibility Check
            try {
                Invoke-WebRequest -Uri $compatibilityCheckScriptDownloadUrl -OutFile $compatibilityCheckScriptPath -UseBasicParsing -ErrorAction Stop
            } catch {
                throw 'Failed to download the compatibility check script from ''{0}''. Reason: {1}' -f $compatibilityCheckScriptDownloadUrl, $($Error[0].Exception.Message)
                exit 1
            }
            Unblock-File -Path $compatibilityCheckScriptPath -ErrorAction SilentlyContinue

            $compatibilityCheck = & $compatibilityCheckScriptPath
            $obj = $compatibilityCheck[1] | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($obj.returnResult -ne 'CAPABLE' -or $compatibilityCheck -match 'NOT CAPABLE') {
                throw @"
$Env:ComputerName is incompatible with windows 11 upgrade.
Result returned by Compatibility check script:
$compatibilityCheck
Minimum system requirements: https://www.microsoft.com/en-in/windows/windows-11-specifications
"@
                exit 1
            }
            #endRegion

            #region Download
            try {
                Invoke-WebRequest -Uri $ps1Url -OutFile $ps1Path -UseBasicParsing -ErrorAction Stop
            } catch {
                throw 'Failed to download the installer from ''{0}''. Reason: {1}' -f $ps1Url, $($Error[0].Exception.Message)
                exit 1
            }
            #endRegion

            #region Scheduled Task
            (Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }) | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            try {
                $action = New-ScheduledTaskAction -Execute 'cmd.exe'-WorkingDirectory $workingDirectory -Argument  ('/c start /min "" Powershell' + ' -NoLogo -ExecutionPolicy Bypass -NoProfile -NonInteractive -Windowstyle Hidden' + " -File ""$($ps1Path)""")
                $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(15)
                $setting = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
                $principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -RunLevel Highest
                $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting -Principal $principal
                Register-ScheduledTask -TaskName $TaskName -InputObject $ScheduledTask -ErrorAction Stop | Out-Null
                return ('Task to run the primary script ''{1}'' has been scheduled. Detailed logs can be found at ''{0}''' -f $workingDirectory, $taskName)
            } catch {
                throw ('Failed to Schedule the task. Reason: {0}' -f ($Error[0].Exception.Message))
                exit 1
            }
            #endRegion
        }
    }
}
