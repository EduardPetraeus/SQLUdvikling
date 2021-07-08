CREATE PROCEDURE [Fact].[UpdateFact]
    @FactName NVARCHAR(100),
    @ParentJobId BIGINT,
    @FullLoad BIT = 0,
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    DECLARE @FactStagingName NVARCHAR(105) = 'Fact_' + @FactName

    -------------------------------------------------------
    -- Start batchlog and get JobId
    -------------------------------------------------------
    DECLARE @JobId BIGINT = -1
    IF @PrintOnly = 0
        EXEC Audit.ExecutionStart NULL, NULL, @JobId OUT, @ParentJobId, 'Staging', @FactStagingName, 'Fact', @FactName

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
        -- TODO!

        --------------------------------------------
        -- Get the business key(s) from the map table
        --------------------------------------------
        DECLARE @BusinessKeys TABLE (value NVARCHAR (100))

        INSERT INTO @BusinessKeys
          SELECT '[' + COLUMN_NAME + ']'
          FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
          WHERE TABLE_SCHEMA = 'Fact'
            AND TABLE_NAME = @FactName
            AND COLUMN_NAME NOT LIKE 'Meta_%'
            AND LEFT(CONSTRAINT_NAME, 3) = 'PK_'

        -- Create merge join
        DECLARE @BusinessKeysJoin NVARCHAR(max) = ''
        SELECT @BusinessKeysJoin = @BusinessKeysJoin + ' AND fct.' + value + ' = sta.' + value FROM @BusinessKeys
        SET @BusinessKeysJoin = SUBSTRING(@BusinessKeysJoin, 6, LEN(@BusinessKeysJoin))

        -- Create key list
        DECLARE @BusinessKeysList NVARCHAR(max) = ''
        SELECT @BusinessKeysList = @BusinessKeysList + ', ' + value FROM @BusinessKeys
        SET @BusinessKeysList = SUBSTRING(@BusinessKeysList, 3, LEN(@BusinessKeysList))

        -- Create key staging list
        DECLARE @BusinessKeysStaList NVARCHAR(max) = ''
        SELECT @BusinessKeysStaList = @BusinessKeysStaList + ', sta.' + value FROM @BusinessKeys
        SET @BusinessKeysStaList = SUBSTRING(@BusinessKeysStaList, 3, LEN(@BusinessKeysStaList))


        -------------------------------------------
        -- Get the columns to handle from Fact
        -------------------------------------------
        DECLARE @Columns TABLE (value NVARCHAR(100))

        INSERT @Columns
          SELECT '[' + COLUMN_NAME + ']'
          FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = 'Fact'
            AND TABLE_NAME = @FactName
	        AND COLUMN_NAME NOT LIKE 'Meta_%'
	        AND NOT EXISTS (SELECT 1 FROM @BusinessKeys WHERE '[' + COLUMN_NAME + ']' = value)

        -- Create column list
        DECLARE @ColumnList NVARCHAR(max) = ''
        SELECT @ColumnList = @ColumnList + ', ' + value FROM @Columns
        SET @ColumnList = SUBSTRING(@ColumnList, 3, LEN(@ColumnList))
        
        -- Create column staging list
        DECLARE @ColumnStaList NVARCHAR(max) = ''
        SELECT @ColumnStaList = @ColumnStaList + ', sta.' + value FROM @Columns
        SET @ColumnStaList = SUBSTRING(@ColumnStaList, 3, LEN(@ColumnStaList))

        -- Create column update list
        DECLARE @ColumnUpList NVARCHAR(max) = ''
        SELECT @ColumnUpList = @ColumnUpList + ', fct.' + value + ' = sta.' + value FROM @Columns
        SET @ColumnUpList = SUBSTRING(@ColumnUpList, 3, LEN(@ColumnUpList))

        -- Create column diff list
        DECLARE @ColumnDiffList NVARCHAR(max) = ''
        SELECT @ColumnDiffList = @ColumnDiffList + '  OR (sta.' + value + ' <> fct.' + value + ' OR (sta.' + value + ' IS NULL AND fct.' + value + ' IS NOT NULL) OR (sta.' + value + ' IS NOT NULL AND fct.' + value + ' IS NULL))' + @NewLine FROM @Columns
        SET @ColumnDiffList = SUBSTRING(@ColumnDiffList, 6, LEN(@ColumnDiffList))


        ------------------------------------------------------
        -- Now make the SQL to update the archive from extract
        ------------------------------------------------------
        DECLARE @SQL NVARCHAR(max)
        DECLARE @SelectedRows INT = 0
        DECLARE @InsertedRows INT = 0
        DECLARE @UpdatedRows INT = 0

        SET @SQL = '
        /* Set last run time for archive load*/
        DECLARE @LastRunTime DATETIME
        SELECT @LastRunTime = MAX(StartTime)
        FROM Audit.ExecutionLog WHERE DstSchema = ''Fact'' AND DstTable = ''<FactName>'' AND JobStatus = ''Succeeded''

        IF @FullLoad = 1 OR @LastRunTime IS NULL
            SELECT @LastRunTime = CAST(Value AS DATE) FROM Utility.FixedValues WHERE [Key] = ''DateBOU''

        /* Truncate Fact if full load */
        IF @FullLoad = 1
        BEGIN
            EXEC Fact.TruncateFact <FactName>
        END

        /* Merge Fact table */
        DECLARE @Actions TABLE (act NVARCHAR (10))

        MERGE Fact.<FactName> fct
        USING (
          SELECT *
          FROM Staging.Fact_<FactName>
          WHERE Meta_ValidFrom >= @LastRunTime
        ) sta ON <BusinessKeyJoin>

        WHEN MATCHED AND (<ColumnDiffList>)
          THEN UPDATE
          SET <ColumnUpList>, fct.Meta_UpdateJob = @JobId, fct.Meta_UpdateTime = GETDATE()

        WHEN NOT MATCHED BY TARGET
          THEN INSERT (<BusinessKeyList>, <ColumnList>, Meta_CreateJob, Meta_CreateTime)
          VALUES (<BusinessKeyStaList>, <ColumnStaList>, @JobId, GETDATE())

        OUTPUT $action INTO @Actions
        ;
        
        SELECT @SelectedRows = COUNT(*) FROM @Actions
        SELECT @InsertedRows = COUNT(*) FROM @Actions WHERE act = ''INSERT''
        SELECT @UpdatedRows = COUNT(*) FROM @Actions WHERE act = ''UPDATE''

        '

        SET @SQL = REPLACE(@SQL,'<FactName>', @FactName);
        SET @SQL = REPLACE(@SQL,'<BusinessKeyJoin>', @BusinessKeysJoin);
        SET @SQL = REPLACE(@SQL,'<BusinessKeyList>', @BusinessKeysList);
        SET @SQL = REPLACE(@SQL,'<BusinessKeyStaList>', @BusinessKeysStaList);
        SET @SQL = REPLACE(@SQL,'<ColumnList>', @ColumnList);
        SET @SQL = REPLACE(@SQL,'<ColumnUpList>', @ColumnUpList);
        SET @SQL = REPLACE(@SQL,'<ColumnStaList>', @ColumnStaList);
        SET @SQL = REPLACE(@SQL,'<ColumnDiffList>', @ColumnDiffList);

        IF @PrintOnly = 1
        BEGIN
          EXEC Utility.PrintLargeString @SQL
        END
        ELSE
        BEGIN
          EXECUTE sp_executesql @SQL
            , N'@JobId BIGINT, @SelectedRows INT OUT, @InsertedRows INT OUT, @UpdatedRows INT OUT, @FullLoad BIT'
            , @JobId
            , @SelectedRows OUTPUT
            , @InsertedRows OUTPUT
            , @UpdatedRows OUTPUT
            , @FullLoad
        END


		-------------------------------------------------------
		-- Commit transaction (if started here)
		-------------------------------------------------------
		IF @TranCounter = 0
			COMMIT TRANSACTION;

        -------------------------------------------------------
        -- End batchlog - success
        -------------------------------------------------------
        IF @PrintOnly = 0
            EXEC Audit.ExecutionEnd @JobId, 'Succeeded', @SelectedRows, @InsertedRows, @UpdatedRows
	
	END TRY

	BEGIN CATCH

        -------------------------------------------------------
		-- Rollback if transaction was started here OR rollback
        -- to @SavePoint if transaction OK, ELSE throw error
        -------------------------------------------------------
		IF @TranCounter = 0
			ROLLBACK TRANSACTION;
		ELSE 
			IF XACT_STATE() = 1
				ROLLBACK TRANSACTION @SavePoint

	    -------------------------------------------------------
        -- End batchlog - failure
        -------------------------------------------------------
        EXEC Audit.ExecutionEnd @JobId, 'Failed';

		THROW;

	END CATCH

END
