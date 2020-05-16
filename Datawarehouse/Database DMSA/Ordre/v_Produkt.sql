CREATE VIEW [Ordre].[v_Produkt]
	AS 
SELECT [Ekey_Produkt]
      ,[Product_Id] AS [Produkt Id]
      ,[Product_Name] AS [Produkt navn]
      ,[Department] AS [Afdeling]
      ,[Aisle] AS [Gang]
  FROM [DMSA].[Dim_Produkt]