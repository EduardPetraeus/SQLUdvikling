CREATE TABLE [Audit].[ExecutionQueue]
(
    [ExecutionId] BIGINT NOT NULL,
    [PackageID] NVARCHAR (50) NULL,
    [PackageName] NVARCHAR (260) NOT NULL,

    /* Constraints */
    CONSTRAINT [PK_ExecutionQueue] PRIMARY KEY CLUSTERED ([ExecutionId] ASC, [PackageName] ASC)
)
GO