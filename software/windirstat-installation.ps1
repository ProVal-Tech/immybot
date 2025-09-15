$MSIArguments = @(
    "/i"
    $InstallerFile
    "/quiet"
    "/norestart"
)

Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
