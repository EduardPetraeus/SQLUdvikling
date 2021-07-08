CREATE TABLE [Audit].[DataTransferLog]
(
    [Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [SchemaName] NVARCHAR (255) NOT NULL,
    [TableName] NVARCHAR (255) NOT NULL,
    [Source] NVARCHAR(1000) NULL,
    [ExecutionId] BIGINT NULL,
    [TaskID] NVARCHAR (50) NULL,
	[TaskName] NVARCHAR (260) NULL,
    [StoredProcedureName] NVARCHAR (255) NULL,
    [StoredProcedureVersion] NVARCHAR (255) NULL,
    [TableTruncated] BIT NULL,
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
    CONSTRAINT [CHK_DataTransferLog_Status] CHECK ([Status] = 'Started' OR [Status] = 'Succeeded' OR [Status] = 'Failed'),
    CONSTRAINT [PK_DataTransferLog] PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO