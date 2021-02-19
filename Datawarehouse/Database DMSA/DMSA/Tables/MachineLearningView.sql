CREATE TABLE [DMSA].[MachineLearningView]
(   [Meta_Id]                                      INT IDENTITY(1,1)  PRIMARY KEY NOT NULL, 
    [Kunde Id]                                     INT                                NULL,
	[Ordre Id]                                     INT                                NULL,
	[Evaluerings saet]                             NVARCHAR(20)                       NULL,
	[Ordre nummer for kunden]                      SMALLINT                           NULL,
	[Dag for bestilling]                           SMALLINT                           NULL,
	[Tidspunkt for bestilling]                     SMALLINT                           NULL,
	[Dage siden sidste bestilling]                 SMALLINT                           NULL,
	[Raekkefoelge varer er tilfoejet til kurven]   SMALLINT                           NULL,
	[Genbestilt (Ja /Nej)]                         SMALLINT                           NULL,
	[Produkt Id]                                   INT                                NULL,
	[Afdeling Id]								   INT                                NULL,
	[Gang Id]                                      INT                                NULL,

)
GO 
