$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$regPathRtp = "$regPath\Real-Time Protection"
switch ($Method)
{
    "test" {
        Invoke-ImmyCommand {
            $MpPreference = Get-MpPreference -ErrorAction SilentlyContinue
            if (($MpPreference.DisableRealtimeMonitoring -eq $true) -or ($MpPreference.DisableIOAVProtection -eq $true)) {
                return $false
            } else {
                return $true
            }
        }
        Get-WindowsRegistryValue -Path $regPathRtp -Name "DisableBehaviorMonitoring" | RegistryShould-Be -Type DWord -Value 0
        Get-WindowsRegistryValue -Path $regPathRtp -Name "DisableOnAccessProtection" | RegistryShould-Be -Type DWord -Value 0
        Get-WindowsRegistryValue -Path $regPathRtp -Name "DisableScanOnRealtimeEnable" | RegistryShould-Be -Type DWord -Value 0
        Get-WindowsRegistryValue -Path $regPath -Name "DisableAntiSpyware" | RegistryShould-Be -Type DWord -Value 0
    }
    "set" {
        Invoke-ImmyCommand {
            function Enable-WindowsDefender {
                <#
                .SYNOPSIS
                Enables various Windows Defender features and services.
            
                .DESCRIPTION
                The Enable-WindowsDefender function ensures that Windows Defender's real-time monitoring, I/O protection, behavior monitoring, on-access protection, real-time scanning, and anti-spyware features are enabled. It also starts the Windows Defender and Windows Defender Network Inspection services if they are not already running.
            
                .PARAMETER PassThru
                If specified, returns the current Windows Defender preferences after enabling the features and services.
            
                .OUTPUTS
                Microsoft.Management.Infrastructure.CimInstance
                Returns the current Windows Defender preferences.
            
                .NOTES
                Requires the ConfigDefender module to be installed and imported.
                This function must be run with administrative privileges.
            
                .EXAMPLE
                PS C:\> Enable-WindowsDefender -PassThru
                Enables all specified Windows Defender features and services, and returns the current preferences.
                #>
                [CmdletBinding()]
                [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
                param (
                    [Parameter()][switch]$PassThru
                )
                
                if (!(Get-Module -Name ConfigDefender -ListAvailable)) {
                    Write-Error 'ConfigDefender module is not installed.' -ErrorAction Stop
                }
            
                Import-Module ConfigDefender
                $mpPreferences = Get-MpPreference -ErrorAction Stop
                if ($mpPreferences.DisableRealtimeMonitoring) {
                    Set-MpPreference -DisableRealtimeMonitoring $false
                    Write-Information 'Windows Defender real-time monitoring has been enabled.'
                } else {
                    Write-Information 'Windows Defender real-time monitoring is already enabled.'
                }
            
                if ($mpPreferences.DisableIOAVProtection) {
                    Set-MpPreference -DisableIOAVProtection $false
                    Write-Information 'Windows Defender I/O protection has been enabled.'
                } else {
                    Write-Information 'Windows Defender I/O protection is already enabled.'
                }
            
            
                $targetRegistryKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection'
            
                if (New-Item -Path $targetRegistryKey -ErrorAction SilentlyContinue) {
                    Write-Information "'$targetRegistryKey' registry key has been created."
                } else {
                    if ($Error[0].CategoryInfo.Category -eq 'ResourceExists') {
                        Write-Information "'$targetRegistryKey' registry key already exists."
                    } else {
                        Write-Error "Failed to create '$targetRegistryKey' registry key. Error: $($Error[0])" -ErrorAction Stop
                    }
                }
            
                if (Set-ItemProperty -Path $targetRegistryKey -Name DisableBehaviorMonitoring -Value 0 -PassThru -ErrorAction SilentlyContinue) {
                    Write-Information 'Behavior monitoring is enabled.'
                } else {
                    Write-Error "Failed to enable behavior monitoring. Error: $($Error[0])" -ErrorAction Stop
                }
            
                if (Set-ItemProperty -Path $targetRegistryKey -Name DisableOnAccessProtection -Value 0 -PassThru -ErrorAction SilentlyContinue) {
                    Write-Information 'On-access protection is enabled.'
                } else {
                    Write-Error "Failed to enable on-access protection. Error: $($Error[0])" -ErrorAction Stop
                }
            
                if (Set-ItemProperty -Path $targetRegistryKey -Name DisableScanOnRealtimeEnable -Value 0 -PassThru -ErrorAction SilentlyContinue) {
                    Write-Information 'Real-time scanning is enabled.'
                } else {
                    Write-Error "Failed to enable real-time scanning. Error: $($Error[0])" -ErrorAction Stop
                }
            
                if (Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 0 -PassThru -ErrorAction SilentlyContinue) {
                    Write-Information 'Anti-spyware is enabled.'
                } else {
                    Write-Error "Failed to enable anti-spyware. Error: $($Error[0])" -ErrorAction Stop
                }
            
                if (Start-Service -Name WinDefend -PassThru -ErrorAction SilentlyContinue) {
                    Write-Information 'Windows Defender service has been started.'
                } else {
                    Write-Error "Failed to start Windows Defender service. Error: $($Error[0])" -ErrorAction Stop
                }
            
                if (Start-Service -Name WdNisSvc -PassThru -ErrorAction SilentlyContinue) {
                    Write-Information 'Windows Defender Network Inspection service has been started.'
                } else {
                    Write-Error "Failed to start Windows Defender Network Inspection service. Error: $($Error[0])" -ErrorAction Stop
                }
            
                Write-Information 'Windows Defender has been enabled.'
                if ($PassThru) {
                    return Get-MpPreference
                }
            }
            return Enable-WindowsDefender -PassThru -InformationAction "Continue"
        }
    }
}