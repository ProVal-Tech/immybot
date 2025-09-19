$processes = Get-Process -Name "SoundSwitch" -ErrorAction SilentlyContinue
if ($processes) {
$processes | Stop-Process -Force
} 


$apps = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                   "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*SoundSwitch*" }

if ($apps) {
    foreach ($app in $apps) {
   if ($app.UninstallString) {
            $uninstallCmd = $app.UninstallString 
                Start-Process "cmd.exe" -ArgumentList "/c `"$uninstallCmd /VERYSILENT /SUPPRESSMSGBOXES /NORESTART`"" 

        }
    }
} 


function Is-SoundswitchInstalled {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "*soundswitch*"
        }
        if ($apps) {
            return $true
        }
    }  return $false
}

for ($i = 1; $i -le 40; $i++) {
    if (!Is-SoundswitchInstalled) {
        break
    } else {
        Start-Sleep -Seconds 30
    }
}
