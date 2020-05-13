PARAM(
    [string]$Server = "."
)

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_07_Databank-LZ_MDS_DeployAllMDSPackages_ps1.log"
Write-Output "Deploying MDS Packages" | Set-Content -Path $LOGPATH

# CreateOrAlter all SQL Functions and Stored procedures
get-item Funktioner\*.sql | %{
    Write-Host -ForegroundColor Green "Executing script: $($_.Name)"
    Write-Output "Executing script: $($_.Name)" | Add-Content -Path $LOGPATH
    Invoke-Sqlcmd -InputFile $_.FullName -ServerInstance $Server -ErrorAction Stop *>&1 | Tee-Object $LOGPATH -Append
}

	
# Deploy all MDS Packages
get-item pakker\*.pkg | ?{$_.Name} | %{
    Write-Host -ForegroundColor Green "DeployMDSPackage -PackageFile $($_.Name)"
    Write-Output "DeployMDSPackage -PackageFile $($_.Name)" | Add-Content -Path $LOGPATH
    .\DeployMDSPackage.ps1 -PackageFile $_.FullName -Server $Server
    if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}
}

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
