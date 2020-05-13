CREATE PROCEDURE [Staging].[sp_Staging_Adresse]
     @StagingId BIGINT
	,@LastSuccessfullJobId BIGINT = 0
    ,@RecordsSelected BIGINT = 0
	,@RecordsInserted BIGINT = 0
	,@Status NVARCHAR (20) = 'Succeeded'
	,@RecordsFailed INT = 0
    ,@RecordsDiscarded INT = 0
AS
BEGIN TRY
	BEGIN TRANSACTION

--	 Delta update 
UPDATE [Staging].[Adresse] 
SET    
       [ENHNR]                                     = AAA.[ENHNR]
      ,[ADR_TYPE]								   = AAA.[ADR_TYPE]
      ,[PE_PNR]									   = AAA.[PE_PNR]
      ,[JE_CVRNR]								   = AAA.[JE_CVRNR]
      ,[BP_BNR]									   = AAA.[BP_BNR]
      ,[ASE_ANR]								   = AAA.[ASE_ANR]
      ,[CPRVALID]								   = AAA.[CPRVALID]
      ,[KM_KOM_ID]								   = AAA.[KM_KOM_ID]
      ,[VA_VEJAFS_ID]							   = AAA.[VA_VEJAFS_ID]
      ,[BY_VEJAFS_ID]							   = AAA.[BY_VEJAFS_ID]
      ,[PVA_POST_VEJAFS_ID]						   = AAA.[PVA_POST_VEJAFS_ID]
      ,[VEJKODE]								   = AAA.[VEJKODE]
      ,[CO_NAVN]								   = AAA.[CO_NAVN]
      ,[HUSNR_FRA]								   = AAA.[HUSNR_FRA]
      ,[BOGST_FRA]								   = AAA.[BOGST_FRA]
      ,[HUSNR_TIL]								   = AAA.[HUSNR_TIL]
      ,[HUSNR]									   = CONCAT (AAA.HUSNR_FRA ,AAA.BOGST_FRA) 
      ,[BOGST_TIL]								   = AAA.[BOGST_TIL]
      ,[ETAGE]									   = AAA.[ETAGE]
      ,[SIDE_DOER]								   = AAA.[SIDE_DOER]
      ,[PD_POSTNR]								   = AAA.[PD_POSTNR]
      ,[POSTBOKS]								   = AAA.[POSTBOKS]
      ,[VEJNAVN_LANGT]							   = AAA.[VEJNAVN_LANGT]
      ,[VEJNAVN_KORT]							   = AAA.[VEJNAVN_KORT]
      ,[LD_ISO_LAND]							   = AAA.[LD_ISO_LAND]
      ,[ADRESSE_FRITEKST]						   = AAA.[ADRESSE_FRITEKST]
      ,[FAD_HEMMELIG_ADR]						   = AAA.[FAD_HEMMELIG_ADR]
      ,[XADRESSE_FRITEKST]						   = AAA.[XADRESSE_FRITEKST]
      ,[ADR_ART]								   = AAA.[ADR_ART]
      ,[ENHEDSTYPE]								   = AAA.[ENHEDSTYPE]
      ,[OPRET_DATO]								   = AAA.[OPRET_DATO]
      ,[OPRET_BRUGER]							   = AAA.[OPRET_BRUGER]
      ,[AJOUR_DATO]								   = AAA.[AJOUR_DATO]
      ,[AJOUR_BRUGER]							   = AAA.[AJOUR_BRUGER]
      ,[AJOUR_BATDATO]							   = AAA.[AJOUR_BATDATO]
      ,[AJOUR_BATBRUGER]						   = AAA.[AJOUR_BATBRUGER]
      ,[AJOUR_ANTAL]							   = AAA.[AJOUR_ANTAL]
      ,[IABYG_INR]								   = AAA.[IABYG_INR]
      ,[UDENLANDSK_POSTNUMMER]					   = AAA.[UDENLANDSK_POSTNUMMER]
      ,[UDENLANDSK_BY]							   = AAA.[UDENLANDSK_BY]
      ,[UDENLANDSK_POSTDISTRIKT]				   = AAA.[UDENLANDSK_POSTDISTRIKT]
      ,[TCV_UDL_VIRKSOMHEDER_ID]				   = AAA.[TCV_UDL_VIRKSOMHEDER_ID]
      ,[TCV_UDL_LOKATIONER_ID]					   = AAA.[TCV_UDL_LOKATIONER_ID]
      ,[VEJNAVN_LANGT_UTF8]						   = AAA.[VEJNAVN_LANGT_UTF8]
      ,[UDENLANDSK_POSTNUMMER_UTF8]				   = AAA.[UDENLANDSK_POSTNUMMER_UTF8]
      ,[UDENLANDSK_POSTDISTRIKT_UTF8]			   = AAA.[UDENLANDSK_POSTDISTRIKT_UTF8]
      ,[UDENLANDSK_BY_NAVN_UTF8]                   = AAA.[UDENLANDSK_BY_NAVN_UTF8]
      ,[Meta_UpdateTime]                           = GETDATE()
      ,[Meta_UpdateJob]	                           = @StagingId
     
FROM [RUT].[Archive].[ATIS_Adresser] AAA
WHERE AAA.[ADRESSE_ID] = [Staging].[Adresse].[ADRESSE_ID]
AND AAA.Meta_IsCurrent = 1 AND AAA.Meta_IsDeleted = 0
AND AAA.Meta_CreateJob > @LastSuccessfullJobId

    DECLARE @RecordsUpdated1 BIGINT 
	SET @RecordsUpdated1 = (
			SELECT @@ROWCOUNT
			)

---Delta insert
	INSERT INTO [Staging].[Adresse] (
	
       [ADRESSE_ID]
      ,[ENHNR]
      ,[ADR_TYPE]
      ,[PE_PNR]
      ,[JE_CVRNR]
      ,[BP_BNR]
      ,[ASE_ANR]
      ,[CPRVALID]
      ,[KM_KOM_ID]
      ,[VA_VEJAFS_ID]
      ,[BY_VEJAFS_ID]
      ,[PVA_POST_VEJAFS_ID]
      ,[VEJKODE]
      ,[CO_NAVN]
      ,[HUSNR_FRA]
      ,[BOGST_FRA]
      ,[HUSNR_TIL]
      ,[HUSNR]
      ,[BOGST_TIL]
      ,[ETAGE]
      ,[SIDE_DOER]
      ,[PD_POSTNR]
      ,[POSTBOKS]
      ,[VEJNAVN_LANGT]
      ,[VEJNAVN_KORT]
      ,[LD_ISO_LAND]
      ,[ADRESSE_FRITEKST]
      ,[FAD_HEMMELIG_ADR]
      ,[XADRESSE_FRITEKST]
      ,[ADR_ART]
      ,[ENHEDSTYPE]
      ,[OPRET_DATO]
      ,[OPRET_BRUGER]
      ,[AJOUR_DATO]
      ,[AJOUR_BRUGER]
      ,[AJOUR_BATDATO]
      ,[AJOUR_BATBRUGER]
      ,[AJOUR_ANTAL]
      ,[IABYG_INR]
      ,[UDENLANDSK_POSTNUMMER]
      ,[UDENLANDSK_BY]
      ,[UDENLANDSK_POSTDISTRIKT]
      ,[TCV_UDL_VIRKSOMHEDER_ID]
      ,[TCV_UDL_LOKATIONER_ID]
      ,[VEJNAVN_LANGT_UTF8]
      ,[UDENLANDSK_POSTNUMMER_UTF8]
      ,[UDENLANDSK_POSTDISTRIKT_UTF8]
      ,[UDENLANDSK_BY_NAVN_UTF8]
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
      ,[Meta_UpdateTime]
      ,[Meta_UpdateJob]
      ,[Meta_DeleteTime]
      ,[Meta_DeleteJob]
		)
	SELECT   
		[ADRESSE_ID]
      ,[ENHNR]
      ,[ADR_TYPE]
      ,[PE_PNR]
      ,[JE_CVRNR]
      ,[BP_BNR]
      ,[ASE_ANR]
      ,[CPRVALID]
      ,[KM_KOM_ID]
      ,[VA_VEJAFS_ID]
      ,[BY_VEJAFS_ID]
      ,[PVA_POST_VEJAFS_ID]
      ,[VEJKODE]
      ,[CO_NAVN]
      ,[HUSNR_FRA]
      ,[BOGST_FRA]
      ,[HUSNR_TIL]
	  ,CONCAT (
		HUSNR_FRA
		,BOGST_FRA
		) AS HUSNR
      ,[BOGST_TIL]
      ,[ETAGE]
      ,[SIDE_DOER]
      ,[PD_POSTNR]
      ,[POSTBOKS]
      ,[VEJNAVN_LANGT]
      ,[VEJNAVN_KORT]
      ,[LD_ISO_LAND]
      ,[ADRESSE_FRITEKST]
      ,[FAD_HEMMELIG_ADR]
      ,[XADRESSE_FRITEKST]
      ,[ADR_ART]
      ,[ENHEDSTYPE]
      ,[OPRET_DATO]
      ,[OPRET_BRUGER]
      ,[AJOUR_DATO]
      ,[AJOUR_BRUGER]
      ,[AJOUR_BATDATO]
      ,[AJOUR_BATBRUGER]
      ,[AJOUR_ANTAL]
      ,[IABYG_INR]
      ,[UDENLANDSK_POSTNUMMER]
      ,[UDENLANDSK_BY]
      ,[UDENLANDSK_POSTDISTRIKT]
      ,[TCV_UDL_VIRKSOMHEDER_ID]
      ,[TCV_UDL_LOKATIONER_ID]
      ,[VEJNAVN_LANGT_UTF8]
      ,[UDENLANDSK_POSTNUMMER_UTF8]
      ,[UDENLANDSK_POSTDISTRIKT_UTF8]
      ,[UDENLANDSK_BY_NAVN_UTF8]
      ,GETDATE()
      ,@StagingId
      ,NULL
      ,NULL
      ,NULL
      ,NULL
  FROM [RUT].[Archive].[ATIS_Adresser] AS AA
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Staging].[Adresse] AS SA
			WHERE AA.[ADRESSE_ID] = SA.[ADRESSE_ID]
			)
	AND AA.Meta_IsCurrent = 1 AND AA.Meta_IsDeleted = 0
	AND AA.Meta_CreateJob > @LastSuccessfullJobId

	SET @RecordsSelected = (
			SELECT @@ROWCOUNT
			)


--	 Delta Delete 
UPDATE [Staging].[Adresse] 
SET 
       [Meta_DeleteTime]                           = GETDATE()
      ,[Meta_DeleteJob]	                           = @StagingId

FROM [RUT].[Archive].[ATIS_Adresser] AAA
WHERE AAA.[ADRESSE_ID] = [Staging].[Adresse].[ADRESSE_ID]
AND AAA.Meta_IsCurrent = 1 AND AAA.Meta_IsDeleted = 1
AND AAA.Meta_DeleteJob > @LastSuccessfullJobId


 DECLARE @RecordsUpdated2 BIGINT 
	 	SET @RecordsUpdated2 = (
			SELECT @@ROWCOUNT
			)

SET @RecordsInserted = @RecordsUpdated1 + @RecordsUpdated2 + @RecordsSelected


	UPDATE LZDB.Audit.StagingLog
	SET  [RecordsSelected]=@RecordsInserted
		,[RecordsInserted] = @RecordsInserted
		,[RecordsFailed] = @RecordsFailed
		,[RecordsDiscarded] = @RecordsDiscarded
		,[Status] = @Status
        ,[EndTime] = GETDATE()
	WHERE [Id] = @StagingId

	COMMIT
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION RAISEERROR
END CATCH