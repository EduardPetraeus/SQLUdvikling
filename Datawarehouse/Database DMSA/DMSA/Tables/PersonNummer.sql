CREATE TABLE [DMSA].[PersonNummer]
(
	[Id]           INT IDENTITY(1,1) NOT NULL,
	[PersonNummer] NVARCHAR(15)      NOT NULL

	CONSTRAINT PK_Id_PersonNummer PRIMARY KEY CLUSTERED ([Id])
)
