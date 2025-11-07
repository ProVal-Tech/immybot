# Execution Context: User
$regPath = "HKCU:\Software\Scooter Software\Beyond Compare"
switch ($Method) {
    'Test' {
        $(try { Get-ItemPropertyValue $regPath -Name CertKey -ErrorAction SilentlyContinue } catch {}) -eq $LicenseString
    }
    'Get' {
        $(try { Get-ItemPropertyValue $regPath -Name CertKey -ErrorAction SilentlyContinue } catch {})
    }
    'Set' {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name CertKey -Value $LicenseString
    }
}
