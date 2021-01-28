CREATE TABLE [DMSA].[Dim_Produkt_Delta_Load]
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
CONSTRAINT PK_Ekey_Dim_Produkt_DMSA_Delta PRIMARY KEY CLUSTERED ([Ekey_Produkt])
);
GO