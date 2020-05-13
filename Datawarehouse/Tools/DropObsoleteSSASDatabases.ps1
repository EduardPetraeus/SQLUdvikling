PARAM(
    [string]$Server = "."
)

$databases =
    "Produktionstal",
    "Egne Produktionstal"

# This will exit the script with return code 1 if something bad happens
# Without this block, the exit code is always 0
trap {
    $ErrorActionPreference = "continue"
    write-error -ErrorRecord $_
    Stop-Transcript
    exit 1
}
$ErrorActionPreference = "Stop"

$Server = $Server.Replace(".\", $env:COMPUTERNAME + "\")

Start-Transcript -Path "$PSScriptRoot\DropObsoleteSSASDatabases.log" -Append -Force

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_05_Databank-DZ_SSAS_DropObsoleteSSASDatabases_ps1.log"

$databases | %{
    Write-Output "Deleting database $_" | Tee-Object $LOGPATH -Append
    "{
    `"delete`": {
        `"object`": {
        `"database`": `"$_`"
        }
    }
    }" | Out-File $PSScriptRoot\deletedb.json

    $result = Invoke-ASCmd -server $server -InputFile $PSScriptRoot\deletedb.json
    Write-Output $result | Add-Content -Path $LOGPATH
}

Stop-Transcript
