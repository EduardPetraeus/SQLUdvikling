CREATE TABLE [Audit].[StagingLog] (
    [Id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [Database]         NVARCHAR (255) NULL,
    [TableName]        NVARCHAR (100) NOT NULL,
	[Schema]		   NVARCHAR (255) NULL,
    [ExecutionId]      BIGINT         NULL,
    [Status]           NVARCHAR (20)  NULL,
    [StartTime]        DATETIME2 (7)  NULL,
    [EndTime]          DATETIME2 (7)  NULL,
    [IsFullLoad]       BIT            NULL,
    [RecordsSelected]  INT            NULL,
    [RecordsInserted]  INT            NULL,
    [RecordsFailed]    INT            NULL,
	[RecordsDiscarded] INT			  NULL
    CONSTRAINT [PK_StagingLog] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [CHK_StagingLog_Status] CHECK ([Status]='Started' OR [Status]='Succeeded' OR [Status]='Failed')
);

