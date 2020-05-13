# Get TNS identifier and password from arguments, if specified
if($args.count -gt 0) {
    $tns_identifier = $args[0]
    $Server = $args[1]
} 
else {
    throw "Please enter the TNS identifier for the database"
}

$ErrorActionPreference = "Stop"

#Deploy SQL Scripts
$script = "$PSScriptRoot\DZI\deploy.ps1"
$command = "$script " + "$tns_identifier"
cd DZI
invoke-expression "$command"
cd ..

#Deploy SSAS kuber
$script = "$PSScriptRoot\SSAS\DeployAllSSASDatabases.ps1"
$command = "$script " + "$Server"

cd SSAS
invoke-expression $command
cd..

#Deploy SQL Server Agent jobs 
$script = "$PSScriptRoot\SqlAgent\SetupAgentJobs.ps1"
$command = "$script " + "$Server"
cd SqlAgent
invoke-expression $command
cd..
