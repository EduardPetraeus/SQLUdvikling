CREATE TABLE [Extract].[Order_Products__Prior]
(   
    [Id_Order_Products__Prior] BIGINT                NOT NULL,
	[Order_Id]                 INT                   NOT NULL,
	[Product_Id]               INT                   NOT NULL,
	[Add_To_Cart_Order]        INT                   NOT NULL,
	[Reordered]                INT                   NOT NULL,


	/* Metadata */
	[Meta_Id]           BIGINT   IDENTITY (1,1)      NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Order_Products__Prior_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Order_Products__Prior
ON [Extract].[Order_Products__Prior] ([Id_Order_Products__Prior], [Meta_CreateTime])