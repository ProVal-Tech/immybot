$URL = 'https://download01.logi.com/web/ftp/pub/techsupport/gaming/lghub_installer.exe'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response