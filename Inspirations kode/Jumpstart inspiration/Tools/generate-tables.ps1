# Example script illustrating how to generate Extract and Archive tables corresponding to a set of source tables in an SQL Server database
# Modify the following parameters to suit your needs, then run the script from the solution root directory, e.g. using PowerShell ISE
PARAM(
    [string]$OutDir = "Data Warehouse",							# Where to put the generated files, relative to current location
    [string]$SourceName = "AdventureWorks2014",					# The name of the source system, used as prefix for the generated tables
    [string]$ServerInstance = "imnetc01.cloudapp.net,57500",	# SQL Server host\instance
    [string]$Database = "AdventureWorks2014",					# Name of source database
    [string]$Schema = "Purchasing",								# Name of source schema
    [string]$Namepattern = "^(Product)?Vendor|PurchaseOrder(Detail|Header)$",	# A regex pattern that defines which tables to create
    [string]$Username = "imuser",								# User name (assuming SQL Server authentication)
    [string]$Password = "NetC2015"								# Password (assuming SQL Server authentication)
)

# This will exit the script with return code 1 if something bad happens
# Without this block, the exit code is always 0
trap{
	$errorActionPreference = "continue"
	write-error -ErrorRecord $_
#	Stop-Transcript
    exit 1
}

& .\Tools\generate-extract-tables.ps1 -OutDir "$OutDir\Extract" -SourceName $SourceName -ServerInstance $ServerInstance -Database $Database -Schema $Schema -Namepattern $Namepattern -Username $Username -Password $Password
& .\Tools\generate-archive-tables.ps1 -OutDir "$OutDir\Archive" -SourceName $SourceName -ServerInstance $ServerInstance -Database $Database -Schema $Schema -Namepattern $Namepattern -Username $Username -Password $Password