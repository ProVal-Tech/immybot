$firefoxPoliciesPath = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\SanitizeOnShutdown'

switch ($Method) {
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
                $keys = ('Cache', 'History', 'Cookies')
                $ExpectedValue = 1
                foreach ($key in $keys) {
                    $Value = (Get-ItemProperty -Path $using:firefoxPoliciesPath -Name $key -ErrorAction SilentlyContinue).$keys
                    if ($value -ne $ExpectedValue) {
                        return $false
                    }
                }
                return $true
            } else {
                return $false
            }
        }
    }
    'Set' {
        Invoke-ImmyCommand -ScriptBlock {
            if (-not (Test-Path $using:firefoxPoliciesPath)) {
                New-Item -Path $using:firefoxPoliciesPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            }

            foreach ($key in ('Cache', 'History', 'Cookies')) {
                try {
                    Set-ItemProperty -Path $using:firefoxPoliciesPath -Name $key -Value 1 -Force -ErrorAction Stop
                } catch {
                    return "Failed to set $key. Reason: $($Error[0].Exception.Message)"
                }
            }
        }
    }
}