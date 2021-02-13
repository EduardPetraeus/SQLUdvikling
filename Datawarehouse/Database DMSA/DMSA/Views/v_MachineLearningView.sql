CREATE VIEW [DMSA].[v_MachineLearningView]
	AS 

SELECT TOP(547057)
       SAO.[User_Id]                                  AS [Kunde Id]
      ,SAO.[Order_Id]                                 AS [Ordre Id]		
      ,SAO.[Eval_Set]                                 AS [Evaluerings sæt]		
      ,SAO.[Order_Number]                             AS [Ordre nummer for kunden]		
      ,SAO.[Order_Dow]                                AS [Dag for bestilling]	 
      ,SAO.[Order_Hour_Of_Day]                        AS [Tidspunkt for bestilling]
      ,CAST(CAST(SAO.[Days_Since_Prior_Order] AS DECIMAL(6,1)) AS SMALLINT) AS [Dage siden sidste bestilling]
	  --,SOP.[Product_Id] 
      ,SOP.[Add_To_Cart_Order]                        AS [Rækkefølge varer er tilføjet til kurven]
      ,SOP.[Reordered]                                AS [Genbestilt (Ja /Nej)]	 
	  ,DP.[Product_Name]                              AS [Produkt navn]
	  ,DP.[Department]                                AS [Afdeling]
	  ,DP.[Aisle]                                     AS [Gang]

  FROM [Salg].[Archive].[Orders] SAO 
  LEFT JOIN [Staging].[Staging].[Temp_Orders_Products] SOP
  ON SAO.[Order_Id] = SOP.[Order_Id]

  LEFT JOIN [Staging].[Staging].[Dim_Produkt] DP
  ON SOP.Product_Id = DP.Product_Id


  WHERE SAO.Meta_IsCurrent = 1 AND SAO.Meta_IsDeleted = 0
  AND SAO.[User_Id] IN (SELECT [User_Id] FROM [Salg].[Archive].[Orders] WHERE [Eval_Set] = 'test' AND Meta_IsCurrent = 1 AND Meta_IsDeleted = 0 )

   ORDER BY SAO.[User_Id],CASE WHEN SAO.[Eval_Set] = 'test' THEN '1'
                WHEN SAO.[Eval_Set] = 'train' THEN '2'
			    WHEN SAO.[Eval_Set] = 'prior' THEN '3'
              ELSE SAO.[Eval_Set] END ASC, SAO.[Order_Id], SAO.[Order_Number], SOP.[Add_To_Cart_Order]