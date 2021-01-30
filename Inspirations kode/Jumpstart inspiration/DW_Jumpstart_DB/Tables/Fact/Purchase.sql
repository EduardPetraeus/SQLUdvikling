CREATE TABLE [Fact].[Purchase]
(
	/* Business keys */
    [PurchaseOrderID] INT NOT NULL,  
	[PurchaseOrderDetailID] INT NOT NULL,  

    /* References */
    
	-- Regular references
	[EKey_Vendor] BIGINT NOT NULL,
	[EKey_Product] BIGINT NOT NULL,

	-- Roleplaying time dimension
	[EKey_Date_OrderDate] BIGINT NOT NULL,
	[EKey_Date_ShipDate] BIGINT NOT NULL,
	[EKey_Date_DueDate] BIGINT NOT NULL,

    /* Attributes and measures */
	[OrderQty] INT NULL,
	[UnitPrice] DECIMAL (18, 2),
	[LineTotal] DECIMAL (18, 2),

    /* Metadata */
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL, -- Reference to the audit framework

    /* Constraints */
    CONSTRAINT [PK_Purchase] PRIMARY KEY CLUSTERED ([PurchaseOrderID],[PurchaseOrderDetailID]),
    --CONSTRAINT [FK_Purchase_OrderDate] FOREIGN KEY ([EKey_Date_OrderDate]) REFERENCES [Dimension].[Date](EKey_Date),
	--CONSTRAINT [FK_Purchase_ShipDate] FOREIGN KEY ([EKey_Date_ShipDate]) REFERENCES [Dimension].[Date](EKey_Date),
	--CONSTRAINT [FK_Purchase_DueDate] FOREIGN KEY ([EKey_Date_DueDate]) REFERENCES [Dimension].[Date](EKey_Date),
	--CONSTRAINT [FK_Purchase_Vendor] FOREIGN KEY ([EKey_Vendor]) REFERENCES [Dimension].[Vendor_T1](EKey_Vendor),
)
GO
