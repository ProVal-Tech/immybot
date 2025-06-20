<#
    Name: nvidia-app-for-enterprise-installation-script
    Type: Software Version Action
    Execution System
    Language: PowerShell
    Override timeout: No
    Access Level: All
#>
if (Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" -or $_.VideoProcessor -like "*NVIDIA*" }) {
    #region Variables
    $argumentList = @(
        '-s',
        '-noreboot',
        '-noeula',
        '-nofinish',
        '-nosplash'
    )
    #endRegion

    #region Installation
    Start-Process -FilePath $InstallerFile -ArgumentList $argumentList -NoNewWindow -Wait
    #endRegion
} else {
    throw 'The NVIDIA App can only be installed on machines equipped with an NVIDIA GPU.'
}