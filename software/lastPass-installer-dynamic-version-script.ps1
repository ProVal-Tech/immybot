$URL = 'https://download.cloud.lastpass.com/windows_installer/LastPassInstaller.msi'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response