CREATE PROCEDURE [Distribution].[sp_Dublet_Udenlandsk_Lokationer]
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
		WHERE SourceTableName = 'ATIS_Dublet_Udenlandsk_Lokationer'
		) IS NULL
BEGIN
	INSERT INTO [RZDB].[Meta].[LastSuccesfullLoad] (
		[TableName]
		,SourceTableName
		,[LastSuccesfullJobId]
		)
	VALUES (
		'Dublet_Udenlandsk_Lokationer'
		,'ATIS_Dublet_Udenlandsk_Lokationer'
		,0
		)
END;

	
--	 Delta update 
UPDATE [Distribution].[Dublet_Udenlandsk_Lokationer]
SET    
       [Udenlandsk_Lokationer_ATIS_Id]            = LDUL.[Udenlandsk_Lokationer_ATIS_Id]
      ,[Udenlandsk_Lokationer_RZ_Id]			  = LDUL.[Udenlandsk_Lokationer_RZ_Id]
      ,[Dublet_Udenlandsk_Lokationer_ATIS_Id]	  = LDUL.[Dublet_Udenlandsk_Lokationer_ATIS_Id]
      ,[Dublet_Udenlandsk_Lokationer_RZ_Id]	      = LDUL.[Dublet_Udenlandsk_Lokationer_RZ_Id]
      ,[Meta_UpdateTime]                          = GETDATE()
      ,[Meta_UpdateJob]	                          = @DistributionId
	  ,[Meta_DeleteTime]                          = NULL
	  ,[Meta_DeleteJob]							  = NULL
   
FROM [Load].[ATIS_Dublet_Udenlandsk_Lokationer] LDUL
LEFT JOIN RZDB.Meta.LastSuccesfullLoad LSL
ON LDUL.[Source_TableName] = LSL.SourceTableName
AND LSL.TableName = @Tablename

WHERE LDUL.[Dublet_ATIS_Id] = [Distribution].[Dublet_Udenlandsk_Lokationer].[Dublet_ATIS_Id]
AND ( LDUL.Source_UpdateJob > LSL.LastSuccesfullJobId   
OR [Distribution].[Dublet_Udenlandsk_Lokationer].[Meta_DeleteTime] IS NOT NULL )

    DECLARE @RecordsUpdated1 BIGINT 
	SET @RecordsUpdated1 = (
			SELECT @@ROWCOUNT
			)

---Delta insert
	INSERT INTO [Distribution].[Dublet_Udenlandsk_Lokationer] (
	
       [Dublet_ATIS_Id]
      ,[Udenlandsk_Lokationer_ATIS_Id]
      ,[Udenlandsk_Lokationer_RZ_Id]
      ,[Dublet_Udenlandsk_Lokationer_ATIS_Id]
      ,[Dublet_Udenlandsk_Lokationer_RZ_Id] 
      ,[Meta_CreateTime]
      ,[Meta_CreateJob]
      ,[Meta_UpdateTime]
      ,[Meta_UpdateJob]
      ,[Meta_DeleteTime]
      ,[Meta_DeleteJob]
		)
	SELECT   
       [Dublet_ATIS_Id]
      ,[Udenlandsk_Lokationer_ATIS_Id]
      ,[Udenlandsk_Lokationer_RZ_Id]
      ,[Dublet_Udenlandsk_Lokationer_ATIS_Id]
      ,[Dublet_Udenlandsk_Lokationer_RZ_Id]
      ,GETDATE()
      ,@DistributionId
      ,NULL
      ,NULL
      ,NULL
      ,NULL
  FROM [Load].[ATIS_Dublet_Udenlandsk_Lokationer] AS DUL
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Distribution].[Dublet_Udenlandsk_Lokationer] AS DDUL
			WHERE DUL.[Dublet_ATIS_Id] = DDUL.[Dublet_ATIS_Id]
			)

	SET @RecordsSelected = (
			SELECT @@ROWCOUNT
			)


--	 Delta Delete 
IF EXISTS (SELECT TOP 1 1 FROM [Load].[ATIS_Dublet_Udenlandsk_Lokationer])
UPDATE [Distribution].[Dublet_Udenlandsk_Lokationer] 
SET 
       [Meta_DeleteTime]                           = GETDATE()
      ,[Meta_DeleteJob]	                           = @DistributionId

FROM [Distribution].[Dublet_Udenlandsk_Lokationer] DDUL
WHERE NOT EXISTS (
		SELECT 1
		FROM [Load].[ATIS_Dublet_Udenlandsk_Lokationer] AS LDUL
		WHERE LDUL.[Dublet_ATIS_Id] = DDUL.[Dublet_ATIS_Id]
		)

 DECLARE @RecordsUpdated2 BIGINT 
	 	SET @RecordsUpdated2 = (
			SELECT @@ROWCOUNT
			)

SET @RecordsUpdated = @RecordsUpdated1 + @RecordsUpdated2 

IF EXISTS (SELECT TOP 1 1 FROM [Load].[ATIS_Dublet_Udenlandsk_Lokationer])
UPDATE [RZDB].[Meta].[LastSuccesfullLoad] 
SET LastSuccesfullJobId = (SELECT MAX(Source_UpdateJob) FROM [Load].[ATIS_Dublet_Udenlandsk_Lokationer]) 

WHERE TableName = 'Dublet_Udenlandsk_Lokationer'
AND  SourceTableName = 'ATIS_Dublet_Udenlandsk_Lokationer'

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
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	THROW;
END CATCH;