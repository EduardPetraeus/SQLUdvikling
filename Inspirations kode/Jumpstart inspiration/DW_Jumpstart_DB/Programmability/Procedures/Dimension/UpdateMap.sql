CREATE PROCEDURE [Dimension].[UpdateMap]
    @StagingTableName NVARCHAR (255),
    @ExecutionId BIGINT = -1,
    @MarkDeletes BIT = 0, -- If 1 then 'WHEN NOT MATCHED BY SOURCE' will be added to merge
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    -----------------------------------------------------------------------------------------------
    -- Set meta column names and default (NULL will be interpreted as not used)
    -----------------------------------------------------------------------------------------------
    DECLARE @MetaColumns TABLE (ColumnName NVARCHAR(255), DefaultOnInsert NVARCHAR(255), DefaultOnDelete NVARCHAR(255))

    INSERT INTO @MetaColumns
    VALUES (N'Meta_CreateJob', N'@DataTransferId', NULL)
          ,(N'Meta_CreateTime', N'GETDATE()', NULL)
          ,(N'Meta_DeleteJob', NULL, N'@DataTransferId')
          ,(N'Meta_DeleteTime', NULL, N'GETDATE()')
          ,(N'Meta_IsDeleted', N'0', N'1')


    -----------------------------------------------------------------------------------------------
    -- Set schema and table variables
    -----------------------------------------------------------------------------------------------
    SET @StagingTableName = REPLACE(REPLACE(@StagingTableName, N']', N''), N'[', N'')

    DECLARE @StagingSchemaName NVARCHAR(255) = N'Staging'
    DECLARE @MapTableName NVARCHAR(255) = REPLACE(@StagingTableName, N'Dimension_', N'')
    DECLARE @MapSchemaName NVARCHAR(255) = N'Map'

    DECLARE @MapTableFullName NVARCHAR(500) =  QUOTENAME(@MapSchemaName) + N'.' + QUOTENAME(@MapTableName)
    DECLARE @StagingTableFullName NVARCHAR(500) = QUOTENAME(@StagingSchemaName) + N'.' + QUOTENAME(@StagingTableName)


    -----------------------------------------------------------------------------------------------
    -- Set other setup variables
    -----------------------------------------------------------------------------------------------
    DECLARE @IsLogingEnabled BIT = 0
    IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'Audit' AND TABLE_NAME = 'DataTransferLog') BEGIN
        SET @IsLogingEnabled = 1
    END

    DECLARE @SurrogateKeyPrefix NVARCHAR (10) = N'EKey_'

    
    -----------------------------------------------------------------------------------------------
    -- Test if the tables exists
    -----------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName) BEGIN
        RAISERROR(N'The staging table %s does not exists.', 16, 1, @StagingTableFullName)
    END

    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @MapSchemaName AND TABLE_NAME = @MapTableName) BEGIN
        RAISERROR(N'The map table %s does not exists.', 16, 1, @MapTableFullName)
    END


    -----------------------------------------------------------------------------------------------
    -- Get all columns used from map incl. primary key and staging
    -----------------------------------------------------------------------------------------------
    DECLARE @AllColumns TABLE (ColumnName NVARCHAR (255), DefaultOnInsert NVARCHAR (255), DefaultOnDelete NVARCHAR(255), IsBusinessKeyColumn BIT, IsSurrogateKeyColumn BIT, IsMetaColumn BIT)

    INSERT INTO @AllColumns
    SELECT
        N'[' + map.COLUMN_NAME + N']' AS ColumnName
    ,   meta.DefaultOnInsert
    ,   meta.DefaultOnDelete
    ,   IIF(sta.COLUMN_NAME IS NOT NULL AND meta.ColumnName IS NULL, 1, 0) AS IsBusinessKeyColumn
    ,   IIF(LEFT(map.COLUMN_NAME, LEN(@SurrogateKeyPrefix)) = @SurrogateKeyPrefix, 1, 0) AS IsSurrogateKeyColumn
    ,   IIF(meta.ColumnName IS NOT NULL, 1, 0) AS IsMetaColumn
    FROM (
        SELECT COLUMN_NAME, ORDINAL_POSITION
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @MapSchemaName AND TABLE_NAME = @MapTableName
    ) map
    LEFT JOIN (
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName
    ) sta ON sta.COLUMN_NAME = map.COLUMN_NAME
    LEFT JOIN @MetaColumns meta ON meta.ColumnName = map.COLUMN_NAME
    ORDER BY map.ORDINAL_POSITION


    -----------------------------------------------------------------------------------------------
    -- Test if everything is OK
    -----------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT TOP 1 1 FROM @AllColumns WHERE IsBusinessKeyColumn = 1) BEGIN
        RAISERROR(N'Could not find business key column(s) in staging table.', 16, 1);
        RETURN -1;
    END

    IF NOT EXISTS(SELECT TOP 1 1 FROM @AllColumns WHERE IsSurrogateKeyColumn = 1) BEGIN
        RAISERROR(N'Could not find surrogate key column in map table.', 16, 1);
        RETURN -1;
    END

    -----------------------------------------------------------------------------------------------
    -- Construct SQL statement
    -----------------------------------------------------------------------------------------------
    DECLARE @BusinessKeyList NVARCHAR(max) = N''
    SELECT @BusinessKeyList = @BusinessKeyList + N', ' + ColumnName FROM @AllColumns WHERE IsBusinessKeyColumn = 1
    SET @BusinessKeyList = SUBSTRING(@BusinessKeyList, 3, LEN(@BusinessKeyList))

    DECLARE @BusinessKeyJoin NVARCHAR(max) = N''
    SELECT @BusinessKeyJoin = @BusinessKeyJoin + ' AND map.' + ColumnName + ' = sta.' + ColumnName FROM @AllColumns WHERE IsBusinessKeyColumn = 1
    SET @BusinessKeyJoin = SUBSTRING(@BusinessKeyJoin, 6, LEN(@BusinessKeyJoin))

    DECLARE @InsertColumnList NVARCHAR(max) = N''
    SELECT @InsertColumnList = @InsertColumnList + N', ' + ColumnName FROM @AllColumns WHERE (IsMetaColumn = 0 AND IsSurrogateKeyColumn = 0) OR (IsMetaColumn = 1 AND DefaultOnInsert IS NOT NULL)
    SET @InsertColumnList = SUBSTRING(@InsertColumnList, 3, LEN(@InsertColumnList))

    DECLARE @InsertValueList NVARCHAR(max) = N''
    SELECT @InsertValueList = @InsertValueList + N', ' + IIF(IsMetaColumn = 1, DefaultOnInsert, N'sta.' + ColumnName) FROM @AllColumns WHERE (IsMetaColumn = 0 AND IsSurrogateKeyColumn = 0) OR (IsMetaColumn = 1 AND DefaultOnInsert IS NOT NULL)
    SET @InsertValueList = SUBSTRING(@InsertValueList, 3, LEN(@InsertValueList))
    
    DECLARE @DeleteColumnList NVARCHAR(max) = N''
    SELECT @DeleteColumnList = @DeleteColumnList + N', map.' + ColumnName + ' = ' + IIF(IsMetaColumn = 1, DefaultOnDelete, N'sta.' + ColumnName) FROM @AllColumns WHERE IsMetaColumn = 1 AND DefaultOnDelete IS NOT NULL
    SET @DeleteColumnList = SUBSTRING(@DeleteColumnList, 3, LEN(@DeleteColumnList))

    DECLARE @SQL NVARCHAR(max) = N''

    IF @IsLogingEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
    /* Start log */
    DECLARE @DataTransferId BIGINT = -1;
    EXECUTE [Audit].[DataTransferStart] @SchemaName = ''<MapSchemaName>'',
                                        @TableName = ''<MapTableName>'',
                                        @DataTransferId = @DataTransferId OUTPUT,
                                        @ExecutionId = @ExecutionId,
                                        @Source = ''<StagingSchemaName>.<StagingTableName>'',
                                        @StoredProcedureName = ''UpdateMap'',
                                        @StoredProcedureVersion = ''1.0'',
                                        @TableTruncated = 0;
    '
    END
    ELSE BEGIN
        SET @SQL = @SQL + N'
    DECLARE @DataTransferId BIGINT = @ExecutionId;
    '
    END

    SET @SQL = @SQL + N'
    BEGIN TRY
        /* Start transaction - join if there is an existing one */
        DECLARE @TranCounter INT = @@TRANCOUNT;
        DECLARE @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N''_'' + CAST(@@NESTLEVEL AS NVARCHAR(2));

        IF @TranCounter > 0
            SAVE TRANSACTION @SavePoint;
        ELSE
            BEGIN TRANSACTION;

        /* Merge map table */
        DECLARE @Actions TABLE (act NVARCHAR (10));

        MERGE <MapTableFullName> map
        USING (
            SELECT DISTINCT <BusinessKeyList>
            FROM <StagingTableFullName>
        ) sta ON <BusinessKeyJoin>

        WHEN NOT MATCHED BY TARGET
            THEN INSERT (<InsertColumnList>)
            VALUES (<InsertValueList>)
    '
    IF @MarkDeletes = 1 BEGIN
        SET @SQL = @SQL + N'
        WHEN NOT MATCHED BY SOURCE
            THEN UPDATE
            SET <DeleteColumnList>
    '
    END

    SET @SQL = @SQL + N'
        OUTPUT $action INTO @Actions;
        
        /* Commit transaction (if started here) */
		IF @TranCounter = 0 BEGIN
			COMMIT TRANSACTION;
        END
    '

    IF @IsLogingEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
        /* End log - Succeeded */
        DECLARE @RecordsSelected INT = 0, @RecordsInserted INT = 0, @RecordsDeleted INT = 0;
        SELECT @RecordsSelected = COUNT(*) FROM <StagingTableFullName>;
        SELECT @RecordsInserted = COUNT(*) FROM @Actions WHERE act = ''INSERT'';
        SELECT @RecordsDeleted = COUNT(*) FROM @Actions WHERE act = ''UPDATE'';

        EXECUTE [Audit].[DataTransferEnd] @DataTransferId = @DataTransferId,
                                          @RecordsSelected = @RecordsSelected,
                                          @RecordsInserted = @RecordsInserted,
                                          @RecordsDeleted = @RecordsDeleted;
    '
    END

	SET @SQL = @SQL + N'
	END TRY
	BEGIN CATCH
        /* Rollback if transaction was started here OR rollback to @SavePoint if transaction OK */
        IF @TranCounter = 0
	        ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
	        ROLLBACK TRANSACTION @SavePoint;
    '

    IF @IsLogingEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
        /* End log - Failed */
        EXECUTE [Audit].[DataTransferEnd] @DataTransferId = @DataTransferId,
                                          @Status = N''Failed'';
        '
    END

    SET @SQL = @SQL + N'
        THROW;
	END CATCH
    '

    SET @SQL = REPLACE(@SQL, N'<MapSchemaName>', @MapSchemaName);
	SET @SQL = REPLACE(@SQL, N'<MapTableName>', @MapTableName);
    SET @SQL = REPLACE(@SQL, N'<StagingSchemaName>', @StagingSchemaName);
    SET @SQL = REPLACE(@SQL, N'<StagingTableName>', @StagingTableName);
    SET @SQL = REPLACE(@SQL, N'<MapTableFullName>', @MapTableFullName);
    SET @SQL = REPLACE(@SQL, N'<BusinessKeyList>', @BusinessKeyList);
    SET @SQL = REPLACE(@SQL, N'<StagingTableFullName>', @StagingTableFullName);
    SET @SQL = REPLACE(@SQL, N'<BusinessKeyJoin>', @BusinessKeyJoin);
    SET @SQL = REPLACE(@SQL, N'<InsertColumnList>', @InsertColumnList);
    SET @SQL = REPLACE(@SQL, N'<InsertValueList>', @InsertValueList);
    SET @SQL = REPLACE(@SQL, N'<DeleteColumnList>', @DeleteColumnList);


    -----------------------------------------------------------------------------------------------
    -- Execute or print SQL statement
    -----------------------------------------------------------------------------------------------
    IF @PrintOnly = 1 BEGIN
        SET @SQL = N'
    DECLARE @ExecutionId BIGINT = -1
    ' + @SQL

        EXEC Utility.PrintLargeString @SQL

        SELECT * FROM @AllColumns
    END
    ELSE BEGIN
        EXECUTE sp_executesql @SQL, N'@ExecutionId BIGINT', @ExecutionId
    END

END