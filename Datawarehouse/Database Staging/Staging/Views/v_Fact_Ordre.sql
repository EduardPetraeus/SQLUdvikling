CREATE VIEW [Staging].[v_Fact_Ordre]
	AS 
SELECT SAO.[Order_Id]
      ,SAO.[Eval_Set]
      ,SAO.[Order_Number]
      ,SAO.[Order_Dow]
      ,SAO.[Order_Hour_Of_Day]
      ,SAO.[Days_Since_Prior_Order]
	  ,SOP.[Product_Id]
      ,SOP.[Add_To_Cart_Order]
      ,SOP.[Reordered]
  FROM [Salg].[Archive].[Orders] SAO
  LEFT JOIN [Staging].[Temp_Orders_Products] SOP
  ON SAO.[Order_Id] = SOP.[Order_Id]

  WHERE SAO.Meta_IsCurrent = 1 AND SAO.Meta_IsDeleted = 1
