CREATE TABLE [DMSA].[Fact_Ordre]
(   [Ekey_Kunde]               BIGINT                 NOT NULL,
	[Order_Id]                 BIGINT                 NOT NULL,
	[Eval_Set]                 NVARCHAR(50)           NULL,
	[Order_Number]             INT                    NULL,
	[Order_Dow]                INT                    NULL,
	[Order_Hour_Of_Day]        INT                    NULL,
	[Days_Since_Prior_Order]   NVARCHAR(50)           NULL,
	[Ekey_Produkt]             BIGINT                 NOT NULL,
	[Add_To_Cart_Order]        INT                    NOT NULL,
	[Reordered]                INT                    NOT NULL,
	[Initial_Load_Time]        DATETIME2(7)           NULL,

	
	/* Metadata */
	[Meta_Id]           BIGINT IDENTITY (1,1)        NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL
)
GO 

CREATE NONCLUSTERED INDEX IDX_Ekey_Dim_Kunde ON [DMSA].[Fact_Ordre] ([Ekey_Kunde])
GO

CREATE NONCLUSTERED INDEX IDX_Ekey_Dim_Produkt ON [DMSA].[Fact_Ordre] ([Ekey_Produkt])
GO