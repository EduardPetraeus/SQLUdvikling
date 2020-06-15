CREATE TABLE [Load].[Produkt]
(
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,
	[Source_UpdateJob]  BIGINT		  NULL,
	[Source_TableName]  NVARCHAR(40)  NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Load_Dim_Produkt_Id PRIMARY KEY CLUSTERED ([Product_Id])
);
GO