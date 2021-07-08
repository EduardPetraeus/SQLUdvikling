CREATE TABLE [Dimension].[Product_T2]
(
    /* Keys */
    [HKey_Product] BIGINT IDENTITY (1,1) NOT NULL,
    [EKey_Product] BIGINT NOT NULL,

    /* Details */
    [StandardCost] MONEY NULL,
	[ListPrice] MONEY NULL,

    /* Meta data*/
    [Meta_ValidFrom] DATETIME NOT NULL,
    [Meta_ValidTo] DATETIME NULL,
    [Meta_IsCurrent] BIT NOT NULL,
    [Meta_IsInferred] BIT NOT NULL,
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL, -- Reference to the audit framework
    [Meta_UpdateTime] DATETIME NULL,
    [Meta_UpdateJob] BIGINT NULL, -- Reference to the audit framework
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL, -- Reference to the audit framework

	/* Constraints */
	CONSTRAINT [PK_Product_T2] PRIMARY KEY CLUSTERED ([HKey_Product]),
)
GO

CREATE INDEX [IDX_Product_T2_EKey] ON [Dimension].[Product_T2] ([EKey_Product] ASC) INCLUDE ([HKey_Product])
GO
