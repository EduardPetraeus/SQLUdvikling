CREATE TABLE [Extract].[Temp_Order_Products__Train]
(   
    [Id_Order_Products__Train]       BIGINT IDENTITY (1,1) NOT NULL,
	[Order_Id_Train]                 INT                   NOT NULL,
	[Product_Id_Train]               INT                   NOT NULL,
	[Add_To_Cart_Order_Train]        INT                   NOT NULL,
	[Reordered_Train]                INT                   NOT NULL,


	CONSTRAINT PK_Temp_Order_Products__Train_Id PRIMARY KEY CLUSTERED ([Id_Order_Products__Train])
)
GO

