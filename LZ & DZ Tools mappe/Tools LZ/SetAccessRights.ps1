#Variabel brugernavn alt efter hostame
$UserName = If    ((Hostname) -like "Bmat-Dbank-t*") {"PROD\F005492"}
			elseif ((Hostname) -eq "BMAT-LZSQL-PP01") {"PROD\F005489"}
			elseif ((Hostname) -eq "BMAT-LZSQL-P01") {"PROD\F005483"}
			elseif ((Hostname) -like "at-pbi*") {"NCART\SPFARM_TEST"} 
			else   {"NT SERVICE\SQLSERVERAGENT"}

#Sti til folder

$Sti =  If    ((Hostname) -like "Bmat*") {"E:\CSV"}
        else   {"C:\CSV"}

$LOGFOLDER = Join-Path -Path $PSScriptRoot -ChildPath ".." | Join-Path -ChildPath "LOGS"
$LOGPATH = Join-Path -Path $LOGFOLDER -ChildPath "LOG_05_Databank-LZ_SSIS_SetAccessRights_ps1.log"

#Lav folder hvis den ikke findes
New-Item -ItemType Directory -Force -Path $($Sti) -Verbose | Add-Content -Path $LOGPATH

#giv 'Full access' til folderen inkl. evt. underfoldere for brugeren
&icacls $sti /Grant "$($UserName):(OI)(CI)(F)" /t /c *>&1 | Tee-Object $LOGPATH -Append

(Get-Content $LOGPATH) -replace "`0", "" | Set-Content $LOGPATH
(Get-Content $LOGPATH) | ? {$_.trim() -ne "" } | Set-Content $LOGPATH