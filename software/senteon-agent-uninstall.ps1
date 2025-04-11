$SENTEONAGENT = Get-CimInstance -ClassName Win32_Product | Where-Object {$_.Name -eq 'Senteon Agent'}
cmd.exe /c msiexec /x $SENTEONAGENT.IdentifyingNumber /quiet /l*v "SenteonAgentUninstall.log"
