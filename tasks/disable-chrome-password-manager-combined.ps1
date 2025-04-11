$chromePoliciesPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome'

Switch ($Method) {
    'Get' {
        Invoke-ImmyCommand -ScriptBlock {
            if (Test-Path $using:chromePoliciesPath) {
                Get-ItemProperty -Path $using:chromePoliciesPath
            } else {
                return 'Chrome policies path does not exist.'
            }
        }
    }
    'Test' {
        Invoke-ImmyCommand -ScriptBlock {
            if (Test-Path $using:chromePoliciesPath) {
                $key = 'passwordmanagerenabled'
                if (-not (Get-ItemProperty -Path $using:chromePoliciesPath -Name $key -ErrorAction SilentlyContinue)) {
                    return $false
                }
                $value = (Get-ItemProperty -Path $using:chromePoliciesPath -Name $key -ErrorAction SilentlyContinue).$key
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
        if (-not (Test-Path $using:chromePoliciesPath)) {
            New-Item -Path $using:chromePoliciesPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        try {
            Set-ItemProperty -Path $using:chromePoliciesPath -Name 'passwordmanagerenabled' -Value 0 -Force -ErrorAction Stop
        } catch {
            return "Failed to set 'passwordmanagerenabled'. Reason: $($Error[0].Exception.Message)"
        }
    }
}