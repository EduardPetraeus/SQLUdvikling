CREATE TABLE [Extract].[AdventureWorks2014_Purchasing_ProductVendor]
(
    /* Natural keys*/
    [ProductID] [int] NOT NULL,
    [BusinessEntityID] [int] NOT NULL,

    /* Attributes */
	[AverageLeadTime] [int]  NULL,
	[StandardPrice] [money]  NULL,
	[LastReceiptCost] [money] NULL,
	[LastReceiptDate] [datetime] NULL,
	[MinOrderQty] [int]  NULL,
	[MaxOrderQty] [int]  NULL,
	[OnOrderQty] [int] NULL,
	[UnitMeasureCode] [nchar](3)  NULL,
	[ModifiedDate] [datetime] ,


    /* Meta data */
    [Meta_Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [Meta_CreateTime] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_CreateJob] BIGINT NULL,
    [Meta_ExternalJob] NVARCHAR (255) NULL,

    /* Constraints */
	CONSTRAINT [PK_AdventureWorks2014_Purchasing_ProductVendor] PRIMARY KEY CLUSTERED ([Meta_Id] ASC)
)
GO

CREATE INDEX [IDX_AdventureWorks2014_Purchasing_ProductVendor] ON [Extract].[AdventureWorks2014_Purchasing_ProductVendor] ([ProductID] ASC, [BusinessEntityID] ASC, [Meta_CreateTime] ASC)
GO
