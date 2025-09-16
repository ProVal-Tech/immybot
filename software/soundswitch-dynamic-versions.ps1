$apiUri = 'https://api.github.com/repositories'
$repoId = '197275551'
$what = 'contents'
$where = 'manifests'
$finalDirectory = 'a/AntoineAflalo/SoundSwitch'

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

$installerUri = 'https://github.com/Belphemur/SoundSwitch/releases/download/v{0}/SoundSwitch_v{0}.0_Release_Installer.exe' -f $maxVersion
$fileName = 'SoundSwitch_v{0}.0_Release_Installer.exe' -f $maxVersion

$Response.Versions | ForEach-Object {
    $_.FileName = $fileName
    $_.Url = $installerUri
}

return $Response