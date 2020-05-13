-- Set status indicator
-- If the property is still defined after deployment, it is an indication that this script was aborted prematurely
IF NOT EXISTS (SELECT *
    FROM SSISDB.sys.extended_properties
    WHERE class_desc = N'DATABASE'
    AND name = N'Environment setup status')
    EXEC [SSISDB].sys.sp_addextendedproperty @name=N'Environment setup status', @value=N'In progress' 

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
    value nvarchar(4000),
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
	WHEN @@SERVERNAME LIKE 'BMAT-%-PP0_' THEN N'PP'
	WHEN @@SERVERNAME LIKE 'BMAT-%-T01' THEN N'T1'
	WHEN @@SERVERNAME LIKE 'BMAT-%-T02' THEN N'T2'
	WHEN @@SERVERNAME LIKE 'BMAT-%-T03' THEN N'T3'
	WHEN @@SERVERNAME LIKE 'BMAT-%-P0_' THEN N'PROD'
	WHEN @@SERVERNAME LIKE 'AT-PBI-U1\SPOR_' THEN N'DEV' + RIGHT(@@SERVICENAME, 1)
	WHEN @@SERVERNAME LIKE 'AT-PBI-U2\SPOR_' THEN N'TST' + RIGHT(@@SERVICENAME, 1)
	ELSE N'DEV'
END

DECLARE @msg NVARCHAR(200) = 'Aktuelt miljø: ' + @environment
RAISERROR (@msg, 0, 1) WITH NOWAIT

----------------------------------------
-- Oprydning i projekter som ikke længere bruges
INSERT INTO #ProjectsToDelete (folder, project)
VALUES
    (N'Landingszone',   N'Erhvervssygdomme'),
    (N'Landingszone',   N'Forudsætningsoverblik'),
	(N'Landingszone',   N'Forudsμtningsoverblik'),
	(N'Data Warehouse', N'Forudsμtningsoverblik'),
    (N'Landingszone',   N'Metadatamodel'),
    (N'Landingszone',   N'Template'),
    (N'Data Warehouse', N'Template'),
    (N'Fasttrack',      N'Forudsætningsoverblik')

----------------------------------------
-- Oprydning i variabler som ikke længere bruges
-- INSERT INTO #VariablesToDelete (folder, environment, variable)
-- VALUES (N'Landingszone', N'<projektnavn>', N'<variabelnavn>')

-- Her defineres alle miljøvariabler
-- OBS! Passwords skal defineres manuelt i SIT miljøerne, de værdier der står herunder er default som kun gælder i NCART miljøet (de er sat ind a.h.t. Jenkins)
INSERT INTO #Variables
    (ServerEnvironment, folder, environment, parameter, variable, type, value, sensitive)
VALUES

-- ATIS
	(N'DEV',              N'Landingszone',   N'ATIS', 	                N'ATIS_Pwd',	                            N'Pwd-ATISDBA',                             N'String', N'*',                                                                                         1),             
	(N'DEV1;TST1',        N'Landingszone',   N'ATIS', 	                N'ATIS_Pwd',	                            N'Pwd-ATISDBA',                             N'String', N'*',                                                                                         1),  
	(N'DEV2;TST2',        N'Landingszone',   N'ATIS', 	                N'ATIS_Pwd',	                            N'Pwd-ATISDBA',                             N'String', N'*',                                                                                         1),  
	(N'DEV3;TST3',        N'Landingszone',   N'ATIS', 	                N'ATIS_Pwd',	                            N'Pwd-ATISDBA',                             N'String', N'*',                                                                                         1),  
	(N'DEV4;TST4',        N'Landingszone',   N'ATIS', 	                N'ATIS_Pwd',	                            N'Pwd-ATISDBA',                             N'String', N'*',                                                                                         1),  
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'ATIS', 	                N'ATIS_Pwd',	                            N'Pwd-ATISDBA',                             N'String', N'*',                                                                                         1), 

-- Direktionsrapportering	                                                                                                                                    
	(N'DEV',              N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',   0),            
	(N'DEV1;TST1',        N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',   0),                 
	(N'DEV2;TST2',        N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',   0),
	(N'DEV3;TST3',        N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',   0),
	(N'DEV4;TST4',        N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',   0),
	(N'T1',               N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gotest-t1.at.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',                 0),
	(N'T2',               N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gotest-t2.at.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',                 0),
	(N'T3',               N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gotest-t3.at.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',                 0),
	(N'PP',               N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gopre-pp.at.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',                  0),
	(N'PROD',             N'Landingszone',   N'Direktionsrapportering', N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://go.at.dk/sites/direktionsrapportering/_vti_bin/ListData.svc',                        0),
	
-- AES_ATP    
    (N'DEV',              N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws-int05.atp.dk/ErhvervssygdomReplika',                                             0), 
	(N'DEV1;TST1',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws-int05.atp.dk/ErhvervssygdomReplika',                                             0),
	(N'DEV2;TST2',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws-int05.atp.dk/ErhvervssygdomReplika',                                             0),
	(N'DEV3;TST3',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws-int05.atp.dk/ErhvervssygdomReplika',                                             0),
	(N'DEV4;TST4',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws-int05.atp.dk/ErhvervssygdomReplika',                                             0),
	(N'T1;T2;T3;PP',      N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws-int05.atp.dk/ErhvervssygdomReplika',                                             0),
    (N'PROD',             N'Landingszone',   N'AES_ATP',                N'ErhvervssygdomReplikaEndpoint',           N'ErhvervssygdomReplikaEndpoint',           N'String', N'https://ws.atp.dk/ErhvervssygdomReplika',                                                   0),
	 
	(N'DEV',              N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws-int05.atp.dk/ArbejdsskadeKlassifikation',                                        0),
	(N'DEV1;TST1',        N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws-int05.atp.dk/ArbejdsskadeKlassifikation',                                        0),
	(N'DEV2;TST2',        N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws-int05.atp.dk/ArbejdsskadeKlassifikation',                                        0),
    (N'DEV3;TST3',        N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws-int05.atp.dk/ArbejdsskadeKlassifikation',                                        0),
    (N'DEV4;TST4',        N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws-int05.atp.dk/ArbejdsskadeKlassifikation',                                        0),
	(N'T1;T2;T3;PP',      N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws-int05.atp.dk/ArbejdsskadeKlassifikation',                                        0),
    (N'PROD',             N'Landingszone',   N'AES_ATP',                N'ArbejdsskadeKlassifikationsdataEndpoint', N'ArbejdsskadeKlassifikationsdataEndpoint', N'String', N'https://ws.atp.dk/ArbejdsskadeKlassifikation',                                              0),
	 
	(N'DEV',              N'Landingszone',   N'AES_ATP',                N'ErhvervssygdommeCSVPath',                 N'ErhvervssygdommeCSVPath',                 N'String', N'\\art-dev-build.ncart.netcompany.dk\f$\temp\NyESS_CSV\erhvervssygdomme.csv',                0),   
	(N'DEV1;TST1',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdommeCSVPath',                 N'ErhvervssygdommeCSVPath',                 N'String', N'\\art-dev-build.ncart.netcompany.dk\f$\temp\NyESS_CSV\erhvervssygdomme.csv',                0),
	(N'DEV2;TST2',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdommeCSVPath',                 N'ErhvervssygdommeCSVPath',                 N'String', N'\\art-dev-build.ncart.netcompany.dk\f$\temp\NyESS_CSV\erhvervssygdomme.csv',                0),
	(N'DEV3;TST3',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdommeCSVPath',                 N'ErhvervssygdommeCSVPath',                 N'String', N'\\art-dev-build.ncart.netcompany.dk\f$\temp\NyESS_CSV\erhvervssygdomme.csv',                0),
    (N'DEV4;TST4',        N'Landingszone',   N'AES_ATP',                N'ErhvervssygdommeCSVPath',                 N'ErhvervssygdommeCSVPath',                 N'String', N'\\art-dev-build.ncart.netcompany.dk\f$\temp\NyESS_CSV\erhvervssygdomme.csv',                0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'AES_ATP',                N'ErhvervssygdommeCSVPath',                 N'ErhvervssygdommeCSVPath',                 N'String', N'\\BMAT-DW-P01.PROD.SITAD.DK\easy_ess\erhvervssygdomme.csv',                                 0),
	
	(N'DEV',              N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - E-boks AT - Test',                                                        0),
	(N'DEV1;TST1',        N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - E-boks AT - Test',                                                        0),
	(N'DEV2;TST2',        N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - E-boks AT - Test',                                                        0),
	(N'DEV3;TST3',        N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - E-boks AT - Test',                                                        0),
	(N'DEV4;TST4',        N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - E-boks AT - Test',                                                        0),
	(N'T1;T2;T3;PP',      N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - E-boks AT - Test',                                                        0),
    (N'PROD',             N'Landingszone',   N'AES_ATP',                N'ClientCertificateSubject',                N'ClientCertificateSubject',                N'String', N'Arbejdstilsynet - NyEasy - Prod (funktionscertifikat)',                                     0),
	
	(N'DEV',              N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - ATP Test',                                                0),
    (N'DEV1;TST1',        N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - ATP Test',                                                0),
	(N'DEV2;TST2',        N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - ATP Test',                                                0),
	(N'DEV3;TST3',        N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - ATP Test',                                                0),
	(N'DEV4;TST4',        N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - ATP Test',                                                0),
    (N'T1;T2;T3;PP',      N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - ATP Test',                                                0),
    (N'PROD',             N'Landingszone',   N'AES_ATP',                N'ServiceCertificateSubject',               N'ServiceCertificateSubject',               N'String', N'Arbejdsmarkedets Tillægspension - virksomhedscertifika',                                    0), 
	
    (N'DEV',              N'Landingszone',   N'AES_ATP',                N'AT2_ARC_PW',                              N'AT2_ARC_PW',                              N'String', N'AT2_ARC',                                                                                   0), 	
	(N'DEV1;TST1',        N'Landingszone',   N'AES_ATP',                N'AT2_ARC_PW',                              N'AT2_ARC_PW',                              N'String', N'AT2_ARC',                                                                                   0),
	(N'DEV2;TST2',        N'Landingszone',   N'AES_ATP',                N'AT2_ARC_PW',                              N'AT2_ARC_PW',                              N'String', N'AT2_ARC',                                                                                   0),
	(N'DEV3;TST3',        N'Landingszone',   N'AES_ATP',                N'AT2_ARC_PW',                              N'AT2_ARC_PW',                              N'String', N'AT2_ARC',                                                                                   0),
	(N'DEV4;TST4',        N'Landingszone',   N'AES_ATP',                N'AT2_ARC_PW',                              N'AT2_ARC_PW',                              N'String', N'AT2_ARC',                                                                                   0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'AES_ATP',                N'AT2_ARC_PW',                              N'AT2_ARC_PW',                              N'String', N'AT2_ARC',                                                                                   0),

	(N'DEV',              N'Landingszone',	 N'AES_ATP',				N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),  	
	(N'DEV1;TST1',        N'Landingszone',	 N'AES_ATP',				N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'DEV2;TST2',        N'Landingszone',	 N'AES_ATP',				N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'DEV3;TST3',        N'Landingszone',	 N'AES_ATP',				N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'DEV4;TST4',        N'Landingszone',	 N'AES_ATP',				N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',	 N'AES_ATP',				N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	
-- MDS	
	(N'DEV',              N'Landingszone',   N'MDS', 				    N'CSV_Drive',	                            N'CSV-Drive',                          	    N'String', N'C:\CSV\Brancher.csv',                                                                       0),
    (N'DEV1;TST1',        N'Landingszone',   N'MDS', 				    N'CSV_Drive',	                            N'CSV-Drive',                          	    N'String', N'C:\CSV\Brancher.csv',                                                                       0),
	(N'DEV2;TST2',        N'Landingszone',   N'MDS', 				    N'CSV_Drive',	                            N'CSV-Drive',                          	    N'String', N'C:\CSV\Brancher.csv',                                                                       0),
	(N'DEV3;TST3',        N'Landingszone',   N'MDS', 				    N'CSV_Drive',	                            N'CSV-Drive',                          	    N'String', N'C:\CSV\Brancher.csv',                                                                       0),
	(N'DEV4;TST4',        N'Landingszone',   N'MDS', 				    N'CSV_Drive',	                            N'CSV-Drive',                          	    N'String', N'C:\CSV\Brancher.csv',                                                                       0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'MDS', 				    N'CSV_Drive',	                            N'CSV-Drive',                          	    N'String', N'E:\CSV\Brancher.csv',                                                                       0),
	
	(N'DEV',              N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),  
	(N'DEV1;TST1',        N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV2;TST2',        N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV3;TST3',        N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV4;TST4',        N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'T1;T2;T3',         N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'PROD\F005481',                                                                              0),
	(N'PP',               N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'PROD\F005480',                                                                              0),
	(N'PROD',             N'Landingszone',   N'MDS', 				    N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'PROD\F005486',                                                                              0),
	
-- Staging	
	(N'DEV',              N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV1;TST1',        N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV2;TST2',        N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV3;TST3',        N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'DEV4;TST4',        N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'NCART\Jenkins1',                                                                            0),
	(N'T1;T2;T3',         N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'PROD\F005481',                                                                              0),
	(N'PP',               N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'PROD\F005480',                                                                              0),
	(N'PROD',             N'Landingszone',   N'Staging', 				N'MDS_UserName',	                        N'MDS-UserName',                            N'String', N'PROD\F005486',                                                                              0),
	
	(N'DEV',              N'Landingszone',   N'Staging', 				N'MSORA_AT6_DM_PW',	                        N'MSORA-AT6-DM-PW',                         N'String', N'AT6_DM',                                                                                    0),
	(N'DEV1;TST1',        N'Landingszone',   N'Staging', 				N'MSORA_AT6_DM_PW',	                        N'MSORA-AT6-DM-PW',                         N'String', N'AT6_DM',                                                                                    0),
	(N'DEV2;TST2',        N'Landingszone',   N'Staging', 				N'MSORA_AT6_DM_PW',	                        N'MSORA-AT6-DM-PW',                         N'String', N'AT6_DM',                                                                                    0),
	(N'DEV3;TST3',        N'Landingszone',   N'Staging', 				N'MSORA_AT6_DM_PW',	                        N'MSORA-AT6-DM-PW',                         N'String', N'AT6_DM',                                                                                    0),
	(N'DEV4;TST4',        N'Landingszone',   N'Staging', 				N'MSORA_AT6_DM_PW',	                        N'MSORA-AT6-DM-PW',                         N'String', N'AT6_DM',                                                                                    0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'Staging', 				N'MSORA_AT6_DM_PW',	                        N'MSORA-AT6-DM-PW',                         N'String', N'AT6_DM',                                                                                    0),
	
-- Metadatamodellen	
	(N'DEV',              N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/_vti_bin/ListData.svc',         0),
	(N'DEV1;TST1',        N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/_vti_bin/ListData.svc',         0),
	(N'DEV2;TST2',        N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/_vti_bin/ListData.svc',         0),
	(N'DEV3;TST3',        N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/_vti_bin/ListData.svc',         0),
	(N'DEV4;TST4',        N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://at-dev-go.ncart.netcompany.dk/sites/metadatamodellen/_vti_bin/ListData.svc',         0),
	(N'T1',               N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gotest-t1.at.dk/sites/metadatamodellen/_vti_bin/ListData.svc',                       0), 
	(N'T2',               N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gotest-t2.at.dk/sites/metadatamodellen/_vti_bin/ListData.svc',                       0),
	(N'T3',               N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gotest-t3.at.dk/sites/metadatamodellen/_vti_bin/ListData.svc',                       0),
	(N'PP',               N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://gopre-pp.at.dk/sites/metadatamodellen/_vti_bin/ListData.svc',                        0),
	(N'PROD',             N'Landingszone',   N'Metadatamodellen',       N'SharePoint_URL',                          N'SharePoint-URL',                          N'String', N'https://go.at.dk/sites/metadatamodellen/_vti_bin/ListData.svc',                              0),
	
-- Forudsætningsoverblik    
    (N'DEV',              N'Data Warehouse', N'Forudsætningsoverblik',  N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),  	
	(N'DEV1;TST1',        N'Data Warehouse', N'Forudsætningsoverblik',  N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'DEV2;TST2',        N'Data Warehouse', N'Forudsætningsoverblik',  N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'DEV3;TST3',        N'Data Warehouse', N'Forudsætningsoverblik',  N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'DEV4;TST4',        N'Data Warehouse', N'Forudsætningsoverblik',  N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	(N'T1;T2;T3;PP;PROD', N'Data Warehouse', N'Forudsætningsoverblik',  N'Pwd_AT0_DWH',                             N'Pwd-AT0-DWH',                             N'String', N'*',                                                                                         1),
	
-- GDPR	
	(N'DEV',              N'GDPR',           N'GDPR', 				    N'Pwd_ATISDBA',	                            N'Pwd-ATISDBA',                        	    N'String', N'*',                                                                                         1),
	(N'DEV1;TST1',        N'GDPR',           N'GDPR', 				    N'Pwd_ATISDBA',	                            N'Pwd-ATISDBA',                        	    N'String', N'*',                                                                                         1),
	(N'DEV2;TST2',        N'GDPR',           N'GDPR', 				    N'Pwd_ATISDBA',	                            N'Pwd-ATISDBA',                        	    N'String', N'*',                                                                                         1),
	(N'DEV3;TST3',        N'GDPR',           N'GDPR', 				    N'Pwd_ATISDBA',	                            N'Pwd-ATISDBA',                        	    N'String', N'*',                                                                                         1),
	(N'DEV4;TST4',        N'GDPR',           N'GDPR', 				    N'Pwd_ATISDBA',	                            N'Pwd-ATISDBA',                        	    N'String', N'*',                                                                                         1),
	(N'T1;T2;T3;PP;PROD', N'GDPR',           N'GDPR', 				    N'Pwd_ATISDBA',	                            N'Pwd-ATISDBA',                        	    N'String', N'*',                                                                                         1),
	
	(N'DEV',              N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Views.asmx',                       0),
	(N'DEV1;TST1',        N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Views.asmx',                       0),
	(N'DEV2;TST2',        N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Views.asmx',                       0),
	(N'DEV3;TST3',        N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Views.asmx',                       0),
	(N'DEV4;TST4',        N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Views.asmx',                       0),
	(N'T1',               N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://gotest-t1.at.dk/sites/gdpr/_vti_bin/views.asmx',                                     0),
	(N'T2',               N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://gotest-t2.at.dk/sites/gdpr/_vti_bin/views.asmx',                                     0),
	(N'T3',               N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://gotest-t3.at.dk/sites/gdpr/_vti_bin/views.asmx',			                          0),
	(N'PP',               N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://gopre-pp.at.dk/sites/gdpr/_vti_bin/views.asmx',                                      0),
	(N'PROD',             N'GDPR',           N'GDPR', 				    N'ViewsAsmxUrl',	                        N'ViewsAsmxUrl',                        	N'String', N'https://go.at.dk/sites/gdpr/_vti_bin/views.asmx',                                            0),
	
	(N'DEV',              N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx',                       0),
	(N'DEV1;TST1',        N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx',                       0),
	(N'DEV2;TST2',        N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx',                       0),
	(N'DEV3;TST3',        N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx',                       0),
	(N'DEV4;TST4',        N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx',                       0),
	(N'T1',               N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://gotest-t1.at.dk/sites/gdpr/_vti_bin/lists.asmx',                                     0),
	(N'T2',               N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://gotest-t2.at.dk/sites/gdpr/_vti_bin/lists.asmx',                                     0),
	(N'T3',               N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://gotest-t3.at.dk/sites/gdpr/_vti_bin/lists.asmx',                                     0),
	(N'PP',               N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://gopre-pp.at.dk/sites/gdpr/_vti_bin/lists.asmx',                                      0),
	(N'PROD',             N'GDPR',           N'GDPR', 				    N'ListsAsmxUrl',	                        N'ListsAsmxUrl',                        	N'String', N'https://go.at.dk/sites/gdpr/_vti_bin/lists.asmx',                                            0),
	
	(N'DEV',              N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://at-d02-go.ncart.netcompany.dk/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/atis/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/greenland/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/probas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx', 0),
	(N'DEV1;TST1',        N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://at-d02-go.ncart.netcompany.dk/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/atis/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/greenland/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/probas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx', 0),
	(N'DEV2;TST2',        N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://at-d02-go.ncart.netcompany.dk/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/atis/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/greenland/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/probas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx', 0),
	(N'DEV3;TST3',        N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://at-d02-go.ncart.netcompany.dk/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/atis/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/greenland/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/probas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx', 0),
	(N'DEV4;TST4',        N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://at-d02-go.ncart.netcompany.dk/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/atis/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/greenland/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/probas/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://at-d02-go.ncart.netcompany.dk/sites/gdpr/_vti_bin/Lists.asmx', 0),
	(N'T1',               N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://gotest-t1.at.dk/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/atis/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/greenland/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/probas/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://gotest-t1.at.dk/sites/gdpr/_vti_bin/Lists.asmx',                                                                                                                                                                         0),
	(N'T2',               N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://gotest-t2.at.dk/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/atis/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/greenland/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/probas/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://gotest-t2.at.dk/sites/gdpr/_vti_bin/Lists.asmx',                                                                                                                                                                         0),
	(N'T3',               N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://gotest-t3.at.dk/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/atis/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/greenland/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/probas/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://gotest-t3.at.dk/sites/gdpr/_vti_bin/Lists.asmx',                                                                                                                                                                         0),
	(N'PP',               N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://gopre-pp.at.dk/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/atis/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/greenland/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/probas/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://gopre-pp.at.dk/sites/gdpr/_vti_bin/Lists.asmx',                                                                                                                                                                                     0),
	(N'PROD',             N'GDPR',           N'GDPR', 				    N'SPEndpoints',	                            N'SPEndpoints',                        	    N'String', N'https://go.at.dk/_vti_bin/Lists.asmx,https://go.at.dk/organisering/Anerkendelsessager/_vti_bin/Lists.asmx,https://go.at.dk/organisering/atis/_vti_bin/Lists.asmx,https://go.at.dk/organisering/emnesager/_vti_bin/Lists.asmx,https://go.at.dk/organisering/greenland/_vti_bin/Lists.asmx,https://go.at.dk/organisering/ministerbetjening/_vti_bin/Lists.asmx,https://go.at.dk/organisering/naturgas/_vti_bin/Lists.asmx,https://go.at.dk/organisering/oevrigeemnesager/_vti_bin/Lists.asmx,https://go.at.dk/organisering/offshoresager/_vti_bin/Lists.asmx,https://go.at.dk/organisering/probas/_vti_bin/Lists.asmx,https://go.at.dk/organisering/sagermedparter/_vti_bin/Lists.asmx,https://go.at.dk/sites/gdpr/_vti_bin/Lists.asmx',                                                                                                                                                                                                                                                             0),
	
-- CVRIntegration	
	(N'DEV',              N'Landingszone',   N'CvrIntegration',         N'Pwd_CVR2DBA',                             N'Pwd_CVR2DBA',                             N'String', N'*',                                                                                         1),
	(N'DEV1;TST1',        N'Landingszone',   N'CvrIntegration',         N'Pwd_CVR2DBA',                             N'Pwd_CVR2DBA',                             N'String', N'*',                                                                                         1),
	(N'DEV2;TST2',        N'Landingszone',   N'CvrIntegration',         N'Pwd_CVR2DBA',                             N'Pwd_CVR2DBA',                             N'String', N'*',                                                                                         1),
	(N'DEV3;TST3',        N'Landingszone',   N'CvrIntegration',         N'Pwd_CVR2DBA',                             N'Pwd_CVR2DBA',                             N'String', N'*',                                                                                         1),
	(N'DEV4;TST4',        N'Landingszone',   N'CvrIntegration',         N'Pwd_CVR2DBA',                             N'Pwd_CVR2DBA',                             N'String', N'*',                                                                                         1),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'CvrIntegration',         N'Pwd_CVR2DBA',                             N'Pwd_CVR2DBA',                             N'String', N'*',                                                                                         1),
	
	(N'DEV',              N'Landingszone',   N'CvrIntegration',         N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),       
	(N'DEV1;TST1',        N'Landingszone',   N'CvrIntegration',         N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'DEV2;TST2',        N'Landingszone',   N'CvrIntegration',         N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'DEV3;TST3',        N'Landingszone',   N'CvrIntegration',         N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'DEV4;TST4',        N'Landingszone',   N'CvrIntegration',         N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'CvrIntegration',         N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	
	(N'DEV',              N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Path',                      N'CvrConsoleApp_Path',                      N'String', N'C:\Netcompany\CVRIntegration',                                                              0),
	(N'DEV1;TST1',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Path',                      N'CvrConsoleApp_Path',                      N'String', N'C:\Netcompany\CVRIntegration\Spor1',                                                        0),
	(N'DEV2;TST2',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Path',                      N'CvrConsoleApp_Path',                      N'String', N'C:\Netcompany\CVRIntegration\Spor2',                                                        0),
	(N'DEV3;TST3',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Path',                      N'CvrConsoleApp_Path',                      N'String', N'C:\Netcompany\CVRIntegration\Spor3',                                                        0),
	(N'DEV4;TST4',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Path',                      N'CvrConsoleApp_Path',                      N'String', N'C:\Netcompany\CVRIntegration\Spor4',                                                        0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Path',                      N'CvrConsoleApp_Path',                      N'String', N'C:\Netcompany\CVRIntegration',                                                              0),
	
	(N'DEV',              N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Name',                      N'CvrConsoleApp_Name',                      N'String', N'CVRIntegration.exe',                                                                        0),
	(N'DEV1;TST1',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Name',                      N'CvrConsoleApp_Name',                      N'String', N'CVRIntegration.exe',                                                                        0),
	(N'DEV2;TST2',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Name',                      N'CvrConsoleApp_Name',                      N'String', N'CVRIntegration.exe',                                                                        0),
	(N'DEV3;TST3',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Name',                      N'CvrConsoleApp_Name',                      N'String', N'CVRIntegration.exe',                                                                        0),
	(N'DEV4;TST4',        N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Name',                      N'CvrConsoleApp_Name',                      N'String', N'CVRIntegration.exe',                                                                        0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'CvrIntegration',         N'CvrConsoleApp_Name',                      N'CvrConsoleApp_Name',                      N'String', N'CVRIntegration.exe',                                                                        0),
	
	(N'DEV',              N'Landingszone',   N'CvrIntegration',         N'MaxErrorsLog',                            N'MaxErrorsLog',                            N'String', N'50',                                                                                        0),
	(N'DEV1;TST1',        N'Landingszone',   N'CvrIntegration',         N'MaxErrorsLog',                            N'MaxErrorsLog',                            N'String', N'50',                                                                                        0),
	(N'DEV2;TST2',        N'Landingszone',   N'CvrIntegration',         N'MaxErrorsLog',                            N'MaxErrorsLog',                            N'String', N'50',                                                                                        0),
	(N'DEV3;TST3',        N'Landingszone',   N'CvrIntegration',         N'MaxErrorsLog',                            N'MaxErrorsLog',                            N'String', N'50',                                                                                        0),
	(N'DEV4;TST4',        N'Landingszone',   N'CvrIntegration',         N'MaxErrorsLog',                            N'MaxErrorsLog',                            N'String', N'50',                                                                                        0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'CvrIntegration',         N'MaxErrorsLog',                            N'MaxErrorsLog',                            N'String', N'50',                                                                                        0),
	
-- RUT	
	(N'DEV',              N'Landingszone',   N'RUT',                    N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),       
	(N'DEV1;TST1',        N'Landingszone',   N'RUT',                    N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'DEV2;TST2',        N'Landingszone',   N'RUT',                    N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'DEV3;TST3',        N'Landingszone',   N'RUT',                    N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'DEV4;TST4',        N'Landingszone',   N'RUT',                    N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'RUT',                    N'Pwd_ATISDBA',                             N'Pwd-ATISDBA',                      	    N'String', N'*',                                                                                         1),

	(N'DEV',              N'Landingszone',   N'RUT',                    N'RutConsoleApp_Path',                      N'RutConsoleApp_Path',                      N'String', N'C:\Applications\RUTIntegration',    												         0),
	(N'DEV1;TST1',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Path',                      N'RutConsoleApp_Path',                      N'String', N'E:\RUTIntegration',			          												     0),
	(N'DEV2;TST2',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Path',                      N'RutConsoleApp_Path',                      N'String', N'E:\RUTIntegration',			          												     0),
	(N'DEV3;TST3',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Path',                      N'RutConsoleApp_Path',                      N'String', N'E:\RUTIntegration',			          												     0),
	(N'DEV4;TST4',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Path',                      N'RutConsoleApp_Path',                      N'String', N'E:\RUTIntegration',			          												     0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'RUT',                    N'RutConsoleApp_Path',                      N'RutConsoleApp_Path',                      N'String', N'E:\RUTIntegration',			          												     0),
	
	(N'DEV',              N'Landingszone',   N'RUT',                    N'RutConsoleApp_Name',                      N'RutConsoleApp_Name',                      N'String', N'RUTIntegration.exe',                     												     0),
	(N'DEV1;TST1',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Name',                      N'RutConsoleApp_Name',                      N'String', N'RUTIntegration.exe',                     												     0),
	(N'DEV2;TST2',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Name',                      N'RutConsoleApp_Name',                      N'String', N'RUTIntegration.exe',                     												     0),
	(N'DEV3;TST3',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Name',                      N'RutConsoleApp_Name',                      N'String', N'RUTIntegration.exe',                     												     0),
	(N'DEV4;TST4',        N'Landingszone',   N'RUT',                    N'RutConsoleApp_Name',                      N'RutConsoleApp_Name',                      N'String', N'RUTIntegration.exe',                     												     0),
	(N'T1;T2;T3;PP;PROD', N'Landingszone',   N'RUT',                    N'RutConsoleApp_Name',                      N'RutConsoleApp_Name',                      N'String', N'RUTIntegration.exe',                     												     0),

	(N'DEV',              N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'DEV',                                 													     0),
	(N'DEV1',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCDEV1',                                 												     0),
	(N'DEV2',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCDEV2',                                 												     0),
	(N'DEV3',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCDEV3',                                 												     0),
	(N'DEV4',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCDEV4',                                 												     0),		
	(N'TST1',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCTST1',                                 												     0),
	(N'TST2',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCTST2',                                 												     0),
	(N'TST3',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCTST3',                                 												     0),
	(N'TST4',			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'NCTST4',                                 												     0),
	(N'T1',   			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'T1',  																					   	 0),
	(N'T2',   			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'T2',  																					   	 0),
	(N'T3',   			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'T3',  																					   	 0),
	(N'PP',   			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'PREPROD',  			     															  	 0),
	(N'PROD', 			  N'Landingszone',   N'RUT',                    N'RutConsoleApp_Settings',                  N'RutConsoleApp_Settings',                  N'String', N'PROD',  								  												     0)       

-- Her defineres alle miljøspecifikke connection strings
-- OBS: "Integrated Security=True" fungerer ikke for OLEDB connections. Her bruges i stedet "Integrated Security=SSPI"
INSERT INTO #ConnectionStrings
    (environment, folder, project, connection, connectionString)
VALUES

-- ATIS
	(N'DEV',                N'Landingszone',                N'ATIS',                    N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'ATIS',                    N'ADO.NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'ATIS',                    N'ADO.NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'ATIS',                    N'ADO.NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'ATIS',                    N'ADO.NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'ATIS',                    N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'ATIS',                    N'ADO.NET ATIS',                    N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'ATIS',                    N'ADO.NET ATIS',                    N'Data Source=.\Spor1;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'ATIS',                    N'ADO.NET ATIS',                    N'Data Source=.\Spor2;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'ATIS',                    N'ADO.NET ATIS',                    N'Data Source=.\Spor3;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'ATIS',                    N'ADO.NET ATIS',                    N'Data Source=.\Spor4;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'ATIS',                    N'ADO.NET ATIS',                    N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'ATIS',                    N'OLEDB ATIS',                      N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'ATIS',                    N'OLEDB ATIS',                      N'Data Source=.\Spor1;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'ATIS',                    N'OLEDB ATIS',                      N'Data Source=.\Spor2;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'ATIS',                    N'OLEDB ATIS',                      N'Data Source=.\Spor3;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'ATIS',                    N'OLEDB ATIS',                      N'Data Source=.\Spor4;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'ATIS',                    N'OLEDB ATIS',                      N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV1;USERNAME=atisdba'),
	(N'DEV1;TST1',          N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV1;USERNAME=atisdba'),
	(N'DEV2;TST2',          N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV2;USERNAME=atisdba'),
	(N'DEV3;TST3',          N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV3;USERNAME=atisdba'),
	(N'DEV4;TST4',          N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV1;USERNAME=atisdba'),
	(N'T2',                 N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=bmat-ora01-tc:1522/ATIST2;USERNAME=atisdba'),
	(N'T3',                 N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=bmat-ora01-tc:1522/ATIST3;USERNAME=atisdba'),
	(N'T1',                 N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=bmat-ora01-tc:1522/ATIST1;USERNAME=atisdba'),
	(N'PP',                 N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=bmat-ora01-pp:1522/ATISPP;USERNAME=atisdba'),
	(N'PROD',               N'Landingszone',                N'ATIS',                    N'MSORA ATIS',                      N'SERVER=bmat-ora01-p/ATISDB.WORLD;USERNAME=atisdba'),

-- Direktionsrapportering	
    (N'DEV',                N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET Direktionsrapportering',  N'Data Source=.\Spor1;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET Direktionsrapportering',  N'Data Source=.\Spor2;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET Direktionsrapportering',  N'Data Source=.\Spor3;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET Direktionsrapportering',  N'Data Source=.\Spor4;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET Direktionsrapportering',  N'Data Source=.;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Direktionsrapportering',  N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'Direktionsrapportering',  N'OLEDB LZ Direktionsrapportering', N'Data Source=.;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'Direktionsrapportering',  N'OLEDB LZ Direktionsrapportering', N'Data Source=.\Spor1;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'Direktionsrapportering',  N'OLEDB LZ Direktionsrapportering', N'Data Source=.\Spor2;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'Direktionsrapportering',  N'OLEDB LZ Direktionsrapportering', N'Data Source=.\Spor3;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'Direktionsrapportering',  N'OLEDB LZ Direktionsrapportering', N'Data Source=.\Spor4;Initial Catalog=Direktionsrapportering;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Direktionsrapportering',  N'OLEDB LZ Direktionsrapportering', N'Data Source=.;Initial Catalog=Direktionsrapportering;integrated Security=SSPI;'),

-- AES_ATP	
    (N'DEV',                N'Landingszone',                N'AES_ATP',                 N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'AES_ATP',                 N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'AES_ATP',                 N'ADO.NET AES_ATP',                 N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET AES_ATP',                 N'Data Source=.\Spor1;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET AES_ATP',                 N'Data Source=.\Spor2;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET AES_ATP',                 N'Data Source=.\Spor3;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'AES_ATP',                 N'ADO.NET AES_ATP',                 N'Data Source=.\Spor4;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'AES_ATP',                 N'ADO.NET AES_ATP',                 N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ AES_ATP', 	            N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ AES_ATP', 	            N'Data Source=.\Spor1;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ AES_ATP', 	            N'Data Source=.\Spor2;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ AES_ATP', 	            N'Data Source=.\Spor3;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ AES_ATP', 	            N'Data Source=.\Spor4;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ AES_ATP', 	            N'Data Source=.;Initial Catalog=AES_ATP;integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ ATIS', 		            N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ ATIS', 		            N'Data Source=.\Spor1;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ ATIS', 		            N'Data Source=.\Spor2;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ ATIS', 		            N'Data Source=.\Spor3;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ ATIS', 		            N'Data Source=.\Spor4;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'AES_ATP',  		        N'OLEDB LZ ATIS', 		            N'Data Source=.;Initial Catalog=ATIS;integrated Security=SSPI;'),

	(N'DEV',            	N'Landingszone',   				N'AES_ATP', 		        N'MSORA AT2_ARC',  		            N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT2_ARC'),
    (N'DEV1;TST1',       	N'Landingszone',   				N'AES_ATP', 		        N'MSORA AT2_ARC',  		            N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT2_ARC'),
    (N'DEV2;TST2',       	N'Landingszone',   				N'AES_ATP', 		        N'MSORA AT2_ARC',  		            N'SERVER=NCAT-DW-U2.DWPROD;USERNAME=AT2_ARC'),
    (N'DEV3;TST3',       	N'Landingszone',   				N'AES_ATP', 		        N'MSORA AT2_ARC',  		            N'SERVER=NCAT-DW-U3.DWPROD;USERNAME=AT2_ARC'),
    (N'DEV4;TST4',       	N'Landingszone',   				N'AES_ATP', 		        N'MSORA AT2_ARC',  		            N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT2_ARC'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',   				N'AES_ATP', 		        N'MSORA AT2_ARC',  		            N'SERVER=BMATDW;USERNAME=AT2_ARC'),

	(N'DEV',                N'Landingszone',	            N'AES_ATP',				    N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u2.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
    (N'DEV1;TST1',          N'Landingszone',	            N'AES_ATP',				    N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u1.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'DEV2;TST2',          N'Landingszone',	            N'AES_ATP',				    N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u2.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'DEV3;TST3',          N'Landingszone',	            N'AES_ATP',				    N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u3.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'DEV4;TST4',          N'Landingszone',	            N'AES_ATP',				    N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u3.dwu4;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',	            N'AES_ATP',				    N'OLEDB DW AT0_DWH',                N'Data Source=bmatdw;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),


-- Forudsætningsoverblik    
    (N'DEV',                N'Data Warehouse',              N'Forudsætningsoverblik',   N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'ADO.NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'ADO.NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'ADO.NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'ADO.NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Data Warehouse',              N'Forudsætningsoverblik',   N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

	(N'DEV',                N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB LZ ATIS',                   N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB LZ ATIS',                   N'Data Source=.\Spor1;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB LZ ATIS',                   N'Data Source=.\Spor2;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB LZ ATIS',                   N'Data Source=.\Spor3;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB LZ ATIS',                   N'Data Source=.\Spor4;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB LZ ATIS',                   N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u2.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
    (N'DEV1;TST1',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u1.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'DEV2;TST2',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u2.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'DEV3;TST3',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u3.dwprod;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'DEV4;TST4',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB DW AT0_DWH',                N'Data Source=ncat-dw-u3.dwu4;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),
	(N'T1;T2;T3;PP;PROD',   N'Data Warehouse',              N'Forudsætningsoverblik',   N'OLEDB DW AT0_DWH',                N'Data Source=bmatdw;User ID=AT0_DWH;Provider=OraOLEDB.Oracle.1;Persist Security Info=True;'),

	(N'DEV',                N'Data Warehouse',              N'Forudsætningsoverblik',   N'MSORA DW AT0_DWH',                N'SERVER=ncat-dw-u2/dwprod;USERNAME=AT0_DWH'),
    (N'DEV1;TST1',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'MSORA DW AT0_DWH',                N'SERVER=ncat-dw-u1/dwprod;USERNAME=AT0_DWH'),
	(N'DEV2;TST2',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'MSORA DW AT0_DWH',                N'SERVER=ncat-dw-u2/dwprod;USERNAME=AT0_DWH'),
	(N'DEV3;TST3',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'MSORA DW AT0_DWH',                N'SERVER=ncat-dw-u3/dwprod;USERNAME=AT0_DWH'),
	(N'DEV4;TST4',          N'Data Warehouse',              N'Forudsætningsoverblik',   N'MSORA DW AT0_DWH',                N'SERVER=ncat-dw-u2/dwu4;USERNAME=AT0_DWH'),
	(N'T1;T2;T3;PP;PROD',   N'Data Warehouse',              N'Forudsætningsoverblik',   N'MSORA DW AT0_DWH',                N'SERVER=bmatdw;USERNAME=AT0_DWH'),

-- GDPR	
	(N'DEV',                N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV1,DEV4',          N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV2',               N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV2;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV3',               N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV3;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'TST1,TST4',          N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCTST1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'TST2',               N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCTST2;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'TST3',               N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=at-com-oracle.ncart.netcompany.dk/NCTST3;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
	(N'T1',                 N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=bmat-ora01-tc:1522/ATIST1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
	(N'T2',                 N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=bmat-ora01-tc:1522/ATIST2;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
	(N'T3',                 N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=bmat-ora01-tc:1522/ATIST3;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'PP',                 N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=bmat-ora01-pp:1522/ATISPP;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'PROD',               N'GDPR',                        N'GDPR',                    N'OLEDB ATIS',                      N'Data Source=bmat-ora01-p:1521/ATISDB.WORLD;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),

	(N'DEV',                N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV1;DEV3',          N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV2;DEV4',          N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV2;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST1;TST3',          N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST1;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST2;TST4',          N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST2;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T1',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=bmat-mssql01-t1.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T2',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=bmat-mssql01-t2.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T3',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=bmat-mssql01-t3.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'PP',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=bmat-mssql01-pp.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'PROD',               N'GDPR',                        N'GDPR',                    N'OLEDB ESL',                       N'Data Source=bmat-mssql01-p.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESL;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),

	(N'DEV',                N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV1;DEV3',          N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV2;DEV4',          N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV2;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST1;TST3',          N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST1;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST2;TST4',          N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST2;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T1',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=bmat-mssql01-t1.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T2',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=bmat-mssql01-t2.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T3',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=bmat-mssql01-t3.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'PP',                 N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=bmat-mssql01-pp.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'PROD',               N'GDPR',                        N'GDPR',                    N'OLEDB ESLUsers',                  N'Data Source=bmat-mssql01-p.prod.sitad.dk,1435\PROBAS;Initial Catalog=ESLUsers;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),

	(N'DEV',                N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV1;DEV3',          N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV2;DEV4',          N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV2;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST1;TST3',          N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST1;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST2;TST4',          N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST2;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T1',                 N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=bmat-mssql01-t1.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T2',                 N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=bmat-mssql01-t2.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T3',                 N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=bmat-mssql01-t3.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'PP',                 N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=bmat-mssql01-pp.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'PROD',               N'GDPR',                        N'GDPR',                    N'OLEDB Probas',                    N'Data Source=bmat-mssql01-p.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),

    (N'DEV',                N'GDPR',                		N'GDPR',                 	N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'GDPR',                		N'GDPR',                 	N'ADO.NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'GDPR',                		N'GDPR',                 	N'ADO.NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'GDPR',                		N'GDPR',                 	N'ADO.NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'GDPR',                		N'GDPR',                 	N'ADO.NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'GDPR',                		N'GDPR',                 	N'ADO.NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	
-- MDS	
	(N'DEV',                N'Landingszone',                N'MDS',                     N'ADO.NET_LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'MDS',                     N'ADO.NET_LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'MDS',                     N'ADO.NET_LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'MDS',                     N'ADO.NET_LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'MDS',                     N'ADO.NET_LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'MDS',                     N'ADO.NET_LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'MDS',                     N'ADO.NET_MDS',                     N'Data Source=.;Initial Catalog=MDS;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'MDS',                     N'ADO.NET_MDS',                     N'Data Source=.\Spor1;Initial Catalog=MDS;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'MDS',                     N'ADO.NET_MDS',                     N'Data Source=.\Spor2;Initial Catalog=MDS;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'MDS',                     N'ADO.NET_MDS',                     N'Data Source=.\Spor3;Initial Catalog=MDS;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'MDS',                     N'ADO.NET_MDS',                     N'Data Source=.\Spor4;Initial Catalog=MDS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'MDS',                     N'ADO.NET_MDS',                     N'Data Source=.;Initial Catalog=MDS;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'MDS',                     N'OLEDB AES_ATP',                   N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'MDS',                     N'OLEDB AES_ATP',                   N'Data Source=.\Spor1;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV2;TST2',          N'Landingszone',                N'MDS',                     N'OLEDB AES_ATP',                   N'Data Source=.\Spor2;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV3;TST3',          N'Landingszone',                N'MDS',                     N'OLEDB AES_ATP',                   N'Data Source=.\Spor3;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'MDS',                     N'OLEDB AES_ATP',                   N'Data Source=.\Spor4;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'MDS',                     N'OLEDB AES_ATP',                   N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'MDS',                     N'OLEDB_Master Data Services',      N'Data Source=.;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'MDS',                     N'OLEDB_Master Data Services',      N'Data Source=.\Spor1;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'MDS',                     N'OLEDB_Master Data Services',      N'Data Source=.\Spor2;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'MDS',                     N'OLEDB_Master Data Services',      N'Data Source=.\Spor3;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'MDS',                     N'OLEDB_Master Data Services',      N'Data Source=.\Spor4;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'MDS',                     N'OLEDB_Master Data Services',      N'Data Source=.;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
    
	(N'DEV',                N'Landingszone',                N'MDS',                     N'OLEDB_MDS',                       N'Data Source=.;Initial Catalog=MDS;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'MDS',                     N'OLEDB_MDS',                       N'Data Source=.\Spor1;Initial Catalog=MDS;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'MDS',                     N'OLEDB_MDS',                       N'Data Source=.\Spor2;Initial Catalog=MDS;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'MDS',                     N'OLEDB_MDS',                       N'Data Source=.\Spor3;Initial Catalog=MDS;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'MDS',                     N'OLEDB_MDS',                       N'Data Source=.\Spor4;Initial Catalog=MDS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'MDS',                     N'OLEDB_MDS',                       N'Data Source=.;Initial Catalog=MDS;Integrated Security=SSPI;'),

-- Metadatamodellen    
	(N'DEV',                N'Landingszone',                N'Metadatamodellen',        N'ADO NET Metadatamodellen',        N'Data Source=.;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET Metadatamodellen',        N'Data Source=.\Spor1;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),    
	(N'DEV2;TST2',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET Metadatamodellen',        N'Data Source=.\Spor2;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),    
	(N'DEV3;TST3',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET Metadatamodellen',        N'Data Source=.\Spor3;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET Metadatamodellen',        N'Data Source=.\Spor4;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Metadatamodellen',        N'ADO NET Metadatamodellen',        N'Data Source=.;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'Metadatamodellen',        N'OLEDB LZ Metadatamodellen',       N'Data Source=at-pbi-u1.ncart.netcompany.dk,2452;User ID=Developer;Password=Netcompany123;Initial Catalog=Metadatamodellen;Persist Security Info=True;'),
	(N'DEV1;TST1',          N'Landingszone',                N'Metadatamodellen',        N'OLEDB LZ Metadatamodellen',       N'Data Source=.\Spor1;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',                N'Metadatamodellen',        N'OLEDB LZ Metadatamodellen',       N'Data Source=.\Spor2;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',                N'Metadatamodellen',        N'OLEDB LZ Metadatamodellen',       N'Data Source=.\Spor3;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'Metadatamodellen',        N'OLEDB LZ Metadatamodellen',       N'Data Source=.\Spor4;Initial Catalog=Metadatamodellen;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Metadatamodellen',        N'OLEDB LZ Metadatamodellen',       N'Data Source=.;Initial Catalog=Metadatamodellen;integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'Metadatamodellen',        N'ADO NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
	(N'DEV2;TST2',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
	(N'DEV3;TST3',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',                N'Metadatamodellen',        N'ADO NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Metadatamodellen',        N'ADO NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

-- CVRIntegration	
    (N'DEV',                N'Landingszone',                N'CvrIntegration',          N'ADO NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'ADO NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'ADO NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'ADO NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'ADO NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'ADO NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'CvrIntegration',          N'ADO NET CVR',                     N'Data Source=.;Initial Catalog=CVR;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CVR',                     N'Data Source=.\Spor1;Initial Catalog=CVR;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CVR',                     N'Data Source=.\Spor2;Initial Catalog=CVR;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CVR',                     N'Data Source=.\Spor3;Initial Catalog=CVR;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CVR',                     N'Data Source=.\Spor4;Initial Catalog=CVR;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'ADO NET CVR',                     N'Data Source=.;Initial Catalog=CVR;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR',                       N'Data Source=.;Initial Catalog=CVR;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR',                       N'Data Source=.\Spor1;Initial Catalog=CVR;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR',                       N'Data Source=.\Spor2;Initial Catalog=CVR;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR',                       N'Data Source=.\Spor3;Initial Catalog=CVR;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR',                       N'Data Source=.\Spor4;Initial Catalog=CVR;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR',                       N'Data Source=.;Initial Catalog=CVR;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'CvrIntegration',          N'ADO NET CPR',                     N'Data Source=.;Initial Catalog=CPR;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CPR',                     N'Data Source=.\Spor1;Initial Catalog=CPR;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CPR',                     N'Data Source=.\Spor2;Initial Catalog=CPR;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CPR',                     N'Data Source=.\Spor3;Initial Catalog=CPR;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'ADO NET CPR',                     N'Data Source=.\Spor4;Initial Catalog=CPR;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'ADO NET CPR',                     N'Data Source=.;Initial Catalog=CPR;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'CvrIntegration',          N'OLEDB CPR',                       N'Data Source=.;Initial Catalog=CPR;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CPR',                       N'Data Source=.\Spor1;Initial Catalog=CPR;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CPR',                       N'Data Source=.\Spor2;Initial Catalog=CPR;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CPR',                       N'Data Source=.\Spor3;Initial Catalog=CPR;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CPR',                       N'Data Source=.\Spor4;Initial Catalog=CPR;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'OLEDB CPR',                       N'Data Source=.;Initial Catalog=CPR;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'CvrIntegration',          N'ADO NET DAWA',                    N'Data Source=.;Initial Catalog=DAWA;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'ADO NET DAWA',                    N'Data Source=.\Spor1;Initial Catalog=DAWA;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'ADO NET DAWA',                    N'Data Source=.\Spor2;Initial Catalog=DAWA;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'ADO NET DAWA',                    N'Data Source=.\Spor3;Initial Catalog=DAWA;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'ADO NET DAWA',                    N'Data Source=.\Spor4;Initial Catalog=DAWA;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'ADO NET DAWA',                    N'Data Source=.;Initial Catalog=DAWA;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'CvrIntegration',          N'OLEDB DAWA',                      N'Data Source=.;Initial Catalog=DAWA;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'OLEDB DAWA',                      N'Data Source=.\Spor1;Initial Catalog=DAWA;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'OLEDB DAWA',                      N'Data Source=.\Spor2;Initial Catalog=DAWA;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'OLEDB DAWA',                      N'Data Source=.\Spor3;Initial Catalog=DAWA;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'OLEDB DAWA',                      N'Data Source=.\Spor4;Initial Catalog=DAWA;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'OLEDB DAWA',                      N'Data Source=.;Initial Catalog=DAWA;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR Staging',               N'Data Source=.;Initial Catalog=CVRIntegration_Staging;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR Staging',               N'Data Source=.\Spor1;Initial Catalog=CVRIntegration_Staging;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR Staging',               N'Data Source=.\Spor2;Initial Catalog=CVRIntegration_Staging;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR Staging',               N'Data Source=.\Spor3;Initial Catalog=CVRIntegration_Staging;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR Staging',               N'Data Source=.\Spor4;Initial Catalog=CVRIntegration_Staging;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR Staging',               N'Data Source=.;Initial Catalog=CVRIntegration_Staging;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV1;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV1;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV2;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV3;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV4;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'T1',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=bmat-ora01-tc.prod.sitad.dk:1522/ATIST1;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'T2',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=bmat-ora01-tc.prod.sitad.dk:1522/ATIST2;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'T3',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=bmat-ora01-tc.prod.sitad.dk:1522/ATIST3;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'PP',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=bmat-ora01-pp.prod.sitad.dk:1522/CVRPP.WORLD;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),
    (N'PROD',               N'Landingszone',                N'CvrIntegration',          N'OLEDB CVR2DBA',                   N'Data Source=bmat-ora01-p.prod.sitad.dk:1521/CVRDB.WORLD;User ID=CVR2DBA;Provider=OraOLEDB.Oracle.1;'),

	(N'DEV',                N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV1;TST1',          N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV2;TST2',          N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV2;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV3;TST3',          N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV3;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'DEV4;TST4',          N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=at-com-oracle.ncart.netcompany.dk/NCDEV4;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'T1',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=bmat-ora01-tc.prod.sitad.dk:1522/ATIST1;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'T2',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=bmat-ora01-tc.prod.sitad.dk:1522/ATIST2;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'T3',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=bmat-ora01-tc.prod.sitad.dk:1522/ATIST3;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
	(N'PP',                 N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=bmat-ora01-pp.prod.sitad.dk:1522/ATISPP.WORLD;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),
    (N'PROD',               N'Landingszone',                N'CvrIntegration',          N'OLEDB ATISDBA',                   N'Data Source=bmat-ora01-p.prod.sitad.dk:1521/ATISDB.WORLD;User ID=ATISDBA;Provider=OraOLEDB.Oracle.1;'),

-- RUT
    (N'DEV',                N'Landingszone',                N'RUT',                     N'ADO NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'RUT',                     N'ADO NET LZDB',                    N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV2;TST2',          N'Landingszone',                N'RUT',                     N'ADO NET LZDB',                    N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV3;TST3',          N'Landingszone',                N'RUT',                     N'ADO NET LZDB',                    N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'RUT',                     N'ADO NET LZDB',                    N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'RUT',                     N'ADO NET LZDB',                    N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),

    (N'DEV',                N'Landingszone',                N'RUT',                     N'ADO NET RUT',                     N'Data Source=.;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'RUT',                     N'ADO NET RUT',                     N'Data Source=.\Spor1;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV2;TST2',          N'Landingszone',                N'RUT',                     N'ADO NET RUT',                     N'Data Source=.\Spor2;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV3;TST3',          N'Landingszone',                N'RUT',                     N'ADO NET RUT',                     N'Data Source=.\Spor3;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'RUT',                     N'ADO NET RUT',                     N'Data Source=.\Spor4;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'RUT',                     N'ADO NET RUT',                     N'Data Source=.;Initial Catalog=RUT;Integrated Security=SSPI;'),

	(N'DEV',                N'Landingszone',                N'RUT',                     N'OLEDB ERST',			  			N'Data Source=.;Initial Catalog=RUT_ERST_LZ;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV1;TST1',          N'Landingszone',                N'RUT',                     N'OLEDB ERST', 		      			N'Data Source=.\Spor1;Initial Catalog=RUT_ERST_LZ;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV2;TST2',          N'Landingszone',                N'RUT',                     N'OLEDB ERST', 		      			N'Data Source=.\Spor2;Initial Catalog=RUT_ERST_LZ;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV3;TST3',          N'Landingszone',                N'RUT',                     N'OLEDB ERST', 		      			N'Data Source=.\Spor3;Initial Catalog=RUT_ERST_LZ;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV4;TST4',          N'Landingszone',                N'RUT',                     N'OLEDB ERST', 		      			N'Data Source=.\Spor4;Initial Catalog=RUT_ERST_LZ;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'RUT',                     N'OLEDB ERST', 		      			N'Data Source=.;Initial Catalog=RUT_ERST_LZ;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	
	(N'DEV',                N'Landingszone',                N'RUT',                     N'OLEDB RUT',			  			N'Data Source=.;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'RUT',                     N'OLEDB RUT', 		      			N'Data Source=.\Spor1;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV2;TST2',          N'Landingszone',                N'RUT',                     N'OLEDB RUT', 		      			N'Data Source=.\Spor2;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV3;TST3',          N'Landingszone',                N'RUT',                     N'OLEDB RUT', 		      			N'Data Source=.\Spor3;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'RUT',                     N'OLEDB RUT', 		      			N'Data Source=.\Spor4;Initial Catalog=RUT;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'RUT',                     N'OLEDB RUT', 		      			N'Data Source=.;Initial Catalog=RUT;Integrated Security=SSPI;'),
	
    (N'DEV',                N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV1;USERNAME=atisdba'),
    (N'DEV1;TST1',          N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV1;USERNAME=atisdba'),
    (N'DEV2;TST2',          N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV2;USERNAME=atisdba'),
    (N'DEV3;TST3',          N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV3;USERNAME=atisdba'),
    (N'DEV4;TST4',          N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=at-com-oracle.ncart.netcompany.dk/NCDEV1;USERNAME=atisdba'),
    (N'T1',                 N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=bmat-ora01-tc:1522/ATIST1;USERNAME=atisdba'),
    (N'T2',                 N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=bmat-ora01-tc:1522/ATIST2;USERNAME=atisdba'),
    (N'T3',                 N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=bmat-ora01-tc:1522/ATIST3;USERNAME=atisdba'),
    (N'PP',                 N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=bmat-ora01-pp:1522/ATISPP;USERNAME=atisdba'),
    (N'PROD',               N'Landingszone',                N'RUT',                     N'MSORA ATISDBA',                   N'SERVER=bmat-ora01-p/ATISDB.WORLD;USERNAME=atisdba'),

-- Staging	
	(N'DEV',                N'Landingszone',                N'Staging',                 N'OLEDB LZ AES_ATP',                N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Staging',                 N'OLEDB LZ AES_ATP',                N'Data Source=.\Spor1;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV2;TST2',          N'Landingszone',                N'Staging',                 N'OLEDB LZ AES_ATP',                N'Data Source=.\Spor2;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV3;TST3',          N'Landingszone',                N'Staging',                 N'OLEDB LZ AES_ATP',                N'Data Source=.\Spor3;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Staging',                 N'OLEDB LZ AES_ATP',                N'Data Source=.\Spor4;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Staging',                 N'OLEDB LZ AES_ATP',                N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Landingszone',    			N'Staging',   				N'OLEDB LZ ATIS',                   N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ ATIS',                   N'Data Source=.\Spor1;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ ATIS',                   N'Data Source=.\Spor2;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ ATIS',                   N'Data Source=.\Spor3;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ ATIS',                   N'Data Source=.\Spor4;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',    			N'Staging',   				N'OLEDB LZ ATIS',                   N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=.;Initial Catalog=ATIS;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=.\Spor1;Initial Catalog=DM;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=.\Spor2;Initial Catalog=DM;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=.\Spor3;Initial Catalog=DM;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=.\Spor4;Initial Catalog=DM;Integrated Security=SSPI;'),
	(N'T1;T2;T3',   		N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=.;Initial Catalog=DM;Integrated Security=SSPI;'),
	(N'PP',   				N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=BMAT-DZSQL-PP01;Initial Catalog=DM;Integrated Security=SSPI;'),
	(N'PROD',   			N'Landingszone',    			N'Staging',   				N'OLEDB DM',                   		N'Data Source=BMAT-DZSQL-P01;Initial Catalog=DM;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Landingszone',    			N'Staging',   				N'OLEDB LZ Staging',                N'Data Source=.;Initial Catalog=Staging;Integrated Security=SSPI;'),
	(N'DEV1;TST1',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ Staging',                N'Data Source=.\Spor1;Initial Catalog=Staging;Integrated Security=SSPI;'),
	(N'DEV2;TST2',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ Staging',                N'Data Source=.\Spor2;Initial Catalog=Staging;Integrated Security=SSPI;'),
	(N'DEV3;TST3',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ Staging',                N'Data Source=.\Spor3;Initial Catalog=Staging;Integrated Security=SSPI;'),
	(N'DEV4;TST4',          N'Landingszone',    			N'Staging',   				N'OLEDB LZ Staging',                N'Data Source=.\Spor4;Initial Catalog=Staging;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',    			N'Staging',   				N'OLEDB LZ Staging',                N'Data Source=.;Initial Catalog=Staging;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Landingszone',                N'Staging',                 N'OLEDB Master Data Services',      N'Data Source=.;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Staging',                 N'OLEDB Master Data Services',      N'Data Source=.\Spor1;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Staging',                 N'OLEDB Master Data Services',      N'Data Source=.\Spor2;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Staging',                 N'OLEDB Master Data Services',      N'Data Source=.\Spor3;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Staging',                 N'OLEDB Master Data Services',      N'Data Source=.\Spor4;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Staging',                 N'OLEDB Master Data Services',      N'Data Source=.;Initial Catalog=Master Data Services;Integrated Security=SSPI;'),
	
	(N'DEV',            	N'Landingszone',   				N'Staging',     			N'ADO.NET LZDB',       				N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',       	N'Landingszone',   				N'Staging',     			N'ADO.NET LZDB',       				N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',       	N'Landingszone',   				N'Staging',     			N'ADO.NET LZDB',       				N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',       	N'Landingszone',   				N'Staging',     			N'ADO.NET LZDB',       				N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',       	N'Landingszone',   				N'Staging',     			N'ADO.NET LZDB',       				N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',   				N'Staging',     			N'ADO.NET LZDB',       				N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	
	(N'DEV',            	N'Landingszone',   				N'Staging',     			N'ADO NET Staging',       			N'Data Source=.;Initial Catalog=Staging;Integrated Security=SSPI;'),
    (N'DEV1;TST1',       	N'Landingszone',   				N'Staging',     			N'ADO NET Staging',       			N'Data Source=.\Spor1;Initial Catalog=Staging;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',       	N'Landingszone',   				N'Staging',     			N'ADO NET Staging',       			N'Data Source=.\Spor2;Initial Catalog=Staging;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',       	N'Landingszone',   				N'Staging',     			N'ADO NET Staging',       			N'Data Source=.\Spor3;Initial Catalog=Staging;Integrated Security=SSPI;'),
    (N'DEV4;TST4',       	N'Landingszone',   				N'Staging',     			N'ADO NET Staging',       			N'Data Source=.\Spor4;Initial Catalog=Staging;Integrated Security=SSPI;'),
    (N'T1;T2;T3;PP;PROD',   N'Landingszone',   				N'Staging',     			N'ADO NET Staging',       			N'Data Source=.;Initial Catalog=Staging;Integrated Security=SSPI;'),
	
    (N'DEV',                N'Landingszone',                N'Staging',        			N'ADO.NET AES_ATP',                 N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Staging',        			N'ADO.NET AES_ATP',                 N'Data Source=.\Spor1;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Staging',        			N'ADO.NET AES_ATP',                 N'Data Source=.\Spor2;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Staging',        			N'ADO.NET AES_ATP',                 N'Data Source=.\Spor3;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Staging',        			N'ADO.NET AES_ATP',                 N'Data Source=.\Spor4;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Staging',        			N'ADO.NET AES_ATP',                 N'Data Source=.;Initial Catalog=AES_ATP;Integrated Security=SSPI;'),

	(N'DEV',            	N'Landingszone',   				N'Staging', 				N'MSORA AT6_DM',  					N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT6_DM'),
    (N'DEV1;TST1',        	N'Landingszone',   				N'Staging', 				N'MSORA AT6_DM',  					N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT6_DM'),
    (N'DEV2;TST2',        	N'Landingszone',   				N'Staging', 				N'MSORA AT6_DM',  					N'SERVER=NCAT-DW-U2.DWPROD;USERNAME=AT6_DM'),
    (N'DEV3;TST3',        	N'Landingszone',   				N'Staging', 				N'MSORA AT6_DM',  					N'SERVER=NCAT-DW-U3.DWPROD;USERNAME=AT6_DM'),
    (N'DEV4;TST4',        	N'Landingszone',   				N'Staging', 				N'MSORA AT6_DM',  					N'SERVER=NCAT-DW-U1.DWPROD;USERNAME=AT6_DM'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',   				N'Staging', 				N'MSORA AT6_DM',  					N'SERVER=BMATDW;USERNAME=AT6_DM'),
	

-- Probas
	(N'DEV',                N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV1;DEV3',          N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV1;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'DEV2;DEV4',          N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCDEV2;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST1;TST3',          N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST1;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'TST2;TST4',          N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=at-com-sql.ncart.netcompany.dk\PROBAS_NCTST2;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T1',                 N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=bmat-mssql01-t1.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T2',                 N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=bmat-mssql01-t2.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'T3',                 N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=bmat-mssql01-t3.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
	(N'PP',                 N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=bmat-mssql01-pp.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    (N'PROD',               N'Landingszone',                N'Probas',                  N'OLEDB Probas_src',                N'Data Source=bmat-mssql01-p.prod.sitad.dk,1435\PROBAS;Initial Catalog=Probas;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),

	(N'DEV',                N'Landingszone',                N'Probas',                 	N'OLEDB Probas_dst',				N'Data Source=.;Initial Catalog=Probas;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Probas',                 	N'OLEDB Probas_dst',				N'Data Source=.\Spor1;Initial Catalog=Probas;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Probas',                 	N'OLEDB Probas_dst',				N'Data Source=.\Spor2;Initial Catalog=Probas;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Probas',                 	N'OLEDB Probas_dst',				N'Data Source=.\Spor3;Initial Catalog=Probas;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Probas',                 	N'OLEDB Probas_dst',				N'Data Source=.\Spor4;Initial Catalog=Probas;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Probas',                 	N'OLEDB Probas_dst',				N'Data Source=.;Initial Catalog=Probas;Integrated Security=SSPI;'),
	
    (N'DEV',                N'Landingszone',                N'Probas',                 	N'ADO NET LZDB',					N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Probas',                 	N'ADO NET LZDB',					N'Data Source=.\Spor1;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Probas',                 	N'ADO NET LZDB',					N'Data Source=.\Spor2;Initial Catalog=LZDB;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Probas',                 	N'ADO NET LZDB',					N'Data Source=.\Spor3;Initial Catalog=LZDB;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Probas',                 	N'ADO NET LZDB',					N'Data Source=.\Spor4;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Probas',                 	N'ADO NET LZDB',					N'Data Source=.;Initial Catalog=LZDB;Integrated Security=SSPI;'),
	
	(N'DEV',                N'Landingszone',                N'Probas',					N'ADO NET Probas',                  N'Data Source=.;Initial Catalog=Probas;Integrated Security=SSPI;'),
    (N'DEV1;TST1',          N'Landingszone',                N'Probas',					N'ADO NET Probas',                  N'Data Source=.\Spor1;Initial Catalog=Probas;Integrated Security=SSPI;'),    
    (N'DEV2;TST2',          N'Landingszone',                N'Probas',					N'ADO NET Probas',                  N'Data Source=.\Spor2;Initial Catalog=Probas;Integrated Security=SSPI;'),    
    (N'DEV3;TST3',          N'Landingszone',                N'Probas',					N'ADO NET Probas',                  N'Data Source=.\Spor3;Initial Catalog=Probas;Integrated Security=SSPI;'),
    (N'DEV4;TST4',          N'Landingszone',                N'Probas',					N'ADO NET Probas',                  N'Data Source=.\Spor4;Initial Catalog=Probas;Integrated Security=SSPI;'),
	(N'T1;T2;T3;PP;PROD',   N'Landingszone',                N'Probas',					N'ADO NET Probas',                  N'Data Source=.;Initial Catalog=Probas;Integrated Security=SSPI;')


 

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
    PRINT 'Opretter miljø: ' + @folder + '\' + @environmentName

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

--_______________________________________
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
    PRINT 'Knytter miljø til projekt: ' + @folder + '\' + @project

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
    PRINT 'Sætter parameter: ' + @folder + '\' + @project + '\' + @parameter + ' = ' + CAST(@value AS NVARCHAR(500))

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
    PRINT 'Sætter connection string: ' + @folder + '\' + @project + '\' + @connection + ' = ' + CAST(@value AS NVARCHAR(500))

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

-- Reset status indicator
EXEC [SSISDB].sys.sp_dropextendedproperty @name=N'Environment setup status' 