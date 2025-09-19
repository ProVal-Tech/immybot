$MSIArguments = @(
    "/SUPPRESSMSGBOXES"
    "/VERYSILENT"
    "/NORESTART"
)

Start-Process $InstallerFile -ArgumentList $MSIArguments -NoNewWindow


function Is-soundswitchInstalled {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "*Soundswitch*"
        }
        if ($apps) {
            return $true
        }
    }  return $false
}

for ($i = 1; $i -le 40; $i++) {
    if (Is-soundswitchInstalled) {
        break
    } else {
        Start-Sleep -Seconds 30
    }
}
