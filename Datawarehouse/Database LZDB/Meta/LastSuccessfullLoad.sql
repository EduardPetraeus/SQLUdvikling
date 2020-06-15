CREATE TABLE [Meta].[LastSuccessfullLoad]
(
[Id] INT NOT NULL PRIMARY KEY IDENTITY(1,1),
[DestinationTableName] NVARCHAR(255),
[SourceTableName] NVARCHAR(255), 
[LastSuccessfullJobId] BIGINT
) 
GO

CREATE NONCLUSTERED INDEX IDX_TableName ON [Meta].[LastSuccessfullLoad] (DestinationTableName ASC)