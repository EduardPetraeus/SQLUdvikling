CREATE VIEW [Ordre].[v_Ordre]
	AS  SELECT
       [Ekey_Kunde]
      ,[Order_Id] AS [Ordre Id]
      ,[Eval_Set] AS [Evaluerings sæt]
      ,[Order_Number] AS [Ordre nummer]
	  ,CASE   WHEN [Order_Dow] = 0 THEN   'Lørdag' 
              WHEN [Order_Dow] = 1 THEN   'Søndag'   
              WHEN [Order_Dow] = 2 THEN   'Mandag'   
              WHEN [Order_Dow] = 3 THEN   'Tirsdag'  
              WHEN [Order_Dow] = 4 THEN   'Onsdag'
              WHEN [Order_Dow] = 5 THEN   'Torsdag' 
              WHEN [Order_Dow] = 6 THEN   'Fredag'              
        END
           AS [Dag for bestilling]
      ,[Order_Dow] AS [Ugedag for bestilling]
      ,FORMAT(DATEADD(hh,[Order_Hour_Of_Day],'00:00'),'hh:mm')  AS [Tidspunkt for bestilling]
      ,[Days_Since_Prior_Order] AS [Dage siden sidste bestilling]
      ,[Ekey_Produkt]
      ,[Add_To_Cart_Order] AS [Rækkefølge varer er tilføjet til kurven]
      ,MAX([Add_To_Cart_Order]) OVER(PARTITION BY [Order_Id],[Order_Number]) AS [Antal produkter i en given ordre]
      ,CASE WHEN [Reordered] = 1 THEN 'Ja' WHEN [Reordered] = 0 THEN 'Nej' ELSE 'Ukendt' END AS [Genbestilt (Ja /Nej)]
      ,[Initial_Load_Time] AS [Række indlæst i Datavarehus]

  FROM [DMSA].[Fact_Ordre]
