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
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_04_Databank-LZ_SSIS_SetupSSISVariables_ps1.log"
$LOGPATHERR = Join-Path -Path $LOGFOLDER -ChildPath "LOG_04_Databank-LZ_SSIS_SetupSSISVariables_ps1_err.log"

get-item Environments.sql | %{
    Write-Host -ForegroundColor Green "Executing script: $($_.Name)"
    Write-Output "Executing script: $($_.Name)" | Add-Content -Path $LOGPATH
    Invoke-Sqlcmd2 -InputFile $_.FullName -ServerInstance $ServerInstance -Verbose 2>$LOGPATHERR 3>&1 4>&1 5>&1 | Out-String | Tee-Object $LOGPATH -Append
    $ERR = Get-Content $LOGPATHERR
    Write-Output $ERR | Tee-Object $LOGPATH -Append
}

Stop-Transcript

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH

$NRERR = ($ERR | measure-object -line).Lines
if($NRERR -gt 1){
    Write-Output "`nDer er fejl i 'Environments.sql'. Eksekveringen af scriptet stopper." | Tee-Object $LOGPATH -Append
    (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
    (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
    Exit(1)
}