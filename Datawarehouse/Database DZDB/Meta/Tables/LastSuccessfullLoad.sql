CREATE TABLE [Meta].[LastSuccessfullLoad]
(
[Id]                   INT IDENTITY(1,1) NOT NULL, 
[DestinationTableName] NVARCHAR(50)      NULL,
[SourceTableName]      NVARCHAR(50)      NULL, 
[LastSuccessfullJobId] BIGINT	 	     NULL,
[DateCreated]          DATETIME          NULL,
[DateModified]         DATETIME          NULL,
CONSTRAINT PK_LastSuccessfullLoad_Id PRIMARY KEY CLUSTERED ([Id])
) 
GO

CREATE NONCLUSTERED INDEX NCIX_Source_Destination_TableName ON [Meta].[LastSuccessfullLoad] (DestinationTableName ASC,[SourceTableName] ASC)