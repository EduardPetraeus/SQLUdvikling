CREATE TABLE [Dimension].[Product_T1]
(
    /* Keys */
    [EKey_Product] BIGINT NOT NULL,

    /* Attributes */
    [ProductID] INT NULL,
    [Name] NVARCHAR(50) NULL,
    [ProductNumber] NVARCHAR(25) NULL,

    /* Meta data*/
    [Meta_IsInferred] BIT NOT NULL,
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,
    [Meta_UpdateTime] DATETIME NULL,
    [Meta_UpdateJob] BIGINT NULL,
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL,

    /* Constraints */
    CONSTRAINT [PK_Product_T1] PRIMARY KEY CLUSTERED ([EKey_Product]),
)
GO
