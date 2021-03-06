﻿CREATE TABLE [DMSA_History].[Dim_Produkt_Delta_Load]
(   [Hkey_Produkt]      INT IDENTITY(1,1)  NOT NULL,
	[Ekey_Produkt]      INT                NOT NULL,
	[Product_Id]        INT                NOT NULL,
	[Product_Name]      VARCHAR(100)       NULL,
	[Department]        NVARCHAR(30)       NULL,
	[Aisle]             NVARCHAR(50)       NULL,

	/* Metadata */
	[Insert_Datetime]   DATETIME           NOT NULL,

CONSTRAINT PK_Hkey_Dim_Produkt_Delta_Load PRIMARY KEY CLUSTERED ([Hkey_Produkt])
);
GO

CREATE INDEX [IDX_Dim_Produkt_EKey_Delta_Load] ON [DMSA_History].[Dim_Produkt_Delta_Load] ([Ekey_Produkt] ASC) INCLUDE ([Hkey_Produkt])
GO