CREATE TABLE [Extract].[AdventureWorks2014_Purchasing_Vendor]
(
    /* Natural keys*/
   [BusinessEntityID] [int] NOT NULL,

    /* Attributes */
	[AccountNumber] NVARCHAR(15),
	[Name] NVARCHAR(50),
	[CreditRating] [tinyint],
	[PreferredVendorStatus] BIT,
	[ActiveFlag] BIT,
	[PurchasingWebServiceURL] [nvarchar](1024),
	[ModifiedDate] [datetime] ,

    /* Meta data */
    [Meta_Id] BIGINT IDENTITY (1, 1) NOT NULL,
    [Meta_CreateTime] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_CreateJob] BIGINT NULL,
    [Meta_ExternalJob] NVARCHAR (255) NULL,

    /* Constraints */
	CONSTRAINT [PK_AdventureWorks2014_Purchasing_Vendor] PRIMARY KEY CLUSTERED ([Meta_Id] ASC)
)
GO

CREATE INDEX [IDX_AdventureWorks2014_Purchasing_Vendor] ON [Extract].[AdventureWorks2014_Purchasing_Vendor] ([BusinessEntityID] ASC, [Meta_CreateTime] ASC)
GO
