<#
Script Details:
    Name = intel-driver-and-support-assistant-dynamic-version
    Type = Dynamic Version
    Execution Context = Cloud Script
    Language = PowerShell
    Override timeout = false
    Access Level = All
#>
$installerUri = 'https://dsadata.intel.com/installer'
$apiUri = 'https://api.github.com/repositories'
$repoId = '197275551'
$what = 'contents'
$where = 'manifests'
$finalDirectory = 'i/Intel/IntelDriverAndSupportAssistant'

$maxVersionUri = '{0}/{1}/{2}/{3}/{4}' -f $apiUri, $repoId, $what, $where, $finalDirectory

$maxVersion = (
    (Invoke-RestMethod -Method Get -Uri $maxVersionUri) | `
            Select-Object @{n = 'Version'; e = { [version]$_.name } } | `
            Sort-Object Version -Descending | `
            Select-Object -First 1 -ExpandProperty Version
).ToString()

$version = New-DynamicVersion -Version $maxVersion

$Response = New-Object PSObject -Property @{
    Versions = @($version)
}

$Response.Versions | ForEach-Object {
    $_.FileName = 'Intel-Driver-and-Support-Assistant-Installer.exe'
    $_.Url = $installerUri
}

return $Response