CREATE TABLE [Staging].[Dimension_Product]
(
    /* Natrual key */
    [ProductID] INT NOT NULL,

    /* Attributes */
	[Name] NVARCHAR(50) NULL,
	[ProductNumber] NVARCHAR(25) NULL,
    [StandardCost] MONEY NULL,
	[ListPrice] MONEY NULL,

	/* Meta data */
    [Meta_ValidFrom] DATETIME NOT NULL, -- Madatory for T2 dimensions
    [Meta_Id] BIGINT IDENTITY NOT NULL, -- Madatory for T2 dimensions
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,

	/* Constraints */
    CONSTRAINT [PK_Dimension_Product] PRIMARY KEY ([ProductID] ASC, [Meta_ValidFrom] ASC),
)
GO
