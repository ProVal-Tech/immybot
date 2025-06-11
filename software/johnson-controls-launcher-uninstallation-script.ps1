<#
    Name: johnson-controls-launcher-uninstallation-script
    Type: Software Version Action
    Execution Context: System
    Language: PowerShell
    Override Timeout: false
    Access Level: All
#>

#region Variable
$softwareName = 'Johnson Controls - Launcher'
#endRegion
#region Functions
function Get-ProductId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][String]$SoftwareName
    )
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $uninstallInfo = Get-ChildItem $uninstallPaths -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -match [Regex]::Escape($SoftwareName) }
    if ($uninstallInfo) {
        return $uninstallInfo.PSChildName
    } else {
        return $null
    }
}

Function Uninstall-Software {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][String]$ProductId
    )
    $argumentList = @(
        '/x',
        $ProductId,
        '/quiet',
        '/norestart'
    )
    $UninstallProcess = Start-Process 'msiexec.exe' -ArgumentList $argumentList -Wait -PassThru
    Start-Sleep -Seconds 5
    return $UninstallProcess
}
#endRegion
#region Uninstall Software
foreach ($software in $softwareName) {
    $productId = Get-ProductId -SoftwareName $software
    if ($productId) {
        $uninstallProcessInfo = Uninstall-Software -ProductId $productId
        if (!(Get-ProductId -SoftwareName $software)) {
            Write-Output ('{0} uninstalled successfully.' -f $software)
        } else {
            throw ('{0} uninstall failed. Uninstallation Process Exit Code: ''{1}''' -f $software, $uninstallProcessInfo.ExitCode)
        }
    } else {
        Write-Output ('{0} is not installed.' -f $software)
    }
}
#endRegion