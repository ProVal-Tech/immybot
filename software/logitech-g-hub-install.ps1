Start-Process -FilePath $InstallerFile -ArgumentList '--silent' -NoNewWindow -Wait
Start-Sleep -Seconds 60
