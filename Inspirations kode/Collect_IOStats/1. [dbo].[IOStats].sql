USE [Maintenance]
GO

DROP TABLE IF EXISTS [dbo].[IOStats]
;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IOStats](
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[database_name] [nvarchar](128) NULL,
	[DatabaseFilename] [nvarchar](260) NULL,
	[Reads] [bigint] NULL,
	[Writes] [bigint] NULL,
	[ReadsPerSec] [decimal](10, 2) NULL,
	[WritesPerSec] [decimal](10, 2) NULL,
	[ReadKBPerSec] [decimal](10, 2) NULL,
	[KBPerRead] [decimal](10, 2) NULL,
	[KBPerWrite] [decimal](10, 2) NULL,
	[WriteKBPerSec] [decimal](10, 2) NULL,
	[AvgReadLatencyMs] [bigint] NULL,
	[AvgWriteLatencyMs] [bigint] NULL
)
;
GO
