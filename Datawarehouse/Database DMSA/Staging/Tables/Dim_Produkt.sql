CREATE TABLE [Staging].[Dim_Produkt]
(   
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,

   /* Meta data*/
    [Meta_Id] BIGINT IDENTITY (1,1) NOT NULL,
    [Meta_ValidFrom] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_ValidTo] DATETIME NULL,
    [Meta_CreateTime] DATETIME DEFAULT GETDATE() NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL, -- Reference to the audit framework


CONSTRAINT PK_Staging_Dim_Produkt_Id PRIMARY KEY CLUSTERED ([Product_Id])
);
GO