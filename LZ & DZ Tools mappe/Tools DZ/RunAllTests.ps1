PARAM(
    [string]$Server = "."
)

. $PSScriptRoot\Invoke-Sqlcmd2.ps1

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_08_Databank-DZ_Database_RunAllTests_ps1.log"

$databases = Invoke-Sqlcmd2 -ServerInstance $Server -Database master -Query "SELECT name FROM sys.databases" -As DataRow

# Run tests in all databases with an associated test project
$databases.name | %{
    Write-Host -ForegroundColor Gray "Looking for tSQLt in the '$_' database"
    Write-Output "Looking for tSQLt in the '$_' database" | Add-Content -Path $LOGPATH
    $objectId = (Invoke-Sqlcmd2 -ServerInstance $Server -Database $_ -Query "SELECT objectId = OBJECT_ID('tSQLt.RunTestClass')" -Verbose).objectId

    if(($objectId -is [dbnull]) -eq $false){
        Write-Host -ForegroundColor Green "Running all tests in the '$_' database"
        Write-Output "Running all tests in the '$_' database" | Add-Content -Path $LOGPATH
        Invoke-Sqlcmd2 -ServerInstance $Server -Database $_ -Query "EXEC [tSQLt].[RunTestClass] 'test_Objekt_DZ'" -Verbose *>&1 | Tee-Object $LOGPATH -Append
        [xml]$logOutput = -join (Invoke-Sqlcmd2 -ServerInstance $Server -Database $_ -Query "SET NOCOUNT ON;EXEC tSQLt.XmlResultFormatter").ItemArray
        $logOutput.Save("$PSScriptRoot\test.$_.xml")
    }
}

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
