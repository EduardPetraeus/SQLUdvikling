[CmdletBinding()]
Param(
    # IsPacFilePath is required
    [Parameter(Mandatory=$True,Position=1)]
    [string]$IspacFilePath,
    
    # SsisServer is required	
    [Parameter(Mandatory=$True,Position=2)]
    [string]$SsisServer,
    
    # FolderName is required
    [Parameter(Mandatory=$True,Position=3)]
    [string]$FolderName,
    
    # ProjectName is not required
    # If empty filename is used
    [Parameter(Mandatory=$False,Position=4)]
    [string]$ProjectName  = [system.io.path]::GetFileNameWithoutExtension($IspacFilePath),
    
    # EnvironmentName is not required
    # If empty no environment is referenced
    [Parameter(Mandatory=$False,Position=5)]
    [string]$EnvironmentName,
    
    # EnvironmentFolderName is not required
    # If empty the FolderName param is used
    [Parameter(Mandatory=$False,Position=6)]
    [string]$EnvironmentFolderName = $FolderName
)

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_03_Databank-LZ_SSIS_DeployAllSSISProjects_ps1.log"

Write-Output "$(Get-Date -Format g)`tDeploying $ProjectName" | Tee-Object $LOGPATH -Append

# Check if ispac file exists
if (-Not (Test-Path $IspacFilePath))
{
    Throw  [System.IO.FileNotFoundException] "Ispac file $IspacFilePath doesn't exists!"
}
else
{
    $IspacFileName = split-path $IspacFilePath -leaf
    Write-Output "Ispac file" $IspacFileName "found" | Tee-Object $LOGPATH -Append
}

# If the filename and projectname are different
# Then we need to rename the internal projectname
# before deploying it.

# Derive projectname from ISPAC filename
$CurrentProjectName = [system.io.path]::GetFileNameWithoutExtension($IspacFilePath)

# Check if rename is necessary
If (-not($CurrentProjectName -eq $ProjectName))
{
    # Split filepath of ispac file in folder and file
  	$TmpUnzipPath = split-path $IspacFilePath -Parent
    # Determine the filepath of the new ispac file
    $NewIspacFilePath = $TmpUnzipPath + "\" + $ProjectName + ".ispac"
    # Determine the path of the unzip folder
    $TmpUnzipPath = $TmpUnzipPath + "\" + $CurrentProjectName
    
    # Catch unexpected errors and stop script
    Try
    {
        # Check if new ispac already exists
        if (Test-Path $NewIspacFilePath)
        {
            [System.IO.File]::Delete($NewIspacFilePath)
        }

        # Search strings
	    $SearchStringStart = '<SSIS:Property SSIS:Name="Name">'
	    $SearchStringEnd = '</SSIS:Property>'
 
	    # Add reference to compression namespace
	    Add-Type -assembly "system.io.compression.filesystem"

	    # Extract ispac file to temporary location (.NET Framework 4.5) 
	    [io.compression.zipfile]::ExtractToDirectory($IspacFilePath, $TmpUnzipPath)

	    # Replace internal projectname with new projectname
        $EditFile = $TmpUnzipPath + "\@Project.manifest"

        [xml]$manifest = ""; $manifest.Load($EditFile)
        ($manifest.Project.Properties.Property | ?{$_.Name -ceq 'Name'}).'#text' = $ProjectName
        $manifest.Save($EditFile)

	    # Zip temporary location to new ispac file (.NET Framework 4.5) 
	    [io.compression.zipfile]::CreateFromDirectory($TmpUnzipPath, $NewIspacFilePath)

	    # Delete temporary location
	    [System.IO.Directory]::Delete($TmpUnzipPath, $True)

	    # Replace ispac parameter
	    $IspacFilePath = $NewIspacFilePath
    }
    Catch [System.Exception]
    {
        Throw  [System.Exception] "Failed renaming project in $IspacFileName : $_.Exception.Message "
    }
}

# Load the Integration Services Assembly
Write-Output "Connecting to server $SsisServer " | Tee-Object $LOGPATH -Append
$SsisNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
[System.Reflection.Assembly]::LoadWithPartialName($SsisNamespace) | Out-Null;

# Create a connection to the server
$SqlConnectionstring = "Data Source=" + $SsisServer + ";Initial Catalog=master;Integrated Security=SSPI;"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection $SqlConnectionstring

# Create the Integration Services object
$IntegrationServices = New-Object $SsisNamespace".IntegrationServices" $SqlConnection

# Check if connection succeeded
if (-not $IntegrationServices)
{
  Throw  [System.Exception] "Failed to connect to server $SsisServer "
}
else
{
   Write-Output "Connected to server" $SsisServer | Tee-Object $LOGPATH -Append
}

# Create object for SSISDB Catalog
$Catalog = $IntegrationServices.Catalogs["SSISDB"]

# Check if the SSISDB Catalog exists
if (-not $Catalog)
{
    # Catalog doesn't exists. The user should create it manually.
    # It is possible to create it, but that shouldn't be part of
    # deployment of packages.
    Throw  [System.Exception] "SSISDB catalog doesn't exist. Create it manually!"
}
else
{
    Write-Output "Catalog SSISDB found" | Tee-Object $LOGPATH -Append
}

# Create object to the (new) folder
$Folder = $Catalog.Folders[$FolderName]

# Check if folder already exists
if (-not $Folder)
{
    # Folder doesn't exists, so create the new folder.
    Write-Output "Creating new folder" $FolderName | Tee-Object $LOGPATH -Append
    $Folder = New-Object $SsisNamespace".CatalogFolder" ($Catalog, $FolderName, $FolderName)
    $Folder.Create()
}
else
{
    Write-Output "Folder" $FolderName "found" | Tee-Object $LOGPATH -Append
}

# Deploying project to folder
if($Folder.Projects.Contains($ProjectName)) {
    Write-Output "Deploying" $ProjectName "to" $FolderName "(REPLACE)" | Tee-Object $LOGPATH -Append
}
else
{
    Write-Output "Deploying" $ProjectName "to" $FolderName "(NEW)" | Tee-Object $LOGPATH -Append
}
# Reading ispac file as binary
[byte[]] $IspacFile = [System.IO.File]::ReadAllBytes($IspacFilePath)
$Folder.DeployProject($ProjectName, $IspacFile) *>&1 | Tee-Object $LOGPATH -Append
$Project = $Folder.Projects[$ProjectName]
if (-not $Project)
{
    # Something went wrong with the deployment
    # Don't continue with the rest of the script
    return ""
}

# Check if environment name is filled
if (-not $EnvironmentName)
{
    # Kill connection to SSIS
    $IntegrationServices = $null 

    # Stop the deployment script
    Return "Ready deploying $IspacFileName without adding environment references"
}

# Create object to the (new) folder
$EnvironmentFolder = $Catalog.Folders[$EnvironmentFolderName]

# Check if environment folder exists
if (-not $EnvironmentFolder)
{
  Throw  [System.Exception] "Environment folder $EnvironmentFolderName doesn't exist"
}

# Check if environment exists
if(-not $EnvironmentFolder.Environments.Contains($EnvironmentName))
{
    $Environment = New-Object "$SsisNamespace.EnvironmentInfo" -ArgumentList @($EnvironmentFolder, $EnvironmentName, "Environment for the $ProjectName project")
    $Environment.Create()
    #Throw  [System.Exception] "Environment $EnvironmentName doesn't exist in $EnvironmentFolderName "
}
else
{
    # Create object for the environment
    $Environment = $Catalog.Folders[$EnvironmentFolderName].Environments[$EnvironmentName]
}

if ($Project.References.Contains($EnvironmentName, $EnvironmentFolderName))
{
    Write-Output "Reference to" $EnvironmentName "found" | Tee-Object $LOGPATH -Append
}
else
{
    Write-Output "Adding reference to" $EnvironmentName | Tee-Object $LOGPATH -Append
    $Project.References.Add($EnvironmentName, $EnvironmentFolderName)
    $Project.Alter() 
}

$ParameterCount = 0
# Loop through all project parameters
foreach ($Parameter in $Project.Parameters)
{
    # Get parameter name and check if it exists in the environment
    $ParameterName = $Parameter.Name
    if ($ParameterName.StartsWith("CM.","CurrentCultureIgnoreCase")) 
    { 
        # Ignoring connection managers 
    } 
    elseif ($ParameterName.StartsWith("INTERN_","CurrentCultureIgnoreCase")) 
    { 
        # Optional:
        # Internal parameters are ignored (where name starts with INTERN_) 
        Write-Output "Ignoring Project parameter" $ParameterName " (internal use only)" | Tee-Object $LOGPATH -Append
    } 
    elseif ($Environment.Variables.Contains($Parameter.Name))
    {
        $ParameterCount = $ParameterCount + 1
        Write-Output "Project parameter" $ParameterName "connected to environment" | Tee-Object $LOGPATH -Append
        $Project.Parameters[$Parameter.Name].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $Parameter.Name)
        $Project.Alter()
    }
    elseif($Parameter.Required)
    {
        # Variable with the name of the project parameter is not found in the environment
        # Throw an exeception or remove next line to ignore parameter
        Write-Error "Required project parameter $ParameterName doesn't exist in environment"
        Throw  [System.Exception]  "Required project parameter $ParameterName doesn't exist in environment"
    }
}
Write-Output "Number of project parameters mapped:" $ParameterCount | Tee-Object $LOGPATH -Append

$ParameterCount = 0
# Loop through all packages
foreach ($Package in $Project.Packages)
{
    # Loop through all package parameters
    foreach ($Parameter in $Package.Parameters)
    {
        # Get parameter name and check if it exists in the environment
        $PackageName = $Package.Name
        $ParameterName = $Parameter.Name 
        if ($ParameterName.StartsWith("CM.","CurrentCultureIgnoreCase")) 
        { 
            # Ignoring connection managers 
        } 
        elseif ($ParameterName.StartsWith("INTERN_","CurrentCultureIgnoreCase")) 
        { 
            # Optional:
            # Internal parameters are ignored (where name starts with INTERN_) 
            Write-Output "Ignoring Package parameter" $ParameterName " (internal use only)" | Tee-Object $LOGPATH -Append
        } 
        elseif ($Environment.Variables.Contains($Parameter.Name))
        {
            $ParameterCount = $ParameterCount + 1
            Write-Output "Package parameter" $ParameterName "from package" $PackageName "connected to environment" | Tee-Object $LOGPATH -Append
            $Package.Parameters[$Parameter.Name].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $Parameter.Name)
            $Package.Alter()
        }
        elseif($Parameter.Required)
        {
            # Variable with the name of the package parameter is not found in the environment
            # Throw an exeception or remove next line to ignore parameter
            Throw  [System.Exception]  "Required package parameter $ParameterName from package $PackageName doesn't exist in environment"
        }
    }
}
Write-Output "Number of package parameters mapped:" $ParameterCount | Tee-Object $LOGPATH -Append

# Kill connection to SSIS
$IntegrationServices = $null 
Write-Output "$(Get-Date -Format g)`tReady deploying $ProjectName" | Tee-Object $LOGPATH -Append
