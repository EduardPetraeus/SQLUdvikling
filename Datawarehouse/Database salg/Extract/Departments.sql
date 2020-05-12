CREATE TABLE [Extract].[Departments]
(
	[Department_Id]     INT                          NOT NULL,
	[Department]        NVARCHAR(100)                NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Department_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Department
ON [Extract].[Departments] ([Department_Id], [Meta_CreateTime])