$MSIArguments = @(
    "/i"
    $InstallerFile
    "/quiet"
)

Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow