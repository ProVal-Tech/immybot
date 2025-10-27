$InstallerFile = $InstallerFolder + "\Mail Merge Toolkit (x64).msi"
msiexec /x “$InstallerFile” /qn
Start-Sleep -Seconds 10