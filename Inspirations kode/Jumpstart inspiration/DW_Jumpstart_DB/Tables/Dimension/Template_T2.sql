/*
CREATE TABLE [Dimension].[Template_T2]
(
    /* Keys */
    [HKey_Template] BIGINT IDENTITY (1,1) NOT NULL,
    [EKey_Template] BIGINT NOT NULL,

    /* References */
	[EKey_Date] BIGINT NOT NULL,

	/* Details */
	[Attribute1] NVARCHAR (100) NULL,
	[Attribute2] NVARCHAR (390) NULL,

    /* Metadata*/
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
	CONSTRAINT [PK_Template_T2] PRIMARY KEY CLUSTERED ([HKey_Template]),
    CONSTRAINT [FK_Template_T2_Date] FOREIGN KEY ([EKey_Date]) REFERENCES [Dimension].[Date]([EKey_Date]),
)
GO

CREATE INDEX [IDX_Template_T2_EKey] ON [Dimension].[Template_T2] ([EKey_Template] ASC) INCLUDE ([HKey_Template])
GO

*/