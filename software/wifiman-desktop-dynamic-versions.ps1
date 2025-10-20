$URL = 'https://desktop.wifiman.com/wifiman-desktop-1.1.3-amd64.exe'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response