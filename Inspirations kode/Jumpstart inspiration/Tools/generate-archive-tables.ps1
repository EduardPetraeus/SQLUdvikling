# Example script illustrating how to generate Archive tables corresponding to a set of source tables in an SQL Server database
# Modify the following parameters to suit your needs, the run the script from the solution root directory, e.g. using PowerShell ISE
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

Import-Module SQLPS -DisableNameChecking

$OutDir = $OutDir.TrimEnd("\")

### Generate table scripts
$tablequery = "
SELECT DISTINCT
    schema_name = a.name,
    table_name  = b.name,
    object_id   = b.object_id,
	target_table_name = REPLACE('$($SourceName)_' + a.name + '_' + b.name, ' ', '')
FROM sys.schemas a
LEFT JOIN sys.objects b
    ON a.schema_id = b.schema_id
WHERE b.type IN ('U', 'V')
    AND a.name = '$Schema'"

$tables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Username $Username -Password $Password -Query $tablequery -MaxCharLength 1e6 | 
	?{$_.table_name -match $Namepattern}


$tables | ?{!(Test-Path -Path "$OutDir\$($_.target_table_name).sql")}| %{
    $columnquery = "
    SELECT
	column_name = c.name,
	column_definition = 
        '[' + c.name + '] ' +        
        CASE
            WHEN d.name IN ('char', 'varchar', 'nchar', 'nvarchar') AND c.max_length < 0 THEN UPPER(d.name) + '(MAX)'
            WHEN d.name IN ('nchar', 'nvarchar') THEN UPPER(d.name) + '(' + CAST(c.max_length / 2 AS NVARCHAR(MAX)) + ')'
			WHEN d.name IN ('char', 'varchar') THEN UPPER(d.name) + '(' + CAST(c.max_length AS NVARCHAR(MAX)) + ')'
            WHEN d.name IN ('decimal', 'numeric') THEN UPPER(d.name) + '(' + CAST(c.precision AS NVARCHAR(MAX)) + ', ' + CAST(c.scale AS NVARCHAR(MAX)) + ')'
			WHEN d.name IN ('timestamp', 'rowversion') THEN 'BINARY(8)'
			WHEN d.name IN ('image') THEN 'VARBINARY(MAX)'
            ELSE UPPER(d.name)
            END +
        CASE ISNULL(c.collation_name, 'NULL') WHEN 'NULL' THEN '' ELSE ' COLLATE ' + c.collation_name END +
        CASE c.is_nullable WHEN 0 THEN ' NOT NULL' ELSE ' NULL' END,
	pk_column = COALESCE(e.index_column_id, 0)
    FROM sys.columns c
    LEFT JOIN sys.systypes d
        ON c.system_type_id = d.xusertype
	LEFT JOIN sys.indexes a
		ON c.object_id = a.object_id
		AND a.is_primary_key = 1
	LEFT JOIN sys.index_columns e
		ON a.object_id = e.object_id
		AND a.index_id = e.index_id
		AND c.column_id = e.column_id
    WHERE c.object_id = $($_.object_id)
    ORDER BY c.column_id"

    $columns = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Username $Username -Password $Password -Query $columnquery -MaxCharLength 1e6)
    
    "CREATE TABLE Archive.$($_.target_table_name) (", 
	"`t/* Business key */",
	"$([string]::Join(",`n", @($columns | ?{$_.pk_column -gt 0} | sort -Property pk_column | %{"`t$($_.column_definition)"}))),", 
	"`n`t/* Attributes */",
	"$([string]::Join(",`n", @($columns | ?{$_.pk_column -eq 0} | %{"`t$($_.column_definition)"}))),", 
	"`n`t/* Metadata */",
    "`t[Meta_Id] BIGINT NOT NULL IDENTITY (1, 1),",
    "`t[Meta_VersionNo] INT NOT NULL,",
    "`t[Meta_ValidFrom] DATETIME NOT NULL,",
    "`t[Meta_ValidTo] DATETIME NULL,",
    "`t[Meta_IsValid] BIT NOT NULL, -- If false rows exists in data validation table",
    "`t[Meta_IsCurrent] BIT NOT NULL,",
    "`t[Meta_IsDeleted] BIT NOT NULL,",
    "`t[Meta_CreateTime] DATETIME NOT NULL,",
    "`t[Meta_CreateJob] BIGINT NOT NULL, -- Reference to the audit framework",
    "`t[Meta_UpdateTime] DATETIME NULL,",
    "`t[Meta_UpdateJob] BIGINT NULL, -- Reference to the audit framework",
    "`t[Meta_DeleteTime] DATETIME NULL,",
    "`t[Meta_DeleteJob] BIGINT NULL, -- Reference to the audit framework",
    "`n`t/* Constraints */",
	"`tCONSTRAINT PK_$($_.target_table_name) PRIMARY KEY CLUSTERED ($(
		[string]::Join(", ", @($columns | ?{$_.pk_column -gt 0} | sort -Property pk_column | %{"[$($_.column_name)]"}))), Meta_ValidFrom)",
	")",
	"GO",
	"`nCREATE UNIQUE INDEX IDX_$($_.target_table_name) ON Archive.$($_.target_table_name) (Meta_Id)",
	"GO" |
	Out-File -Encoding utf8 -FilePath "$OutDir\$($_.target_table_name).sql"
}
