PARAM(
    [string]$Server = ".",
    [switch]$PublishTests = $false
)

# This will exit the script with return code 1 if something bad happens
# Without this block, the exit code is always 0
trap {
    $ErrorActionPreference = "continue"
    write-error -ErrorRecord $_
    Stop-Transcript
    exit 1
}
$ErrorActionPreference = "Stop"

Start-Transcript -Path "$PSScriptRoot\PublishAllDatabases.log" -Append -Force

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_02_Databank-LZ_Database_PublishAllDatabases_ps1.log"
Write-Output "Publicerer alle Databaser" | Set-Content -Path $LOGPATH

# Publish all databases except system and test databases
get-item *.dacpac | 
    ?{$_.Name -inotin "master.dacpac", "SSISDB.dacpac"} | 
    ?{$_.Name -inotlike "Test *.dacpac"} | 
    %{
        Write-Host -ForegroundColor Green "PublishDatabase -DacpacFile $($_.Name)"
        Write-Output "PublishDatabase -DacpacFile $($_.Name)" | Add-Content -Path $LOGPATH
        .\PublishDatabase.ps1 -DacpacFile $_.FullName -Server $Server
        (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
        (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
        if ($LASTEXITCODE -gt 0) {Stop-Transcript; exit $LASTEXITCODE }
    }

$commonTestProject = (Get-Item "Test Fælles.dacpac").FullName

# Publish all test databases
if($PublishTests){
    get-item *.dacpac | 
        ?{$_.Name -inotin "Test Fælles.dacpac"} | 
        ?{$_.Name -ilike "Test *.dacpac"} | 
        %{
            $database = $_.BaseName.Substring(5)    # Remove "Test " prefix

            Write-Host -ForegroundColor Green "PublishDatabase -DacpacFile `"Test Fælles.dacpac`" -Database $database"
            Write-Output "PublishDatabase -DacpacFile `"Test Fælles.dacpac`" -Database $database" | Add-Content -Path $LOGPATH
            .\PublishDatabase.ps1 -DacpacFile $commonTestProject -Server $Server -Database $database
            (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
            (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
            if ($LASTEXITCODE -gt 0) {Stop-Transcript; exit $LASTEXITCODE }

            Write-Host -ForegroundColor Green "PublishDatabase -DacpacFile $($_.Name) -Database $database"
            Write-Output "PublishDatabase -DacpacFile $($_.Name) -Database $database" | Add-Content -Path $LOGPATH
            .\PublishDatabase.ps1 -DacpacFile $_.FullName -Server $Server -Database $database
            (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
            (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
            if ($LASTEXITCODE -gt 0) {Stop-Transcript; exit $LASTEXITCODE }
        }
}

Stop-Transcript