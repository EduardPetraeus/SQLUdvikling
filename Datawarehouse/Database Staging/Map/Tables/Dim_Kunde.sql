﻿CREATE TABLE [Map].[Dim_Kunde]
(   
    [Ekey_Kunde]          INT            NOT NULL IDENTITY (1,1),
	[Order_Id]            INT            NOT NULL,

    /* Metadata */
	[Meta_IsDeleted]		BIT			   NOT NULL,
    [Meta_CreateTime]		DATETIME       NOT NULL,
    [Meta_CreateJob]		BIGINT         NOT NULL,
   	[Meta_DeleteTime]		DATETIME       NULL,
   	[Meta_DeleteJob]		BIGINT         NULL,
    
	CONSTRAINT [PK_Map_Dim_Kunde] PRIMARY KEY CLUSTERED ([Ekey_Kunde] ASC),
	CONSTRAINT [UQ_Map_Dim_Kunde] UNIQUE ([Order_Id])
)
