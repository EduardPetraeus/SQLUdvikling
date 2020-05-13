CREATE TABLE [Extract].[Order_Products__Train]
(   
    [Id_Order_Products__Train]       BIGINT          NOT NULL,
	[Order_Id_Train]                 INT             NOT NULL,
	[Product_Id_Train]               INT             NOT NULL,
	[Add_To_Cart_Order_Train]        INT             NOT NULL,
	[Reordered_Train]                INT             NOT NULL,


	/* Metadata */
	[Meta_Id]           BIGINT   IDENTITY (1,1)      NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Order_Products__Train_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Order_Products__Train
ON [Extract].[Order_Products__Train] ([Id_Order_Products__Train], [Meta_CreateTime])