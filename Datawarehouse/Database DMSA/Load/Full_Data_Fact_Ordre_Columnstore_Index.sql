﻿CREATE TABLE [Load].[Full_Data_Fact_Ordre_Columnstore_Index]
(   [Bkey_Kunde]               INT                    NOT NULL,
	[Order_Id]                 INT                    NOT NULL,
	[Eval_Set]                 NVARCHAR(20)           NULL,
	[Order_Number]             SMALLINT               NOT NULL,
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

CREATE CLUSTERED COLUMNSTORE INDEX Load_Full_Data_Fact_Ordre_Columnstore_Index ON [Load].[Full_Data_Fact_Ordre_Columnstore_Index]

GO
CREATE  NONCLUSTERED  INDEX NCX_Bkey_Kunde_Bkey_Produkt ON [Load].[Full_Data_Fact_Ordre_Columnstore_Index] ( [Bkey_Kunde], [Bkey_Produkt] )
GO
