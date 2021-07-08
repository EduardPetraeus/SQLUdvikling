CREATE TABLE [Extract].[AdventureWorks2014_Purchasing_PurchaseOrderDetail]
(
    /* Natural keys*/
	[PurchaseOrderID] [int] NOT NULL,
	[PurchaseOrderDetailID] [int] NOT NULL,

    /* Attributes */

	[DueDate] [datetime] ,
	[OrderQty] [smallint]  NULL,
	[ProductID] [int]  NULL,
	[UnitPrice] [money]  NULL,
	[LineTotal]   [money]  NULL,
	[ReceivedQty] [decimal](8, 2)  NULL,
	[RejectedQty] [decimal](8, 2)  NULL,
	[StockedQty]  [decimal](8, 2),
	[ModifiedDate] [datetime] ,

    /* Meta data */
    [Meta_Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [Meta_CreateTime] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_CreateJob] BIGINT NULL,
    [Meta_ExternalJob] NVARCHAR (255) NULL,

    /* Constraints */
	CONSTRAINT [PK_AdventureWorks2014_Purchasing_PurchaseOrderDetail] PRIMARY KEY CLUSTERED ([Meta_Id] ASC)
)
GO

CREATE INDEX [IDX_AdventureWorks2014_Purchasing_PurchaseOrderDetail] ON [Extract].[AdventureWorks2014_Purchasing_PurchaseOrderDetail] ([PurchaseOrderID] ASC, [PurchaseOrderDetailID] ASC, [Meta_CreateTime] ASC)
GO
