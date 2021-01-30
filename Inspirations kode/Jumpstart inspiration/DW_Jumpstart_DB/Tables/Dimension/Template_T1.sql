/*CREATE TABLE [Dimension].[Template_T1]
(
    /* Keys */
    [EKey_Template] BIGINT NOT NULL,

    /* References */
	[EKey_Date] BIGINT NOT NULL,

	/* Details */
	[Attribute1] NVARCHAR (100) NULL,
	[Attribute2] NVARCHAR (390) NULL,

    /* Meta data */
    [Meta_IsInferred] BIT NOT NULL,
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,
    [Meta_UpdateTime] DATETIME NULL,
    [Meta_UpdateJob] BIGINT NULL,
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL,

	/* Constraints */
	CONSTRAINT [PK_Template_T1] PRIMARY KEY CLUSTERED (EKey),
    CONSTRAINT [FK_Template_T1_Date] FOREIGN KEY ([EKey_Date]) REFERENCES [Dimension].[Date]([EKey_Date]),
)
GO
*/