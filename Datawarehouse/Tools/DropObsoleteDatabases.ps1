PARAM(
    [string]$ServerInstance = "."
)

# This will exit the script with return code 1 if something bad happens
# Without this block, the exit code is always 0
trap {
    $ErrorActionPreference = "continue"
    write-error -ErrorRecord $_
    Stop-Transcript
    exit 1
}

Start-Transcript -Path "$PSScriptRoot\Deploy.log" -Append -Force

. $PSScriptRoot\Invoke-Sqlcmd2.ps1

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_01_Databank-DZ_Database_DropObsoleteDatabases_ps1.log"

get-item DropObsoleteDatabases.sql | %{
    Write-Host -ForegroundColor Green "Executing script: $($_.Name)"
    Write-Output "Executing script: $($_.Name)" | Add-Content -Path $LOGPATH
    Invoke-Sqlcmd2 -InputFile $_.FullName -ServerInstance $ServerInstance -Database master -Verbose *>&1 | Tee-Object $LOGPATH -Append
}

Stop-Transcript

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH