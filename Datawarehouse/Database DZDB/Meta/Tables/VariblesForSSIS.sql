CREATE TABLE [Meta].[VariblesForSSIS]
(
[Id]                   INT IDENTITY(1,1)           NOT NULL, 
[SchemaTableName]      NVARCHAR(200)               NULL,
[TableName]            NVARCHAR(200)               NULL, 
[TruncateTable]        NVARCHAR(200)               NULL,
[Year]                 SMALLINT	 	               NULL,
[DateCreated]          DATETIME  DEFAULT GETDATE() NULL,
[Ajour_Antal]          INT       DEFAULT 0         NOT NULL,
[Valid_From_Day]       SMALLINT  DEFAULT 1         NOT NULL,
[Valid_To_Day]         SMALLINT  DEFAULT 1         NOT NULL,
CONSTRAINT PK_VariblesForSSIS_Id PRIMARY KEY CLUSTERED ([Id])
) 
GO
