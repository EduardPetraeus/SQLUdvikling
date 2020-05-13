PARAM(
    [string]$Server = "."
)

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_06_Databank-DZ_SSAS_DeployAllSSASDatabases_ps1.log"
Write-Output "Leverer SSAS Databaser" | Set-Content -Path $LOGPATH

# Deploy and process all foundation cubes
get-item *.asdatabase | ?{$_.Name -cmatch "^GK "} | %{
    Get-Date
    Write-Host -ForegroundColor Green "DeploySSASDatabase -DatabaseFile $($_.Name)"
    Write-Output "DeploySSASDatabase -DatabaseFile $($_.Name)" | Add-Content -Path $LOGPATH
    .\DeploySSASDatabase.ps1 -DatabaseFile $_.FullName -Server $Server
    (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
    (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
    if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}
}

# Deploy and process all other cubes
get-item *.asdatabase | ?{$_.Name -cnotmatch "^GK "} | %{
    Get-Date
    Write-Host -ForegroundColor Green "DeploySSASDatabase -DatabaseFile $($_.Name)"
    Write-Output "DeploySSASDatabase -DatabaseFile $($_.Name)" | Add-Content -Path $LOGPATH
    .\DeploySSASDatabase.ps1 -DatabaseFile $_.FullName -Server $Server
    (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
    (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
    if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}
}

