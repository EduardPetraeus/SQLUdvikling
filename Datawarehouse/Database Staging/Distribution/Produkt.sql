CREATE TABLE [Distribution].[Produkt]
(
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,

	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME                     NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL,
	[Meta_UpdateTime]   DATETIME                     NULL,
	[Meta_UpdateJob]    BIGINT                       NULL, -- Reference to the audit framework
	[Meta_DeleteTime]   DATETIME                     NULL,
	[Meta_DeleteJob]    BIGINT                       NULL, -- Reference to the audit framework

CONSTRAINT PK_Distribution_Dim_Produkt_Id PRIMARY KEY CLUSTERED ([Product_Id])
);
GO