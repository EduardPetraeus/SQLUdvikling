CREATE TABLE [DMSA].[Staging_Dim_Produkt]
(
	[Ekey_Produkt]      INT           NOT NULL,
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,

	/* Metadata */
	[Meta_CreateTime]   DATETIME      NOT NULL,
	[Meta_CreateJob]	BIGINT		  NOT NULL,
	[Meta_UpdateTime]   DATETIME   	  NULL,
	[Meta_UpdateJob]    BIGINT	   	  NULL,
	[Meta_DeleteTime]   DATETIME   	  NULL,
	[Meta_DeleteJob]    BIGINT	   	  NULL
CONSTRAINT PK_Ekey_Staging_Dim_Produkt_DMSA PRIMARY KEY CLUSTERED ([Ekey_Produkt])
);
GO