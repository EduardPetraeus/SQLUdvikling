CREATE TABLE [Load].[Dim_Produkt_Delta_Load]
(
	[Ekey_Produkt]      INT           NOT NULL,
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,
	[Source_UpdateJob]	BIGINT	      NULL,
	[Source_TableName]  NVARCHAR(50)  NULL,

	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Ekey_Dim_Produkt_Load_Delta PRIMARY KEY CLUSTERED ([Ekey_Produkt])
);
GO