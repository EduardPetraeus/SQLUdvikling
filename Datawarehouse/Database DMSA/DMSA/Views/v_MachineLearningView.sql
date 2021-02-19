CREATE VIEW [DMSA].[v_MachineLearningView]
	AS 

SELECT TOP(15000000)  -- Train rækker: SELECT TOP(514377). Test rækker: SELECT TOP(547057). Dette antal er valgt, da det matcher med afslutningen af ordre for en specifik kunde. Rækkerne skal ind i et Excel ark, så derfor skal der ikke for mange rækker med.
       SAO.[User_Id]                                                                    AS [Kunde Id]
      ,SAO.[Order_Id]                                                                   AS [Ordre Id]		
      ,ISNULL(SAO.[Eval_Set],'Ukendt')                                                  AS [Evaluerings saet]		
      ,ISNULL(SAO.[Order_Number],-1)                                                    AS [Ordre nummer for kunden]		
      ,ISNULL(SAO.[Order_Dow],-1)                                                       AS [Dag for bestilling]	 
      ,ISNULL(SAO.[Order_Hour_Of_Day],-1)                                               AS [Tidspunkt for bestilling]
      ,ISNULL(CAST(CAST(SAO.[Days_Since_Prior_Order]  AS DECIMAL(6,1)) AS SMALLINT),-1) AS [Dage siden sidste bestilling] 
      ,ISNULL(SOP.[Add_To_Cart_Order],-1)                                               AS [Raekkefoelge varer er tilfoejet til kurven]
      ,ISNULL(SOP.[Reordered],-1)                                                       AS [Genbestilt (Ja /Nej)]	 
	  ,ISNULL(DP.[Product_Id],-1)                                                       AS [Produkt Id]    -- Disse kan bruges i sin machine learning model, hvis man hellere vil bruge kodeværdier end navne i sin analyse.
      ,ISNULL(DP.[Department_Id],-1)                                                    AS [Afdeling Id]   -- Disse kan bruges i sin machine learning model, hvis man hellere vil bruge kodeværdier end navne i sin analyse.
      ,ISNULL(DP.[Aisle_Id],-1)                                                         AS [Gang Id]       -- Disse kan bruges i sin machine learning model, hvis man hellere vil bruge kodeværdier end navne i sin analyse.
      --,ISNULL(DP.[Product_Name],'Ukendt')                                               AS [Produkt navn]
	  --,ISNULL(DP.[Department],'Ukendt')                                                 AS [Afdeling]
	  --,ISNULL(DP.[Aisle],'Ukendt')                                                      AS [Gang]

  FROM [Salg].[Archive].[Orders] SAO 
  LEFT JOIN [Staging].[Staging].[Temp_Orders_Products] SOP
  ON SAO.[Order_Id] = SOP.[Order_Id]

  LEFT JOIN [Staging].[Staging].[v_Dim_Produkt] DP
  ON SOP.Product_Id = DP.Product_Id


  WHERE SAO.Meta_IsCurrent = 1 AND SAO.Meta_IsDeleted = 0
  AND SAO.[Eval_Set] <> 'test' -- Denne kan slås til eller fra alt efter hvilke data man ser på. Test rækker skal måske ikke med i Machine learning model, men de skal tastes ind ved udregning.
  
  --AND SAO.[User_Id] IN (SELECT [User_Id] FROM [Salg].[Archive].[Orders] WHERE [Eval_Set] = 'train' AND Meta_IsCurrent = 1 AND Meta_IsDeleted = 0 )

  -- Ovenstående logik kan udskiftes til at søge efter test eller train rækker. Der er altid en kobling imellem Train og prior rækker samt Test og prior rækker.
  -- Test viser den seneste ordre for kunden, og det er den, man skal gætte med sin machine learning model.
  -- Train indikerer det samme, men her får man oplsyningerne om varerne givet, så den kan bruges til at hjælpe en i sin analyse.
  -- Train data skal bruges til sin supervised machine learning model, og data for test skal bruges til sine predictions.
  -- Derfor vil der aldrig være et sammenfald imellem train og test rækker for en kunde, da de er uafhængige af hinanden.
  -- Prior indikerer hvad kunden tidligere har bestilt af varer.
  -- Der kan være flere train rækker, hvis en kunde har bestilte flere varer i en ordre. (Ordre_Id 1187899 for Kunde_Id 1 er et eksempel)
  -- Der vil dog altid kun være en test række, og det er den, som man skal gætte varen på, samt om den er genbestilt eller ej.
  -- Hvis man udskifter til train eller test rækker, så skal man justere antallet af valgte rækker, så det matcher med et givent kunde_id, så man får alle rækkerne med for den kunde.

   ORDER BY SAO.[User_Id],SAO.[Order_Number],SAO.[Order_Id], SOP.[Add_To_Cart_Order]
           --,CASE WHEN SAO.[Eval_Set] = 'test' THEN '1'
           --     WHEN SAO.[Eval_Set] = 'train' THEN '2'
			--    WHEN SAO.[Eval_Set] = 'prior' THEN '3'
           --   ELSE SAO.[Eval_Set] END ASC
              