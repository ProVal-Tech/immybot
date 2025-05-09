
#requires -RunAsAdministrator
#requires -Version 5.1

<#
.SYNOPSIS
This script enforces browser security policies by disabling password managers, autofill features (addresses and credit cards), and the Microsoft Edge Wallet. It also removes saved passwords from browser profiles if specified.

.DESCRIPTION
This script automates the process of applying security policies to browsers installed on a Windows system. It performs the following tasks:

1. **Parameter Validation**:
   - Uses `ValidateSet` to restrict the `Browser` parameter to predefined options, ensuring valid input.
   - Provides optional parameters to enable or disable specific security features.

2. **Working Directory Management**:
   - Creates a working directory for temporary files and logs if it does not already exist.

3. **Application Detection**:
   - Checks if the specified browser(s) are installed on the system by querying the Windows registry.

4. **Registry Configuration**:
   - Configures registry settings to disable features such as:
     - Password managers.
     - Autofill for addresses.
     - Autofill for credit card details.

5. **Edge Wallet Management**:
   - Disables the Microsoft Edge Wallet and removes its data if specified.

6. **Saved Password Removal**:
   - Deletes saved passwords from browser profiles for supported browsers, including Chromium-based browsers and Firefox.

7. **Error Handling and Logging**:
   - Logs the success or failure of each operation to a log file.
   - Provides detailed error messages for failed operations.

8. **Browser Process Management**:
   - Stops browser processes if necessary to apply changes or remove sensitive data.

.PARAMETER Browser
- Specifies the browser(s) to apply the changes for. Valid values are:
  - `Chrome`: Applies changes to Google Chrome.
  - `Edge`: Applies changes to Microsoft Edge.
  - `Brave`: Applies changes to Brave Browser.
  - `Firefox`: Applies changes to Mozilla Firefox.
  - `All`: Applies changes to all supported browsers.

.PARAMETER DisablePasswordManager
- Disables the password manager for the specified browser(s). Default is `$true`.

.PARAMETER DisableAutofillAddress
- Disables the autofill feature for addresses in the specified browser(s). Default is `$true`.

.PARAMETER DisableAutofillCreditCard
- Disables the autofill feature for credit card details in the specified browser(s). Default is `$true`.

.PARAMETER RemoveSavedPassword
- Removes saved passwords from the specified browser(s). Default is `$false`.

.PARAMETER DisableEdgeWallet
- Disables the Microsoft Edge Wallet and removes its data. Default is `$false`.

.EXAMPLE
# Example 1: Apply all security policies to all supported browsers
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser All

.EXAMPLE
# Example 2: Disable the password manager for Google Chrome
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser Chrome -DisablePasswordManager $true

.EXAMPLE
# Example 3: Remove saved passwords from Microsoft Edge and disable the Edge Wallet
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser Edge -RemoveSavedPassword $true -DisableEdgeWallet $true

.EXAMPLE
# Example 4: Disable autofill for addresses and credit card details for Brave Browser
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser Brave -DisableAutofillAddress $true -DisableAutofillCreditCard $true

.EXAMPLE
# Example 5: Remove saved passwords from all browsers
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser All -RemoveSavedPassword $true

.EXAMPLE
# Example 6: Disable password managers and autofill features for Chrome, Edge, and Brave
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser Chrome,Edge,Brave -DisablePasswordManager $true -DisableAutofillAddress $true -DisableAutofillCreditCard $true

.EXAMPLE
# Example 7: Remove saved passwords from Firefox and Edge while disabling the Edge Wallet
.\lockdown-browsers-autofill-and-password-manager.ps1 -Browser Firefox,Edge -RemoveSavedPassword $true -DisableEdgeWallet $true

.NOTES
- This script requires administrative privileges to run.
- Ensure that PowerShell version 5.1 or higher is installed on the system.
- The script modifies registry settings, so it is recommended to back up the registry before running the script.
- If the `RemoveSavedPassword` parameter is set to `$true`, browsers will be forcefully closed to delete saved passwords.
- The `DisableEdgeWallet` parameter must be set to `$true` to remove saved passwords from Microsoft Edge.

**ImmyBot Script Details:** 

- Name: lockdown-browsers-autofill-and-password-manager
- Type: Task
- ExecutionContext: Metascript
- Language: PowerShell
- OverrideTimeout: false
- AccessLevel: All
#>

# Parameters
# This section defines the input parameters for the script. These parameters allow the user to specify:
# - The browser(s) to apply the changes to (`Browser`).
# - Whether to disable the password manager (`DisablePasswordManager`).
# - Whether to disable autofill for addresses (`DisableAutofillAddress`).
# - Whether to disable autofill for credit card details (`DisableAutofillCreditCard`).
# - Whether to remove saved passwords (`RemoveSavedPassword`).
# - Whether to disable the Microsoft Edge Wallet (`DisableEdgeWallet`).
param (
    [Parameter(Position = 1, Mandatory = $false, HelpMessage = 'Name of the Browser(s) to apply the changes for. Supported Browsers: Chrome, Edge, Brave, Firefox, All')]
    [ValidateSet('Chrome', 'Edge', 'Brave', 'Firefox', 'All')]
    [String[]]$Browser = 'All',

    [Parameter(Position = 2, Mandatory = $false, HelpMessage = 'Set this value = false to NOT disable the password manager for the browser(s).')]
    [bool]$DisablePasswordManager = $true,

    [Parameter(Position = 3, Mandatory = $false, HelpMessage = 'Set this value = false to NOT disable the auto-filling of addresses for the browser(s).')]
    [bool]$DisableAutofillAddress = $true,

    [Parameter(Position = 4, Mandatory = $false, HelpMessage = 'Set this value = false to NOT disable the auto-filling of credit card details for the browser(s).')]
    [bool]$DisableAutofillCreditCard = $true,

    [Parameter(Position = 5, Mandatory = $false, HelpMessage = 'Setting this to true will remove the saved passwords from the browser(s). Browser(s) will be forcefully closed if they are running.')]
    [bool]$RemoveSavedPassword = $false,

    [Parameter(Position = 6, Mandatory = $false, HelpMessage = 'Setting this to true will disable the Microsoft Edge Wallet''s sync. Microsoft Edge will be forcefully closed if it is running. It is mandatory to set this parameter to True to remove the saved password from Microsoft Edge.')]
    [bool]$DisableEdgeWallet = $false
)

# Initialize Browser List
# This section initializes the `$Browser` variable based on the input parameter.
# If the `Browser` parameter is set to `All`, it assigns a list of all supported browsers (`Chrome`, `Edge`, `Brave`, `Firefox`) to the `$Browser` variable.
# Otherwise, it uses the value provided in the `Browser` parameter.

if ($Browser -eq 'All') {
    $Browser = @('Chrome', 'Edge', 'Brave', 'Firefox')
} else {
   $Browser = $Browser
}

# Set Parameter to Variables
$DisablePasswordManager = $DisablePasswordManager
$DisableAutofillAddress = $DisableAutofillAddress
$DisableAutofillCreditCard = $DisableAutofillCreditCard
$RemoveSavedPassword = $RemoveSavedPassword
$DisableEdgeWallet = $DisableEdgeWallet

# ImmyBot Implementation
# This section implements the logic for the ImmyBot automation framework. It uses a `switch` statement to handle different methods (`Get`, `Test`, and `Set`):
# - `Get`: Ensures the working directory exists for storing temporary files and logs.
# - `Test`: Checks the log file to determine the success or failure of the last operation.
# - `Set`: Executes the main logic of the script, including applying security policies to the specified browsers.
switch ($method) {
    # Get Switch
    # This section contains the logic for checking the presence of the specified browsers on the system.
    # It includes a function to:
    # - Determine if a browser is installed (`Find-Application`) by searching the Windows registry.
    # The script iterates through the list of specified browsers and checks their installation status.
    # For each browser, it logs whether the application is installed or not.
    # This block does not modify any settings or configurations; it is purely informational.
    'Get' {
        Invoke-ImmyCommand -ScriptBlock {
            #Function to check if the application is installed
            function Find-Application {
                <#
                .SYNOPSIS
                Checks if a specified application is installed on the system.

                .DESCRIPTION
                The `Find-Application` function searches the Windows registry to determine if a specified application is installed by examining both 32-bit and 64-bit uninstall registry paths.

                .PARAMETER Name
                The name of the application to search for.

                .OUTPUTS
                Returns `$true` if the application is installed.
                Returns `$false` if the application is not installed.

                .EXAMPLE
                # Example 1: Check if Google Chrome is installed
                Find-Application -Name 'Google Chrome'

                .EXAMPLE
                # Example 2: Check if Mozilla Firefox is installed
                Find-Application -Name 'Mozilla Firefox'
                #>
                Param(
                    [Parameter(Mandatory)]
                    [String]$Name
                )
                $uninstallPaths = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
                )
                if (Get-ChildItem -Path $uninstallPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match "$Name" }) {
                    return $app
                } else {
                    return $false
                }
            }

            # Output the installation status for each specified browser
            foreach ($app in $using:Browser) {
                Find-Application -Name $app
            }
        }
    }
    # Test Switch
    # This section contains the logic for verifying the compliance of the specified browsers with the desired security policies.
    # It includes functions to:
    # - Check if a browser is installed (`Find-Application`).
    # - Retrieve registry values (`Get-RegValue`) to verify settings.
    # - Validate browser configurations such as disabling password managers, autofill features, and saved password data.
    # - Check for the presence of saved passwords in browser profiles.
    # The script iterates through the specified browsers and evaluates their settings against the desired configuration.
    # Any non-compliant browsers are added to the `$test` array, which is used to determine the overall compliance status.
    # The block returns `$true` if all browsers are compliant, or `$false` if any browser requires remediation.
    'Test' {
        Invoke-ImmyCommand -ScriptBlock {
            # Function to determine if an application is installed on the system
            function Find-Application {
                <#
                .SYNOPSIS
                Checks if a specified application is installed on the system.

                .DESCRIPTION
                The `Find-Application` function searches the Windows registry to determine if a specified application is installed by examining both 32-bit and 64-bit uninstall registry paths.

                .PARAMETER Name
                The name of the application to search for.

                .OUTPUTS
                Returns `$true` if the application is installed.
                Returns `$false` if the application is not installed.

                .EXAMPLE
                # Example 1: Check if Google Chrome is installed
                Find-Application -Name 'Google Chrome'

                .EXAMPLE
                # Example 2: Check if Mozilla Firefox is installed
                Find-Application -Name 'Mozilla Firefox'
                #>
                Param(
                    [Parameter(Mandatory)]
                    [String]$Name
                )
                $uninstallPaths = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
                )
                if (Get-ChildItem -Path $uninstallPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match "$Name" }) {
                    return $true
                } else {
                    return $false
                }
            }

            # Function to retrieve the data of a specified registry value
            function Get-RegValue {
                <#
                .SYNOPSIS
                Retrieves the data of a specified registry value.

                .DESCRIPTION
                The `Get-RegValue` function retrieves the data of a specified registry value from the Windows registry. If the value does not exist or the key path is invalid, it returns `$null`.

                .PARAMETER path
                The registry key path to query.

                .PARAMETER Reg
                The name of the registry value to retrieve.

                .OUTPUTS
                Returns the data of the specified registry value.
                Returns `$null` if the value does not exist or the key path is invalid.

                .EXAMPLE
                # Example 1: Retrieve the data of a registry value
                Get-RegValue -path 'HKLM:\Software\Policies\Google\Chrome' -Reg 'PasswordManagerEnabled'
                #>
                Param(
                    [Parameter(Mandatory)]
                    [String]$path,
                    [Parameter(Mandatory)]
                    [String]$Reg
                )
                try {
                    return (Get-ItemProperty -Path $path -ErrorAction Stop)."$Reg"
                } catch {
                    return $null
                }
            }

            # Initialize an array to track browsers that do not meet the desired configuration
            $test = @()
            $Browser = $using:Browser

            # Verify Browser Security Settings
            # This section iterates through the specified browsers and verifies their security settings against the desired configuration.
            # It checks settings related to password managers, autofill for addresses, autofill for credit card details, and saved password data
            # by examining the appropriate registry keys and file paths for each browser.
            # Only browsers installed on the system, as confirmed by the `Find-Application` function, are evaluated.
            # Browsers that do not comply with the desired settings are added to the `$test` array.
            foreach ($app in $Browser) {
                # Configure Browser-Specific Settings
                # This section assigns the registry path, application name, process name, and profile path based on the current browser.
                # A `switch` statement determines these values for supported browsers (e.g., Chrome, Edge, Brave, Firefox) to facilitate subsequent checks.
                switch ($app) {
                    'Chrome' {
                        $regPath = 'HKLM:\Software\Policies\Google\Chrome'
                        $appName = 'Google Chrome'
                        $profilePath = 'AppData\Local\Google\Chrome'
                    }
                    'Edge' {
                        $regPath = 'HKLM:\Software\Policies\Microsoft\Edge'
                        $appName = 'Microsoft Edge'
                        $profilePath = 'AppData\Local\Microsoft\Edge'
                    }
                    'Brave' {
                        $regPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'
                        $appName = 'Brave'
                        $profilePath = 'AppData\Local\BraveSoftware\Brave-Browser'
                    }
                    'Firefox' {
                        $regPath = 'HKLM:\Software\Policies\Mozilla\Firefox'
                        $appName = 'Mozilla Firefox'
                        $profilePath = 'AppData\Roaming\Mozilla\Firefox\Profiles'
                    }
                }

                # Verify Browser Installation
                # This section confirms whether the specified browser is installed on the system using the `Find-Application` function.
                # If the browser is not installed, further checks for that browser are skipped.
                if (Find-Application -Name $appName) {

                    # Verify Password Manager is Disabled
                    # If the `DisablePasswordManager` flag is `$true`, this section checks whether the 'PasswordManagerEnabled' registry value
                    # is set to 0 (disabled). If it is not, the browser is added to the `$test` array, indicating remediation is required.
                    if ($using:DisablePasswordManager -eq $true) {
                        $reg = 'PasswordManagerEnabled'
                        $Value = 0
                        if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                            $test += $app
                        }
                    }

                    # Verify Autofill for Addresses is Disabled in Chromium-Based Browsers
                    # If the `DisableAutofillAddress` flag is `$true`, this section checks whether the 'AutofillAddressEnabled' registry value
                    # is set to 0 (disabled) for Chromium-based browsers (excluding Firefox). Non-compliant browsers are added to the `$test` array.
                    if ($using:DisableAutofillAddress -eq $true -and $app -ne 'Firefox') {
                        $Value = 0
                        $reg = 'AutofillAddressEnabled'
                        if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                            $test += $app
                        }
                    }

                    # Verify Autofill for Credit Cards is Disabled in Chromium-Based Browsers
                    # If the `DisableAutofillCreditCard` flag is `$true`, this section checks whether the 'AutofillCreditCardEnabled' and
                    # 'PaymentMethodQueryEnabled' registry values are set to 0 (disabled) for Chromium-based browsers (excluding Firefox).
                    # Non-compliant browsers are added to the `$test` array.
                    if ($using:DisableAutofillCreditCard -eq $true -and $app -ne 'Firefox') {
                        $Value = 0
                        foreach ($reg in 'AutofillCreditCardEnabled', 'PaymentMethodQueryEnabled') {
                            if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                                $test += $app
                            }
                        }
                    }

                    # Verify Edge Wallet is Disabled and Data is Removed
                    # For Microsoft Edge, if the `DisableEdgeWallet` flag is `$true`, this section checks whether the 'SyncDisabled' registry value
                    # is set to 1 (disabled) and verifies that the 'Edge Wallet' folder does not exist in any user profile's browser data directory.
                    # If either condition is not met, Edge is added to the `$test` array.
                    if ($using:DisableEdgeWallet -eq $true -and $app -eq 'Edge') {
                        $reg = 'SyncDisabled'
                        $Value = 1
                        if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                            $test += $app
                        }
                        foreach ($path in Get-ChildItem -Path 'C:\Users' | Where-Object { $_.Mode -match 'd' }) {
                            if (Test-Path -Path "$($path.FullName)\$profilePath") {
                                if (Test-Path -Path "$($path.FullName)\$profilePath\User Data\Edge Wallet") {
                                    $test += $app
                                }
                            }
                        }
                    }

                    # Verify No Saved Passwords Exist in Chromium-Based Browsers
                    # If the `RemoveSavedPassword` flag is `$true`, this section checks for the presence of 'Login Data' and 'Login Data-journal'
                    # files in the user profile data directories of Chromium-based browsers (excluding Firefox). If found, the browser is added to the `$test` array.
                    if ($using:RemoveSavedPassword -eq $true -and $app -ne 'Firefox') {
                        foreach ($path in Get-ChildItem -Path 'C:\Users' | Where-Object { $_.Mode -match 'd' }) {
                            if (Test-Path -Path "$($path.FullName)\$profilePath") {
                                foreach ($item in ('Login Data', 'Login Data-journal')) {
                                    if (Test-Path -Path "$($path.FullName)\$profilePath\User Data\Default\$item") {
                                        $test += $app
                                    }
                                }
                            }
                        }
                    }

                    # Verify No Saved Passwords Exist in Firefox
                    # If the `RemoveSavedPassword` flag is `$true`, this section checks for the presence of password storage files (e.g., 'logins.json', 'signons.sqlite')
                    # in Firefox profile directories within user profiles. If found, Firefox is added to the `$test` array.
                    if ($using:RemoveSavedPassword -eq $true -and $app -eq 'Firefox') {
                        foreach ($path in Get-ChildItem -Path 'C:\Users' | Where-Object { $_.Mode -match 'd' }) {
                            if (Test-Path -Path "$($path.FullName)\$profilePath") {
                                foreach ($profile in Get-ChildItem -Path "$($path.FullName)\$profilePath" | Where-Object { $_.Mode -match 'd' }) {
                                    foreach ($item in ('signons.txt', 'signons2.txt', 'signons3.txt', 'signons.sqlite', 'logins.json', 'logins-backup.json')) {
                                        if (Test-Path -Path "$($profile.FullName)\$item") {
                                            $test += $app
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            # Return Compliance Status
            # Returns `$false` if the `$test` array contains any items, indicating that one or more browsers are non-compliant with the desired configuration.
            # Returns `$true` if all checked browsers comply with the desired configuration.
            if ($test) {
                return $false
            } else {
                return $true
            }
        }
    }
    # Set Switch
    # This section contains the main logic for applying security policies to the specified browsers.
    # It includes functions to:
    # - Check if a browser is installed (`Find-Application`).
    # - Retrieve and set registry values (`Get-RegValue` and `Set-RegValue`).
    # - Apply security policies such as disabling password managers, autofill features, and the Microsoft Edge Wallet.
    # - Remove saved passwords from browser profiles.
    # It also tracks any failures during these operations and logs the results.
    'Set' {
        Invoke-ImmyCommand -ScriptBlock {
            #Function to check if the application is installed
            function Find-Application {
                <#
                .SYNOPSIS
                Checks if a specified application is installed on the system.

                .DESCRIPTION
                The `Find-Application` function searches the Windows registry to determine if a specified application is installed. It checks both 32-bit and 64-bit registry paths for uninstall information.

                .PARAMETER Name
                - The name of the application to search for.

                .OUTPUTS
                - Returns the name of the application if it is installed.
                - Returns `$false` if the application is not installed.

                .EXAMPLE
                # Example 1: Check if Google Chrome is installed
                Find-Application -Name 'Google Chrome'

                .EXAMPLE
                # Example 2: Check if Mozilla Firefox is installed
                Find-Application -Name 'Mozilla Firefox'
                #>
                Param(
                    [Parameter(Mandatory)]
                    [String]$Name
                )
                $uninstallPaths = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
                )
                if (Get-ChildItem -Path $uninstallPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match "$Name" }) {
                    Write-Information "$Name is installed." -InformationAction Continue
                    return $Name
                } else {
                    Write-Information "$Name is not installed." -InformationAction Continue
                    return $false
                }
            }

            #Function to check the current value of the registry key
            function Get-RegValue {
                <#
                .SYNOPSIS
                Retrieves the value of a specified registry key.

                .DESCRIPTION
                The `Get-RegValue` function retrieves the value of a specified registry key from the Windows registry. If the key does not exist, it returns `$null`.

                .PARAMETER path
                - The registry path to query.

                .PARAMETER Reg
                - The name of the registry key to retrieve.

                .OUTPUTS
                - Returns the value of the specified registry key.
                - Returns `$null` if the key does not exist.

                .EXAMPLE
                # Example 1: Get the value of a registry key
                Get-RegValue -path 'HKLM:\Software\Policies\Google\Chrome' -Reg 'PasswordManagerEnabled'
                #>
                Param(
                    [Parameter(Mandatory)]
                    [String]$path,
                    [Parameter(Mandatory)]
                    [String]$Reg
                )
                try {
                    return (Get-ItemProperty -Path $path -ErrorAction Stop)."$Reg"
                } catch {
                    return $null
                }
            }

            #Function to set the value to the registry key
            function Set-RegValue {
                <#
                .SYNOPSIS
                Sets the value of a specified registry key.

                .DESCRIPTION
                The `Set-RegValue` function sets the value of a specified registry key in the Windows registry. If the registry path does not exist, it creates the path before setting the value.

                .PARAMETER path
                - The registry path to modify.

                .PARAMETER Reg
                - The name of the registry key to set.

                .PARAMETER Value
                - The value to assign to the registry key.

                .EXAMPLE
                # Example 1: Set a registry key value
                Set-RegValue -path 'HKLM:\Software\Policies\Google\Chrome' -Reg 'PasswordManagerEnabled' -Value 0
                #>
                Param(
                    [Parameter(Mandatory)]
                    [String]$path,
                    [Parameter(Mandatory)]
                    [String]$Reg,
                    [Parameter(Mandatory)]
                    [Int32]$Value
                )

                if ((Get-RegValue -path $path -Reg $Reg) -ne $Value) {
                    if (!(Test-Path -Path $path)) {
                        New-Item -Path $path -Force | Out-Null
                    }
                    Set-ItemProperty -Path $path -Name $Reg -Value $Value -Force
                }
            }

            # The `$failed` array is initialized here to track any browsers where operations fail.
            $failed = @()
            $Browser = $using:Browser

            # Disable Password Manager and Autofill
            # This section iterates through the list of specified browsers and applies security policies.
            # It disables the password manager, autofill for addresses, and autofill for credit card details
            # by setting the appropriate registry keys for each browser.
            # The operations are performed only for browsers that are installed on the system, as verified by the `Find-Application` function.
            # Any failures during these operations are logged in the `$failed` array.
            foreach ($app in $Browser) {
                # Set the registry settings for the current Browser
                # This section determines the registry path, application name, process name, and profile path for the current browser.
                # It uses a `switch` statement to assign these values based on the browser being processed (e.g., Chrome, Edge, Brave, or Firefox).
                # These values are used in subsequent operations to configure registry settings and manage browser profiles.
                switch ($app) {
                    'Chrome' {
                        $regPath = 'HKLM:\Software\Policies\Google\Chrome'
                        $appName = 'Google Chrome'
                        $process = 'chrome'
                        $profilePath = 'AppData\Local\Google\Chrome'
                    }
                    'Edge' {
                        $regPath = 'HKLM:\Software\Policies\Microsoft\Edge'
                        $appName = 'Microsoft Edge'
                        $process = 'msedge'
                        $profilePath = 'AppData\Local\Microsoft\Edge'
                    }
                    'Brave' {
                        $regPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'
                        $appName = 'Brave'
                        $process = 'brave'
                        $profilePath = 'AppData\Local\BraveSoftware\Brave-Browser'
                    }
                    'Firefox' {
                        $regPath = 'HKLM:\Software\Policies\Mozilla\Firefox'
                        $appName = 'Mozilla Firefox'
                        $process = 'firefox'
                        $profilePath = 'AppData\Roaming\Mozilla\Firefox\Profiles'
                    }
                }

                # Check Application
                # This section verifies if the specified browser application is installed on the system.
                # It uses the `Find-Application` function to search for the application in the Windows registry.
                # If the application is not installed, the script skips further operations for that browser.
                if (Find-Application -Name $appName) {

                    # Disable Password Manager
                    # This section disables the password manager for the specified browser by setting the appropriate registry key.
                    # It uses the `Set-RegValue` function to set the `PasswordManagerEnabled` registry key to `0` (disabled).
                    # After setting the value, it verifies the change using the `Get-RegValue` function and logs any failures.
                    if ($using:DisablePasswordManager -eq $true) {
                        $reg = 'PasswordManagerEnabled'
                        $Value = 0
                        Write-Information "Disabling Password Manager for $appName." -InformationAction Continue
                        Set-RegValue -Path $regPath -Reg $reg -Value $Value
                        if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                            $failed += $app
                        }
                    }

                    # Disable Autofill Address for Chromium
                    # This section disables the autofill feature for addresses in Chromium-based browsers (e.g., Chrome, Edge, Brave).
                    # It sets the `AutofillAddressEnabled` registry key to `0` (disabled) using the `Set-RegValue` function.
                    # Firefox is excluded from this operation as it does not use the same registry keys.
                    if ($using:DisableAutofillAddress -eq $true -and $app -ne 'Firefox') {
                        $Value = 0
                        Write-Information "Disabling Address Autofilling for $appName." -InformationAction Continue
                        $reg = 'AutofillAddressEnabled'
                        Set-RegValue -Path $regPath -Reg $reg -Value $Value
                        if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                            $failed += $app
                        }
                    }

                    # Disable Autofill Credit Card for Chromium
                    # This section disables the autofill feature for credit card details in Chromium-based browsers.
                    # It sets the `AutofillCreditCardEnabled` and `PaymentMethodQueryEnabled` registry keys to `0` (disabled).
                    # Firefox is excluded from this operation as it does not use the same registry keys.
                    if ($using:DisableAutofillCreditCard -eq $true -and $app -ne 'Firefox') {
                        $Value = 0
                        Write-Information "Disabling Credit Card Information Autofilling for $appName." -InformationAction Continue
                        foreach ($reg in 'AutofillCreditCardEnabled', 'PaymentMethodQueryEnabled') {
                            Set-RegValue -Path $regPath -Reg $reg -Value $Value
                            if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                                $failed += $app
                            }
                        }
                    }

                    # Disable Edge Wallet
                    # This section disables the Microsoft Edge Wallet and removes its associated data.
                    # It stops the Edge process if it is running, sets the `SyncDisabled` registry key to `1` (disabled),
                    # and deletes the "Edge Wallet" folder from user profiles if it exists.
                    # Any failures during these operations are logged.
                    if ($using:DisableEdgeWallet -eq $true -and $app -eq 'Edge') {
                        Write-Information 'Disabling Edge Wallet.' -InformationAction Continue
                        Write-Information "Stopping the process for $appName if it's running." -InformationAction Continue
                        Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force -Confirm:$false -WarningAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        $reg = 'SyncDisabled'
                        $Value = 1
                        Set-RegValue -Path $regPath -Reg $reg -Value $Value
                        if ((Get-RegValue -path $regPath -Reg $reg) -ne $Value) {
                            $failed += $app
                        }
                        foreach ($path in Get-ChildItem -Path 'C:\Users' | Where-Object { $_.Mode -match 'd' }) {
                            if (Test-Path -Path "$($path.FullName)\$profilePath") {
                                if (Test-Path -Path "$($path.FullName)\$profilePath\User Data\Edge Wallet") {
                                    try {
                                        Remove-Item -Path "$($path.FullName)\$profilePath\User Data\Edge Wallet" -Recurse -Force -Confirm:$false -ErrorAction Stop
                                    } catch {
                                        $failed += $app
                                    }
                                }
                            }
                        }
                    }

                    # Delete Saved Passwords for Chromium
                    # This section removes saved passwords from Chromium-based browsers.
                    # It stops the browser process if it is running and deletes the "Login Data" and "Login Data-journal" files
                    # from the "User Data\Default" folder in user profiles.
                    # Any failures during these operations are logged.
                    if ($using:RemoveSavedPassword -eq $true -and $app -ne 'Firefox') {
                        Write-Information "Stopping the process for $appName if it's running." -InformationAction Continue
                        Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force -Confirm:$false -WarningAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        foreach ($path in Get-ChildItem -Path 'C:\Users' | Where-Object { $_.Mode -match 'd' }) {
                            if (Test-Path -Path "$($path.FullName)\$profilePath") {
                                foreach ($item in ('Login Data', 'Login Data-journal')) {
                                    if (Test-Path -Path "$($path.FullName)\$profilePath\User Data\Default\$item") {
                                        try {
                                            Write-Information "Removing the passwords saved in $appName for $($path.Name)" -InformationAction Continue
                                            Remove-Item -Path "$($path.FullName)\$profilePath\User Data\Default\$item" -Recurse -Force -Confirm:$false -ErrorAction Stop
                                        } catch {
                                            $failed += $app
                                        }
                                    }
                                }
                            }
                        }
                    }

                    # Delete Saved Passwords for Firefox
                    # This section removes saved passwords from Mozilla Firefox.
                    # It stops the Firefox process if it is running and deletes files such as `logins.json` and `signons.sqlite`
                    # from the Firefox profile folders in user profiles.
                    # Any failures during these operations are logged.
                    if ($using:RemoveSavedPassword -eq $true -and $app -eq 'Firefox') {
                        Write-Information "Stopping the process for $appName if it's running." -InformationAction Continue
                        Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force -Confirm:$false -WarningAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        foreach ($path in Get-ChildItem -Path 'C:\Users' | Where-Object { $_.Mode -match 'd' }) {
                            if (Test-Path -Path "$($path.FullName)\$profilePath") {
                                foreach ($profile in Get-ChildItem -Path "$($path.FullName)\$profilePath" | Where-Object { $_.Mode -match 'd' }) {
                                    foreach ($item in ('signons.txt', 'signons2.txt', 'signons3.txt', 'signons.sqlite', 'logins.json', 'logins-backup.json')) {
                                        if (Test-Path -Path "$($profile.FullName)\$item") {
                                            try {
                                                Write-Information "Removing the passwords saved in $appName for $($path.Name)" -InformationAction Continue
                                                Remove-Item -Path "$($profile.FullName)\$item" -Force -Confirm:$false -ErrorAction Stop
                                            } catch {
                                                $failed += $app
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            # Return Failures
            # This section checks if any operations failed during the script execution.
            if ($failed.Count -gt 0) {
                throw "The following applications encountered issues: $($failed -join ', ')"
            } else {
                Write-Information 'All operations completed successfully.' -InformationAction Continue
            }
        }
    }
}
