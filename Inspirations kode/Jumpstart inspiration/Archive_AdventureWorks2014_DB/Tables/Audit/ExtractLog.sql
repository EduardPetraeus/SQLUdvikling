CREATE TABLE [Audit].[ExtractLog]
(
    [Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [TableName] NVARCHAR (100) NOT NULL,
    [ExecutionId] BIGINT NULL,
    [ExternalId] NVARCHAR (255) NULL,
    [Status] NVARCHAR (20) NULL,
    [StartTime] DATETIME2 NULL,
    [EndTime] DATETIME2 NULL,
    [IsFullLoad] BIT NULL,
    [IsClearingLoad] BIT NULL,
    [RecordsSelected] INT NULL,
    [RecordsInserted] INT NULL,
    [RecordsFailed] INT NULL,
    [RecordsDiscarded] INT NULL,
    [ArchiveId] BIGINT NULL,
    [ArchiveTime] DATETIME2 NULL,

    /* Constraints */
    CONSTRAINT [CHK_ExtractLog_Status] CHECK ([Status] = 'Started' OR [Status] = 'Succeeded' OR [Status] = 'Failed'),
    CONSTRAINT [PK_ExtractLog] PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO