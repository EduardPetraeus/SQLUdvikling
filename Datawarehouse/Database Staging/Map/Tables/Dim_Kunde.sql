CREATE TABLE [Map].[Dim_Kunde]
(   
    [Ekey_Dim_Kunde]      BIGINT         NOT NULL IDENTITY (1,1),
	[Order_Id]            BIGINT         NOT NULL,

    /* Metadata */
	[Meta_IsDeleted]		BIT			   NOT NULL,
    [Meta_CreateTime]		DATETIME       NOT NULL,
    [Meta_CreateJob]		BIGINT         NOT NULL,
   	[Meta_DeleteTime]		DATETIME       NULL,
   	[Meta_DeleteJob]		BIGINT         NULL,
    
	CONSTRAINT [PK_Map_Dim_Kunde] PRIMARY KEY CLUSTERED ([Ekey_Dim_Kunde] ASC),
	CONSTRAINT [UQ_Map_Dim_Kunde] UNIQUE ([Order_Id])
)
