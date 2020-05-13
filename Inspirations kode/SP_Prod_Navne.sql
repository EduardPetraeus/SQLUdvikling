CREATE PROC [Distribution].[SP_Prod_Navne] 
     @DistributionId BIGINT
	,@RecordsInserted BIGINT = 0
	,@RecordsUpdated BIGINT = 0
	,@Status NVARCHAR (20) = 'Succeeded'
	,@RecordsFailed INT = NULL
    ,@RecordsDiscarded INT = NULL
AS
BEGIN TRY
	BEGIN TRANSACTION

	---Delta insert
	INSERT INTO [Distribution].[Prod_Navne] (
		[Id_Prod_Navne]
		,[PNummer]
		,[Navn]
		,[GyldigFra]
		,[GyldigTil]
		,[Meta_VersionNo]
		,[Meta_ValidFrom]
		,[Meta_ValidTo]
		,[Meta_IsValid]
		,[Meta_IsCurrent]
		,[Meta_IsDeleted]
		,[Meta_CreateTime]
		,[Meta_CreateJob]
		,[Meta_UpdateTime]
		,[Meta_UpdateJob]
		,Meta_DeleteTime
		,Meta_DeleteJob
		,[Meta_Id]
		)
	SELECT m.[Id_Prod_Navne]
		,p.[PNummer]
		,p.[Navn]
		,p.[GyldigFra]
		,p.[GyldigTil]
		,p.[Meta_VersionNo]
		,p.[Meta_ValidFrom]
		,p.[Meta_ValidTo]
		,p.[Meta_IsValid]
		,p.[Meta_IsCurrent]
		,p.[Meta_IsDeleted]
		,p.[Meta_CreateTime]
		,p.[Meta_CreateJob]
		,p.[Meta_UpdateTime]
		,p.[Meta_UpdateJob]
		,p.Meta_DeleteTime
		,p.Meta_DeleteJob
		,p.[Meta_Id]
	FROM [Load].[Prod_Navne] AS p
	INNER JOIN [Map].[Prod_Navne] AS m ON p.[PNummer] = m.[PNummer]
		AND p.[Navn] = m.[Navn]
		AND p.[GyldigFra] = m.[GyldigFra]
		AND p.[Meta_ValidFrom] = m.[Meta_ValidFrom]
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Distribution].[Prod_Navne] AS d
			WHERE d.[Id_Prod_Navne] = m.[Id_Prod_Navne]
			)

	SET @RecordsInserted = (
			SELECT @@ROWCOUNT
			)

	-- Delta update 

-- Denne updated statement opdaterer rækker baseret på, om der er kommet en opdatering til GyldigTil for en given rækker, der allerede eksisterer
UPDATE p
SET  p.Meta_IsCurrent = 0, 
     p.[Meta_IsDeleted] = 1
	,p.[Meta_ValidTo] = m.Meta_ValidFrom
	,p.Meta_UpdateTime = m.Meta_ValidFrom
	,p.Meta_UpdateJob = @DistributionId
FROM [Distribution].[Prod_Navne] AS p
INNER JOIN (
	SELECT [PNummer]
		,[Navn]
		,[GyldigFra]
		,[Meta_Id]
		,Meta_ValidFrom
		,row_number() OVER (
			PARTITION BY [PNummer]
			,[Navn]
			,[GyldigFra] ORDER BY [Meta_Id] DESC
			) AS RowNum
	FROM [Distribution].[Prod_Navne]
	) AS m ON p.[PNummer] = m.[PNummer]
	AND p.[Navn] = m.[Navn]
	AND p.[GyldigFra] = m.[GyldigFra]
	AND p.Meta_ValidFrom <> m.Meta_ValidFrom
	AND p.[Meta_Id] <> m.[Meta_Id] 
	AND m.RowNum = 1
	AND p.Meta_UpdateTime IS NULL -- Denne statement er meget vigtig, fordi den sikrer at kun nye rækker, som kommer ind, opdaterer en eksisterende række, og at alle rækker, som eksisterer ikke bliver opdateret hver gang.

-- Denne updated statement opdaterer rækker baseret på, hvilken rækker der er tidsmæssig gyldig
UPDATE p
SET  p.Meta_IsCurrent = 0
	,p.Meta_UpdateTime = GETDATE()
	,p.Meta_UpdateJob = @DistributionId
FROM [Distribution].[Prod_Navne] AS p
INNER JOIN (
	SELECT [PNummer]
		,[Navn]
		,[GyldigFra]
		,[Meta_VersionNo]
		,Meta_ValidFrom
		,row_number() OVER (
			PARTITION BY [PNummer]
			ORDER BY [GyldigFra]DESC, [Meta_VersionNo] DESC
			) AS RowNum
	FROM [Distribution].[Prod_Navne]
	where GyldigFra <= GETDATE()
	) AS m ON p.[PNummer] = m.[PNummer]
	AND (p.[Meta_VersionNo] <> m.[Meta_VersionNo] or p.[GyldigFra] <> m.[GyldigFra])
	AND m.RowNum = 1
	AND p.GyldigFra < GETDATE()
	AND p.Meta_UpdateTime IS NULL -- Denne statement er meget vigtig, fordi den sikrer at kun nye rækker, som kommer ind, opdaterer en eksisterende række, og at alle rækker, som eksisterer ikke bliver opdateret hver gang.

	
	-- Denne update statement sætter tidsmæssige ugyldige rækker til Meta_IsCurrent = 0, hvis de står til at have Meta_IsCurrent = 1
-- Den håndterer de rækker, som var gyldige (Meta_IsCurrent = 1), da vi fik dem ind, og hvor der ikke er kommet flere opdateringer til dem senere, og de er udløbet tidsmæssigt.
-- Disse rækker er ikke gyldige længere, og de er derfor udgået. Derfor skal de have Meta_IsCurrent = 0.

	UPDATE [Distribution].[Prod_Navne]
SET      Meta_IsCurrent = 0
	,Meta_UpdateTime = GETDATE()
	,Meta_UpdateJob = @DistributionId
WHERE       GyldigFra < GETDATE()
	AND GyldigTil < GETDATE()
	AND Meta_UpdateTime IS NULL
	AND Meta_IsCurrent = 1


-- Denne update statement sætter tidsmæssige gyldige rækker til Meta_IsCurrent = 1, hvis de står til at have Meta_IsCurrent = 0
-- Den håndterer de rækker, som var ugyldige (Meta_IsCurrent = 0), da vi fik dem ind, fordi de havde en GyldigFra, der var større end dags-dato ved indlæsning til RZ.
-- Når disse rækker er blevet gyldige, skal de have Meta_IsCurrent = 1, og det gør nedenstående update statement.


UPDATE m
SET m.Meta_IsCurrent = 1
FROM [Distribution].[Prod_Navne] m
INNER JOIN (
	SELECT Id_Prod_Navne
		,[PNummer]
		,[GyldigFra]
		,GyldigTil
		,Meta_IsCurrent
		,[Meta_VersionNo]
		,[Meta_ValidFrom]
		,Meta_UpdateTime
		,ROW_NUMBER() OVER (
			PARTITION BY [PNummer]
			 ORDER BY [GyldigFra] DESC, [Meta_Id] DESC
			) AS RowNum
	FROM [Distribution].[Prod_Navne]
	WHERE GyldigFra <= GETDATE()
	) AS d ON d.Id_Prod_Navne = m.Id_Prod_Navne
	AND d.PNummer = m.PNummer
	AND d.Meta_ValidFrom = m.Meta_ValidFrom
	AND d.GyldigFra = m.GyldigFra
	AND d.RowNum = 1
	AND (
		m.GyldigTil IS NULL
		OR m.GyldigTil >= GETDATE()
		)
	AND m.Meta_IsCurrent = 0
	AND m.Meta_IsDeleted = 0

	SET @RecordsUpdated = (
			SELECT @@ROWCOUNT
			)

	UPDATE RZDB.Audit.DistributionLog
	SET  [RecordsSelected]=@RecordsInserted
		,[RecordsInserted] = @RecordsInserted
		,[RecordsUpdated] = @RecordsUpdated
		,[RecordsFailed] = @RecordsFailed
		,[RecordsDiscarded] = @RecordsDiscarded
		,[Status] = @Status
        ,[EndTime] = GETDATE()
	WHERE [Id] = @DistributionId

	COMMIT
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION RAISEERROR
END CATCH