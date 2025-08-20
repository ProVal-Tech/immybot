$URL = 'https://www.plotsoft.com/download/PDFill_FREE_PDF_Editor_Basic.msi'
$Result = Get-DynamicVersionFromInstallerURL $URL
$Response = New-Object PSObject -Property @{
    Versions = @(New-DynamicVersion -URL $URL -Version $Result.Versions.Version)
}
return $Response