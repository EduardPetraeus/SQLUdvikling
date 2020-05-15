CREATE TABLE [Staging].[Dim_Produkt]
(
	[Product_Id]        BIGINT         NOT NULL,
	[Product_Name]      VARCHAR(2000)  NULL,
	[Department]        NVARCHAR(100)  NULL,
	[Aisle]             NVARCHAR(100)  NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Staging_Dim_Produkt_Id PRIMARY KEY CLUSTERED ([Product_Id])
);
GO