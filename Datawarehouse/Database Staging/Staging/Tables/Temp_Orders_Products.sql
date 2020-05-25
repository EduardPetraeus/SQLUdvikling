CREATE TABLE [Staging].[Temp_Orders_Products]
(
	[Id_Order_Products]          INT          NOT NULL IDENTITY (1,1),
	[Order_Id]                   INT          NOT NULL,
	[Product_Id]                 INT          NOT NULL,
	[Add_To_Cart_Order]          SMALLINT     NOT NULL,
	[Reordered]                  SMALLINT     NOT NULL,

	CONSTRAINT PK_Orders_Products_Id PRIMARY KEY CLUSTERED ([Id_Order_Products])
)
