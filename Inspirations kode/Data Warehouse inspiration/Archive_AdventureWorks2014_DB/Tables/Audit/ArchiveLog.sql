CREATE TABLE [Audit].[ArchiveLog]
(
    [Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [TableName] NVARCHAR (255) NOT NULL,
    [ExecutionId] BIGINT NULL,
    [StoredProcedureName] NVARCHAR (255) NULL,
    [StoredProcedureVersion] NVARCHAR (255) NULL,
    [Status] NVARCHAR (20) NULL,
    [StartTime] DATETIME2 NULL,
    [EndTime] DATETIME2 NULL,
    [RecordsSelected] INT NULL,
    [RecordsInserted] INT NULL,
    [RecordsUpdated] INT NULL,
    [RecordsFailed] INT NULL,
    [RecordsDeleted] INT NULL,
    [RecordsDiscarded] INT NULL,

    /* Constraints */
    CONSTRAINT [CHK_ArchiveLog_Status] CHECK ([Status] = 'Started' OR [Status] = 'Succeeded' OR [Status] = 'Failed'),
    CONSTRAINT [PK_ArchiveLog] PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO