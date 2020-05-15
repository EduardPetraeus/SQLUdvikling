CREATE TABLE [Staging].[Temp_Orders_Products]
(
	[Id_Order_Products]          BIGINT       NOT NULL IDENTITY (1,1),
	[Order_Id]                   INT          NOT NULL,
	[Product_Id]                 INT          NOT NULL,
	[Add_To_Cart_Order]          INT          NOT NULL,
	[Reordered]                  INT          NOT NULL,

	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Orders_Products_Id PRIMARY KEY CLUSTERED ([Id_Order_Products])
)
