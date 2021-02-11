CREATE TABLE [Meta].[VariblesForSSIS]
(
[Id]                   INT IDENTITY(1,1)           NOT NULL, 
[SchemaTableName]      NVARCHAR(200)               NULL,
[TableName]            NVARCHAR(200)               NULL, 
[TruncateTable]        NVARCHAR(200)               NULL,
[Year]                 SMALLINT	 	               NULL,
[DateCreated]          DATETIME  DEFAULT GETDATE() NULL,
CONSTRAINT PK_VariblesForSSIS_Id PRIMARY KEY CLUSTERED ([Id])
) 
GO
