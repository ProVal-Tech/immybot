<#
Script Details:
    Name = Inbox Dynamic Version Script
    Type = Dynamic Versions
    Execution Context = Cloud Script
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
$URL = 'https://inbox.chatgenie.io/downloads/desktop/inbox.exe'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response