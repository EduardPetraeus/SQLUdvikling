CREATE VIEW [DMSA].[v_UdregningAlderMedPersonNummer]
	AS SELECT 
      [PersonNummer],
 
 (CAST(FORMAT(GETDATE(),'yyyyMMdd') AS INT) -
 (
CASE
            WHEN TRY_CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2), SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS DATE) IS NOT NULL
            THEN -- A VALID DATE FOR CALCULATION OF AGE BUT DO NOT COVER 1900-02-29 BECAUSE I AM USE FIXED 20 CENTURY.
              CASE WHEN SUBSTRING(PersonNummer, 7, 1) IN('0','1','2','3')
                     THEN CAST(CONCAT('19',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '4' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '00' AND '36'
                     THEN CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '4' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '37' AND '99'
                     THEN CAST(CONCAT('19',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) IN('5','6','7','8') AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '00' AND '57'
                     THEN CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) IN('5','6','7','8') AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '58' AND '99'
                     THEN CAST(CONCAT('18',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '9' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '00' AND '36'
                     THEN CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT) 
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '9' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '37' AND '99'
                     THEN CAST(CONCAT('19',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
              END                    
            END
            )
            ) / 10000 																    AS [Alder],
            CASE
            WHEN TRY_CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2), SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS DATE) IS NOT NULL
            THEN -- A VALID DATE FOR CALCULATION OF AGE BUT DO NOT COVER 1900-02-29 BECAUSE I AM USE FIXED 20 CENTURY.
              CASE WHEN SUBSTRING(PersonNummer, 7, 1) IN('0','1','2','3')
                     THEN CAST(CONCAT('19',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '4' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '00' AND '36'
                     THEN CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '4' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '37' AND '99'
                     THEN CAST(CONCAT('19',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) IN('5','6','7','8') AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '00' AND '57'
                     THEN CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) IN('5','6','7','8') AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '58' AND '99'
                     THEN CAST(CONCAT('18',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '9' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '00' AND '36'
                     THEN CAST(CONCAT('20',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT) 
                   WHEN SUBSTRING(PersonNummer, 7, 1) = '9' AND SUBSTRING(PersonNummer, 5, 2) BETWEEN '37' AND '99'
                     THEN CAST(CONCAT('19',SUBSTRING(PersonNummer, 5, 2),SUBSTRING(PersonNummer, 3, 2),SUBSTRING(PersonNummer, 1, 2)) AS INT)
              END                    
            END
            
             / 10000                                                                    AS [Årstal født]


			 FROM [DMSA].[PersonNummer]



			