Invoke-ImmyCommand -ScriptBlock {
    @'
    class UserHive {
        [string]$SID
        [string]$Username
        [string]$Path
        [string]$Hive
        [bool]$WasLoaded

        [void] Dismount() {
            if ($this.WasLoaded) {
                [gc]::Collect()
                reg unload HKU\$($this.SID) | Out-Null
            }
        }
    }
'@ | Invoke-Expression
    function Get-RegistryHivePath {
        <#
    .SYNOPSIS
        Gets a list of registry hives from the local computer.
    .EXAMPLE
        Get-RegistryHivePath
        Returns the full list of registry hives.
    .PARAMETER ExcludeDefault
        Exclude the Default template hive from the return.
    #>
        [CmdletBinding()]
        [OutputType([PSCustomObject])]
        param (
            [Parameter(Mandatory = $false)][switch]$ExcludeDefault
        )
        # Regex pattern for SIDs
        $patternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'

        # Get Username, SID, and location of ntuser.dat for all users
        $profileList = @(
            Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } |
                Select-Object @{name = 'SID'; expression = { $_.PSChildName } },
                @{name = 'UserHive'; expression = { "$($_.ProfileImagePath)\ntuser.dat" } },
                @{name = 'Username'; expression = { (New-Object System.Security.Principal.SecurityIdentifier($_.PSChildName)).Translate([System.Security.Principal.NTAccount]).Value } }
        )

        # If the default user was not excluded, add it to the list of profiles to process.
        if (!$ExcludeDefault) {
            $profileList += [PSCustomObject]@{
                SID = '.DEFAULT'
                UserHive = "$env:SystemDrive\Users\Default\ntuser.dat"
                Username = 'DefaultUserTemplate'
            }
        }
        return $profileList
    }

    function Open-UserHives {
        [CmdletBinding()]
        [OutputType([UserHive])]
        param (
            [Parameter(Mandatory = $false)][switch]$ExcludeDefault
        )

        $profileList = Get-RegistryHivePath -ExcludeDefault:$ExcludeDefault
        $patternSID = "((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$(if(!$ExcludeDefault) { '|.DEFAULT' })$"
        $loadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = 'SID'; expression = { $_.PSChildName } }
        if ($LoadedHives) {
            $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = 'SID'; expression = { $_.InputObject } }, UserHive, Username
        } else {
            $UnloadedHives = $ProfileList
        }
        $returnEntries = @(
            foreach ($profile in $ProfileList) {
                if ([string]::IsNullOrWhiteSpace($profile.Username)) { continue }
                # Load User ntuser.dat if it's not already loaded
                if ($profile.SID -in $UnloadedHives.SID) {
                    reg load HKU\$($profile.SID) $($profile.UserHive) | Out-Null
                }

                $hivePath = "Registry::HKEY_USERS\$($profile.SID)"

                [UserHive]@{
                    SID = $profile.SID
                    Username = $profile.Username
                    Path = $hivePath
                    Hive = $profile.UserHive
                    WasLoaded = $profile.SID -notin $loadedHives.SID
                }
            }
        )
        return $returnEntries
    }

    function Test-OutlookSharedMailboxCache {
        [CmdletBinding()]
        [OutputType([bool])]
        param ()

        $hives = Open-UserHives
        $cachePolicyEnforced = $true
        foreach ($hive in $hives) {
            Write-Information -MessageData "Processing $($hive.Username) hive"
            Write-Information -MessageData "Hive Path: $($hive.Path)"
            $officeVersions = (Get-ChildItem -Path "$($hive.Path)\Software\Microsoft\Office" -ea 0).Name -split '\\' | Where-Object { $_ -match '(\d+\.\d+)' }
            foreach ($officeVersion in $officeVersions) {
                $targetKeys = "Software\Policies\Microsoft\Cloud\Office\$officeVersion\Outlook\Cached Mode", "Software\Policies\Microsoft\Office\$officeVersion\Outlook\Cached Mode"
                foreach ($officeKey in $targetKeys) {
                    $fullTargetPath = "$($hive.Path)\$officeKey"
                    Write-Information -MessageData "Checking for $fullTargetPath"
                    if (
                        !(Test-Path -Path $fullTargetPath) -or
                    ((Get-ItemProperty -Path $fullTargetPath -Name CacheOthersMail -ea 0).CacheOthersMail -ne 0) -or
                    ((Get-ItemProperty -Path $fullTargetPath -Name DownloadSharedFolders -ea 0).DownloadSharedFolders -ne 0)
                    ) {
                        $cachePolicyEnforced = $false
                    }
                    $hive.Dismount()
                }
            }
        }
        return $cachePolicyEnforced
    }
    return Test-OutlookSharedMailboxCache
}