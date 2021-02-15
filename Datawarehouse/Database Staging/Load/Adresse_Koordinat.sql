CREATE TABLE [Load].[Adresse_Koordinat]
(
	Ekey_Adresse											BIGINT			NOT NULL, 
	Etrs89koordinat_oest									REAL			NULL,
	Etrs89koordinat_nord									REAL			NULL,
	Wgs84koordinat_laengde									REAL			NULL,
	Wgs84koordinat_bredde									REAL			NULL,
	Vejnavn													NVARCHAR(500)	NULL,
	Husnummer												NVARCHAR(46)	NULL,
	Postnummer												SMALLINT		NULL,
	Kommune_Navn											VARCHAR (100)	NULL,
	Kommune_Kode											SMALLINT		NULL,	

	/* Metadata */
	Meta_Id			BIGINT IDENTITY (1,1)   NOT NULL,
    Meta_CreateTime DATETIME  NOT NULL,
    Meta_CreateJob  BIGINT    NOT NULL, -- Reference to the audit framework

	/* Constraints */
CONSTRAINT PK_Load_Adresse_Koordinat PRIMARY KEY CLUSTERED (Ekey_Adresse)
);