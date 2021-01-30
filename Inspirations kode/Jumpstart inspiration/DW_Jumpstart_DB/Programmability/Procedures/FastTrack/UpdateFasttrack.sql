CREATE PROCEDURE [Fasttrack].[UpdateFasttrack]
    @TableName NVARCHAR(100),
    @ParentJobId BIGINT,
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13) + CHAR(2)

    BEGIN TRY

        -------------------------------------------------------
        -- Start transaction (join if there is an existing one)
        -- Start log
        -------------------------------------------------------
        DECLARE @TranCounter INT = @@TRANCOUNT
        DECLARE @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N'_' + CAST(@@NESTLEVEL AS NVARCHAR(2));

        IF @TranCounter > 0
            SAVE TRANSACTION @SavePoint;
        ELSE
            BEGIN TRANSACTION;

        DECLARE @JobId BIGINT
        EXEC Audit.ExecutionStart NULL, NULL, @JobId OUT, @ParentJobId, 'Extract', @TableName, 'Fasttrack', @TableName

        -----------------------------------------------
        -- Test if tables exists in extract and archive
        -----------------------------------------------
        -- TODO!


        ----------------------------
        -- Get the columns to handle
        ----------------------------
        DECLARE @Columns TABLE (value NVARCHAR(100))
        INSERT @Columns
          SELECT COLUMN_NAME
          FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = 'Fasttrack'
            AND TABLE_NAME = @TableName
	        AND COLUMN_NAME NOT LIKE 'Meta_%'

        -- Create column list
        DECLARE @ColumnList NVARCHAR(max) = ''
        SELECT @ColumnList = @ColumnList + ', ' + value FROM @Columns
        SET @ColumnList = SUBSTRING(@ColumnList, 3, LEN(@ColumnList))

        ------------------------------------------------------
        -- Now make the SQL to update the archive from extract
        ------------------------------------------------------
        DECLARE @SQL NVARCHAR(max)
        DECLARE @SelectedRows INT
        DECLARE @InsertedRows INT

        SET @SQL = '
		TRUNCATE TABLE Fasttrack.<TableName>

		INSERT INTO Fasttrack.<TableName> (<ColumnList>, Meta_CreateJob, Meta_CreateTime)
		SELECT <ColumnList>, @JobId, GETDATE()
		FROM Extract.<TableName>

        SELECT @SelectedRows = COUNT(*) FROM Extract.<TableName>
        SELECT @InsertedRows = COUNT(*) FROM Fasttrack.<TableName>
        '

        SET @SQL = REPLACE(@SQL,'<TableName>', @TableName);
        SET @SQL = REPLACE(@SQL,'<ColumnList>', @ColumnList);

        IF @PrintOnly = 1
        BEGIN
          PRINT LEN(@SQL)
          PRINT @SQL
        END
        ELSE
        BEGIN
          EXECUTE sp_executesql @SQL
            , N'@JobId BIGINT, @SelectedRows INT OUT, @InsertedRows INT OUT'
            , @JobId
            , @SelectedRows OUTPUT
            , @InsertedRows OUTPUT
        END

    	-------------------------------------------------
		-- End log and commit transaction (if started here)
		-------------------------------------------------
        EXEC Audit.ExecutionEnd @JobId, 'Succeded', @SelectedRows, @InsertedRows

		IF @TranCounter = 0
			COMMIT TRANSACTION;

	
	END TRY

	BEGIN CATCH

        -- Log task status
        EXEC Audit.ExecutionEnd @JobId, 'Failed'

		-- Rollback if transaction was started in this procedure
		IF @TranCounter = 0
			ROLLBACK TRANSACTION;
		ELSE 
			IF XACT_STATE() = 1
			-- NOT started here, but transactional OK
			-- Roll back to savepoint
				ROLLBACK TRANSACTION @SavePoint
			ELSE 
				IF XACT_STATE() = -1
				-- Critical!!! rollback!
					ROLLBACK TRANSACTION;
        THROW;
		RETURN 1;

	END CATCH

END
