/*
CREATE TABLE [Map].[Template]
(
    /* Keys */
    [EKey_Template]	BIGINT IDENTITY (1, 1) NOT NULL,

    [BusinessKey1] NVARCHAR (120) NOT NULL,

    /* Metadata */
    [Meta_IsInferred] BIT NOT NULL,
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL,

    CONSTRAINT [PK_CoveredObject] PRIMARY KEY CLUSTERED ([BusinessKey1] ASC)
	)
GO

CREATE UNIQUE INDEX [IDX_CoveredObject_BusinessKey] ON [Map].[Template] ([EKey] ASC)
GO


*/