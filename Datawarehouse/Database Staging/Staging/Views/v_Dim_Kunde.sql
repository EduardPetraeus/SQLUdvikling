CREATE VIEW [Staging].[v_Dim_Kunde]
	AS SELECT 
       [Order_Id]
      ,[User_Id]
  FROM [Salg].[Archive].[Orders]