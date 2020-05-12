CREATE TABLE [System].[ArchiveQueue]
(
    [ExecutionId] BIGINT NOT NULL,
    [TableName] NVARCHAR (255) NOT NULL,

    /* Constraints */
    CONSTRAINT [PK_ArchiveQueue] PRIMARY KEY CLUSTERED ([ExecutionId] ASC, [TableName] ASC)
)
GO