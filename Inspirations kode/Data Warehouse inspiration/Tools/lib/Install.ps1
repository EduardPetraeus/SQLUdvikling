# This script installs dlls to GAC

# Instructions:
# 1. Start Powershell or Powershell ISE as an administrator
# 2. Navigate to the location of the script and the dlls (e.g. cd C:\Temp)
# 3. Execute the script
# 4. Verify that the dlls have been properly installed by examining C:\Windows\Microsoft.Net\assembly\GAC_MSIL

[System.Reflection.Assembly]::LoadWithPartialName("System.EnterpriseServices")
$publish = New-Object System.EnterpriseServices.Internal.Publish
$publish.GacInstall("$pwd\AngleSharp.dll") 
