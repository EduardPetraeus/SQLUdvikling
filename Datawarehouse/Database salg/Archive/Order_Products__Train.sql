CREATE TABLE [Archive].[Order_Products__Train]
(
    [Id_Order_Products__Train]   INT          NOT NULL,
	[Order_Id_Train]             INT          NOT NULL,
	[Product_Id_Train]           INT          NOT NULL,
	[Add_To_Cart_Order_Train]    SMALLINT     NOT NULL,
	[Reordered_Train]            SMALLINT     NOT NULL,
                                 
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
	CONSTRAINT PK_Archive_Order_Products__Train PRIMARY KEY CLUSTERED ([Id_Order_Products__Train], [Meta_ValidFrom])
);
GO
	
CREATE UNIQUE INDEX IDX_Archive_Order_Products__Train ON [Archive].[Order_Products__Train] ([Meta_Id])
