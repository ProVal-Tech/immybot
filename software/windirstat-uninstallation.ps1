$apps = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                   "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*windirstat*" }

if ($apps) {
    foreach ($app in $apps) {
   if ($app.UninstallString) {
            $uninstallCmd = $app.UninstallString 
                Start-Process "cmd.exe" -ArgumentList "/c `"$uninstallCmd /quiet`"" 

        }
    }
} 