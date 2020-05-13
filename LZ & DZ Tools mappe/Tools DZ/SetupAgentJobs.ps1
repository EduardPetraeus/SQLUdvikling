PARAM(
    [string]$ServerInstance = "."
)

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_07_Databank-DZ_SqlAgent_SetupAgentJobs_ps1.log"

get-item *.sql | %{
    Write-Host -ForegroundColor Green "Executing script: $($_.Name)"
    Write-Output "Executing script: $($_.Name)" | Add-Content -Path $LOGPATH
    Invoke-Sqlcmd -InputFile $_.FullName -ServerInstance $ServerInstance -ErrorAction Stop *>&1 -DisableVariables | Tee-Object $LOGPATH -Append
}
