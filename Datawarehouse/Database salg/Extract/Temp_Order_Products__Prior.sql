CREATE TABLE [Extract].[Temp_Order_Products__Prior]
(   
    [Id_Order_Products__Prior] INT    IDENTITY (1,1) NOT NULL,
	[Order_Id]                 INT                   NOT NULL,
	[Product_Id]               INT                   NOT NULL,
	[Add_To_Cart_Order]        SMALLINT              NOT NULL,
	[Reordered]                SMALLINT              NOT NULL,


	CONSTRAINT PK_Temp_Order_Products_PriorOrder_Products__Prior_Id PRIMARY KEY CLUSTERED ([Id_Order_Products__Prior])
)
GO

