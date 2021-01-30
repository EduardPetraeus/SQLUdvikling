CREATE TABLE [Map].[Product]
(
    /* Surrogate key */
    [EKey_Product]	BIGINT IDENTITY (1, 1) NOT NULL,

    /* Natural key */
    [ProductID] INT NOT NULL,

    /* Meta data */
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL,

    /* Constraints */
    CONSTRAINT [PK_Map_Product] PRIMARY KEY CLUSTERED ([EKey_Product] ASC),
	CONSTRAINT [UQ_Map_Product] UNIQUE ([ProductID])
	)
GO
