CREATE TABLE [Staging].[Dim_Kunde]
(
	[Order_Id]                 BIGINT                 NOT NULL,
	[User_Id]                  INT                    NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Staging_Dim_Kunde_Id PRIMARY KEY CLUSTERED ([Order_Id])
);
GO