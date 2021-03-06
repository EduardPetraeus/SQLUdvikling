﻿CREATE TABLE [Extract].[Products]
(   
    [Product_Id]               INT                   NOT NULL,
	[Product_Name]             VARCHAR(100)          NULL,
	[Aisle_Id]                 NVARCHAR(20)          NULL,
	[Department_Id]            NVARCHAR(20)          NULL,

	/* Metadata */
	[Meta_Id]           BIGINT   IDENTITY (1,1)      NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Products_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Products
ON [Extract].[Products] ([Product_Id], [Meta_CreateTime])