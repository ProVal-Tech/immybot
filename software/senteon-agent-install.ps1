$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
Invoke-WebRequest -Uri 'update.senteon.co/installers/SenteonAgent.msi' -UseBasicParsing -OutFile 'C:\Windows\Temp\SenteonAgent.msi'
cmd.exe /c msiexec /i 'C:\Windows\Temp\SenteonAgent.msi' /quiet ORGANIZATION="$Organization" TENANT="$Tenant" REGISTRATIONCODE="$RegistrationCode" AUTOEVAL="true" ACCEPTALL=YES /l*v "C:\Windows\Temp\SenteonInstall.log"