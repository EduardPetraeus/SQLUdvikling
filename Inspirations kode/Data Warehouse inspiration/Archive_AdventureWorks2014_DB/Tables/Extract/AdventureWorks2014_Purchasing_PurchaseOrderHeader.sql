CREATE TABLE [Extract].[AdventureWorks2014_Purchasing_PurchaseOrderHeader]
(
    /* Natural keys*/
	[PurchaseOrderID] [int] NOT NULL,

    /* Attributes */
	[RevisionNumber] [tinyint],
	[Status] [tinyint],
	[EmployeeID] [int],
	[VendorID] [int] ,
	[ShipMethodID] [int] ,
	[OrderDate] [datetime],
	[ShipDate] [datetime],
	[SubTotal] [money],
	[TaxAmt] [money],
	[Freight] [money] ,
	[TotalDue]  [money] ,
	[ModifiedDate] [datetime],


    /* Meta data */
    [Meta_Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [Meta_CreateTime] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_CreateJob] BIGINT NULL,
    [Meta_ExternalJob] NVARCHAR (255) NULL,

    /* Constraints */
	CONSTRAINT [PK_AdventureWorks2014_Purchasing_PurchaseOrderHeader] PRIMARY KEY CLUSTERED ([Meta_Id] ASC)
)
GO

CREATE INDEX [IDX_PK_AdventureWorks2014_Purchasing_PurchaseOrderHeader] ON [Extract].[AdventureWorks2014_Purchasing_PurchaseOrderHeader] ([PurchaseOrderID] ASC, [Meta_CreateTime] ASC)
GO
