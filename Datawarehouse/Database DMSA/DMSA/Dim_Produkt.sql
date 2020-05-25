CREATE TABLE [DMSA].[Dim_Produkt]
(
	[Ekey_Produkt]      INT           NOT NULL,
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,

	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Ekey_Dim_Produkt PRIMARY KEY CLUSTERED ([Ekey_Produkt])
);
GO