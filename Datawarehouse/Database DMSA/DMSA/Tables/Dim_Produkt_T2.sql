CREATE TABLE [DMSA].[Dim_Produkt_T2]
(
    /* Keys */
    [HKey_Produkt] BIGINT IDENTITY (1,1) NOT NULL,
    [Ekey_Produkt] BIGINT NOT NULL,

    /* Details */
    [Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL,

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
	CONSTRAINT [PK_Dim_Produkt_T2] PRIMARY KEY CLUSTERED ([HKey_Produkt]),
)
GO

CREATE INDEX [IDX_Dim_Produkt_T2_EKey] ON [DMSA].[Dim_Produkt_T2] ([Ekey_Produkt] ASC) INCLUDE ([HKey_Produkt])
GO
