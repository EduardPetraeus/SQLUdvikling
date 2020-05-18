CREATE VIEW [Staging].[v_Fact_Ordre]
	AS 
SELECT TOP 5000000  -- Jeg tager kun 5 millioner rækker med over, fordi min lokale maskine har problemer med at køre flere rækker over uden at chrashe. Datasættet indeholder omkring 35 millioner rækker
       SAO.[Order_Id] AS [Bkey_Dim_Kunde]
      ,SAO.[Order_Id]
      ,SAO.[Eval_Set]
      ,SAO.[Order_Number]
      ,SAO.[Order_Dow]
      ,SAO.[Order_Hour_Of_Day]
      ,SAO.[Days_Since_Prior_Order]
	  ,CAST(SOP.[Product_Id] AS BIGINT) AS [Bkey_Dim_Produkt]
      ,SOP.[Add_To_Cart_Order]
      ,SOP.[Reordered]
      ,LAE.[StartTime] AS [Initial_Load_Time]
  FROM [Salg].[Archive].[Orders] SAO 
  LEFT JOIN [Staging].[Temp_Orders_Products] SOP
  ON SAO.[Order_Id] = SOP.[Order_Id]

  LEFT JOIN (SELECT MAX([StartTime]) AS [StartTime] FROM [LZDB].[Audit].[ExtractLog] 
  WHERE [TableName] = N'Orders' AND [Database] =N'Salg' and [Status] = N'Succeeded') LAE ON 1=1 

  WHERE SAO.Meta_IsCurrent = 1 AND SAO.Meta_IsDeleted = 0
 
 ORDER BY SAO.[Order_Id]

