﻿CREATE VIEW [Staging].[v_Fact_Ordre]
	AS 
SELECT  
       SAO.[Order_Id] AS [Bkey_Kunde]
      ,SAO.[Order_Id]
      ,SAO.[Eval_Set]
      ,SAO.[Order_Number]
      ,SAO.[Order_Dow]
       	,CASE SAO.[Order_Dow]
		WHEN 0
			THEN 2021
		WHEN 1
			THEN 2020
		WHEN 2
			THEN 2019
		WHEN 3
			THEN 2018
		WHEN 5
			THEN 2017
		WHEN 6
			THEN 2016
		ELSE 2016
		END AS [Årstal]
      ,SAO.[Order_Hour_Of_Day]
      ,ISNULL(CAST(SAO.[Days_Since_Prior_Order] AS DECIMAL(6,1)),-1) AS [Days_Since_Prior_Order]
	  ,ISNULL(SOP.[Product_Id],-1) AS [Bkey_Produkt]
      ,ISNULL(SOP.[Add_To_Cart_Order],-1) AS [Add_To_Cart_Order]
      ,ISNULL(SOP.[Reordered],-1) [Reordered]
      ,LAE.[StartTime] AS [Initial_Load_Time]
  FROM [Salg].[Archive].[Orders] SAO 
  LEFT JOIN [Staging].[Staging].[Temp_Orders_Products] SOP
  ON SAO.[Order_Id] = SOP.[Order_Id]

  LEFT JOIN (SELECT MAX([StartTime]) AS [StartTime] FROM [LZDB].[Audit].[ExtractLog] 
  WHERE [TableName] = N'Orders' AND [Database] =N'Salg' and [Status] = N'Succeeded') LAE ON 1=1 

  WHERE SAO.Meta_IsCurrent = 1 AND SAO.Meta_IsDeleted = 0
 

