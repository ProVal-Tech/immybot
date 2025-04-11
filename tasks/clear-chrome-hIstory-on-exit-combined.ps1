$chromePoliciesPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList'

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
                $items = ('1:browsing_history', '2:cookies_and_other_site_data', '3:cached_images_and_files')
                foreach ($item in $items) {
                    $Name = $item.Split(':')[0]
                    $ExpectedValue = $item.Split(':')[1]
                    $Value = (Get-ItemProperty -Path $using:chromePoliciesPath -Name $Name -ErrorAction SilentlyContinue).$Name
                    if ($Value -ne $ExpectedValue ) {
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

            foreach ( $item in ('1:browsing_history', '2:cookies_and_other_site_data', '3:cached_images_and_files') ) {
                try {
                    Set-ItemProperty -Path $using:chromePoliciesPath -Name $item.Split(':')[0] -Value $item.Split(':')[1] -Force -ErrorAction Stop
                } catch {
                    return "Failed to set Chrome policy: $item. Reason: $($Error[0].Exception.Message)"
                }
            }
        }
    }
}