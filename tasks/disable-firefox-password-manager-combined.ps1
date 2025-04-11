$firefoxPoliciesPath = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox'

Switch ($Method) {
    'Get' {
        Invoke-ImmyCommand -ScriptBlock {
            if (Test-Path $using:firefoxPoliciesPath) {
                Get-ItemProperty -Path $using:firefoxPoliciesPath
            } else {
                return 'Firefox policies path does not exist.'
            }
        }
    }
    'Test' {
        Invoke-ImmyCommand -ScriptBlock {
            if (Test-Path $using:firefoxPoliciesPath) {
                $key = 'passwordmanagerenabled'
                if (-not (Get-ItemProperty -Path $using:firefoxPoliciesPath -Name $key -ErrorAction SilentlyContinue)) {
                    return $false
                }
                $value = (Get-ItemProperty -Path $using:firefoxPoliciesPath -Name $key -ErrorAction SilentlyContinue).$key
                #We are expecting 0 for the value
                if ($value) {
                    return $false
                }
                return $true
            } else {
                return $false
            }
        }
    }
    'Set' {
        if (-not (Test-Path $using:firefoxPoliciesPath)) {
            New-Item -Path $using:firefoxPoliciesPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        try {
            Set-ItemProperty -Path $using:firefoxPoliciesPath -Name 'passwordmanagerenabled' -Value 0 -Force -ErrorAction Stop
        } catch {
            return "Failed to set 'passwordmanagerenabled'. Reason: $($Error[0].Exception.Message)"
        }
    }
}