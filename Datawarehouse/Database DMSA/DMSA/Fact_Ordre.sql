CREATE TABLE [DMSA].[Fact_Ordre]
(   [Ekey_Kunde]               INT                    NOT NULL,
	[Order_Id]                 INT                    NOT NULL,
	[Eval_Set]                 NVARCHAR(20)           NULL,
	[Order_Number]             SMALLINT               NOT NULL,
	[Order_Dow]                SMALLINT               NOT NULL,
	[Order_Hour_Of_Day]        SMALLINT               NOT NULL,
	[Days_Since_Prior_Order]   DECIMAL(6,1)           NULL,
	[Ekey_Produkt]             INT                    NOT NULL,
	[Add_To_Cart_Order]        SMALLINT               NOT NULL,
	[Reordered]                SMALLINT               NOT NULL,
	[Initial_Load_Time]        DATETIME2(7)           NULL,

	
	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL
)
GO 

CREATE NONCLUSTERED INDEX IDX_Ekey_Dim_Kunde ON [DMSA].[Fact_Ordre] ([Ekey_Kunde])
GO

CREATE NONCLUSTERED INDEX IDX_Ekey_Dim_Produkt ON [DMSA].[Fact_Ordre] ([Ekey_Produkt])
GO