CREATE VIEW [Archive].[V_Prod_Navne]
AS
SELECT [Navn]
	,[GyldigFra]
	,[GyldigTil]
	,[PNummer]
	,[Meta_Id]
	,[Meta_VersionNo]
	,[Meta_ValidFrom]
	,[Meta_ValidTo]
	,[Meta_IsValid]
	,CASE 
        WHEN 
            CAST(FORMAT(MaxVersion,'yyyyMMdd') AS INT) <= CAST(FORMAT(GETDATE(),'yyyyMMdd') AS INT)
            AND [GyldigFra] <= GETDATE()
            AND ([GyldigTil] IS NULL  or [GyldigTil] >= CAST(GETDATE() AS DATE))
            AND [Meta_ValidFrom] = '1800-01-01 00:00:00.000'
            AND [Meta_IsCurrent] = 1
        THEN 0
		ELSE [Meta_IsCurrent]		
	END AS [Meta_IsCurrent]
	,[Meta_IsDeleted]
	,[Meta_CreateTime]
	,[Meta_CreateJob]
	,[Meta_UpdateTime]
	,[Meta_UpdateJob]
	,[Meta_DeleteTime]
	,[Meta_DeleteJob]
FROM (
	SELECT [Navn]
		,[GyldigFra]
		,[GyldigTil]
		,[PNummer]
		,[Meta_Id]
		,ROW_NUMBER() OVER (
			PARTITION BY [PNummer] ORDER BY [GyldigFra] ASC
			) AS [Meta_VersionNo]
		,[Meta_ValidFrom]
		,[Meta_ValidTo]
		,[Meta_IsValid]
		,CASE
            WHEN (
                    [GyldigFra] <= CAST(GETDATE() AS DATE)
                    AND [GyldigTil] >= CAST(GETDATE() AS DATE)
                    AND [Meta_IsCurrent] = 1
                )               
                OR (
                    [GyldigFra] <= CAST(GETDATE() AS DATE)
                    AND [GyldigTil] IS NULL
                    AND [Meta_IsCurrent] = 1
                )
                THEN 1
            ELSE 0
            END AS [Meta_IsCurrent]
		,CASE 
			WHEN [Meta_IsCurrent] = 0
				THEN 1
			ELSE 0
			END AS [Meta_IsDeleted]
		,[Meta_CreateTime]
		,[Meta_CreateJob]
		,[Meta_UpdateTime]
		,[Meta_UpdateJob]
		,[Meta_DeleteTime]
		,[Meta_DeleteJob]
		,lag([GyldigFra]) 
			OVER 
			(
				PARTITION BY [PNummer] 
				ORDER BY [GyldigFra] desc, [Meta_Id] desc
			) AS MaxVersion
	FROM [Archive].[Prod_Navne]
	) AS s