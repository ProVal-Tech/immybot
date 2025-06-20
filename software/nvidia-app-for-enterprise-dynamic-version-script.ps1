<#
    Name: nvidia-app-for-enterprise-dynamic-version
    Type: Dynamic Version
    Execution Context: Cloud Script
    Language: PowerShell
    Override timeout: No
    Access Level: All
#>
#region Globals
$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'
#endRegion

#region Variables
$websiteUrl = 'https://www.nvidia.com/en-us/software/nvidia-app-enterprise/'
$downloadUrlPattern = 'https:\/\/us\.download\.nvidia\.com\/nvapp\/client\/[\d\.]+\/NVIDIA_app_v[\d\.]+\.exe'
$versionPattern = '(\d+\.?)+'
#endRegion

#region Download Url
$iwr = Invoke-WebRequest -Uri $websiteUrl -UseBasicParsing
$downloadUrl = ([regex]::Matches($iwr.Content, $downloadUrlPattern)).Value | Select-Object -First 1
#endRegion

#region Version
$maxVersion = (([regex]::Matches($downloadUrl, $versionPattern)).Value | Select-Object -First 1).ToString()
$version = New-DynamicVersion -Version $maxVersion
#endRegion

#region File Name
$fileName = 'NVIDIA_app_v{0}.exe' -f $maxVersion
#endRegion

#region Response
$Response = New-Object PSObject -Property @{
    Versions = @($version)
}

$Response.Versions | ForEach-Object {
    $_.FileName = $fileName
    $_.Url = $downloadUrl
}

return $Response
#endRegion