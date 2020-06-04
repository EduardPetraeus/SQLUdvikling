CREATE VIEW [Ordre].[v_Ordre]
	AS  
SELECT 
       [Ekey_Kunde]
      ,[Order_Id] AS [Ordre Id]
      ,[Eval_Set] AS [Evaluerings sæt]
      ,[Order_Number] AS [Ordre nummer]
	 -- ,CONVERT(varchar, CONCAT('2020/'+'2/', +[Dag for bestilling])) as [Dato for bestilling]
	  ,CASE   WHEN [Dag for bestilling] = 1 THEN   'Lørdag' 
              WHEN [Dag for bestilling] = 2 THEN   'Søndag'   
              WHEN [Dag for bestilling] = 3 THEN   'Mandag'   
              WHEN [Dag for bestilling] = 4 THEN   'Tirsdag'  
              WHEN [Dag for bestilling] = 5 THEN   'Onsdag'
              WHEN [Dag for bestilling] = 6 THEN   'Torsdag' 
              WHEN [Dag for bestilling] = 7 THEN   'Fredag'              
        END
           AS [Dag for bestilling]
      ,DATEADD(hour,0,(dateadd(hour ,[Order_Hour_Of_Day], CONCAT('2/', +[Dag for bestilling],+ '/2020'))))  AS [Tidspunkt for bestilling]
	  ,DATEADD(DAY,CAST(-[Days_Since_Prior_Order] as int),(dateadd(hour ,[Order_Hour_Of_Day], CONCAT('2/', +[Dag for bestilling],+ '/2020')))) AS [Dage siden sidste bestilling]
      ,[Ekey_Produkt]
      ,[Add_To_Cart_Order] AS [Rækkefølge varer er tilføjet til kurven]
      --,MAX([Add_To_Cart_Order]) OVER(PARTITION BY [Order_Id],[Order_Number]) AS [Antal produkter i en given ordre]
      ,1 AS [Antal produkter i en given ordre]
      ,CASE WHEN [Reordered] = 1 THEN 'Ja' WHEN [Reordered] = 0 THEN 'Nej' ELSE 'Ukendt' END AS [Genbestilt (Ja /Nej)]
      ,[Initial_Load_Time] AS [Række indlæst i Datavarehus] from 

(select [Ekey_Kunde]
      ,[Order_Id]
      ,[Eval_Set]
      ,[Order_Number]
      ,CASE   WHEN [Order_Dow] = 0 THEN   1 
              WHEN [Order_Dow] = 1 THEN   2   
              WHEN [Order_Dow] = 2 THEN   3   
              WHEN [Order_Dow] = 3 THEN   4  
              WHEN [Order_Dow] = 4 THEN   5
              WHEN [Order_Dow] = 5 THEN   6 
              WHEN [Order_Dow] = 6 THEN   7              
        END
           AS [Dag for bestilling]
      ,[Order_Hour_Of_Day]
      ,[Days_Since_Prior_Order]
      ,[Ekey_Produkt]
      ,[Add_To_Cart_Order]
      ,[Reordered]
      ,[Initial_Load_Time]
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
  FROM [DMSA].[Fact_Ordre]) s


