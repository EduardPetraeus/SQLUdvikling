CREATE TABLE [Map].[Vendor]
(
    /* Surrogate key */
    [EKey_Vendor] BIGINT IDENTITY (1, 1) NOT NULL,

    /* Natural key */
    [VendorID] int NOT NULL,

    /* Meta data */
    [Meta_IsDeleted] BIT NOT NULL,
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,
    [Meta_DeleteTime] DATETIME NULL,
    [Meta_DeleteJob] BIGINT NULL,

    CONSTRAINT [PK_Map_Vendor] PRIMARY KEY CLUSTERED (VendorID ASC),
	CONSTRAINT [UQ_Map_Vendor_EKey] UNIQUE ([EKey_Vendor])
	)
GO
