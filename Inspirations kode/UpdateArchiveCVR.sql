CREATE PROCEDURE [Archive].[UpdateArchiveCVR]

     @ExecutionId BIGINT
	,@Tablename  NVARCHAR (100)
	,@ExtractDeleteAction NVARCHAR(10)
AS

BEGIN

DECLARE @Database NVARCHAR(100) = 'CVR'
DECLARE @SourceSchema NVARCHAR(100) = 'Extract'
DECLARE @DestSchema NVARCHAR(100) = 'Archive'
DECLARE @DestTablename NVARCHAR(100) = '[' + @Database + ']' + '.' + '[' + @DestSchema + ']' + '.' + '[' + @Tablename + ']'
DECLARE @SourceTablename NVARCHAR(100) = '[' + @Database + ']' + '.' + '[' + @SourceSchema + ']' + '.' + '[' + @Tablename + ']'

-------------------------------------------------------
-- Start ArchiveStart
-------------------------------------------------------
	DECLARE @ArchiveId BIGINT = -1
	EXECUTE Audit.ArchiveStart
			@Database = @Database
            ,@TableName = @Tablename
			,@Schema = @DestSchema
            ,@ArchiveId = @ArchiveId OUT
            ,@ExecutionId = @ExecutionId
			,@IsFullLoad = 1
	
	BEGIN TRY
	-------------------------------------------------------
        -- Start transaction - join if there is an existing one
        -------------------------------------------------------
        DECLARE @TranCounter INT = @@TRANCOUNT
        DECLARE @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N'_' + CAST(@@NESTLEVEL AS NVARCHAR(2));

        IF @TranCounter > 0
            SAVE TRANSACTION @SavePoint;
        ELSE
            BEGIN TRANSACTION;
			         
----------------------------------------------------
-- Get CvrNummer/PNummer/Enhedsnummer
----------------------------------------------------

        DECLARE @CvrOrPnr TABLE (colname SYSNAME)

        INSERT INTO @CvrOrPnr
        EXEC Utility.GetKeyColumnCVR @Database = @Database, @Schema = @DestSchema, @Tablename = @Tablename

		DECLARE @CvrOrPnrList NVARCHAR(max) = ''
		DECLARE @CvrOrPnrExtList NVARCHAR(max) = ''
		DECLARE @CvrOrPnrWhereList NVARCHAR(max) = ''

        SELECT
			@CvrOrPnrList = @CvrOrPnrList + ', ' + colname,
			@CvrOrPnrExtList = @CvrOrPnrExtList + ', ' + colname + ' = AA.' + colname,
			@CvrOrPnrWhereList = @CvrOrPnrWhereList  + ' AND ' + @DestTablename+ '.' + colname + ' = AA.' + colname
        FROM @CvrOrPnr

        SET @CvrOrPnrList = SUBSTRING(@CvrOrPnrList, 3, LEN(@CvrOrPnrList))
		SET @CvrOrPnrExtList = SUBSTRING(@CvrOrPnrExtList, 3, LEN(@CvrOrPnrExtList))
		SET @CvrOrPnrWhereList = SUBSTRING(@CvrOrPnrWhereList, 5, LEN(@CvrOrPnrWhereList))

		--PRINT @CvrOrPnrList --only for debugging
		--PRINT @CvrOrPnrExtList --only for debugging
		--PRINT @CvrOrPnrWhereList --only for debugging
		
----------------------------------------------------
-- Get other columns from Archive
----------------------------------------------------
		DECLARE @Columns TABLE (colname SYSNAME)

        INSERT INTO @Columns
		EXECUTE Utility.GetNonKeyColumnsCVR @Database = @Database, @Schema = @DestSchema, @Tablename = @Tablename

        DECLARE @ColumnList NVARCHAR(max) = '' 
		DECLARE @ColumnExtList NVARCHAR(max) = ''
		
        SELECT
		@ColumnList = @ColumnList +', ' + colname,
		@ColumnExtList = @ColumnExtList +', ' + colname + ' = AA.' + colname
        FROM @Columns

		--PRINT @ColumnList --only for debugging
		--PRINT @ColumnExtList --only for debugging

DECLARE @SQL NVARCHAR(MAX)
DECLARE @RecordsSelected BIGINT = 0
DECLARE @RecordsUpdated BIGINT = 0
DECLARE @RecordsInserted BIGINT = 0
DECLARE @RecordsDeleted BIGINT = 0
DECLARE @RecordsFailed BIGINT = 0
DECLARE @RecordsDiscarded BIGINT = 0

	SET @SQL = '
----------------------------------------------------
-- Get RecordsSelected, Update table
----------------------------------------------------
SELECT @RecordsSelected = COUNT(*) FROM <SourceTablename>

	UPDATE <DestTablename> 
	SET    
       [Meta_IsCurrent]                         = 0
	  ,[Meta_IsDeleted]							= 1
      ,[Meta_ValidTo]	                        = GETDATE()
	  ,[Meta_ValidFrom]							= DATEADD(ss,1,<DestTablename>.Meta_ValidFrom)
	FROM <SourceTablename> AS AA
	WHERE <CvrOrPnrWhereList>

----------------------------------------------------
-- Insert rows and get RecordsInserted
----------------------------------------------------

		INSERT INTO <DestTablename> 
		(
				 <CvrOrPnrList>
				 <ColumnList>
				,[Meta_VersionNo]
				,[Meta_ValidFrom]
				,[Meta_ValidTo]
				,[Meta_IsValid]
				,[Meta_IsCurrent]
				,[Meta_IsDeleted]
				,[Meta_CreateTime]
				,[Meta_CreateJob]
		)
		SELECT 
				<CvrOrPnrList>
				<ColumnList>
				,1						--Meta_VersionNo
				,''1800-01-01''			--Meta_ValidFrom
				,''9999-12-31''			--Meta_ValidTo
				,1						--Meta_IsValid
				,1						--Meta_IsCurrent
				,0						--Meta_IsDeleted
				,GETDATE()				--Meta_CreateTime
				,<ArchiveId>			--Meta_CreateJob		
		FROM <SourceTablename> AS AA

	SELECT @RecordsInserted = @@ROWCOUNT

----------------------------------------------------
--  Delete rows and get RecordsDeleted
----------------------------------------------------

    DELETE FROM <DestTablename>
    WHERE [Meta_IsCurrent] = 0
		AND [Meta_IsDeleted] = 1
	
	SELECT @RecordsDeleted = @@ROWCOUNT

----------------------------------------------------
-- Update Extract log with ArchiveId & Time
----------------------------------------------------
		UPDATE Audit.ExtractLog
        SET 
			ArchiveId = @ArchiveId,
			ArchiveTime = GETDATE()
        FROM Audit.ExtractLog el
			INNER JOIN (SELECT DISTINCT Meta_CreateJob FROM <SourceTablename>) e
			ON e.Meta_CreateJob = el.Id
		WHERE 
			el.TableName = ''<Tablename>''
		AND el.[Database] = ''<Database>''

----------------------------------------------------
-- Truncate extracted rows in extract table
----------------------------------------------------
IF @ExtractDeleteAction = ''Delete''
BEGIN
	TRUNCATE TABLE <SourceTablename>
END
	' --End Dynamic SQL

	   	SET @SQL = REPLACE(@SQL,'<DestTablename>', @DestTablename);
		SET @SQL = REPLACE(@SQL,'<SourceTablename>', @SourceTablename);
		SET @SQL = REPLACE(@SQL,'<Tablename>', @Tablename);
		SET @SQL = REPLACE(@SQL,'<CvrOrPnrList>', @CvrOrPnrList);
		SET @SQL = REPLACE(@SQL,'<CvrOrPnrExtList>', @CvrOrPnrExtList);
		SET @SQL = REPLACE(@SQL,'<CvrOrPnrWhereList>', @CvrOrPnrWhereList);
		SET @SQL = REPLACE(@SQL,'<ColumnList>', @ColumnList);
		SET @SQL = REPLACE(@SQL,'<ColumnExtList>', @ColumnExtList);
		SET @SQL = REPLACE(@SQL,'<ExecutionId>', @ExecutionId);
		SET @SQL = REPLACE(@SQL,'<DestSchema>', @DestSchema);
		SET @SQL = REPLACE(@SQL,'<Database>', @Database);
	    SET @SQL = REPLACE(@SQL,'<ArchiveId>', @ArchiveId);

-------------------------------------------------------
-- Get values from dynamic sql to use in ArchiveEnd
-------------------------------------------------------
	BEGIN
		EXECUTE sp_executesql @SQL
			,N'@ArchiveId BIGINT, @RecordsSelected BIGINT OUT, 
				@RecordsInserted BIGINT OUT, @RecordsDeleted BIGINT OUT, @ExtractDeleteAction NVARCHAR(10)'
			,@ArchiveId
            ,@RecordsSelected OUTPUT
            ,@RecordsInserted OUTPUT
			,@RecordsDeleted OUTPUT
			,@ExtractDeleteAction
	END
-------------------------------------------------------
-- Commit transaction (if started here)
-------------------------------------------------------
	IF @TranCounter = 0
		COMMIT TRANSACTION;

-------------------------------------------------------
-- End ArchiveEnd if success
-------------------------------------------------------
	EXECUTE Audit.ArchiveEnd @ArchiveId, 'Succeeded', @RecordsSelected, @RecordsInserted, @RecordsUpdated, @RecordsDeleted, @RecordsFailed, @RecordsDiscarded

	END TRY

	BEGIN CATCH
-------------------------------------------------------
-- Rollback if transaction was started here OR rollback
-- to @SavePoint if transaction OK, ELSE throw error
-------------------------------------------------------
	DECLARE 
		 @ErrorMessage NVARCHAR(MAX)
		,@ErrorSeverity INT
		,@ErrorState INT;
	SELECT 
		 @ErrorMessage = ERROR_MESSAGE() + 'Line' + CAST(ERROR_LINE() AS NVARCHAR(5))
		,@ErrorSeverity = ERROR_SEVERITY()
		,@ErrorState = ERROR_STATE();
	IF @@TRANCOUNT > 0
	RAISERROR (
			 @ErrorMessage
			,@ErrorSeverity
			,@ErrorState
			);	
	
	IF @TranCounter = 0 BEGIN
		ROLLBACK TRANSACTION;
	END
		ELSE IF XACT_STATE() = 1 BEGIN
			ROLLBACK TRANSACTION @SavePoint
	END
-------------------------------------------------------
-- End ArchiveEnd if failure
-------------------------------------------------------
EXECUTE Audit.ArchiveEnd @ArchiveId, 'Failed';

		THROW;
	END CATCH
				--PRINT @SQL --Only for debugging
END