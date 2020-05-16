CREATE TABLE [Audit].[CubeLog](
    [Id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExecutionId]      BIGINT         NULL,
    [Status]           NVARCHAR (20)  NULL,
    [StartTime]        DATETIME2 (7)  NULL,
    [EndTime]          DATETIME2 (7)  NULL,
    [CubeName]         NVARCHAR (255) NULL,
	[TableName]        NVARCHAR (100) NULL,
	[RecordsSelected]  INT            NULL,
	[RecordsProcessed] INT            NULL
    
    

    CONSTRAINT [PK_CubeLog] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [CHK_CubeLog_Status] CHECK ([Status]='Started' OR [Status]='Succeeded' OR [Status]='Failed')
);
