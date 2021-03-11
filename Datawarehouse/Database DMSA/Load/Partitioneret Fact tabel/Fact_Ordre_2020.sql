CREATE TABLE [Load].[Fact_Ordre_2020]
(   [Bkey_Kunde]               INT                    NOT NULL,
	[Order_Id]                 INT                    NOT NULL,
	[Eval_Set]                 NVARCHAR(20)           NULL,
	[Order_Number]             SMALLINT               NOT NULL,
	[Year]                     SMALLINT               NOT NULL CHECK( [Year] = 2020),
	[Order_Dow]                SMALLINT               NOT NULL,
	[Order_Hour_Of_Day]        SMALLINT               NOT NULL,
	[Days_Since_Prior_Order]   DECIMAL(6,1)           NULL,
	[Bkey_Produkt]             INT                    NOT NULL,
	[Add_To_Cart_Order]        SMALLINT               NOT NULL,
	[Reordered]                SMALLINT               NOT NULL,
	[Initial_Load_Time]        DATETIME2(7)           NULL,

	
	/* Metadata */
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL
)
GO 

CREATE CLUSTERED COLUMNSTORE INDEX CCI_Load_Fact_Ordre_2020 ON [Load].[Fact_Ordre_2020]
GO

CREATE  NONCLUSTERED  INDEX NCX_Bkey_Kunde_Bkey_Produkt ON [Load].[Fact_Ordre_2020] ( [Bkey_Kunde], [Bkey_Produkt] )
GO

CREATE  NONCLUSTERED  INDEX NCX_Year ON [Load].[Fact_Ordre_2020] ( [Year] )
GO