-- Inspirations kode til opdatering eller sletning af mange rækker

USE [Staging]
GO

SET NOCOUNT ON;
 
DECLARE 
	@v_BATCHSIZE INT
	, @v_WAITFORVAL VARCHAR(8)
	, @v_ITERATION INT
	, @v_TOTALROWS INT
	, @v_IterationMSG NVARCHAR(100)
    , @v_TOTALROWSMSG NVARCHAR(100)
	, @v_rc INT
	, @v_TRANSNAME NVARCHAR(100)
	, @v_CONTROLROWS INT
;
 
SET DEADLOCK_PRIORITY LOW
;

SET @v_BATCHSIZE = 10000
SET @v_WAITFORVAL = '00:00:05'
SET @v_rc = 1
SET @v_IterationMSG = 'Iteration: '
SET @v_TOTALROWSMSG = 'Total updates:'
SET @v_ITERATION=0
SET @v_TOTALROWS=0
SET @v_TRANSNAME='UpdateAdresseRows'
SET @v_CONTROLROWS = 0
;
--TempTable due to several joins. 
DROP TABLE IF EXISTS #AdresseKoordinatTemp 
;

SELECT
	Identity (BIGINT,1,1) AS Id
	,ak.EKey_Adresse
	,ad.Vejnavn
	,ad.Husnummer
	,ad.Postnummer
INTO #AdresseKoordinatTemp
FROM Staging.Adresse ad
INNER JOIN Map.Adresse map ON ad.Enhed_Nummer = map.Enhed_Nummer
	AND ad.Adresse_Type = map.Adresse_Type
	AND ad.Gyldig_Fra = map.Gyldig_Fra
INNER JOIN Staging.Adresse_Koordinat ak ON ak.Ekey_Adresse = map.Ekey_Adresse
WHERE ak.Ekey_Adresse = map.Ekey_Adresse
	;

WHILE @v_rc > 0
BEGIN

	BEGIN TRANSACTION @v_TRANSNAME;
	BEGIN TRY

		UPDATE TOP (@v_BATCHSIZE) 
			sak 
			SET 
				Vejnavn = temp.Vejnavn
				,Husnummer = temp.Husnummer
				,Postnummer = temp.Postnummer
			FROM Staging.Adresse_Koordinat sak 
			INNER JOIN #AdresseKoordinatTemp temp ON sak.EKey_Adresse = temp.EKey_Adresse
			WHERE temp.Id > @v_CONTROLROWS AND temp.Id <= @v_CONTROLROWS+@v_BATCHSIZE
		;

		SET @v_rc = @@ROWCOUNT;

	END TRY
	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_STATE() AS ErrorState
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION @v_TRANSNAME;
	END CATCH;

	IF @@TRANCOUNT > 0
	BEGIN

		COMMIT TRANSACTION @v_TRANSNAME;
	    -- CHECKPOINT;       -- if simple
	    -- BACKUP LOG ... -- if full

		IF @v_rc = 0
		BREAK
		;
	
		SET @v_ITERATION=@v_ITERATION+1
		SET @v_TOTALROWS=@v_TOTALROWS+@v_rc
		SET @v_CONTROLROWS=@v_CONTROLROWS+@v_BATCHSIZE

		RAISERROR('%s:%d', 0, 1, @v_IterationMSG , @v_ITERATION) WITH NOWAIT;
		;
		RAISERROR('%s:%d', 0, 1, @v_TOTALROWSMSG , @v_TOTALROWS) WITH NOWAIT;
		;
		WAITFOR DELAY @v_WAITFORVAL 
		;
	END
END