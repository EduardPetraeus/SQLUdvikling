CREATE TABLE [DMSA].[Dim_Produkt]
(
	[Ekey_Produkt]      BIGINT         NOT NULL,
	[Product_Id]        BIGINT         NOT NULL,
	[Product_Name]      VARCHAR(2000)  NULL,
	[Department]        NVARCHAR(100)  NULL,
	[Aisle]             NVARCHAR(100)  NULL,

	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Ekey_Dim_Produkt PRIMARY KEY CLUSTERED ([Ekey_Produkt])
);
GO