PARAM(
    [string]$Server = "."
)

$isNCDomain = $env:USERDOMAIN -iin "nclan", "ncart"
$isATDomain = $env:USERDOMAIN -ieq "prod"
$isTestEnvironment = $isATDomain -and $env:COMPUTERNAME -match "^BMAT-DBANK-T\d{2}$"

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath "LOGS"
Write-Host "Logfolder is: $LOGFOLDER"
If(!(Test-Path $LOGFOLDER))
{
    New-Item -ItemType Directory -Force -Path $LOGFOLDER -Verbose
}

Set-Location "$PSScriptRoot\Database"
& .\DropPublications.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

& .\DropObsoleteDatabases.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

if($isNCDomain){
    # Only publish tests in internal environments
    & .\PublishAllDatabases.ps1 -Server $Server -PublishTests
}
else{
    & .\PublishAllDatabases.ps1 -Server $Server
}
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

& .\SetRecoveryModelDZ.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

& .\AddPublicationsDZ.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

Set-Location "$PSScriptRoot\SSIS"
& .\DeployAllSSISProjects.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

& .\SetupSSISVariables.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

Set-Location "$PSScriptRoot\SSAS"
& .\DropObsoleteSSASDatabases.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

& .\DeployAllSSASDatabases.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

Set-Location "$PSScriptRoot\SqlAgent"
& .\SetupAgentJobs.ps1 -ServerInstance $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}

Set-Location "$PSScriptRoot\Database"
& .\RunAllTests.ps1 -Server $Server
if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}