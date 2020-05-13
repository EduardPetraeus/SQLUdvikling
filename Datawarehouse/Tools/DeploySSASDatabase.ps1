PARAM(
    [string]$DatabaseFile = $(throw "DatabaseFile was not specified"),
    [string]$Server = ".",
    [switch]$CleanInstall = $false
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
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_06_Databank-DZ_SSAS_DeployAllSSASDatabases_ps1.log"

$fileInfo = Get-Item $DatabaseFile
$sourceDir = $fileInfo.Directory
$projectName = $fileInfo.BaseName
$DatabaseFilePath = $fileInfo.FullName
$Server = $Server.Replace(".\", $env:COMPUTERNAME + "\")

Start-Transcript -Path "$sourceDir\Deploy.log" -Append -Force

if($CleanInstall){
    Write-Output "Deleting database $projectName" | Tee-Object $LOGPATH -Append
    "{
    `"delete`": {
        `"object`": {
        `"database`": `"$projectName`"
        }
    }
    }" | Out-File $sourceDir\deletedb.json

    $result = Invoke-ASCmd -server $server -InputFile $sourceDir\deletedb.json
    Write-Output $result | Add-Content -Path $LOGPATH
}

# Insert the instance name in the deploymenttargets file
[xml]$deploymenttargets = Get-Content "$sourceDir\$projectName.deploymenttargets" -Encoding UTF8
$deploymenttargets.DeploymentTarget.Server = $Server
$deploymenttargets.Save("$sourceDir\$projectName.deploymenttargets")

# Generate deploy script
Write-Output "Deploying SSAS tabular project" | Tee-Object $LOGPATH -Append
& "Microsoft.AnalysisServices.Deployment.exe" "$DatabaseFilePath" /o:"$sourceDir\$($projectName).Deploy.json" *>&1 | Tee-Object $LOGPATH -Append
(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH

# Execute deploy script
$result = Invoke-ASCmd -Server $Server -InputFile "$sourceDir\$($projectName).Deploy.json"

if (([xml]$result).return.root.ChildNodes.Count -gt 0) {
    Write-Error  ([xml]$result).return.root.Messages.Error.Description *>&1 | Tee-Object $LOGPATH -Append
    (Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
    (Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
    throw ([xml]$result).return.root.Messages.Error.Description
}

# Generate post-deploy script
$configFile = "$sourceDir\$($projectName).config.json"
$templateFile = "$sourceDir\$($projectName).PostDeploy.template.json"

Write-Output "Searching for template file: $templateFile" | Tee-Object $LOGPATH -Append
Write-Output "Searching for config file: $configFile" | Tee-Object $LOGPATH -Append

if ((Test-Path $configFile) -and (Test-Path $templateFile)) {
    Write-Output "Generating PostDeploy script" | Tee-Object $LOGPATH -Append

    # Determine the current environment based on domain and computer name
    $environments = @{nclan = "dev"; ncart = "ncart"; prod = "sit"}
    $currentEnvironment = $environments[$env:USERDOMAIN]

    if ($currentEnvironment -eq "ncart") {
        $environments = @{
            "AT-PBI-U1\Spor1" = "dev1";
            "AT-PBI-U1\Spor2" = "dev2";
            "AT-PBI-U1\Spor3" = "dev3";
            "AT-PBI-U1\Spor4" = "dev4";
            "AT-PBI-U2\Spor1" = "stg1";
            "AT-PBI-U2\Spor2" = "stg2";
            "AT-PBI-U2\Spor3" = "stg3";
            "AT-PBI-U2\Spor4" = "stg4"
        }
        $currentEnvironment = $environments[$Server]

        if($currentEnvironment -eq $null){
            $currentEnvironment = "dev"
        }
    }

    if ($currentEnvironment -eq "sit") {
        $environments = @{
            T01  = "t1"; 
            T02  = "t2"; 
            T03  = "t3"; 
            PP01 = "pp"; 
            P01  = "prod"
        }
        $currentEnvironment = $environments[$env:COMPUTERNAME.Split("-")[-1]]
    }

    Write-Output "Current environment: $currentEnvironment" | Tee-Object $LOGPATH -Append

    # Generate script from template
    $config = Get-Content -Raw $configFile | ConvertFrom-Json
    $template = Get-Content -Raw $templateFile
    $values = $config.Values | Where-Object {$_.Environment -eq $currentEnvironment}

    $values.PSObject.Properties | Where-Object {$_.Name -ne "Environment"} | % {
        Write-Output "$($_.Name)`t: $($_.Value)" | Tee-Object $LOGPATH -Append
        $replacement = $_.Value.Replace('\', '\\')
        $template = $template.Replace('"<<<' + $_.Name + '>>>"', $replacement)
        $template = $template.Replace('<<' + $_.Name + '>>', $replacement)
    }

    $scriptFile = "$sourceDir\$($projectName).PostDeploy.json"
    $template | Out-File $scriptFile

    # Execute script
    Write-Output "Executing post-deploy script: $scriptFile" | Tee-Object $LOGPATH -Append
    [xml]$result = Invoke-ASCmd -Server $Server -InputFile $scriptFile

    if ($result.return.root.ChildNodes.Count -gt 0) {
        $msg = $result.return.root.Messages.Error.Description
        if ($msg) {Write-Output $msg | Tee-Object $LOGPATH -Append; throw $msg}
        else {Write-Output $result | Tee-Object $LOGPATH -Append; throw $result}
    }
}
else{
    throw "ERROR: Config or Template file was missing"
}

Stop-Transcript
