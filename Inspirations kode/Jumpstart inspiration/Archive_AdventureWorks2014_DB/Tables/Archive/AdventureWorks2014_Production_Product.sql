CREATE TABLE [Archive].[AdventureWorks2014_Production_Product]
(
    /* Natural keys*/
    [ProductID] [int] NOT NULL,

    /* Attributes */
	[Name] [nvarchar](50),
	[ProductNumber] [nvarchar](25) ,
	[MakeFlag] BIT ,
	[FinishedGoodsFlag] BIT ,
	[Color] [nvarchar](15) NULL,
	[SafetyStockLevel] [smallint] NOT NULL,
	[ReorderPoint] [smallint] NOT NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[SizeUnitMeasureCode] [nchar](3) NULL,
	[WeightUnitMeasureCode] [nchar](3) NULL,
	[Weight] [decimal](8, 2) NULL,
	[DaysToManufacture] [int]  NULL,
	[ProductLine] [nchar](2) NULL,
	[Class] [nchar](2) NULL,
	[Style] [nchar](2) NULL,
	[ProductSubcategoryID] [int] NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime]  NULL,
	[SellEndDate] [datetime] NULL,
	[DiscontinuedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] ,
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
	CONSTRAINT [PK_AdventureWorks2014_Production_Product] PRIMARY KEY CLUSTERED ([ProductID] ASC, [Meta_ValidFrom] ASC)
)
GO

CREATE UNIQUE INDEX [IDX_AdventureWorks2014_Production_Product] ON [Archive].[AdventureWorks2014_Production_Product] ([Meta_Id] ASC)
GO