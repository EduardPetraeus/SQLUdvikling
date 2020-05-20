CREATE VIEW [Staging].[v_Temp_Orders_Products]
	AS SELECT 
       [Order_Id_Train] AS [Order_Id]
      ,[Product_Id_Train] AS [Product_Id]
      ,[Add_To_Cart_Order_Train] AS [Add_To_Cart_Order]
      ,[Reordered_Train] AS [Reordered]
  FROM [Salg].[Extract].[Order_Products__Train] -- Dette skal ideelt set være fra Archive tabellen, da denne indeholder Type2 historik, 
                                                -- men min lokale computer har problemer med at køre 32 millioner rækker over i Archive tabellen med den bruge stored procedure
 

UNION 

SELECT 
       [Order_Id]
      ,[Product_Id]
      ,[Add_To_Cart_Order]
      ,[Reordered]

  FROM [Salg].[Extract].[Order_Products__Prior] -- Dette skal ideelt set være fra Archive tabellen, da denne indeholder Type2 historik, 
                                                -- men min lokale computer har problemer med at køre 32 millioner rækker over i Archive tabellen med den bruge stored procedure
   
