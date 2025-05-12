<#
Script Details:
    Name = intel-driver-and-support-assistant-install
    Type = Software Version Action
    Execution Context = System
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>

try {
	$Process = Start-Process -Wait $InstallerFile -ArgumentList '/silent' -PassThru -ErrorAction Stop
} catch {
	throw ('Error: Failed to initiate the installer. Exit Code: {0}' -f $Process.ExitCode)
}