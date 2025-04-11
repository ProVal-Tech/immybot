$firefoxPoliciesPath = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox'

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
                $key = 'DisableTelemetry'
                $ExpectedValue = 1
                $Value = (Get-ItemProperty -Path $using:firefoxPoliciesPath -Name $key -ErrorAction SilentlyContinue).$key
                if ($Value -ne $ExpectedValue) {
                    return "Key $key does not exist."
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

            try {
                Set-ItemProperty -Path $using:firefoxPoliciesPath -Name 'DisableTelemetry' -Value 1 -Force -ErrorAction Stop
            } catch {
                return "Failed to set 'DisableTelemetry'. Reason: $($Error[0].Exception.Message)"
            }
        }
    }
}