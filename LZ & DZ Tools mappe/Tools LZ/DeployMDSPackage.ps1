PARAM(
    [string]$PackageFile = $(throw "PackageFile was not specified"),
	[string]$Server = "."
)

. $PSScriptRoot\Invoke-Sqlcmd2.ps1

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_07_Databank-LZ_MDS_DeployAllMDSPackages_ps1.log"

$Package 		= Get-Item -Path $PackageFile
$PackageName 		= $Package.FullName
$Modelname		= $Package.BaseName
$MDSModelExists 	= (Invoke-Sqlcmd2 -ServerInstance $Server -Database "Master Data Services" -Query "select Count(*) from mdm.tblmodel where name = '$($ModelName)'").Column1
$Service		= If ($Server -eq "AT-PBI-U2\SPOR1")  {"MDS1"}
					elseif ($Server -eq "AT-PBI-U2\SPOR2") {"MDS2"}
					elseif ($Server -eq "AT-PBI-U2\SPOR3") {"MDS3"}
					elseif ($Server -eq "AT-PBI-U2\SPOR4") {"MDS4"} 
					elseif ($Server -eq "AT-PBI-U1\SPOR1") {"MDS1"}
					elseif ($Server -eq "AT-PBI-U1\SPOR2") {"MDS2"}
					elseif ($Server -eq "AT-PBI-U1\SPOR3") {"MDS3"}
					elseif ($Server -eq "AT-PBI-U1\SPOR4") {"MDS4"}
					else {"MDS1"} 



Write-Output "Deploying model $Modelname with on $Server with Service = $Service" | Tee-Object $LOGPATH -Append

if ($MDSModelExists -eq 0)
{
	# MDSModelDeploy deployclone (beholder ID fra XML fil)
	Write-Output "Deploying model '$Modelname' to service '$Service'" | Tee-Object $LOGPATH -Append
	&.\Pakker\MDSModelDeploy.exe deployclone -package $($PackageName) -Service $Service *>&1 | Tee-Object $LOGPATH -Append
}
Else
{
	# MDSModelDeploy deployupdate
	Write-Output "Updating model '$Modelname' to Service '$Service')  on service '$Service'" | Tee-Object $LOGPATH -Append
	&.\Pakker\MDSModelDeploy.exe deployupdate -package $($PackageName) -Version VERSION_1 -Service $Service *>&1 | Tee-Object $LOGPATH -Append
}

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH
if (cat $LOGPATH | Select-String -Pattern "MDSModelDeploy operation failed."){
	Write-Output "MDSModelDeploy.exe melder: 'MDSModelDeploy operation failed.'. Eksekveringen af scriptet stopper." | Tee-Object $LOGPATH -Append;
	Exit(1)
}