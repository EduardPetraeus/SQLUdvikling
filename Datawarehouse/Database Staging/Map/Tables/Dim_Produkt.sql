CREATE TABLE [Map].[Dim_Produkt]
(   
    [Ekey_Produkt]          BIGINT         NOT NULL IDENTITY (1,1),
	[Product_Id]            BIGINT         NOT NULL,

    /* Metadata */
	[Meta_IsDeleted]		BIT			   NOT NULL,
    [Meta_CreateTime]		DATETIME       NOT NULL,
    [Meta_CreateJob]		BIGINT         NOT NULL,
   	[Meta_DeleteTime]		DATETIME       NULL,
   	[Meta_DeleteJob]		BIGINT         NULL,
    
	CONSTRAINT [PK_Map_Dim_Produkt] PRIMARY KEY CLUSTERED ([Ekey_Produkt] ASC),
	CONSTRAINT [UQ_Map_Dim_Produkt] UNIQUE ([Product_Id])
)
