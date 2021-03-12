CREATE VIEW [DMSA].[v_Fact_Ordre_Partitioneret]
	AS 
-- En lille note til dette view. Før man får performance fordele af dette view, så er det vigtigt at have en check constraint
-- på den kolonne, som deler/partitionerer tabellerne. Year i dette tilfælde. På den måde fortæller vi SQL server, at den kun behøver at kigge på en bestemte tabel,
-- når vi gerne vil se noget bestemt data. På den måde behøver den ikke lave full table scans på alle de underliggende tabeller.
-- Dette er en nem måde at lave partitioneret tabeller på.

SELECT [Bkey_Kunde]
      ,[Order_Id]
      ,[Eval_Set]
      ,[Order_Number]
      ,[Year]
      ,[Order_Dow]
      ,[Order_Hour_Of_Day]
      ,[Days_Since_Prior_Order]
      ,[Bkey_Produkt]
      ,[Add_To_Cart_Order]
      ,[Reordered]
      ,[Initial_Load_Time]
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
FROM [DMSA].[Fact_Ordre_2020]

UNION ALL

SELECT [Bkey_Kunde]
      ,[Order_Id]
      ,[Eval_Set]
      ,[Order_Number]
      ,[Year]
      ,[Order_Dow]
      ,[Order_Hour_Of_Day]
      ,[Days_Since_Prior_Order]
      ,[Bkey_Produkt]
      ,[Add_To_Cart_Order]
      ,[Reordered]
      ,[Initial_Load_Time]
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
  FROM [DMSA].[Fact_Ordre_2021]