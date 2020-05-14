CREATE TABLE [Extract].[Orders]
(   
    [Order_Id]                 BIGINT                 NOT NULL,
	[User_Id]                  INT                    NULL,
	[Eval_Set]                 NVARCHAR(50)           NULL,
	[Order_Number]             INT                    NULL,
	[Order_Dow]                INT                    NULL,
	[Order_Hour_Of_Day]        INT                    NULL,
	[Days_Since_Prior_Order]   NVARCHAR(50)           NULL,


	/* Metadata */
	[Meta_Id]           BIGINT   IDENTITY (1,1)      NOT NULL,
	[Meta_CreateTime]   DATETIME DEFAULT GETDATE()   NOT NULL,
	[Meta_CreateJob]	BIGINT		                 NOT NULL

	CONSTRAINT PK_Orders_Id PRIMARY KEY CLUSTERED ([Meta_Id])
)
GO

CREATE UNIQUE INDEX IDX_Orders
ON [Extract].[Orders] ([Order_Id], [Meta_CreateTime])