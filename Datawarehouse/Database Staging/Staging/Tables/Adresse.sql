CREATE TABLE [Staging].[Adresse]
(
	[Ekey_Adresse]				BIGINT IDENTITY(1,1)			NOT NULL,
	[Vejnavn]					NVARCHAR(500)	NULL,
	[Husnummer]					NVARCHAR(46)	NULL,
	[Postnummer]				SMALLINT		NULL,



	/* Metadata*/
    Meta_CreateTime		DATETIME DEFAULT GETDATE() NOT NULL,
    Meta_CreateJob		BIGINT		               NULL, -- Reference to the audit framework
    Meta_UpdateTime		DATETIME		           NULL,
    Meta_UpdateJob		BIGINT			           NULL, -- Reference to the audit framework
    Meta_DeleteTime		DATETIME		           NULL,
    Meta_DeleteJob		BIGINT			           NULL, -- Reference to the audit framework

	/* Constraints */
CONSTRAINT PK_Staging_Adresse PRIMARY KEY CLUSTERED ([Ekey_Adresse])
);
GO

