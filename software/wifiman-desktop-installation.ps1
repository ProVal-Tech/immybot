Start-Process -FilePath $InstallerFile -ArgumentList '/S' -NoNewWindow

function Is-wifimanInstalled {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "*wifiman desktop*"
        }
        if ($apps) {
            return $true
        }
    }  return $false
}

for ($i = 1; $i -le 40; $i++) {
    if (Is-wifimanInstalled) {
        break
    } else {
        Start-Sleep -Seconds 30
    }
}
