<#
    Name: nvidia-app-for-enterprise-installation-script
    Type: Software Version Action
    Execution System
    Language: PowerShell
    Override timeout: No
    Access Level: All
#>
#region Variables
$argumentList = @(
	'-s',
	'-noreboot',
	'-noeula',
	'-nofinish',
	'-nosplash'
)
#endRegion

#region Installation
Start-Process -FilePath $InstallerFile -ArgumentList $argumentList -NoNewWindow -Wait
#endRegion