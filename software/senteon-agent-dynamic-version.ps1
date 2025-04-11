$URL = 'https://update.senteon.co/installers/SenteonAgent.msi'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response