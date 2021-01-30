CREATE TABLE [Dimension].[Vendor_T1]
(
    /* Keys */
    [EKey_Vendor] BIGINT NOT NULL,

	/* Details */
	[VendorID] int NULL,
	[Name] NVARCHAR (50) NULL,
	[AccountNumber] NVARCHAR (15) NULL,
	[CreditRating] tinyint NULL,

    /* Metadata*/
    [Meta_IsInferred] BIT NOT NULL,
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,
    [Meta_UpdateTime] DATETIME NULL,
    [Meta_UpdateJob] BIGINT NULL,
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL,

	/* Constraints */
	CONSTRAINT [PK_Vendor_T1] PRIMARY KEY CLUSTERED (EKey_Vendor),
)
GO
