CREATE TABLE [Archive].[AdventureWorks2014_Purchasing_ProductVendor]
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
	CONSTRAINT [PK_AdventureWorks2014_Purchasing_ProductVendor] PRIMARY KEY CLUSTERED ([ProductID] ASC, [BusinessEntityID] ASC, [Meta_ValidFrom] ASC)
)
GO

CREATE UNIQUE INDEX [IDX_AdventureWorks2014_Purchasing_ProductVendor] ON [Archive].[AdventureWorks2014_Purchasing_ProductVendor] ([Meta_Id] ASC)
GO