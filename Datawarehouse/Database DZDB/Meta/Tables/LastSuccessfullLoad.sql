CREATE TABLE [Meta].[LastSuccessfullLoad]
(
[Id]                   INT           NOT NULL PRIMARY KEY IDENTITY(1,1), 
[DestinationTableName] NVARCHAR(50)  NULL,
[SourceTableName]      NVARCHAR(50)  NULL, 
[LastSuccessfullJobId] BIGINT		 NULL
) 
GO

CREATE NONCLUSTERED INDEX IDX_TableName ON [Meta].[LastSuccessfullLoad] (DestinationTableName ASC)