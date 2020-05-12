CREATE TABLE [Extract].[Aisles]
(
	[Aisle_Id]          INT                          NOT NULL,
	[Aisle]             NVARCHAR(100)                NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Aisles_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Aisles
ON [Extract].[Aisles] ([Aisle_Id], [Meta_CreateTime])