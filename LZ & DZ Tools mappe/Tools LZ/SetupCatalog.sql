IF NOT EXISTS(SELECT 1 FROM SSISDB.catalog.folders WHERE name = 'Landingszone')
	EXEC [SSISDB].[catalog].[create_folder] @folder_name = N'Landingszone'
GO

IF NOT EXISTS(SELECT 1 FROM SSISDB.catalog.folders WHERE name = 'Fasttrack')
	EXEC [SSISDB].[catalog].[create_folder] @folder_name = N'Fasttrack'
GO