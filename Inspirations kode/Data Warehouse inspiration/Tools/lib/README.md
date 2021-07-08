# Tools/lib
This folder is intended for third party dlls that may be referenced from e.g. SSIS script tasks and thus should be added to GAC on the target machine.

Use Install.ps1 to install the dlls
## Instructions:
1. Start Powershell or Powershell ISE as an administrator
2. Navigate to the location of the script and the dlls (e.g. cd C:\Source\Repos\myproject\Tools\lib)
3. Execute the script
4. Verify that the dlls have been properly installed by examining C:\Windows\Microsoft.Net\assembly\GAC_MSIL
