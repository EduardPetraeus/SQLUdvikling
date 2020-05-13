
CREATE PROC [Distribution].[SP_Prod_Enheder] 
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
	INSERT INTO [Distribution].[Prod_Enheder] (
	
       [PNummer]
      ,[FejlRegistreret]
      ,[Enhedstype]
      ,[FejlBeskrivelse]
      ,[FejlVedIndlaesning]
      ,[BrancheAnsvarskode]
      ,[NaermesteFremtidigeDato]
      ,[ProduktionsEnhedMetadataSammensatStatus]
      ,[SamtId]
      ,[EnhedsNummer]
      ,[Reklamebeskyttet]
      ,[DataAdgang]
      ,[VirkningsAktoer]
      ,[Meta_Id]
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
      ,[Meta_DeleteTime]
      ,[Meta_DeleteJob]
		)
	SELECT   
		     p.[PNummer]
			,p.[FejlRegistreret]
			,p.[Enhedstype]
			,p.[FejlBeskrivelse]
			,p.[FejlVedIndlaesning]
			,p.[BrancheAnsvarskode]
			,p.[NaermesteFremtidigeDato]
			,p.[ProduktionsEnhedMetadataSammensatStatus]
			,p.[SamtId]
			,p.[EnhedsNummer]
			,p.[Reklamebeskyttet]
			,p.[DataAdgang]
			,p.[VirkningsAktoer]
			,p.[Meta_Id]
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
			,p.[Meta_DeleteTime]
			,p.[Meta_DeleteJob]
	FROM [Load].Prod_Enheder AS p
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Distribution].Prod_Enheder AS d
			WHERE p.[PNummer] = d.[PNummer]
			)

	SET @RecordsInserted = (
			SELECT @@ROWCOUNT
			)

--	 Delta update 
UPDATE [Distribution].Prod_Enheder 
SET    
       [FejlRegistreret]                           = LPE.[FejlRegistreret]
      ,[Enhedstype]                                = LPE.[Enhedstype]
      ,[FejlBeskrivelse]                           = LPE.[FejlBeskrivelse]
      ,[FejlVedIndlaesning]                        = LPE.[FejlVedIndlaesning]
      ,[BrancheAnsvarskode]                        = LPE.[BrancheAnsvarskode]
      ,[NaermesteFremtidigeDato]                   = LPE.[NaermesteFremtidigeDato]
      ,[ProduktionsEnhedMetadataSammensatStatus]   = LPE.[ProduktionsEnhedMetadataSammensatStatus]
      ,[SamtId]                                    = LPE.[SamtId]
      ,[EnhedsNummer]                              = LPE.[EnhedsNummer]
      ,[Reklamebeskyttet]                          = LPE.[Reklamebeskyttet]
      ,[DataAdgang]                                = LPE.[DataAdgang]
      ,[VirkningsAktoer]                           = LPE.[VirkningsAktoer]
      ,[Meta_Id]                                   = LPE.[Meta_Id]
      ,[Meta_VersionNo]                            = LPE.[Meta_VersionNo]
      ,[Meta_ValidFrom]                            = LPE.[Meta_ValidFrom]
      ,[Meta_ValidTo]                              = LPE.[Meta_ValidTo]
      ,[Meta_IsValid] 	                           = LPE.[Meta_IsValid]
      ,[Meta_IsCurrent]	                           = LPE.[Meta_IsCurrent]
      ,[Meta_IsDeleted]	                           = LPE.[Meta_IsDeleted]
      ,[Meta_CreateTime]                           = LPE.[Meta_CreateTime]
      ,[Meta_CreateJob]	                           = LPE.[Meta_CreateJob]
      ,[Meta_UpdateTime]                           = LPE.[Meta_UpdateTime]
      ,[Meta_UpdateJob]	                           = LPE.[Meta_UpdateJob]
      ,[Meta_DeleteTime]                           = LPE.[Meta_DeleteTime]
      ,[Meta_DeleteJob]	                           = LPE.[Meta_DeleteJob]

FROM [Load].Prod_Enheder AS LPE
WHERE LPE.PNummer = [Distribution].Prod_Enheder.PNummer

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