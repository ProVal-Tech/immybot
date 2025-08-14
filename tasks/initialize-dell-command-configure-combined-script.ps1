<#
.SYNOPSIS
    Automates installation, update, and execution of Dell Command | Configure (DCC) on Dell workstations, ensuring the latest version is present and providing command-line automation for DCC operations for Dell workstations BIOS configurations.

.DESCRIPTION
    This script is designed to be used within an ImmyBot task to automate the configuration of Dell Command | Configure on Windows systems.
    It provides a combined interface for testing, setting, and verifying Dell BIOS/UEFI settings using Dell Command | Configure's command-line utility (cctk.exe).
    The script expects the user to be familiar with Dell Command | Configure command-line arguments and usage.

.PARAMETER TestArgument
    The command-line argument(s) to pass to Dell Command | Configure for checking the current status of a required configuration.

.PARAMETER ExpectedResult
    The expected output/result from Dell Command | Configure when the configuration is correct.

.PARAMETER SetArgument
    The command-line argument(s) to pass to Dell Command | Configure to set the required configuration.

.EXAMPLE
    $TestArgument "--SecureBoot"   -- Argument to check the current status of Secure Boot
    $ExpectedResult "SecureBoot=Enabled"  -- Expected result when Secure Boot is enabled
    $SetArgument "--SecureBoot=Enabled"  -- Argument to set Secure Boot to enabled

    This example checks if Secure Boot is enabled and sets it if necessary.

.EXAMPLE
    $TestArgument "--PowerWarn"   -- Argument to check the current status of Power Warning
    $ExpectedResult "PowerWarn=Disabled"  -- Expected result when Power Warning is disabled
    $SetArgument "--PowerWarn=Disabled"  -- Argument to set Power Warning to disabled

    This example checks if PowerWarning is disabled and sets it if necessary.

.EXAMPLE
    $TestArgument "--WakeOnLan"   -- Argument to check the current status of Wake On LAN
    $ExpectedResult "WakeOnLan=LanWlan"  -- Expected result when Wake On LAN is enabled
    $SetArgument "--WakeOnLan=LanWlan"  -- Argument to set Wake On LAN configuration to enables wake on either wired or wireless LAN.

    This example checks if Wake On LAN is enabled and sets it if necessary.

.LINK
    Dell Command | Configure CLI Reference:
    - https://www.dell.com/support/manuals/en-us/command-configure-v4.2/dcc_cli_4.2/general-options?guid=guid-70b4993d-58d3-48ef-a8db-ae7feb6e01ae&lang=en-us
    - https://www.dell.com/support/manuals/en-us/command-configure-v4.2/dcc_cli_4.2/bios-options?guid=guid-44c059be-b76d-4b2f-b8ef-655f736c40ce&lang=en-us

    Dell Command | Configure Command Line Syntax:
    https://www.dell.com/support/manuals/en-us/command-configure-v4.2/dcc_cli_4.2/command-line-option-delimiter?guid=guid-a46d5033-22cc-4369-8951-d1b30e51008f

.NOTES
    Name: initialize-dell-command-configure-combined-script
    Type: Task
    Execution Context: Metascript
    Language: PowerShell
    Timeout: 7200
    Override timeout: Yes
    Access Level: All
#>
#region Parameters
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = 'The arguments to provide to Dell Command | Configure to check the current status of the required configuration.')]
    [string]$TestArgument,
    [Parameter(Mandatory = $true, HelpMessage = 'The expected result of the test.')]
    [string]$ExpectedResult,
    [Parameter(Mandatory = $true, HelpMessage = 'The argument to provide to Dell Command | Configure to set the configuration.')]
    [string]$SetArgument
)
#endRegion

#region Convert Parameters to Variables
$testArg = $TestArgument
$expected = $ExpectedResult
$setArg = $SetArgument
#endRegion

#region Variables
$potentialPath = @(
    'C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe',
    'C:\Program Files\Dell\Command Configure\X86_64\cctk.exe',
    'C:\Program Files\Dell\Command Configure\X86\cctk.exe',
    'C:\Program Files (x86)\Dell\Command Configure\X86\cctk.exe'
)
#endRegion

#region ImmyBot Method Switch
switch ($Method) {
    'Get' {
        Invoke-ImmyCommand -ScriptBlock {
            foreach ($path in $using:potentialPath) {
                if (Test-Path -Path $path) {
                    $exePath = $path
                    break
                }
                if ($exePath) {
                    return $exePath
                }
            }
        }
    }
    'Test' {
        Invoke-ImmyCommand -ScriptBlock {
            foreach ($path in $using:potentialPath) {
                if (Test-Path -Path $path) {
                    $exePath = $path
                    break
                }
            }

            if (!$exePath) {
                return $false
            } else {
                $outCome = & $exePath $using:testArg
                if ($outCome -notmatch [regex]::escape($using:expected)) {
                    return $false
                } else {
                    return $true
                }
            }
        }
    }
    'Set' {
        Invoke-ImmyCommand -ScriptBlock {
            #region Variables
            $projectName = 'Initialize-DellCommandConfigure'
            $workingDirectory = '{0}\_Automation\Script\{1}' -f $env:ProgramData, $projectName
            $scriptPath = '{0}\{1}.ps1' -f $workingDirectory, $projectName
            $logPath = '{0}\{1}-log.txt' -f $workingDirectory, $projectName
            $errorLogPath = '{0}\{1}-error.txt' -f $workingDirectory, $projectName
            $baseUrl = 'https://file.provaltech.com/repo'
            $scriptUrl = '{0}/script/{1}.ps1' -f $baseUrl, $projectName
            #endRegion

            #region working Directory
            if (!(Test-Path -Path $workingDirectory)) {
                try {
                    New-Item -Path $workingDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
                } catch {
                    throw ('Failed to Create {0}. Reason: {1}' -f $workingDirectory, $($Error[0].Exception.Message))
                }
            }
            #endRegion

            #region Download Script
            try {
                Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop
            } catch {
                if (!(Test-Path -Path $scriptPath)) {
                    throw ('Failed to download the script from ''{0}'', and no local copy of the script exists on the machine. Reason: {1}' -f $scriptUrl, $($Error[0].Exception.Message))
                }
            }
            #endRegion

            #region Execute script
            if ($using:setArg) {
                & $scriptPath -Argument $using:setArg
            } else {
                & $scriptPath
            }
            #endRegion

            #region Log verification
            if (!(Test-Path -Path $logPath )) {
                throw ('Failed to run the agnostic script ''{0}''. A security application seems to have interrupted the installation.' -f $scriptPath)
            } else {
                $content = Get-Content -Path $logPath
                $logContent = $content[ $($($content.IndexOf($($content -match "$($ProjectName)$")[-1])) + 1)..$($Content.length - 1) ]
                Write-Information ('Log Content: {0}' -f ($logContent | Out-String)) -InformationAction Continue
            }

            if ((Test-Path -Path $errorLogPath)) {
                $errorLogContent = Get-Content -Path $errorLogPath -ErrorAction SilentlyContinue
                throw ('Error log Content: {0}' -f ($errorLogContent | Out-String -ErrorAction SilentlyContinue))
            }
            #endRegion
        }
    }
}