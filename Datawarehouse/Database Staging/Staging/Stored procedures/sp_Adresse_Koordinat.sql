CREATE PROCEDURE [Staging].[sp_Adresse_Koordinat]
     @StagingId BIGINT
   
AS
BEGIN TRY
	BEGIN TRANSACTION

--	 Delta update 
UPDATE [Staging].[Adresse_Koordinat] 
SET    
       [Etrs89koordinat_oest]    = LAK.Etrs89koordinat_oest	
	  ,[Etrs89koordinat_nord]    = LAK.Etrs89koordinat_nord	
	  ,[Wgs84koordinat_laengde]  = LAK.Wgs84koordinat_laengde		
	  ,[Wgs84koordinat_bredde]   = LAK.Wgs84koordinat_bredde
	  ,[Vejnavn]                 = LAK.Vejnavn
	  ,[Husnummer]				 = LAK.Husnummer
	  ,[Postnummer]				 = LAK.Postnummer	
	  ,[Kommune_Navn]			 = LAK.Kommune_Navn
	  ,[Kommune_Kode]			 = LAK.Kommune_Kode
      ,[Meta_UpdateTime]         = GETDATE()
      ,[Meta_UpdateJob]	         = @StagingId
     
FROM [Load].[Adresse_Koordinat] LAK
WHERE LAK.[Ekey_Adresse] = [Staging].[Adresse_Koordinat].[Ekey_Adresse]

---Delta insert
	INSERT INTO [Staging].[Adresse_Koordinat] (
	
       [Ekey_Adresse]
	  ,[Etrs89koordinat_oest]  
	  ,[Etrs89koordinat_nord]  
	  ,[Wgs84koordinat_laengde]
	  ,[Wgs84koordinat_bredde]
	  ,[Vejnavn]
	  ,[Husnummer]
	  ,[Postnummer]
	  ,[Kommune_Navn]
	  ,[Kommune_Kode]
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
      ,[Meta_UpdateTime]
      ,[Meta_UpdateJob]
		)
	SELECT   
       [Ekey_Adresse]
	  ,[Etrs89koordinat_oest]  
	  ,[Etrs89koordinat_nord]  
	  ,[Wgs84koordinat_laengde]
	  ,[Wgs84koordinat_bredde]
	  ,[Vejnavn]
	  ,[Husnummer]
	  ,[Postnummer]  
	  ,[Kommune_Navn]
	  ,[Kommune_Kode]
      ,GETDATE()
      ,@StagingId
      ,NULL
      ,NULL
  FROM [Load].[Adresse_Koordinat] AS AK
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Staging].[Adresse_Koordinat] AS SAK
			WHERE AK.[Ekey_Adresse] = SAK.[Ekey_Adresse]
			)

	COMMIT
END TRY

BEGIN CATCH
	DECLARE @ErrorMessage NVARCHAR(MAX)
		,@ErrorSeverity INT
		,@ErrorState INT;
	SELECT @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() AS NVARCHAR(5))
		,@ErrorSeverity = ERROR_SEVERITY()
		,@ErrorState = ERROR_STATE();
	IF @@trancount > 0
		ROLLBACK TRANSACTION;
	RAISERROR (
			@ErrorMessage
			,@ErrorSeverity
			,@ErrorState
			);
END CATCH