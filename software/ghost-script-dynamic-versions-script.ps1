<#
    Name = "GhostScript (Lite) Dynamic Versions Script"
    Type: "Dynamic Versions"
    Execution Context: "Cloud Script"
    Language: "PowerShell"
    Override Timeout: "false"
    Access Level: "All"

#>


$URL = 'https://www.plotsoft.com/download/GS_Lite.msi'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response