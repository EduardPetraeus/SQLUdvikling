CREATE VIEW [Staging].[v_Temp_Orders_Products]
	AS SELECT 
       [Order_Id_Train] AS [Order_Id]
      ,[Product_Id_Train] AS [Product_Id]
      ,[Add_To_Cart_Order_Train] AS [Add_To_Cart_Order]
      ,[Reordered_Train] AS [Reordered]
  FROM [Salg].[Extract].[Order_Products__Train]
 

UNION 

SELECT 
       [Order_Id]
      ,[Product_Id]
      ,[Add_To_Cart_Order]
      ,[Reordered]

  FROM [Salg].[Extract].[Order_Products__Prior]
   
