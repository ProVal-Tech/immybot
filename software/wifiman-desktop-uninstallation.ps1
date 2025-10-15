$apps = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                   "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*wifiman*" }

if ($apps) {
    foreach ($app in $apps) {
   if ($app.UninstallString) {
            $uninstallCmd = $app.UninstallString 
                Start-Process "cmd.exe" -ArgumentList "/c `"$uninstallCmd /S`"" 

        }
    }
} 

function Is-wifimanInstalled {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "*wifiman Desktop*"
        }
        if ($apps) {
            return $true
        }
    }  return $false
}

for ($i = 1; $i -le 40; $i++) {
    if (!(Is-wifimanInstalled)) {
        break
    } else {
        Start-Sleep -Seconds 30
    }
}

