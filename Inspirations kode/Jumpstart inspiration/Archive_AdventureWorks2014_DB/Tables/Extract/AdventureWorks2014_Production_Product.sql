CREATE TABLE [Extract].[AdventureWorks2014_Production_Product]
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

    /* Meta data */
    [Meta_Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [Meta_CreateTime] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_CreateJob] BIGINT NULL,
    [Meta_ExternalJob] NVARCHAR (255) NULL,

    /* Constraints */
	CONSTRAINT [PK_AdventureWorks2014_Production_Product] PRIMARY KEY CLUSTERED ([Meta_Id] ASC)
)
GO

CREATE INDEX [IDX_AdventureWorks2014_Production_Product] ON [Extract].[AdventureWorks2014_Production_Product] ([ProductID] ASC, [Meta_CreateTime] ASC)
GO
