USE [Maintenance]
GO

DROP TABLE IF EXISTS [dbo].[temp_dbStats]
;
GO

Create Table [dbo].[temp_dbStats] (
    [TimeSampled] datetime NOT NULL,
	[DataBaseName] nvarchar(128) NULL, 
	[DataSpaceType] nvarchar(100) NULL, 
	[SizeGB] decimal(10,2) NULL, 
    [UsedGB] decimal(10,2) NULL, 
	[FreeGB] decimal(10,2) NULL, 
    [PcntUsed] decimal(10,2) NULL, 
	[PcntFree] decimal(10,2) NULL
);
GO
