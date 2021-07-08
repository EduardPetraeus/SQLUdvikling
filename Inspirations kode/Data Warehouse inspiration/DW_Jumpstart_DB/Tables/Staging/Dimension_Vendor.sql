CREATE TABLE [Staging].[Dimension_Vendor] ( 
	
	/* Natrual key */
	[VendorID] int NOT NULL,

	/* Attributes */
	[Name] NVARCHAR (50) NULL,
	[AccountNumber] NVARCHAR (15) NULL,
	[CreditRating] tinyint NULL,

	/* Meta */
    [Meta_ValidFrom] DATETIME NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,

	CONSTRAINT [PK_Dimension_Vendor] PRIMARY KEY CLUSTERED ([VendorID] ASC)
)


;
