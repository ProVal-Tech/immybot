$chromePoliciesPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome'

switch ($Method) {
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
                $keys = ('MetricsReportingEnabled', 'DefaultBrowserSettingEnabled', 'SendUsageStats', 'ExtensionInstallErrorURL')
                foreach ($key in $keys) {
                    if (-not (Get-ItemProperty -Path $using:chromePoliciesPath -Name $key -ErrorAction SilentlyContinue)) {
                        return $false
                    }
                }
                foreach ($key in $keys) {
                    $value = (Get-ItemProperty -Path $using:chromePoliciesPath -Name $key -ErrorAction SilentlyContinue).$key
                    #We are expecting a 0 or NULL Value
                    if ($value) {
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
            if (-not (Test-Path $using:chromePoliciesPath)) {
                New-Item -Path $using:chromePoliciesPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            }

            foreach ($key in ('MetricsReportingEnabled', 'DefaultBrowserSettingEnabled', 'SendUsageStats')) {
                try {
                    Set-ItemProperty -Path $using:chromePoliciesPath -Name $key -Value 0 -Force -ErrorAction Stop
                } catch {
                    return "Failed to set $key. Reason: $($Error[0].Exception.Message)"
                }
            }

            try {
                Set-ItemProperty -Path $using:chromePoliciesPath -Name 'ExtensionInstallErrorURL' -Value '' -Force -ErrorAction Stop
            } catch {
                return "Failed to set 'ExtensionInstallErrorURL'. Reason: $($Error[0].Exception.Message)"
            }
        }
    }
}