<#
    Name: johnson-controls-launcher-dynamic-versions-script
    Type: Dynamic Versions
    Execution Context: Cloud Script
    Language: PowerShell
    Override Timeout: false
    Access Level: All
#>

$ProgressPreference = 'SilentlyContinue'
$downloadUrl = 'https://www.johnsoncontrols.com/-/media/project/jci-global/johnson-controls/us-region/united-states-johnson-controls/building-automation-and-controls/metasys-launcher/launcher-windows.msi'
$webUrl = 'https://www.johnsoncontrols.com/building-automation-and-controls/metasys-launcher'
$iwr = Invoke-WebRequest -Uri $webUrl -UseBasicParsing
$string = $($iwr.rawcontent -split '>|<') -match 'Current Release'
$pattern = '(\d{1,}\.){1,}\d{1,}'
$maxVersion = ([regex]::matches($string, $pattern)).Value
$version = New-DynamicVersion -Version $maxVersion

$Response = New-Object PSObject -Property @{
    Versions = @($version)
}

$Response.Versions | ForEach-Object {
    $_.FileName = 'Launcher-Windows.msi'
    $_.Url = $downloadUrl
}

return $Response