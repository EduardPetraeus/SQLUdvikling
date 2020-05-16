CREATE VIEW [Ordre].[v_Kunde]
	AS 
SELECT [Ekey_Kunde]
      ,[Order_Id] AS [Ordre Id]
      ,[User_Id]  AS [Kunde Id]
  FROM [DMSA].[Dim_Kunde]
