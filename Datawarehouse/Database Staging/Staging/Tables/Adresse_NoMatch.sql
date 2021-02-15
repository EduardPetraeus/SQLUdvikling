CREATE TABLE [Staging].[Adresse_NoMatch]
(
	EKey_Adresse								BIGINT				NOT NULL, 
    Fejlbesked                                  NVARCHAR(500)		NOT NULL,
	RetryCount									BIGINT DEFAULT 0	NOT NULL,

	/* Metadata*/
	Meta_Id			BIGINT IDENTITY (1,1)    NOT NULL,
    Meta_CreateTime DATETIME  NOT NULL,
    Meta_CreateJob  BIGINT    NOT NULL, -- Reference to the audit framework

	/* Constraints */
CONSTRAINT PK_Adresse_NoMatch PRIMARY KEY CLUSTERED (EKey_Adresse)
);
GO
CREATE NONCLUSTERED INDEX IDX_Adresse_NoMatch ON [Staging].[Adresse_NoMatch] (Meta_CreateJob)