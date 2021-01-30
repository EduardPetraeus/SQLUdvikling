CREATE TABLE [Archive].[AdventureWorks2014_Purchasing_PurchaseOrderHeader]
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



    /* Metadata */
    [Meta_Id] BIGINT NOT NULL IDENTITY (1, 1),
    [Meta_VersionNo] INT NOT NULL,
    [Meta_ValidFrom] DATETIME NOT NULL,
    [Meta_ValidTo] DATETIME NULL,
    [Meta_IsValid] BIT NOT NULL, -- If false rows exists in data validation table
    [Meta_IsCurrent] BIT NOT NULL,
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL, -- Reference to the audit framework
    [Meta_UpdateTime] DATETIME NULL,
    [Meta_UpdateJob] BIGINT NULL, -- Reference to the audit framework
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL, -- Reference to the audit framework
	[Meta_HashValue] VARBINARY(32) NOT NULL, -- Used to update the archive table

    /* Constraints */
	CONSTRAINT [PK_AdventureWorks2014_Purchasing_PurchaseOrderHeader] PRIMARY KEY CLUSTERED ([PurchaseOrderID] ASC,  [Meta_ValidFrom] ASC)
)
GO

CREATE UNIQUE INDEX [IDX_AdventureWorks2014_Purchasing_PurchaseOrderHeader] ON [Archive].[AdventureWorks2014_Purchasing_PurchaseOrderHeader] ([Meta_Id] ASC)
GO