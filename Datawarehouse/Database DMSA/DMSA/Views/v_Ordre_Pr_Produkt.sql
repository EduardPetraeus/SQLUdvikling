CREATE VIEW [DMSA].[v_Ordre_Pr_Produkt]
	AS 
	 
SELECT 
       FO.[Ekey_Kunde]
      ,FO.[Order_Id]
      ,FO.[Eval_Set]
      ,FO.[Order_Number]
      ,FO.[Order_Dow]
      ,FO.[Order_Hour_Of_Day]
      ,FO.[Days_Since_Prior_Order]
      ,FO.[Add_To_Cart_Order]
      ,FO.[Reordered]
      ,FO.[Ekey_Produkt]
      ,U.Product_Id
      ,U.Product_Name
      ,U.Department
      ,U.Aisle
  FROM [DMSA].[ufn_Find_Produkter_Købt_I_Ordre] (3) U  --Her joines table valued functions på med de relevante input parametre, produkt nummer. Det kan tilpasses til år, hvis man tilpasser funktion
  INNER JOIN  [DMSA].[Fact_Ordre] FO  ON [FO].[Ekey_Produkt] = [U].[Ekey_Produkt]