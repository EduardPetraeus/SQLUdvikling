
CREATE   PROCEDURE [Archive].[UpdateArchive]
    @Database SYSNAME,
    @TableName NVARCHAR(255),
    @ExecutionId BIGINT = -1,
    @ExtractDeleteAction NVARCHAR(10) = 'Delete',
    @PrintOnly BIT = 0,
	@Schema NVARCHAR(255) = 'Archive'
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    -------------------------------------------------------
    -- Start ExecutionLog and get JobId
    -------------------------------------------------------
    DECLARE @ArchiveId BIGINT = -1
	DECLARE @IsFullLoad INT = (SELECT ISNULL((		SELECT TOP 1 
										CASE 
											WHEN IsFullLoad IS NULL THEN -1 
											ELSE IsFullLoad 
										END 
									FROM Audit.ExtractLog 
									WHERE [Database] = @Database AND TableName = @TableName 
									ORDER BY Id DESC),-1)
							   )

    IF @PrintOnly = 0 BEGIN
        EXEC Audit.ArchiveStart
			@Database = @Database,
            @TableName = @TableName, 
            @ArchiveId = @ArchiveId OUT, 
            @ExecutionId = @ExecutionId,
			@IsFullLoad = @IsFullLoad
                     
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
        -- Test if tables exist in extract and archive
        -----------------------------------------------
        IF Utility.GetObjectId(@Database, N'Extract', @TableName) IS NULL
            RAISERROR(N'The table %s does not exist in the Extract schema.', 16, 1, @TableName)

        IF Utility.GetObjectId(@Database, N'Archive', @TableName) IS NULL
            RAISERROR(N'The table %s does not exist in the Archive schema.', 16, 1, @TableName)

        ----------------------------------------------------
        -- Get the natural keys from archive primary key
        ----------------------------------------------------
        DECLARE @NaturalKeys TABLE (colname SYSNAME)

        INSERT INTO @NaturalKeys
        EXECUTE Utility.GetKeyColumns @Database = @Database, @Schema = 'Archive', @Table = @TableName

        -- Create joins
        -- Create key list
        -- Create key staging list
        -- Create key NULL check
        DECLARE @NaturalKeyJoin NVARCHAR(max) = ''
        DECLARE @NaturalKeyList NVARCHAR(max) = ''
        DECLARE @NaturalKeyExtList NVARCHAR(max) = ''
        DECLARE @NaturalKeyNULLCheck NVARCHAR(max) = ''
        DECLARE @NaturalKeyNULLSelect NVARCHAR(max) = ''

        SELECT
			@NaturalKeyJoin = @NaturalKeyJoin + ' AND ext.' + colname + ' = arc.' + colname,
			@NaturalKeyList = @NaturalKeyList + ', ' + colname,
			@NaturalKeyExtList = @NaturalKeyExtList + ', ext.' + colname,
			@NaturalKeyNULLCheck = @NaturalKeyNULLCheck + ' AND ' + colname + ' IS NOT NULL',
			@NaturalKeyNULLSelect = @NaturalKeyNULLSelect + ' AND ' + colname + ' IS NULL'
        FROM @NaturalKeys

        SET @NaturalKeyJoin = SUBSTRING(@NaturalKeyJoin, 6, LEN(@NaturalKeyJoin))
        SET @NaturalKeyList = SUBSTRING(@NaturalKeyList, 3, LEN(@NaturalKeyList))
        SET @NaturalKeyExtList = SUBSTRING(@NaturalKeyExtList, 3, LEN(@NaturalKeyExtList))

        -----------------------------------------
        -- Get the columns to handle from archive
        -----------------------------------------
        DECLARE @Columns TABLE (colname SYSNAME)

        INSERT INTO @Columns
		EXECUTE Utility.GetNonKeyColumns @Database = @Database, @Schema = 'Archive', @Table = @TableName

        -- Create column list
        -- Create column extract list
        -- Create column diff list
        DECLARE @ColumnList NVARCHAR(max) = ''
        DECLARE @ColumnExtList NVARCHAR(max) = ''
        DECLARE @ColumnDiffList NVARCHAR(max) = ''

        SELECT
			@ColumnList = @ColumnList + ', ' + colname,
			@ColumnExtList = @ColumnExtList + ', ext.' + colname
        FROM @Columns
		WHERE colname NOT IN(
			'[Meta_Id]',
			'[Meta_VersionNo]',
			'[Meta_ValidFrom]',
			'[Meta_ValidTo]',
			'[Meta_IsValid]',
			'[Meta_IsCurrent]',
			'[Meta_IsDeleted]',
			'[Meta_CreateTime]',
			'[Meta_CreateJob]',
			'[Meta_UpdateTime]',
			'[Meta_UpdateJob]',
			'[Meta_DeleteTime]',
			'[Meta_DeleteJob]')

		-- Exclude all columns prefixed with Meta_ from comparison
        SELECT
			@ColumnDiffList = @ColumnDiffList + ' OR ext.' + colname + ' <> arc.' + colname + CHAR(13)	
                + ' OR (ext.' + colname + ' IS NULL AND arc.' + colname + ' IS NOT NULL)' + CHAR(13)
                + ' OR (ext.' + colname + ' IS NOT NULL AND arc.' + colname + ' IS NULL)' + CHAR(13)
            + @NewLine
        FROM @Columns
		WHERE colname NOT LIKE '\[Meta[_]%\]' ESCAPE '\'

        SET @ColumnList = SUBSTRING(@ColumnList, 3, LEN(@ColumnList))
        SET @ColumnExtList = SUBSTRING(@ColumnExtList, 3, LEN(@ColumnExtList))
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
        /*** Get last succeeded extract start time and ids on full loads ***/
        DECLARE @LastSucceededEndTime DATETIME
        DECLARE @SyncCompletedExtractId BIGINT

        SELECT @LastSucceededEndTime = EndTime FROM (
            SELECT TOP 1 EndTime, ArchiveId FROM Audit.ExtractLog 
            WHERE (TableName = ''<TableName>'') 
                AND Status = ''Succeeded'' 
				AND [Database] = ''<Database>''

            ORDER BY StartTime DESC) x
        WHERE ArchiveId IS NOT NULL
		
        SELECT TOP 1
            @SyncCompletedExtractId = CASE WHEN Status = ''Succeeded'' THEN Id ELSE null END
        FROM Audit.ExtractLog
        WHERE (TableName = ''<TableName>'')
            AND IsFullLoad = 1 
			AND [Database] = ''<Database>''

        ORDER BY StartTime DESC

        /*** Merge archive table, one version at a time ***/
        IF OBJECT_ID(''tempdb..#Extract_<TableName>'') IS NOT NULL DROP TABLE #Extract_<TableName>

        SELECT
            <NaturalKeyList>,
            Meta_Id,
            ROW_NUMBER () OVER (PARTITION BY <NaturalKeyList> ORDER BY Meta_CreateTime ASC) Meta_RowNumber
        INTO #Extract_<TableName>
        FROM [<Database>].Extract.<TableName>
        WHERE Meta_CreateTime < ISNULL(@LastSucceededEndTime, Utility.EndOfUniverse())
            <NaturalKeyNULLCheck>

        CREATE INDEX IDX_Extract_<TableName>_Join ON #Extract_<TableName> (Meta_Id ASC)
        CREATE INDEX IDX_Extract_<TableName>_RowNumber ON #Extract_<TableName> (Meta_RowNumber ASC, Meta_Id ASC)

        IF OBJECT_ID(''tempdb..#Actions_<TableName>'') IS NOT NULL DROP TABLE #Actions_<TableName>
        CREATE TABLE #Actions_<TableName> (Meta_Id BIGINT, Meta_RowNumber INT, Meta_Action NVARCHAR(10), Meta_VersionNo INT)

        DECLARE @RowNumber INT = 1
        DECLARE @RowCount INT = 1
        
        WHILE (@RowCount > 0)
        BEGIN
                 
            MERGE [<Database>].Archive.<TableName> WITH (TABLOCKX) arc
            USING (
                SELECT e.*
                FROM [<Database>].Extract.<TableName> e
                INNER JOIN #Extract_<TableName> x ON x.Meta_Id = e.Meta_Id AND x.Meta_RowNumber = @RowNumber
            ) ext ON <NaturalKeyJoin>

            WHEN MATCHED AND arc.Meta_IsCurrent = 1 AND arc.Meta_ValidFrom < ext.Meta_CreateTime AND (arc.Meta_IsDeleted = 1 <ColumnDiffList>)
                THEN UPDATE
                SET arc.Meta_IsCurrent = 0,
                    arc.Meta_IsDeleted = 0,
                    arc.Meta_ValidTo = ext.Meta_CreateTime, 
                    arc.Meta_UpdateJob = @ArchiveId, 
                    arc.Meta_UpdateTime = GETDATE()

            WHEN NOT MATCHED BY TARGET
                THEN INSERT (
                    <NaturalKeyList>, 
                    <ColumnList>
                    Meta_IsCurrent, 
                    Meta_IsValid, 
                    Meta_IsDeleted, 
                    Meta_ValidFrom,
                    Meta_ValidTo, 
                    Meta_VersionNo, 
                    Meta_CreateJob, 
                    Meta_CreateTime)
                VALUES (
                    <NaturalKeyExtList>,
                    <ColumnExtList>
                    1,								-- Meta_IsCurrent 
                    1,								-- Meta_IsValid
                    0,								-- Meta_IsDeleted
                    Utility.BeginningOfUniverse(),	-- Meta_ValidFrom,
                    Utility.EndOfUniverse(),		-- Meta_ValidTo
                    1,								-- Meta_VersionNo
                    @ArchiveId,						-- Meta_CreateJob
                    GETDATE())						-- Meta_CreateTime

            OUTPUT ext.Meta_Id, @RowNumber, $action, inserted.Meta_VersionNo
            INTO #Actions_<TableName>;
                    
            INSERT [<Database>].Archive.<TableName> WITH (TABLOCKX) (
                <NaturalKeyList>,
                <ColumnList>
                Meta_IsCurrent,
                Meta_IsValid,
                Meta_IsDeleted,
                Meta_ValidFrom,
                Meta_ValidTo,
                Meta_VersionNo,
                Meta_CreateJob,
                Meta_CreateTime)
            SELECT
                <NaturalKeyExtList>,		-- <NaturalKeyList>
                <ColumnExtList>				-- <ColumnList>
                1,							-- Meta_IsCurrent
                1,							-- Meta_IsValid
                0,							-- Meta_IsDeleted
                ext.Meta_CreateTime,		-- Meta_ValidFrom
                Utility.EndOfUniverse(),	-- Meta_ValidTo
                act.Meta_VersionNo + 1,		-- Meta_VersionNo
                @ArchiveId,					-- Meta_CreateJob
                GETDATE()					-- Meta_CreateTime
            FROM [<Database>].Extract.<TableName> ext
            INNER JOIN #Actions_<TableName> act
                ON act.Meta_Id = ext.Meta_Id
                AND act.Meta_RowNumber = @RowNumber
            WHERE act.Meta_Action = ''UPDATE''

            SET @RowNumber = @RowNumber + 1

            SELECT @RowCount = COUNT(*)
            FROM #Extract_<TableName>
            WHERE Meta_RowNumber = @RowNumber
        END

        SELECT @SelectedRows = COUNT(*)
        FROM #Extract_<TableName>      
        
        SELECT @InsertedRows = COUNT(*)
        FROM #Actions_<TableName> 
        WHERE Meta_Action = ''INSERT''
        
        SELECT @UpdatedRows = COUNT(*)
        FROM #Actions_<TableName>
        WHERE Meta_Action = ''UPDATE''
        
        SELECT @FailedRows = COUNT(*)
        FROM [<Database>].Extract.<TableName>
        WHERE Meta_CreateTime < ISNULL(@LastSucceededEndTime, Utility.EndOfUniverse()) <NaturalKeyNULLSelect>
        
        SET @DiscardedRows = @SelectedRows - @InsertedRows - @UpdatedRows

        /*** Mark missing rows as deleted, if there is a full load in extract ***/
		IF EXISTS (SELECT TOP 1 1 FROM [<Database>].Extract.<TableName>) AND @SyncCompletedExtractId IS NOT NULL AND <IsFullLoad> = 1
        BEGIN
            UPDATE arc WITH (TABLOCKX)
            SET arc.Meta_IsCurrent = 1,
                arc.Meta_IsDeleted = 1,
                arc.Meta_ValidTo = GETDATE(),
                arc.Meta_DeleteJob = @ArchiveId,
                arc.Meta_DeleteTime = GETDATE()
            FROM [<Database>].Archive.<TableName> arc
            LEFT JOIN (
                SELECT DISTINCT <NaturalKeyList>, Meta_Id
                FROM [<Database>].Extract.<TableName>
                WHERE Meta_CreateJob = @SyncCompletedExtractId
            ) ext ON <NaturalKeyJoin>
            WHERE arc.Meta_IsCurrent = 1
              AND ext.Meta_Id IS NULL
			  AND arc.Meta_IsDeleted = 0
		END
          
        SELECT @DeletedRows = COUNT(*) FROM [<Database>].Archive.<TableName> WHERE Meta_DeleteJob = @ArchiveId

        /*** Update extract log with archive info ***/
        UPDATE el
        SET el.ArchiveId = @ArchiveId, el.ArchiveTime = GETDATE()
        FROM Audit.ExtractLog el
        INNER JOIN (
            SELECT DISTINCT Meta_CreateJob
            FROM [<Database>].Extract.<TableName>
            WHERE Meta_CreateTime <= ISNULL(@LastSucceededEndTime, Utility.EndOfUniverse()) <NaturalKeyNULLCheck>
        ) e ON e.Meta_CreateJob = el.Id
        WHERE el.TableName = ''<TableName>''
			AND el.[Database] = ''<Database>''


        /*** Delete handled rows in extract table, including identical rows ***/
        DECLARE @ExtractRows INT
        SELECT @ExtractRows = COUNT(*) FROM [<Database>].Extract.<TableName>

        IF @ExtractDeleteAction = ''Truncate'' OR (@ExtractDeleteAction = ''Delete'' AND @ExtractRows = @SelectedRows)
            TRUNCATE TABLE [<Database>].Extract.<TableName>
        ELSE IF @ExtractDeleteAction = ''Delete''
            DELETE e FROM [<Database>].Extract.<TableName> e INNER JOIN #Extract_<TableName> x ON x.Meta_Id = e.Meta_Id

        /*** Cleanup temporary table ***/
        DROP TABLE #Extract_<TableName>
        DROP TABLE #Actions_<TableName>
        '

        SET @SQL = REPLACE(@SQL,'<TableName>', @TableName);
		SET @SQL = REPLACE(@SQL,'<IsFullLoad>', @IsFullLoad);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyJoin>', @NaturalKeyJoin);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyList>', @NaturalKeyList);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyExtList>', @NaturalKeyExtList);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyNULLCheck>', @NaturalKeyNULLCheck);
        SET @SQL = REPLACE(@SQL,'<NaturalKeyNULLSelect>', @NaturalKeyNULLSelect);
        SET @SQL = REPLACE(@SQL,'<ColumnList>', @ColumnList);
        SET @SQL = REPLACE(@SQL,'<ColumnExtList>', @ColumnExtList);
        SET @SQL = REPLACE(@SQL,'<ColumnDiffList>', @ColumnDiffList);
		SET @SQL = REPLACE(@SQL,'<Database>', @Database);

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