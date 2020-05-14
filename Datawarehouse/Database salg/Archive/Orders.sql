CREATE TABLE [Archive].[Orders]
(
    [Order_Id]                 BIGINT                 NOT NULL,
	[User_Id]                  INT                    NULL,
	[Eval_Set]                 NVARCHAR(50)           NULL,
	[Order_Number]             INT                    NULL,
	[Order_Dow]                INT                    NULL,
	[Order_Hour_Of_Day]        INT                    NULL,
	[Days_Since_Prior_Order]   NVARCHAR(50)           NULL,

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
	CONSTRAINT PK_Archive_Orders PRIMARY KEY CLUSTERED ([Order_Id], [Meta_ValidFrom])
);
GO
	
CREATE UNIQUE INDEX IDX_Archive_Orders ON [Archive].[Orders] ([Meta_Id])
