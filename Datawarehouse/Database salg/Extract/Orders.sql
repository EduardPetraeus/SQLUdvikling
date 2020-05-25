CREATE TABLE [Extract].[Orders]
(   
    [Order_Id]                 INT                    NOT NULL,
	[User_Id]                  INT                    NULL,
	[Eval_Set]                 NVARCHAR(20)           NULL,
	[Order_Number]             SMALLINT               NULL,
	[Order_Dow]                SMALLINT               NULL,
	[Order_Hour_Of_Day]        SMALLINT               NULL,
	[Days_Since_Prior_Order]   NVARCHAR(20)           NULL,


	/* Metadata */
	[Meta_Id]           BIGINT   IDENTITY (1,1)      NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Orders_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Orders
ON [Extract].[Orders] ([Order_Id], [Meta_CreateTime])