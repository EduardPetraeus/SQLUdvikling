/*
CREATE TABLE [Staging].[Dimension_Template] ( 
	
	/* Natural key */
	[TemplateID] INT NOT NULL,

	/* References */
	[EKey_Date] BIGINT NOT NULL,

	/* Attributes */
	[Attribute1] NVARCHAR (100) NULL,
	[Attribute2] NVARCHAR (390) NULL,

	/* Meta data */
    [Meta_ValidFrom] DATETIME NOT NULL, -- Madatory for T2 dimensions
    [Meta_Id] BIGINT IDENTITY NOT NULL, -- Madatory for T2 dimensions
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,

	CONSTRAINT [PK_Dim_Template] PRIMARY KEY CLUSTERED ([TemplateID] ASC)

);
*/