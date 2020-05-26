CREATE PROCEDURE [Distribution].[sp_Dublet_Udenlandsk_Enheder]
     @DistributionId BIGINT
	,@Tablename  NVARCHAR (100)
	,@RecordsSelected BIGINT = 0
	,@RecordsUpdated BIGINT = 0
	,@Status NVARCHAR (20) = 'Succeeded'
	,@RecordsFailed INT = NULL
    ,@RecordsDiscarded INT = NULL
AS
BEGIN TRY
	BEGIN TRANSACTION


IF (
  SELECT TOP 1 [Id]
  FROM [RZDB].[Meta].[LastSuccesfullLoad]
  WHERE SourceTableName = 'ATIS_Dublet_Udenlandsk_Enheder'
  ) IS NULL
BEGIN
 INSERT INTO [RZDB].[Meta].[LastSuccesfullLoad] (
  [TableName]
  ,SourceTableName
  ,[LastSuccesfullJobId]
  )
 VALUES (
  'Dublet_Udenlandsk_Enheder'
  ,'ATIS_Dublet_Udenlandsk_Enheder'
  ,0
  )
END;


--	 Delta update 
UPDATE [Distribution].[Dublet_Udenlandsk_Enheder]
SET    
       [Udenlandsk_Virksomheder_ATIS_Id]          = LDUE.[Udenlandsk_Virksomheder_ATIS_Id]
      ,[Udenlandsk_Virksomheder_RZ_Id]			  = LDUE.[Udenlandsk_Virksomheder_RZ_Id]
      ,[Dublet_Udenlandsk_Virksomheder_ATIS_Id]	  = LDUE.[Dublet_Udenlandsk_Virksomheder_ATIS_Id]
      ,[Dublet_Udenlandsk_Virksomheder_RZ_Id]	  = LDUE.[Dublet_Udenlandsk_Virksomheder_RZ_Id]
      ,[Meta_UpdateTime]                          = GETDATE()
      ,[Meta_UpdateJob]	                          = @DistributionId
	  ,[Meta_DeleteTime]                          = NULL
	  ,[Meta_DeleteJob]							  = NULL
     
FROM [Load].[ATIS_Dublet_Udenlandsk_Enheder] LDUE
LEFT JOIN RZDB.Meta.LastSuccesfullLoad LSL
ON LDUE.[Source_TableName] = LSL.SourceTableName
AND LSL.TableName = @Tablename

WHERE LDUE.[Dublet_Udenlandsk_Enheder_ATIS_Id] = [Distribution].[Dublet_Udenlandsk_Enheder].[Dublet_Udenlandsk_Enheder_ATIS_Id]

AND ( LDUE.Source_UpdateJob > LSL.LastSuccesfullJobId   
OR [Distribution].[Dublet_Udenlandsk_Enheder].[Meta_DeleteTime] IS NOT NULL )


    DECLARE @RecordsUpdated1 BIGINT 
	SET @RecordsUpdated1 = (
			SELECT @@ROWCOUNT
			)

---Delta insert
	INSERT INTO [Distribution].[Dublet_Udenlandsk_Enheder] (
	
       [Dublet_Udenlandsk_Enheder_ATIS_Id]
      ,[Udenlandsk_Virksomheder_ATIS_Id]
      ,[Udenlandsk_Virksomheder_RZ_Id]
      ,[Dublet_Udenlandsk_Virksomheder_ATIS_Id]
      ,[Dublet_Udenlandsk_Virksomheder_RZ_Id]
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
      ,[Meta_UpdateTime]
      ,[Meta_UpdateJob]
      ,[Meta_DeleteTime]
      ,[Meta_DeleteJob]
		)
	SELECT   
		[Dublet_Udenlandsk_Enheder_ATIS_Id]
      ,[Udenlandsk_Virksomheder_ATIS_Id]
      ,[Udenlandsk_Virksomheder_RZ_Id]
      ,[Dublet_Udenlandsk_Virksomheder_ATIS_Id]
      ,[Dublet_Udenlandsk_Virksomheder_RZ_Id]
      ,GETDATE()
      ,@DistributionId
      ,NULL
      ,NULL
      ,NULL
      ,NULL
  FROM [Load].[ATIS_Dublet_Udenlandsk_Enheder] AS DUE
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Distribution].[Dublet_Udenlandsk_Enheder] AS DDUE
			WHERE DUE.[Dublet_Udenlandsk_Enheder_ATIS_Id] = DDUE.[Dublet_Udenlandsk_Enheder_ATIS_Id]
			)

	SET @RecordsSelected = (
			SELECT @@ROWCOUNT
			)


--	 Delta Delete 

IF NOT EXISTS (SELECT 1 FROM [Load].[ATIS_Dublet_Udenlandsk_Enheder])
SELECT 'Empty'
ELSE
UPDATE [Distribution].[Dublet_Udenlandsk_Enheder] 
SET 
       [Meta_DeleteTime]                           = GETDATE()
      ,[Meta_DeleteJob]	                           = @DistributionId

FROM [Distribution].[Dublet_Udenlandsk_Enheder] DDUE
WHERE NOT EXISTS (
		SELECT 1
		FROM [Load].[ATIS_Dublet_Udenlandsk_Enheder] AS LDUE
		WHERE LDUE.[Dublet_Udenlandsk_Enheder_ATIS_Id] = DDUE.[Dublet_Udenlandsk_Enheder_ATIS_Id]
		)
		

 DECLARE @RecordsUpdated2 BIGINT 
	 	SET @RecordsUpdated2 = (
			SELECT @@ROWCOUNT
			)

SET @RecordsUpdated = @RecordsUpdated1 + @RecordsUpdated2 

IF NOT EXISTS (SELECT 1 FROM [Load].[ATIS_Dublet_Udenlandsk_Enheder])
SELECT 'Empty'
ELSE
UPDATE [RZDB].[Meta].[LastSuccesfullLoad] 
SET LastSuccesfullJobId = (SELECT MAX(Source_UpdateJob) FROM [Load].[ATIS_Dublet_Udenlandsk_Enheder]) 

WHERE TableName = 'Dublet_Udenlandsk_Enheder'
AND  SourceTableName = 'ATIS_Dublet_Udenlandsk_Enheder'


	UPDATE RZDB.Audit.DistributionLog
	SET  [RecordsSelected]=@RecordsSelected
		,[RecordsInserted] = @RecordsSelected
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