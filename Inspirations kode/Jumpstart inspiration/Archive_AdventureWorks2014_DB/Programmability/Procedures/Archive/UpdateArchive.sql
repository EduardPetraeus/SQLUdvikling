CREATE PROCEDURE [Archive].[UpdateArchive]
    @TableName NVARCHAR(255),
    @ExecutionId BIGINT = -1,
    @ExtractDeleteAction NVARCHAR(10) = 'Delete',
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    -------------------------------------------------------
    -- Start ExecutionLog and get JobId
    -------------------------------------------------------
    DECLARE @ArchiveId BIGINT = -1

    IF @PrintOnly = 0 BEGIN
        EXEC Audit.ArchiveStart @TableName, @ArchiveId OUT, @ExecutionId, 'UpdateArchive', '1.0'
    END

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

        -----------------------------------------------
        -- Test if tables exists in extract and archive
        -----------------------------------------------
        IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Extract' AND TABLE_NAME = @TableName)
            RAISERROR(N'The table %s does not exists in the Extract schema.', 16, 1, @TableName)

        IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Archive' AND TABLE_NAME = @TableName)
            RAISERROR(N'The table %s does not exists in the Archive schema.', 16, 1, @TableName)

        ----------------------------------------------------
        -- Get the natural keys from archive primary key
        ----------------------------------------------------
        DECLARE @NaturalKeys TABLE (colname NVARCHAR (100), position INT)

        INSERT INTO @NaturalKeys
          SELECT '[' + COLUMN_NAME + ']', ORDINAL_POSITION
          FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
          WHERE TABLE_SCHEMA = 'Archive'
            AND TABLE_NAME = @TableName
            AND COLUMN_NAME NOT LIKE 'Meta_%'

        -- Create joins
        DECLARE @NaturalKeyJoin NVARCHAR(max) = ''
        SELECT @NaturalKeyJoin = @NaturalKeyJoin + ' AND ext.' + colname + ' = arc.' + colname FROM @NaturalKeys ORDER BY position
        SET @NaturalKeyJoin = SUBSTRING(@NaturalKeyJoin, 6, LEN(@NaturalKeyJoin))

        -- Create key list
        DECLARE @NaturalKeyList NVARCHAR(max) = ''
        SELECT @NaturalKeyList = @NaturalKeyList + ', ' + colname FROM @NaturalKeys ORDER BY position
        SET @NaturalKeyList = SUBSTRING(@NaturalKeyList, 3, LEN(@NaturalKeyList))

        -- Create key staging list
        DECLARE @NaturalKeyExtList NVARCHAR(max) = ''
        SELECT @NaturalKeyExtList = @NaturalKeyExtList + ', ext.' + colname FROM @NaturalKeys ORDER BY position
        SET @NaturalKeyExtList = SUBSTRING(@NaturalKeyExtList, 3, LEN(@NaturalKeyExtList))

        -- Create key NULL check
        DECLARE @NaturalKeyNULLCheck NVARCHAR(max) = ''
        SELECT @NaturalKeyNULLCheck = @NaturalKeyNULLCheck + ' AND ' + colname + ' IS NOT NULL' FROM @NaturalKeys ORDER BY position

        DECLARE @NaturalKeyNULLSelect NVARCHAR(max) = ''
        SELECT @NaturalKeyNULLSelect = @NaturalKeyNULLSelect + ' AND ' + colname + ' IS NULL' FROM @NaturalKeys ORDER BY position

        -----------------------------------------
        -- Get the columns to handle from archive
        -----------------------------------------
        DECLARE @Columns TABLE (colname NVARCHAR(100), coltype NVARCHAR(100))
		DECLARE @ColumnsHash TABLE (colname NVARCHAR(100), coltype NVARCHAR(100))

        INSERT @Columns
          SELECT '[' + COLUMN_NAME + ']', DATA_TYPE
          FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = 'Archive'
            AND TABLE_NAME = @TableName
	        AND COLUMN_NAME NOT LIKE 'Meta_%'
	        AND NOT EXISTS (SELECT 1 FROM @NaturalKeys WHERE '[' + COLUMN_NAME + ']' = colname)

		INSERT @ColumnsHash
          SELECT  COLUMN_NAME, DATA_TYPE
          FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = 'Archive'
            AND TABLE_NAME = @TableName 
            AND COLUMN_NAME NOT LIKE 'Meta_%'

        -- Create column list
        DECLARE @ColumnList NVARCHAR(max) = ''
        SELECT @ColumnList = @ColumnList + ', ' + colname FROM @Columns
        SET @ColumnList = SUBSTRING(@ColumnList, 3, LEN(@ColumnList))

        -- Create column extract list
        DECLARE @ColumnExtList NVARCHAR(max) = ''
        SELECT @ColumnExtList = @ColumnExtList + ', ext.' + colname FROM @Columns
        SET @ColumnExtList = SUBSTRING(@ColumnExtList, 3, LEN(@ColumnExtList))
		
		-- Identify if there is a Meta_HashValue column on the archive table
		DECLARE @HashColumnOnTable BIT
		SELECT @HashColumnOnTable =  1  FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = 'Archive' AND [COLUMN_NAME] = 'Meta_HashValue' AND [TABLE_NAME] = @TableName

		-- Create hash column list
		DECLARE @ColumnListHash NVARCHAR(max) = ''
        SELECT @ColumnListHash = @ColumnListHash + ',''|'',e.' + colname FROM @ColumnsHash
        SET @ColumnListHash = SUBSTRING(@ColumnListHash, 6, LEN(@ColumnListHash))
		
		-- Create hash column extract list
		DECLARE @ColumnExtListHash NVARCHAR(max) = ''
        SELECT @ColumnExtListHash = @ColumnExtListHash + ',''|'',ext.' + colname FROM @ColumnsHash
        SET @ColumnExtListHash = SUBSTRING(@ColumnExtListHash, 6, LEN(@ColumnExtListHash))
	
        -- Create column diff list
        DECLARE @ColumnDiffList NVARCHAR(max) = ''
        SELECT @ColumnDiffList = @ColumnDiffList + ' OR (ext.' + colname + ' <> arc.' + colname + ' OR (ext.' + colname + ' IS NULL AND arc.' + colname + ' IS NOT NULL) OR (ext.' + colname + ' IS NOT NULL AND arc.' + colname + ' IS NULL))' + @NewLine FROM @Columns WHERE coltype <> 'ntext'
        SET @ColumnDiffList = SUBSTRING(@ColumnDiffList, 5, LEN(@ColumnDiffList))

        -- Check for columns and add surronding stuff
        IF LEN(@ColumnList) > 0 
        BEGIN
            SET @ColumnList = @ColumnList + ','
            SET @ColumnExtList = @ColumnExtList + ','
			SET @ColumnDiffList = 'OR (' + @ColumnDiffList + ')'
        END

        ------------------------------------------------------
        -- Now make the SQL to update the archive from extract
        ------------------------------------------------------
        DECLARE @SQL NVARCHAR(max)
        DECLARE @SelectedRows INT = 0
        DECLARE @InsertedRows INT = 0
        DECLARE @UpdatedRows INT = 0
        DECLARE @DeletedRows INT = 0
        DECLARE @DiscardedRows INT = 0
        DECLARE @FailedRows INT = 0

        SET @SQL = '
        /*** Get Begin- and EndOfUniverse dates ***/
        DECLARE @DateEOU DATE
        SELECT @DateEOU = CAST(Value AS DATE) FROM Utility.FixedValues WHERE [Key] = ''DateEOU''

        DECLARE @DateBOU DATE
        SELECT @DateBOU = CAST(Value AS DATE) FROM Utility.FixedValues WHERE [Key] = ''DateBOU''


        /*** Get last succeeded extract start time and ids on full loads ***/
        DECLARE @LastSucceededEndTime DATETIME
        DECLARE @SyncCompletedExtractId BIGINT
        DECLARE @SyncCompletedExternalId NVARCHAR (255)

        SELECT @LastSucceededEndTime = EndTime FROM (SELECT TOP 1 EndTime, ArchiveId FROM Audit.ExtractLog WHERE TableName = ''<TableName>'' AND Status = ''Succeeded'' ORDER BY StartTime DESC) x WHERE ArchiveId IS NOT NULL
        SELECT TOP 1 @SyncCompletedExtractId = Id, @SyncCompletedExternalId = ExternalId FROM Audit.ExtractLog WHERE TableName = ''<TableName>'' AND IsFullLoad = 1 AND Status = ''Succeeded'' ORDER BY StartTime DESC

		/*** Merge archive table, one version at a time ***/
		IF OBJECT_ID(''tempdb..#Extract_<TableName>'') IS NOT NULL DROP TABLE #Extract_<TableName>


		SELECT <NaturalKeyList>, Meta_Id, ROW_NUMBER () OVER (PARTITION BY <NaturalKeyList> ORDER BY Meta_CreateTime ASC) Meta_RowNumber
		INTO #Extract_<TableName>
		FROM Extract.<TableName>
		WHERE Meta_CreateTime < ISNULL(@LastSucceededEndTime, @DateEOU)
			<NaturalKeyNULLCheck>

        CREATE INDEX IDX_Extract_<TableName>_Join ON #Extract_<TableName> (Meta_Id ASC)
        CREATE INDEX IDX_Extract_<TableName>_RowNumber ON #Extract_<TableName> (Meta_RowNumber ASC, Meta_Id ASC)

        IF OBJECT_ID(''tempdb..#Actions_<TableName>'') IS NOT NULL DROP TABLE #Actions_<TableName>
        CREATE TABLE #Actions_<TableName> (Meta_Id BIGINT, Meta_RowNumber INT, Meta_Action NVARCHAR(10), Meta_VersionNo INT)

        DECLARE @RowNumber INT = 1
        DECLARE @RowCount INT = 1
        
        WHILE (@RowCount > 0)
        
		BEGIN'

	IF @HashColumnOnTable = 1
		/*** The following code is used if there is a Meta_HashValue on the archive table ***/
		SET @SQL = @SQL + '
		/*** If there is a Meta_HashValue column on the archive table, compare records using the hash column ***/         
            MERGE Archive.<TableName> WITH (TABLOCKX) arc
            USING (
                SELECT e.*, HASHBYTES(''SHA2_256'', CONCAT(<ColumnListHash>)) as Meta_HashValue 
				FROM Extract.<TableName> e
                INNER JOIN #Extract_<TableName> x ON x.Meta_Id = e.Meta_Id AND x.Meta_RowNumber = @RowNumber
            ) ext ON <NaturalKeyJoin>

            WHEN MATCHED AND arc.Meta_IsCurrent = 1 AND arc.Meta_ValidFrom < ext.Meta_CreateTime AND (arc.Meta_IsDeleted = 1 OR (ext.[Meta_HashValue] <> arc.[Meta_HashValue]))

                THEN UPDATE
                SET arc.Meta_IsCurrent = 0, arc.Meta_IsDeleted = 0, arc.Meta_ValidTo = ext.Meta_CreateTime, arc.Meta_UpdateJob = @ArchiveId, arc.Meta_UpdateTime = GETDATE()

            WHEN NOT MATCHED BY TARGET

                THEN INSERT (<NaturalKeyList>, <ColumnList> Meta_IsCurrent, Meta_IsValid, Meta_IsDeleted, Meta_ValidFrom, Meta_ValidTo, Meta_VersionNo, Meta_CreateJob, Meta_CreateTime, Meta_HashValue)
             
				VALUES (<NaturalKeyExtList>, <ColumnExtList> 1, 1, 0, @DateBOU, @DateEOU, 1, @ArchiveId, GETDATE(),HASHBYTES(''SHA2_256'', CONCAT(<ColumnExtListHash>)))

            OUTPUT ext.Meta_Id, @RowNumber, $action, inserted.Meta_VersionNo INTO #Actions_<TableName>;

            INSERT Archive.<TableName> WITH (TABLOCKX) (<NaturalKeyList>, <ColumnList> Meta_IsCurrent, Meta_IsValid, Meta_IsDeleted, Meta_ValidFrom, Meta_ValidTo, Meta_VersionNo, Meta_CreateJob, Meta_CreateTime, Meta_HashValue)
          
			SELECT <NaturalKeyExtList>, <ColumnExtList> 1, 1, 0, ext.Meta_CreateTime, @DateEOU, act.Meta_VersionNo + 1, @ArchiveId, GETDATE(), HASHBYTES(''SHA2_256'', CONCAT(<ColumnExtListHash>)) as Meta_HashValue
            FROM Extract.<TableName> ext
            INNER JOIN #Actions_<TableName> act ON act.Meta_Id = ext.Meta_Id AND act.Meta_RowNumber = @RowNumber
            WHERE act.Meta_Action = ''UPDATE''
			'

	ELSE
        /*** If there is not a Meta_HashValue on the archive table, the following code is used instead ***/
		SET @SQL = @SQL + '
		/*** If there is no Meta_HashValue column on the archive table, use the ColumnDiffList ***/
            MERGE Archive.<TableName> WITH (TABLOCKX) arc
            USING (
                SELECT e.*
                FROM Extract.<TableName> e
                INNER JOIN #Extract_<TableName> x ON x.Meta_Id = e.Meta_Id AND x.Meta_RowNumber = @RowNumber
            ) ext ON <NaturalKeyJoin>

            WHEN MATCHED AND arc.Meta_IsCurrent = 1 AND arc.Meta_ValidFrom < ext.Meta_CreateTime AND (arc.Meta_IsDeleted = 1 <ColumnDiffList>)
                THEN UPDATE
                SET arc.Meta_IsCurrent = 0, arc.Meta_IsDeleted = 0, arc.Meta_ValidTo = ext.Meta_CreateTime, arc.Meta_UpdateJob = @ArchiveId, arc.Meta_UpdateTime = GETDATE()

            WHEN NOT MATCHED BY TARGET
                THEN INSERT (<NaturalKeyList>, <ColumnList> Meta_IsCurrent, Meta_IsValid, Meta_IsDeleted, Meta_ValidFrom, Meta_ValidTo, Meta_VersionNo, Meta_CreateJob, Meta_CreateTime)
                VALUES (<NaturalKeyExtList>, <ColumnExtList> 1, 1, 0, @DateBOU, @DateEOU, 1, @ArchiveId, GETDATE())

            OUTPUT ext.Meta_Id, @RowNumber, $action, inserted.Meta_VersionNo INTO #Actions_<TableName>;
                    
            INSERT Archive.<TableName> WITH (TABLOCKX) (<NaturalKeyList>, <ColumnList> Meta_IsCurrent, Meta_IsValid, Meta_IsDeleted, Meta_ValidFrom, Meta_ValidTo, Meta_VersionNo, Meta_CreateJob, Meta_CreateTime)
            
			SELECT <NaturalKeyExtList>, <ColumnExtList> 1, 1, 0, ext.Meta_CreateTime, @DateEOU, act.Meta_VersionNo + 1, @ArchiveId, GETDATE()
            FROM Extract.<TableName> ext
            INNER JOIN #Actions_<TableName> act ON act.Meta_Id = ext.Meta_Id AND act.Meta_RowNumber = @RowNumber
            WHERE act.Meta_Action = ''UPDATE''
			'
	SET @SQL = @SQL + '
		SET @RowNumber = @RowNumber + 1
        SELECT @RowCount = COUNT(*) FROM #Extract_<TableName> WHERE Meta_RowNumber = @RowNumber
		
		END

        SELECT @SelectedRows = COUNT(*) FROM #Extract_<TableName>      
        SELECT @InsertedRows = COUNT(*) FROM #Actions_<TableName> WHERE Meta_Action = ''INSERT''
        SELECT @UpdatedRows = COUNT(*) FROM #Actions_<TableName> WHERE Meta_Action = ''UPDATE''
        SELECT @FailedRows = COUNT(*) FROM Extract.<TableName> WHERE Meta_CreateTime < ISNULL(@LastSucceededEndTime, @DateEOU) <NaturalKeyNULLSelect>
        SET @DiscardedRows = @SelectedRows - @InsertedRows - @UpdatedRows


        /*** Mark missing rows as deleted, if there is a full load in extract ***/
        IF @SyncCompletedExtractId IS NOT NULL OR @SyncCompletedExternalId IS NOT NULL
        BEGIN
            UPDATE arc WITH (TABLOCKX)
            SET arc.Meta_IsCurrent = 1, arc.Meta_IsDeleted = 1, arc.Meta_ValidTo = GETDATE(), arc.Meta_DeleteJob = @ArchiveId, arc.Meta_DeleteTime = GETDATE()
            FROM Archive.<TableName> arc
            LEFT JOIN (
                SELECT DISTINCT <NaturalKeyList>, Meta_Id
                FROM Extract.<TableName>
                WHERE Meta_CreateJob = @SyncCompletedExtractId OR Meta_ExternalJob = @SyncCompletedExternalId
            ) ext ON <NaturalKeyJoin>
            WHERE arc.Meta_IsCurrent = 1 AND ext.Meta_Id IS NULL
        END
          
        SELECT @DeletedRows = COUNT(*) FROM Archive.<TableName> WHERE Meta_DeleteJob = @ArchiveId


        /*** Update extract log with archive info ***/
        UPDATE el
        SET el.ArchiveId = @ArchiveId, el.ArchiveTime = GETDATE()
        FROM Audit.ExtractLog el
        INNER JOIN (
            SELECT DISTINCT Meta_CreateJob, Meta_ExternalJob
            FROM Extract.<TableName>
            WHERE Meta_CreateTime <= ISNULL(@LastSucceededEndTime, @DateEOU) <NaturalKeyNULLCheck>
        ) e ON e.Meta_CreateJob = el.Id OR e.Meta_ExternalJob = el.ExternalId
        WHERE el.TableName = ''<TableName>''


        /*** Delete handled rows in extract table, including identical rows ***/
        DECLARE @ExtractRows INT
        SELECT @ExtractRows = COUNT(*) FROM Extract.<TableName>

        IF @ExtractDeleteAction = ''Truncate'' OR (@ExtractDeleteAction = ''Delete'' AND @ExtractRows = @SelectedRows)
            TRUNCATE TABLE Extract.<TableName>
        ELSE IF @ExtractDeleteAction = ''Delete''
            DELETE e FROM Extract.<TableName> e INNER JOIN #Extract_<TableName> x ON x.Meta_Id = e.Meta_Id


        /*** Cleanup temporary table ***/
        DROP TABLE #Extract_<TableName>
        DROP TABLE #Actions_<TableName>
        '

        SET @SQL = REPLACE(@SQL,'<TableName>', @TableName);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyJoin>', @NaturalKeyJoin);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyList>', @NaturalKeyList);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyExtList>', @NaturalKeyExtList);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyNULLCheck>', @NaturalKeyNULLCheck);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyNULLSelect>', @NaturalKeyNULLSelect);
        SET @SQL = REPLACE(@SQL,'<ColumnList>', @ColumnList);
        SET @SQL = REPLACE(@SQL,'<ColumnExtList>', @ColumnExtList);
		SET @SQL = REPLACE(@SQL,'<ColumnListHash>', @ColumnListHash);
		SET @SQL = REPLACE(@SQL,'<ColumnExtListHash>', @ColumnExtListHash);
		SET @SQL = REPLACE(@SQL,'<ColumnDiffList>', @ColumnDiffList);


        IF @PrintOnly = 1
        BEGIN
          EXEC Utility.PrintLargeString @SQL
        END
        ELSE
        BEGIN
          EXECUTE sp_executesql @SQL
            ,N'@ArchiveId BIGINT, @SelectedRows INT OUT, @InsertedRows INT OUT, @UpdatedRows INT OUT, 
               @FailedRows INT OUT, @DiscardedRows INT OUT, @DeletedRows INT OUT, @ExtractDeleteAction NVARCHAR(10)'
            ,@ArchiveId
            ,@SelectedRows OUTPUT
            ,@InsertedRows OUTPUT
            ,@UpdatedRows OUTPUT
            ,@FailedRows OUTPUT
            ,@DiscardedRows OUTPUT
            ,@DeletedRows OUTPUT
            ,@ExtractDeleteAction
        END

		-------------------------------------------------------
		-- Commit transaction (if started here)
		-------------------------------------------------------
		IF @TranCounter = 0
			COMMIT TRANSACTION;

        -------------------------------------------------------
        -- End ExecutionLog - success
        -------------------------------------------------------
        IF @PrintOnly = 0 BEGIN
            EXEC Audit.ArchiveEnd @ArchiveId, 'Succeeded', @SelectedRows, @InsertedRows, @UpdatedRows, @DeletedRows, @FailedRows, @DiscardedRows
		END

	END TRY

	BEGIN CATCH

        -------------------------------------------------------
		-- Rollback if transaction was started here OR rollback
        -- to @SavePoint if transaction OK, ELSE throw error
        -------------------------------------------------------
		IF @TranCounter = 0 BEGIN
			ROLLBACK TRANSACTION;
		END
		ELSE IF XACT_STATE() = 1 BEGIN
			ROLLBACK TRANSACTION @SavePoint
		END

	    -------------------------------------------------------
        -- End ExecutionLog - failure
        -------------------------------------------------------
        EXEC Audit.ArchiveEnd @ArchiveId, 'Failed';

		THROW;
	END CATCH
END
GO