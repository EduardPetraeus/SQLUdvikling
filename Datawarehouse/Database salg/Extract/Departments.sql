CREATE TABLE [Extract].[Departments]
(
	[Department_Id]     SMALLINT                     NOT NULL,
	[Department]        NVARCHAR(30)                 NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Department_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Department
ON [Extract].[Departments] ([Department_Id], [Meta_CreateTime])