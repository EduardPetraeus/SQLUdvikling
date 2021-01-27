CREATE TABLE [Audit].[DMSALog] (
    [Id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [Database]         NVARCHAR (255) NULL,
    [TableName]        NVARCHAR (100) NOT NULL,
	[Schema]		   NVARCHAR (255) NULL,
    [ExecutionId]      BIGINT         NULL,
    [Status]           NVARCHAR (20)  NULL,
    [StartTime]        DATETIME2 (7)  NULL,
    [EndTime]          DATETIME2 (7)  NULL,
    [RecordsSelected]  INT            NULL,
    [RecordsInserted]  INT            NULL,
    [RecordsUpdated]   INT DEFAULT 0  NULL,
    [RecordsFailed]    INT            NULL,
    [RecordsDiscarded] INT            NULL

    CONSTRAINT [PK_DMSALog] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [CHK_DMSALog_Status] CHECK ([Status]='Started' OR [Status]='Succeeded' OR [Status]='Failed')
);

