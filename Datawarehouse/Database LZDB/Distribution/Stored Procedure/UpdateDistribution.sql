CREATE PROCEDURE [Distribution].[UpdateDistribution]
     @StagingId BIGINT
	,@Tablename  NVARCHAR (100)
AS

DECLARE @RecordsFailed INT = 0
DECLARE @RecordsDiscarded INT = 0

DECLARE @Database NVARCHAR(100) = 'Staging'
DECLARE @SourceSchema NVARCHAR(100) = 'Load'
DECLARE @DestSchema NVARCHAR(100) = 'Distribution'
DECLARE @DestTablename NVARCHAR(100) = '[' + @Database + ']' + '.' + '[' + @DestSchema + ']' + '.' + '[' + @Tablename + ']'
DECLARE @SourceTablename NVARCHAR(100) = '[' + @Database + ']' + '.' + '[' + @SourceSchema + ']' + '.' + '[' + @Tablename + ']'


        ----------------------------------------------------
        -- Get the natural keys from Distribution primary key
        ----------------------------------------------------
        DECLARE @NaturalKeys TABLE (colname SYSNAME)

        INSERT INTO @NaturalKeys
        EXECUTE Utility.GetKeyColumns @Database = @Database, @Schema = @DestSchema, @Table = @TableName

        DECLARE @NaturalKeyList NVARCHAR(max) = ''
		DECLARE @NaturalKeyExtList NVARCHAR(max) = ''
		DECLARE @NaturalKeyWhereList NVARCHAR(max) = ''

        SELECT
			@NaturalKeyList = @NaturalKeyList + ', ' + colname,
			@NaturalKeyExtList = @NaturalKeyExtList + ', ' + colname + '= AA.' + colname,
			@NaturalKeyWhereList = @NaturalKeyWhereList  + ' AND ' + @DestTablename+ '.' + colname + '= AA.' + colname
        FROM @NaturalKeys

        SET @NaturalKeyList = SUBSTRING(@NaturalKeyList, 3, LEN(@NaturalKeyList))
		SET @NaturalKeyExtList = SUBSTRING(@NaturalKeyExtList, 3, LEN(@NaturalKeyExtList))
		SET @NaturalKeyWhereList = SUBSTRING(@NaturalKeyWhereList, 5, LEN(@NaturalKeyWhereList))

		--PRINT @NaturalKeyList
		--PRINT @NaturalKeyExtList
		--PRINT @NaturalKeyWhereList

        ----------------------------------------------------
        -- Get the NON natural keys from Distribution
        ----------------------------------------------------

		DECLARE @Columns TABLE (colname SYSNAME)

        INSERT INTO @Columns
		EXECUTE Utility.GetNonKeyColumns @Database = @Database, @Schema = @DestSchema, @Table = @TableName

        DECLARE @ColumnList NVARCHAR(max) = '' 
		DECLARE @ColumnExtList NVARCHAR(max) = ''

		
        SELECT
		@ColumnList = @ColumnList + ', ' + colname,
		@ColumnExtList = @ColumnExtList + ', ' + colname + '= AA.' + colname
        FROM @Columns
		WHERE colname NOT IN(
			'[Meta_Id]',
			'[Meta_CreateTime]',
			'[Meta_CreateJob]',
			'[Meta_UpdateTime]',
			'[Meta_UpdateJob]',
			'[Meta_DeleteTime]',
			'[Meta_DeleteJob]')


		--SET @ColumnList = SUBSTRING(@ColumnList, 3, LEN(@ColumnList))
		--SET @ColumnExtList = SUBSTRING(@ColumnExtList, 3, LEN(@ColumnExtList)) 
		-- Disse er udkommenteret, da vi ikke vil have fjernet kommaet foran den første kolonne
		
		 --PRINT @ColumnList
		 --PRINT @ColumnExtList
		
		DECLARE @SQL NVARCHAR(max)

		SET @SQL = '


----------------------------------------------------
-- Start fejlhåndtering og transaktion
----------------------------------------------------
SET XACT_ABORT ON

BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @RecordsSelected BIGINT
			SET @RecordsSelected = (
			SELECT COUNT(*) FROM <SourceTablename>
			)


----------------------------------------------------
-- Delta Update
----------------------------------------------------

	UPDATE <DestTablename>
	SET    
       <NaturalKeyExtList>
       <ColumnExtList>
      ,[Meta_UpdateTime]                          = GETDATE()
      ,[Meta_UpdateJob]	                          = <StagingId>
	  ,[Meta_DeleteTime]                          = NULL
	  ,[Meta_DeleteJob]							  = NULL		
	FROM <SourceTablename> AS AA

	LEFT JOIN LZDB.Meta.LastSuccessfullLoad LSL
		ON AA.[Source_TableName] = LSL.SourceTableName
		AND LSL.DestinationTableName = ''<Tablename>''

	WHERE <NaturalKeyWhereList>
	AND (AA.Source_UpdateJob > LSL.LastSuccessfullJobId
	OR <DestTablename>.[Meta_DeleteTime] IS NOT NULL)


    DECLARE @RecordsUpdated1 BIGINT 
	SET @RecordsUpdated1 = (
			SELECT @@ROWCOUNT
			)

----------------------------------------------------
-- Delta Insert
----------------------------------------------------

		INSERT INTO <DestTablename> (
				 <NaturalKey>
                 <ColumnList>
				,[Meta_CreateTime]
				,[Meta_CreateJob]
				,[Meta_UpdateTime]
				,[Meta_UpdateJob]
				,[Meta_DeleteTime]
				,[Meta_DeleteJob]	
		)
			SELECT
				 <NaturalKey>
                 <ColumnList>
				,GETDATE()
				,<StagingId>
				,NULL
				,NULL
				,NULL
				,NULL			
            FROM <SourceTablename> AS AA
			WHERE NOT EXISTS (
			SELECT 1
			FROM <DestTablename>
			WHERE <NaturalKeyWhereList>
			)
			
			DECLARE @RecordsInserted BIGINT
			SET @RecordsInserted = (
			SELECT @@ROWCOUNT
			)


----------------------------------------------------
-- Delta Delete
----------------------------------------------------

IF EXISTS (SELECT 1 FROM <SourceTablename>)

UPDATE <DestTablename> 
SET 
       [Meta_DeleteTime] = GETDATE()
      ,[Meta_DeleteJob] = <StagingId>

FROM <DestTablename> 
WHERE NOT EXISTS (
		SELECT 1
		FROM <SourceTablename> AS AA
		WHERE <NaturalKeyWhereList>
		)
AND <DestTablename>.[Meta_DeleteTime] IS NULL


 DECLARE @RecordsUpdated2 BIGINT 
	 	SET @RecordsUpdated2 = (
			SELECT @@ROWCOUNT
			)



----------------------------------------------------
-- Set Recordsopdated ud fra Delta Update + Delta Delete
----------------------------------------------------

DECLARE @RecordsUpdated BIGINT
SET @RecordsUpdated = @RecordsUpdated1 + @RecordsUpdated2 

----------------------------------------------------
-- Opdater Styringstabel
----------------------------------------------------

 MERGE INTO [LZDB].[Meta].[LastSuccessfullLoad] as lsl
 USING (
    SELECT Source_TableName, MAX(Source_UpdateJob) AS maxUpdateJob 
    FROM <SourceTablename>
    GROUP BY Source_TableName
    ) as src 
    ON (lsl.SourceTableName = src.Source_TableName 
    AND lsl.DestinationTableName = ''<Tablename>'')
WHEN MATCHED THEN
    UPDATE SET lsl.LastSuccessfullJobId = src.maxUpdateJob
WHEN NOT MATCHED BY TARGET THEN
    INSERT (DestinationTableName, SourceTableName, LastSuccessfullJobId) 
    VALUES (''<Tablename>'', src.Source_TableName, src.maxUpdateJob)
;

----------------------------------------------------
-- Opdater Log-tabel
----------------------------------------------------

	UPDATE [LZDB].[Audit].StagingLog
	SET  [RecordsSelected] = @RecordsSelected
		,[RecordsInserted] = @RecordsInserted
		,[RecordsUpdated] = @RecordsUpdated
		,[RecordsFailed] = <RecordsFailed>
		,[RecordsDiscarded] = <RecordsDiscarded>
		,[Status] = ''Succeeded''
        ,[EndTime] = GETDATE()
	WHERE [Id] = <StagingId>
	
----------------------------------------------------
-- Slut fejlhåndtering og transaktion
----------------------------------------------------
COMMIT
	END TRY

----------------------------------------------------
-- Hvis der sker fejl, så rul transaktionen tilbage
----------------------------------------------------

BEGIN CATCH
	DECLARE @ErrorMessage NVARCHAR(max)
		,@ErrorSeverity INT
		,@ErrorState INT;
	SELECT @ErrorMessage = ERROR_MESSAGE() + '' Line '' + cast(ERROR_LINE() AS NVARCHAR(5))
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

			'

		SET @SQL = REPLACE(@SQL,'<DestTablename>', @DestTablename);
		SET @SQL = REPLACE(@SQL,'<SourceTablename>', @SourceTablename);
		SET @SQL = REPLACE(@SQL,'<Tablename>', @Tablename);
		SET @SQL = REPLACE(@SQL,'<NaturalKey>', @NaturalKeyList);
		SET @SQL = REPLACE(@SQL,'<NaturalKeyExtList>', @NaturalKeyExtList);
		SET @SQL = REPLACE(@SQL,'<NaturalKeyWhereList>', @NaturalKeyWhereList);
		SET @SQL = REPLACE(@SQL,'<ColumnList>', @ColumnList);
		SET @SQL = REPLACE(@SQL,'<ColumnExtList>', @ColumnExtList);
		SET @SQL = REPLACE(@SQL,'<RecordsFailed>', @RecordsFailed);
		SET @SQL = REPLACE(@SQL,'<RecordsDiscarded>', @RecordsDiscarded);
		SET @SQL = REPLACE(@SQL,'<StagingId>', @StagingId);

		--PRINT @SQL

		EXECUTE sp_executesql @SQL


