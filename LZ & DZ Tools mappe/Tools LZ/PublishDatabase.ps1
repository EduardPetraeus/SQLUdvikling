PARAM(
    [string]$DacpacFile = $(throw "DacpacFile was not specified"),
    [string]$Server = ".",
    [string]$SqlPackage = "",
    [string]$Database = "",
    [switch]$DropObjectsNotInSource
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

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_02_Databank-LZ_Database_PublishAllDatabases_ps1.log"
$DIAGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_02_Databank-LZ_Database_PublishAllDatabases_ps1_diag.log"

Start-Transcript -Path "$PSScriptRoot\PublishDatabase.log" -Append -Force

$SqlPackage = "${PSScriptRoot}\..\Databank Tools\SqlPackage\sqlpackage.exe" 

if(!(Test-Path -Path $SqlPackage)){
    Write-Error "sqlpackage.exe was not found"
}

$Dacpac = Get-Item -Path $DacpacFile
$sourceDir = $Dacpac.Directory
if(!$Database){
    $database = $Dacpac.BaseName
}

$predeployScript = "$sourceDir\predeploy.sql"

# Unzip the predeploy script, if one exists
if(Test-Path -Path $predeployScript){
    Remove-Item -Path $predeployScript
}

Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($DacpacFile)
$zip.Entries | ?{$_.Name -eq 'predeploy.sql'} | %{[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $predeployScript, $true)}
$zip.Dispose()

if(Test-Path -Path $predeployScript){
    $dbid = (Invoke-Sqlcmd -ServerInstance $Server -Database master -Query "SELECT DB_ID('$database')" -ErrorAction Stop).Column1

    if($dbid -isnot [DBNull]){
        Write-Output "Executing predeploy script on $database" | Tee-Object $LOGPATH -Append
        Invoke-Sqlcmd -InputFile $predeployScript -ServerInstance $Server -Database $database -ErrorAction Stop *>&1 | Tee-Object $LOGPATH -Append
    }
    else{
        Write-Output "Creating $database" | Tee-Object $LOGPATH -Append
    }
}

$profile = "$($Dacpac.BaseName).publish.xml"

if (Test-Path -Path $profile) {
    $profile = Get-Item $profile
    Write-Output "Profil: $profile" | Tee-Object $LOGPATH -Append
    # Det er ikke muligt at fange errorstream til fil eller variabel. Det kommer kun i konsollen.
    $RawOut = & $SqlPackage /action:publish /sourcefile:"$DacpacFile" /targetservername:$Server /targetdatabasename:"$database" /p:DropObjectsNotInSource="$($DropObjectsNotInSource.ToString())" /p:IncludeCompositeObjects=True /pr:$Profile /DiagnosticsFile:$DIAGPATH
    If ($LASTEXITCODE -gt 0) {
        Write-Output $RawOut | Tee-Object $LOGPATH -Append
        Write-Output "`nError: LASTEXITCODE=$LASTEXITCODE for $DacpacFile" | Tee-Object $LOGPATH -Append
        Write-Output "Diagnostik log kan findes i filen: $LOGPATH`n" | Tee-Object $LOGPATH -Append
        $ERR = Get-Content $DIAGPATH
        Add-Content -Path $LOGPATH -Value $ERR
        exit $LASTEXITCODE
    }
    Write-Output $RawOut | Tee-Object $LOGPATH -Append
}
else{
    Write-Output "Ingen Profil: $profile" | Tee-Object $LOGPATH -Append
    # Det er ikke muligt at fange errorstream til fil eller variabel. Det kommer kun i konsollen.
    $RawOut = & $SqlPackage /action:publish /sourcefile:"$DacpacFile" /targetservername:$Server /targetdatabasename:"$database" /p:DropObjectsNotInSource="$($DropObjectsNotInSource.ToString())" /p:IncludeCompositeObjects=True /DiagnosticsFile:$DIAGPATH
    If ($LASTEXITCODE -gt 0) {
        Write-Output $RawOut | Tee-Object $LOGPATH -Append
        Write-Output "`nError: LASTEXITCODE=$LASTEXITCODE for $DacpacFile" | Tee-Object $LOGPATH -Append
        Write-Output "Diagnostik log kan findes i filen: $LOGPATH`n" | Tee-Object $LOGPATH -Append
        $ERR = Get-Content $DIAGPATH
        Add-Content -Path $LOGPATH -Value $ERR
        exit $LASTEXITCODE
    }
    Write-Output $RawOut | Tee-Object $LOGPATH -Append
}

Remove-Item $DIAGPATH
Stop-Transcript
