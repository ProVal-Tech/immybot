$InstallerFile = $InstallerFolder + "\Mail Merge Toolkit (x64).msi"
msiexec /i “$InstallerFile” /qn
Start-Sleep -Seconds 10