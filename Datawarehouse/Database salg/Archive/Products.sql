CREATE TABLE [Archive].[Products]
(
    [Product_Id]                 INT            NOT NULL,
	[Product_Name]               VARCHAR(100)   NULL,
	[Aisle_Id]                   NVARCHAR(20)   NULL,
	[Department_Id]              NVARCHAR(20)   NULL,

	/* Metadata */               
    [Meta_Id]                    BIGINT       NOT NULL IDENTITY (1, 1),
    [Meta_VersionNo]             INT          NOT NULL,
    [Meta_ValidFrom]             DATETIME     NOT NULL,
    [Meta_ValidTo]               DATETIME     NULL,
    [Meta_IsValid]               BIT          NOT NULL, -- If false rows exists in data validation table
    [Meta_IsCurrent]             BIT          NOT NULL,
    [Meta_IsDeleted]             BIT          NOT NULL,
    [Meta_CreateTime]            DATETIME     NOT NULL,
    [Meta_CreateJob]             BIGINT       NOT NULL, -- Reference to the audit framework
    [Meta_UpdateTime]            DATETIME     NULL,
    [Meta_UpdateJob]             BIGINT       NULL, -- Reference to the audit framework
    [Meta_DeleteTime]            DATETIME     NULL,
    [Meta_DeleteJob]             BIGINT       NULL, -- Reference to the audit framework
          /* Constraints */
	CONSTRAINT PK_Archive_Products PRIMARY KEY CLUSTERED ([Product_Id], [Meta_ValidFrom])
);
GO
	
CREATE UNIQUE INDEX IDX_Archive_Products ON [Archive].[Products] ([Meta_Id])
