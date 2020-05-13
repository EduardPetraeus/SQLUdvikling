PARAM(
    [string]$Server = "."
)

$zone = @{
    'SSIS GDPR' = 'GDPR';
    'SSIS LZ' = 'Landingszone';
    'SSIS FT' = 'Fasttrack';
    'SSIS DW' = 'Data Warehouse';
}

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_03_Databank-LZ_SSIS_DeployAllSSISProjects_ps1.log"

$zone.Keys | %{
    $prefix = $_
    $folder = $zone[$prefix]
    Write-Host -ForegroundColor Green "Searching for ispac files prefixed with '$prefix'"
    Write-Output "Searching for ispac files prefixed with '$prefix'" | Add-Content -Path $LOGPATH

    # Deploy all projects in zone
    Get-Item *.ispac | ?{$_.Name -cmatch "^$prefix "} | %{
        $project = $_.BaseName.Substring(1 + $prefix.Length)
        Write-Host -ForegroundColor Green "DeploySSISProject -IspacFilePath $($_.Name)"
        Write-Output "`n---`nDeploySSISProject -IspacFilePath $($_.Name)" | Add-Content -Path $LOGPATH
        .\DeploySSISProject.ps1 -IspacFilePath $_.FullName -SsisServer $Server -FolderName "$folder" -ProjectName "$project" -EnvironmentName "$project"
        if ($LASTEXITCODE -gt 0) {exit $LASTEXITCODE}
    }
}

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH