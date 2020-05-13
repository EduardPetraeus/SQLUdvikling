SET XACT_ABORT ON
SET NOCOUNT ON

IF OBJECT_ID('tempdb..#Variables') IS NOT NULL
    DROP TABLE #Variables

IF OBJECT_ID('tempdb..#ConnectionStrings') IS NOT NULL
    DROP TABLE #ConnectionStrings

CREATE TABLE #Variables(
    ServerEnvironment sysname,
    folder sysname,
    environment sysname,
    parameter sysname,
    variable sysname,
    type nvarchar(128),
    value nvarchar(128),
    sensitive bit
)

CREATE TABLE #ConnectionStrings(
    environment sysname,
    folder sysname,
    project sysname,
    connection sysname,
    connectionString nvarchar(500)
)

CREATE TABLE #VariablesToDelete (
    folder sysname,
    environment sysname,
     variable sysname
);

CREATE TABLE #ProjectsToDelete (
    folder sysname,
    project sysname
);

----------------------------------------
-- Bestemmelse af det aktuelle miljø
DECLARE @environment SYSNAME =
CASE
    WHEN @@SERVERNAME LIKE 'BMAT-%-P0_' THEN N'PROD'
	WHEN @@SERVERNAME LIKE 'BMAT-%-PP0_' THEN N'PP'
	WHEN @@SERVERNAME LIKE 'BMAT-%-T01' THEN N'T1'
	WHEN @@SERVERNAME LIKE 'BMAT-%-T02' THEN N'T2'
	WHEN @@SERVERNAME LIKE 'BMAT-%-T03' THEN N'T3'
	WHEN @@SERVERNAME LIKE 'AT-PBI-U_\SPOR_' THEN N'STG' + RIGHT(@@SERVICENAME, 1)
	ELSE N'DEV'
END

DECLARE @msg NVARCHAR(200) = 'Aktuelt miljø: ' + @environment
RAISERROR (@msg, 0, 1) WITH NOWAIT

----------------------------------------
-- Oprydning i projekter som ikke længere bruges
--INSERT INTO #ProjectsToDelete (folder, project)
--VALUES
--    (N'Distributionszone', N'Metadatamodellen')

------------------------------------------
---- Oprydning i variabler som ikke længere bruges
--INSERT INTO #VariablesToDelete (folder, environment, variable)
--VALUES (N'Distributionszone', N'DM', N'SharePoint_Url')

-- Her defineres alle miljøvariabler
-- OBS! Passwords skal defineres manuelt i SIT miljøerne, de værdier der står herunder er default som kun gælder i NCART miljøet (de er sat ind a.h.t. Jenkins)
--INSERT INTO #Variables
--    (ServerEnvironment, folder, environment, parameter, variable, type, value, sensitive)
--VALUES
--    (N'DEV',              N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'STG1',             N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'STG2',             N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'STG3',             N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'STG4',             N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'T1',               N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'T2',               N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'T3',               N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'PP',               N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
--	(N'PROD',             N'Distributionszone',   N'DM',       N'Pwd_AT6_DM',             N'Pwd-AT6_DM',           N'String', N'AT6_DM',  1),
	
--    (N'DEV',              N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/',         0),
--	(N'STG1',             N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/',         0),
--	(N'STG2',             N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/',         0),
--	(N'STG3',             N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/',         0),
--	(N'STG4',             N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/',         0),
--	(N'T1',               N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://gotest-t1.at.dk/sites/metadatamodellen/',                       0), 
--	(N'T2',               N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://gotest-t2.at.dk/sites/metadatamodellen/',                       0),
--	(N'T3',               N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://gotest-t3.at.dk/sites/metadatamodellen/',                       0),
--	(N'PP',               N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://gopre-pp.at.dk/sites/metadatamodellen/',                        0),
--	(N'PROD',             N'Distributionszone',   N'DM',       N'SharePointSiteUrl',      N'SharePointSiteUrl',    N'String', N'https://go.at.dk/sites/metadatamodellen/',                              0),
	
--	(N'DEV',              N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'STG1',             N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'STG2',             N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'STG3',             N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'STG4',             N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'T1',               N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'T2',               N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'T3',               N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'PP',               N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
--	(N'PROD',             N'Distributionszone',   N'Direktionsrapportering',  N'Pwd_DZI', N'Pwd-DZI',              N'String', N'dzi',  1),
	
--	(N'DEV',              N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'STG1',             N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'STG2',             N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'STG3',             N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'STG4',             N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'T1',               N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'T2',               N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'T3',               N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'PP',               N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
--	(N'PROD',             N'Distributionszone',   N'DM',       N'Pwd_DZI',                 N'Pwd-DZI',             N'String', N'dzi',  1),
	
--    (N'DEV',              N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--    (N'STG1',             N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--    (N'STG2',             N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--    (N'STG3',             N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--	(N'STG4',             N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--	(N'T1',               N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--	(N'T2',               N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--	(N'T3',               N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--	(N'PP',               N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1),
--	(N'PROD',             N'Distributionszone',   N'DM',       N'Pwd_AT0_DWH',             N'Pwd-AT0-DWH',         N'String', N'AT0_DWH',     1)
	
	
-- Her defineres alle miljøspecifikke connection strings
-- OBS: "Integrated Security=True" fungerer ikke for OLEDB connections. Her bruges i stedet "Integrated Security=SSPI"
INSERT INTO #ConnectionStrings
    (environment, folder, project, connection, connectionString)
VALUES

-- DM
 --   (N'DEV',            N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT6_DM'),
 --   (N'STG1',           N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT6_DM'),
 --   (N'STG2',           N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=NCAT-DW-U2.DWPROD;USERNAME=AT6_DM'),
 --   (N'STG3',           N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=NCAT-DW-U3.DWPROD;USERNAME=AT6_DM'),
 --   (N'STG4',           N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT6_DM'),
	--(N'T1',             N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=BMATDW;USERNAME=AT6_DM'),
	--(N'T2',             N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=BMATDW;USERNAME=AT6_DM'),
	--(N'T3',             N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=BMATDW;USERNAME=AT6_DM'),
	--(N'PP;PROD',        N'Distributionszone',   N'DM', N'MSORA AT6_DM',  N'SERVER=BMATDW;USERNAME=AT6_DM'),

 --   (N'DEV',            N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=DZI_Direktionsrapportering'),
 --   (N'STG1',           N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=DZI_Direktionsrapportering'),
 --   (N'STG2',           N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=NCAT-DW-U2.DWPROD;USERNAME=DZI_Direktionsrapportering'),
 --   (N'STG3',           N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=NCAT-DW-U3.DWPROD;USERNAME=DZI_Direktionsrapportering'),
 --   (N'STG4',           N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=DZI_Direktionsrapportering'),
	--(N'T1',             N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=BMATDW;USERNAME=DZI_Direktionsrapportering'),
	--(N'T2',             N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=BMATDW;USERNAME=DZI_Direktionsrapportering'),
	--(N'T3',             N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=BMATDW;USERNAME=DZI_Direktionsrapportering'),
	--(N'PP;PROD',        N'Distributionszone',   N'DM', N'MSORA DZI',  N'SERVER=BMATDW;USERNAME=DZI_Direktionsrapportering'),
	
	--(N'DEV',            N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT0_DWH'),
 --   (N'STG1',           N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT0_DWH'),
 --   (N'STG2',           N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=NCAT-DW-U2.DWPROD;USERNAME=AT0_DWH'),
 --   (N'STG3',           N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=NCAT-DW-U3.DWPROD;USERNAME=AT0_DWH'),
 --   (N'STG4',           N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT0_DWH'),
	--(N'T1',             N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=BMATDW;USERNAME=AT0_DWH'),
	--(N'T2',             N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=BMATDW;USERNAME=AT0_DWH'),
	--(N'T3',             N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=BMATDW;USERNAME=AT0_DWH'),
	--(N'PP;PROD',        N'Distributionszone',   N'DM', N'MSORA DW AT0_DWH',  N'SERVER=BMATDW;USERNAME=AT0_DWH'),
	
    (N'DEV',            N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
    (N'STG1',           N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.\spor1;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
    (N'STG2',           N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.\spor2;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
    (N'STG3',           N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.\spor3;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
    (N'STG4',           N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.\spor4;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
	(N'T1',             N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
	(N'T2',             N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
	(N'T3',             N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
	(N'PP;PROD',        N'Salg',   N'Salg', N'OLEDB Salg',  N'Data Source=.;Initial Catalog=Salg;Provider=SQLNCLI11.1;Integrated Security=SSPI;'),
	
	(N'DEV',            N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'STG1',           N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'STG2',           N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'STG3',           N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'STG4',           N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1',             N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T2',             N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T3',             N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'PP;PROD',        N'Salg',   N'Salg', N'ADO NET LZDB',  N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
     
	(N'DEV',            N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'STG1',           N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.\Spor1;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'STG2',           N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.\Spor2;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'STG3',           N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.\Spor3;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'STG4',           N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.\Spor4;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'T1',             N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'T2',             N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'T3',             N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.;Initial Catalog=Salg;Integrated Security=SSPI;'),
	(N'PP;PROD',        N'Salg',   N'Salg', N'ADO NET Salg',  N'Data Source=.;Initial Catalog=Salg;Integrated Security=SSPI;')
	
   

---- Kuber
--    (N'DEV',            N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.;Initial Catalog=DZDB;Integrated Security=SSPI;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.\Spor1;Initial Catalog=DZDB;Integrated Security=SSPI;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.\Spor2;Initial Catalog=DZDB;Integrated Security=SSPI;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.\Spor3;Initial Catalog=DZDB;Integrated Security=SSPI;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.\Spor4;Initial Catalog=DZDB;Integrated Security=SSPI;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.;Initial Catalog=DZDB;Integrated Security=SSPI;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.;Initial Catalog=DZDB;Integrated Security=SSPI;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.;Initial Catalog=DZDB;Integrated Security=SSPI;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'ADO NET DZDB',  N'Data Source=.;Initial Catalog=DZDB;Integrated Security=SSPI;'),

--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.\Spor1;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.\Spor2;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.\Spor3;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.\Spor4;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'), 
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'), 
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'), 
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	                                                                                             
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.\Spor1;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.\Spor2;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.\Spor3;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.\Spor4;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Forudsætningsoverblik',  N'Data Source=.;Initial Catalog=Forudsætningsoverblik;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),	
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.\Spor1;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.\Spor2;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.\Spor3;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.\Spor4;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP GK Erhvervssygdomme',  N'Data Source=.;Initial Catalog=GK Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),	
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.\Spor1;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.\Spor2;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.\Spor3;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.\Spor4;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Medarbejderaktiviteter',  N'Data Source=.;Initial Catalog=Medarbejderaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.\Spor1;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.\Spor2;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.\Spor3;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.\Spor4;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Erhvervssygdomme',  N'Data Source=.;Initial Catalog=Public_Erhvervssygdomme;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.\Spor1;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.\Spor2;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.\Spor3;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.\Spor4;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Tilsyn',  N'Data Source=.;Initial Catalog=Public_Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.\Spor1;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.\Spor2;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.\Spor3;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.\Spor4;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykke',  N'Data Source=.;Initial Catalog=Public_Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.\Spor1;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.\Spor2;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.\Spor3;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.\Spor4;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Public_Ulykker_Aktuelle_Tal',  N'Data Source=.;Initial Catalog=Public_Ulykker_Aktuelle_Tal;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),	
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.\Spor1;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.\Spor2;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.\Spor3;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.\Spor4;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Tidsregistrering',  N'Data Source=.;Initial Catalog=Tidsregistrering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.\Spor1;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.\Spor2;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.\Spor3;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.\Spor4;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsaktiviteter',  N'Data Source=.;Initial Catalog=Tilsynsaktiviteter;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.\Spor1;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.\Spor2;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.\Spor3;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.\Spor4;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Tilsynsreaktioner',  N'Data Source=.;Initial Catalog=Tilsynsreaktioner;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),	
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.\Spor1;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.\Spor2;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.\Spor3;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.\Spor4;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke Kvotering',  N'Data Source=.;Initial Catalog=Ulykke Kvotering;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.\Spor1;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.\Spor2;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.\Spor3;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.\Spor4;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Ulykke',  N'Data Source=.;Initial Catalog=Ulykke;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
	
--	(N'DEV',            N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG1',           N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.\Spor1;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG2',           N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.\Spor2;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),  
--	(N'STG3',           N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.\Spor3;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'STG4',           N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.\Spor4;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T1',             N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'), 
--	(N'T2',             N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'T3',             N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;'),
--	(N'PP;PROD',        N'Distributionszone',   N'Kuber',   N'MSOLAP Virksomheder - Tilsyn',  N'Data Source=.;Initial Catalog=Virksomheder - Tilsyn;Provider=MSOLAP.8;Integrated Security=SSPI;Impersonation Level=Impersonate;')

----------------------------------------
-- Oprydning i projekter og miljøer
DECLARE @folder sysname
DECLARE @project sysname

DECLARE c CURSOR FOR  
SELECT DISTINCT
    c.folder,
    c.project
FROM SSISDB.catalog.folders a
INNER JOIN SSISDB.catalog.projects b
    ON a.folder_id = b.folder_id
INNER JOIN #ProjectsToDelete c
    ON a.name = c.folder COLLATE Danish_Norwegian_CI_AS
    AND b.name = c.project COLLATE Danish_Norwegian_CI_AS

OPEN c
FETCH NEXT FROM c INTO @folder, @project

WHILE @@FETCH_STATUS = 0   
BEGIN
    SET @msg = 'Sletter projekt: ' + @folder + '\' + @project
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXECUTE [SSISDB].[catalog].[delete_project] @project_name = @project, @folder_name = @folder
    FETCH NEXT FROM c INTO @folder, @project
END   

CLOSE c
DEALLOCATE c

DECLARE c CURSOR FOR  
SELECT DISTINCT
    c.folder,
    c.project
FROM SSISDB.catalog.folders a
INNER JOIN SSISDB.catalog.environments b
    ON a.folder_id = b.folder_id
INNER JOIN #ProjectsToDelete c
    ON a.name = c.folder COLLATE Danish_Norwegian_CI_AS
    AND b.name = c.project COLLATE Danish_Norwegian_CI_AS

OPEN c
FETCH NEXT FROM c INTO @folder, @project

WHILE @@FETCH_STATUS = 0   
BEGIN
    SET @msg = 'Sletter miljø: ' + @folder + '\' + @project
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXECUTE [SSISDB].[catalog].[delete_environment] @environment_name = @project, @folder_name = @folder
    FETCH NEXT FROM c INTO @folder, @project
END   

CLOSE c
DEALLOCATE c

----------------------------------------
-- Oprydning i variabler
DECLARE @environmentName sysname
DECLARE @variable sysname

DECLARE c CURSOR FOR  
SELECT DISTINCT
    d.folder,
    d.environment,
    d.variable
FROM SSISDB.catalog.environment_variables a
INNER JOIN SSISDB.catalog.environments b
    ON a.environment_id = b.environment_id
INNER JOIN ssisdb.catalog.folders c
    ON b.folder_id = c.folder_id
INNER JOIN #VariablesToDelete d
    ON c.name = d.folder COLLATE Danish_Norwegian_CI_AS
        AND b.name = d.environment COLLATE Danish_Norwegian_CI_AS
        AND a.name = d.variable COLLATE Danish_Norwegian_CI_AS

OPEN c
FETCH NEXT FROM c INTO @folder, @environmentName, @variable

WHILE @@FETCH_STATUS = 0   
BEGIN
    SET @msg = 'Sletter variabel: ' + @folder + '\' + @environmentName + '\' + @variable
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXECUTE [SSISDB].[catalog].[delete_environment_variable]
        @variable_name = @variable,
        @environment_name = @environmentName,
        @folder_name = @folder

    FETCH NEXT FROM c INTO @folder, @environmentName, @variable
END   

CLOSE c
DEALLOCATE c

----------------------------------------
-- Oprettelse af miljøer

DECLARE c CURSOR FOR  
SELECT DISTINCT folder, environment
FROM #Variables
WHERE NOT EXISTS (
    SELECT * 
    FROM SSISDB.catalog.folders a
    INNER JOIN SSISDB.catalog.environments b
        ON a.folder_id = b.folder_id 
    WHERE a.name = folder COLLATE Danish_Norwegian_CI_AS
        AND b.name = environment COLLATE Danish_Norwegian_CI_AS
)

OPEN c
FETCH NEXT FROM c INTO @folder, @environmentName

WHILE @@FETCH_STATUS = 0   
BEGIN
    SET @msg = 'Opretter miljø: ' + @folder + '\' + @environmentName
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXECUTE [SSISDB].[catalog].[create_environment]
        @environment_name = @environmentName,
        @folder_name = @folder

    FETCH NEXT FROM c INTO @folder, @environmentName
END   

CLOSE c
DEALLOCATE c

-- Opdatering af eksisterender miljøvariabler, hvis de ikke er sensitive. 
-- Sensitive variabler overskrives ikke, men skal oprettes og vedligeholdes v.h.a. release opgave

DECLARE @type nvarchar(128)
DECLARE @value sql_variant
DECLARE @sensitive bit

PRINT 'Opdaterer miljøvariabler'
SELECT DISTINCT folder + '\' + environment + '\' + variable
FROM #Variables
WHERE sensitive = 0
    AND ';' + ServerEnvironment + ';' Like '%;' + @environment + ';%' COLLATE Danish_Norwegian_CI_AS
	AND EXISTS (
    SELECT * 
    FROM SSISDB.catalog.folders a
    INNER JOIN SSISDB.catalog.environments b
        ON a.folder_id = b.folder_id
    INNER JOIN SSISDB.catalog.environment_variables c
        ON b.environment_id = c.environment_id
    WHERE a.name = folder COLLATE Danish_Norwegian_CI_AS
        AND b.name = environment COLLATE Danish_Norwegian_CI_AS
		AND c.name = variable COLLATE Danish_Norwegian_CI_AS
)

DECLARE c CURSOR FOR
SELECT DISTINCT folder, environment, variable, value
FROM #Variables
WHERE sensitive = 0
    AND ';' + ServerEnvironment + ';' Like '%;' + @environment + ';%' COLLATE Danish_Norwegian_CI_AS
	AND EXISTS (
    SELECT * 
    FROM SSISDB.catalog.folders a
    INNER JOIN SSISDB.catalog.environments b
        ON a.folder_id = b.folder_id
    INNER JOIN SSISDB.catalog.environment_variables c
        ON b.environment_id = c.environment_id
    WHERE a.name = folder COLLATE Danish_Norwegian_CI_AS
        AND b.name = environment COLLATE Danish_Norwegian_CI_AS
		AND c.name = variable COLLATE Danish_Norwegian_CI_AS
)

OPEN c
FETCH NEXT FROM c INTO @folder, @environmentName, @variable, @value

WHILE @@FETCH_STATUS = 0   
BEGIN   
    PRINT 'Opdaterer miljøvariabel: ' + @folder + '\' + @environmentName + '\' + @variable

    EXECUTE [SSISDB].[catalog].set_environment_variable_value
		@folder_name = @folder,
		@environment_name = @environmentName,
        @variable_name = @variable, 
        @value = @value

       FETCH NEXT FROM c INTO @folder, @environmentName, @variable, @value
END   

CLOSE c
DEALLOCATE c

-- Oprettelse af miljøvariabler, der ikke eksisterer i forvejen. Ssensitive variabler skal desuden opdateres manuelt v.h.a. release opgave
--
PRINT 'Opretter miljøvariabler'
SELECT DISTINCT folder + '\' + environment + '\' + variable
FROM #Variables 
WHERE NOT EXISTS (
    SELECT * 
    FROM SSISDB.catalog.folders a
    INNER JOIN SSISDB.catalog.environments b
        ON a.folder_id = b.folder_id
    INNER JOIN SSISDB.catalog.environment_variables c
        ON b.environment_id = c.environment_id
    WHERE a.name = folder COLLATE Danish_Norwegian_CI_AS
        AND b.name = environment COLLATE Danish_Norwegian_CI_AS
		AND c.name = variable COLLATE Danish_Norwegian_CI_AS
)


DECLARE c CURSOR FOR
SELECT DISTINCT folder, environment, variable, type, value, sensitive
FROM #Variables
WHERE ';'+ ServerEnvironment+ ';' like '%;' + @environment + ';%'
AND NOT EXISTS (
    SELECT * 
    FROM SSISDB.catalog.folders a
    INNER JOIN SSISDB.catalog.environments b
        ON a.folder_id = b.folder_id
    INNER JOIN SSISDB.catalog.environment_variables c
        ON b.environment_id = c.environment_id
    WHERE a.name = folder COLLATE Danish_Norwegian_CI_AS
        AND b.name = environment COLLATE Danish_Norwegian_CI_AS
		AND c.name = variable COLLATE Danish_Norwegian_CI_AS
)

OPEN c
FETCH NEXT FROM c INTO @folder, @environmentName, @variable, @type, @value, @sensitive

WHILE @@FETCH_STATUS = 0   
BEGIN   
    PRINT 'Opretter miljøvariabel: ' + @folder + '\' + @environmentName + '\' + @variable

    EXECUTE [SSISDB].[catalog].[create_environment_variable]
        @variable_name = @variable, 
        @sensitive=@sensitive, 
        @environment_name = @environmentName,
        @folder_name = @folder,
        @value = @value,
        @data_type = @type

       FETCH NEXT FROM c INTO @folder, @environmentName, @variable, @type, @value, @sensitive
END   

CLOSE c
DEALLOCATE c


-- Mapning af miljøer til projekter med samme navn
DECLARE @reference_id bigint

DECLARE c CURSOR FOR  
SELECT
    c.name,
    a.name
FROM SSISDB.catalog.projects a
INNER JOIN SSISDB.catalog.environments b
    ON a.folder_id = b.folder_id
    AND a.name = b.name
INNER JOIN SSISDB.catalog.folders c
    ON a.folder_id = c.folder_id
WHERE NOT EXISTS (
    SELECT *
    FROM SSISDB.catalog.environment_references c
    WHERE c.project_id = a.project_id
        AND c.environment_name = b.name
)

OPEN c
FETCH NEXT FROM c INTO @folder, @project

WHILE @@FETCH_STATUS = 0   
BEGIN   
    SET @msg = 'Knytter miljø til projekt: ' + @folder + '\' + @project
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXEC [SSISDB].[catalog].[create_environment_reference] 
        @environment_name = @project,
        @reference_id = @reference_id OUTPUT, 
        @project_name = @project,
        @folder_name = @folder,
        @reference_type = R

    FETCH NEXT FROM c INTO @folder, @project
END   

CLOSE c
DEALLOCATE c

-- Mapning af parametre
DECLARE @parameter sysname

DECLARE c CURSOR FOR  
SELECT DISTINCT folder, environment, parameter, variable
FROM #Variables

OPEN c
FETCH NEXT FROM c INTO @folder, @project, @parameter, @value

WHILE @@FETCH_STATUS = 0   
BEGIN
    SET @msg = 'Sætter parameter: ' + @folder + '\' + @project + '\' + @parameter + ' = ' + CAST(@value AS NVARCHAR(500))
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXECUTE SSISDB.catalog.set_object_parameter_value
        @object_type = 20,
        @folder_name = @folder,
        @project_name = @project,
        @parameter_name = @parameter,
        @parameter_value = @value,
        @value_type = R

    FETCH NEXT FROM c INTO @folder, @project, @parameter, @value
END   

CLOSE c
DEALLOCATE c

-- Oprettelse af connection strings
DECLARE @connection SYSNAME

DECLARE c CURSOR FOR  
SELECT DISTINCT
    b.name as folder,
    project,
    connection,
    'CM.' + connection + '.ConnectionString',
    connectionString
FROM #ConnectionStrings a
INNER JOIN SSISDB.catalog.folders b 
    ON ';' + a.folder + ';' LIKE '%;' + b.name + ';%' COLLATE Danish_Norwegian_CI_AS
WHERE ';' + a.environment + ';' LIKE '%;' + @environment + ';%' COLLATE Danish_Norwegian_CI_AS

OPEN c
FETCH NEXT FROM c INTO @folder, @project, @connection, @parameter, @value

WHILE @@FETCH_STATUS = 0   
BEGIN   
    SET @msg = 'Sætter connection string: ' + @folder + '\' + @project + '\' + @connection + ' = ' + CAST(@value AS NVARCHAR(500))
    RAISERROR (@msg, 0, 1) WITH NOWAIT

    EXECUTE SSISDB.catalog.set_object_parameter_value
        @object_type = 20,
        @folder_name = @folder,
        @project_name = @project,
        @parameter_name = @parameter,
        @parameter_value = @value

    FETCH NEXT FROM c INTO @folder, @project, @connection, @parameter, @value
END   

CLOSE c
DEALLOCATE c

DROP TABLE #Variables
DROP TABLE #ConnectionStrings