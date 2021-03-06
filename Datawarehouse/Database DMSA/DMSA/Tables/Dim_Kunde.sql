﻿CREATE TABLE [DMSA].[Dim_Kunde]
(
	[Ekey_Kunde]        INT                          NOT NULL,
	[Order_Id]          INT                          NOT NULL,
	[User_Id]           INT                          NULL,

	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

CONSTRAINT PK_Ekey_Dim_Kunde PRIMARY KEY CLUSTERED ([Ekey_Kunde])
);
GO