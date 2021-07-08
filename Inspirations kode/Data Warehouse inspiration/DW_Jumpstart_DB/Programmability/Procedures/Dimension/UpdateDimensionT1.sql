CREATE PROCEDURE [Dimension].[UpdateDimensionT1]
    @DimensionTableName NVARCHAR (255),
    @StagingTableName NVARCHAR(255) = NULL,
    @ExecutionId BIGINT = -1,
    @TruncateDimension BIT = 0, -- If 1 truncate dimension table before load, otherwise do nothing
    @MarkDeletes BIT = 0, -- If 1 then 'WHEN NOT MATCHED BY SOURCE' will be added to merge
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    -----------------------------------------------------------------------------------------------
    -- Set meta column names and default (NULL will be interpreted as not used)
    -----------------------------------------------------------------------------------------------
    DECLARE @MetaColumns TABLE (ColumnName NVARCHAR(255), DefaultOnInsert NVARCHAR(255), DefaultOnUpdate NVARCHAR(255), DefaultOnDelete NVARCHAR(255))

    INSERT INTO @MetaColumns
    VALUES (N'Meta_CreateJob', N'@DataTransferId', NULL, NULL)
          ,(N'Meta_CreateTime', N'GETDATE()', NULL, NULL)
          ,(N'Meta_UpdateJob', NULL, N'@DataTransferId', NULL)
          ,(N'Meta_UpdateTime', NULL, N'GETDATE()', NULL)
          ,(N'Meta_DeleteJob', NULL, NULL, N'@DataTransferId')
          ,(N'Meta_DeleteTime', NULL, NULL, N'GETDATE()')
          ,(N'Meta_IsDeleted', N'0', NULL, N'1')
          ,(N'Meta_IsInferred', N'0', NULL, NULL)

    DECLARE @ValidFromColumnName NVARCHAR (100) = N'Meta_ValidFrom'


    -----------------------------------------------------------------------------------------------
    -- Set schema and table variables
    -----------------------------------------------------------------------------------------------
    SET @DimensionTableName = REPLACE(REPLACE(@DimensionTableName, N']', N''), N'[', N'')
    SET @StagingTableName = REPLACE(REPLACE(@StagingTableName, N']', N''), N'[', N'')

    IF @StagingTableName IS NULL SET @StagingTableName = N'Dimension_' + @DimensionTableName

    SET @DimensionTableName = @DimensionTableName + N'_T1'

    DECLARE @DimensionSchemaName NVARCHAR(255) = N'Dimension'
    DECLARE @StagingSchemaName NVARCHAR(255) = N'Staging'
    DECLARE @MapTableName NVARCHAR(255) = REPLACE(@StagingTableName, N'Dimension_', N'')
    DECLARE @MapSchemaName NVARCHAR(255) = N'Map'

    DECLARE @MapTableFullName NVARCHAR(500) =  QUOTENAME(@MapSchemaName) + N'.' + QUOTENAME(@MapTableName)
    DECLARE @StagingTableFullName NVARCHAR(500) = QUOTENAME(@StagingSchemaName) + N'.' + QUOTENAME(@StagingTableName)
    DECLARE @DimensionTableFullName NVARCHAR(500) =  QUOTENAME(@DimensionSchemaName) + N'.' + QUOTENAME(@DimensionTableName);


    -----------------------------------------------------------------------------------------------
    -- Set other setup variables
    -----------------------------------------------------------------------------------------------
    DECLARE @LogingIsEnabled BIT = 0
    IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'Audit' AND TABLE_NAME = 'DataTransferLog') BEGIN
        SET @LogingIsEnabled = 1
    END

    DECLARE @StagingHasHistory BIT = 0
    IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName AND COLUMN_NAME = @ValidFromColumnName) BEGIN
        SET @StagingHasHistory = 1
    END

    DECLARE @MapIsUsed BIT = 1
    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @MapSchemaName AND TABLE_NAME = @MapTableName) BEGIN
        SET @MapIsUsed = 0
    END

    DECLARE @SurrogateKeyPrefix NVARCHAR (10) = N'EKey_'


    -----------------------------------------------------------------------------------------------
    -- Test if the tables exists
    -----------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @DimensionSchemaName AND TABLE_NAME = @DimensionTableName) BEGIN
        RAISERROR(N'The staging table %s does not exists.', 16, 1, @DimensionTableFullName)
    END

    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName) BEGIN
        RAISERROR(N'The staging table %s does not exists.', 16, 1, @StagingTableFullName)
    END

    
    -----------------------------------------------------------------------------------------------
    -- Get all columns used from dimension incl. primary key, staging and map
    -----------------------------------------------------------------------------------------------
    DECLARE @AllColumns TABLE (ColumnName NVARCHAR (255), ColumnPos INT, InStaging BIT, InMap BIT, InDimension BIT, DefaultOnInsert NVARCHAR (255), DefaultOnUpdate NVARCHAR (255), DefaultOnDelete NVARCHAR(255), IsBusinessKeyColumn BIT, IsSurrogateKeyColumn BIT, IsMetaColumn BIT)

    INSERT INTO @AllColumns
    SELECT
        N'[' + ISNULL(dim.COLUMN_NAME, map.COLUMN_NAME) + N']' AS ColumnName
    ,   ISNULL(dim.ORDINAL_POSITION, map.ORDINAL_POSITION) AS ColumnPos
    ,   IIF(sta.COLUMN_NAME IS NOT NULL, 1, 0) AS InStaging
    ,   IIF(map.COLUMN_NAME IS NOT NULL, 1, 0) AS InMap
    ,   IIF(dim.COLUMN_NAME IS NOT NULL, 1, 0) AS InDimension
    ,   meta.DefaultOnInsert
    ,   meta.DefaultOnUpdate
    ,   meta.DefaultOnDelete
    ,   IIF(pk.COLUMN_NAME IS NOT NULL AND meta.ColumnName IS NULL, 1, 0) AS IsBusinessKeyColumn
    ,   IIF(LEFT(dim.COLUMN_NAME, LEN(@SurrogateKeyPrefix)) = @SurrogateKeyPrefix AND map.COLUMN_NAME IS NOT NULL, 1, 0) AS IsSurrogateKeyColumn
    ,   IIF(meta.ColumnName IS NOT NULL, 1, 0) AS IsMetaColumn
    FROM (
        SELECT COLUMN_NAME, ORDINAL_POSITION
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @DimensionSchemaName AND TABLE_NAME = @DimensionTableName
    ) dim
    FULL OUTER JOIN (
        SELECT COLUMN_NAME, ORDINAL_POSITION
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @MapSchemaName AND TABLE_NAME = @MapTableName
    ) map ON map.COLUMN_NAME = dim.COLUMN_NAME
    LEFT JOIN (
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName
    ) sta ON sta.COLUMN_NAME = ISNULL(dim.COLUMN_NAME, map.COLUMN_NAME)
    LEFT JOIN (
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName
    ) pk ON pk.COLUMN_NAME = ISNULL(dim.COLUMN_NAME, map.COLUMN_NAME)
    LEFT JOIN @MetaColumns meta ON meta.ColumnName = dim.COLUMN_NAME
    WHERE sta.COLUMN_NAME IS NOT NULL
        OR (map.COLUMN_NAME IS NOT NULL AND dim.COLUMN_NAME IS NOT NULL)
        OR meta.ColumnName IS NOT NULL
    ORDER BY dim.ORDINAL_POSITION


    -----------------------------------------------------------------------------------------------
    -- Test if everything is OK
    -----------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT TOP 1 1 FROM @AllColumns WHERE IsBusinessKeyColumn = 1) BEGIN
        RAISERROR(N'Could not find business key column(s) in staging table.', 16, 1);
        RETURN -1;
    END

    IF NOT EXISTS(SELECT TOP 1 1 FROM @AllColumns WHERE IsSurrogateKeyColumn = 1) AND @MapIsUsed = 1 BEGIN
        RAISERROR(N'Could not find surrogate key column in map table.', 16, 1);
        RETURN -1;
    END

    -----------------------------------------------------------------------------------------------
    -- Construct SQL statement
    -----------------------------------------------------------------------------------------------
    DECLARE @BusinessKeyList NVARCHAR(max) = N''
    SELECT @BusinessKeyList = @BusinessKeyList + N', s.' + ColumnName FROM @AllColumns WHERE IsBusinessKeyColumn = 1 ORDER BY ColumnPos
    SET @BusinessKeyList = SUBSTRING(@BusinessKeyList, 3, LEN(@BusinessKeyList))

    DECLARE @BusinessKeyJoin NVARCHAR(max) = N''
    SELECT @BusinessKeyJoin = @BusinessKeyJoin + N' AND ' + IIF(@MapIsUsed = 1, N'm', N'dim') + N'.' + ColumnName + N' = ' + IIF(@MapIsUsed = 1, N's.', N'sta.') + ColumnName FROM @AllColumns WHERE IsBusinessKeyColumn = 1 ORDER BY ColumnPos
    SET @BusinessKeyJoin = SUBSTRING(@BusinessKeyJoin, 6, LEN(@BusinessKeyJoin))

    DECLARE @SurrogateKeyJoin NVARCHAR(max) = N''
    SELECT @SurrogateKeyJoin = @SurrogateKeyJoin + N' AND sta.' + ColumnName + N' = dim.' + ColumnName FROM @AllColumns WHERE IsSurrogateKeyColumn = 1 ORDER BY ColumnPos
    SET @SurrogateKeyJoin = SUBSTRING(@SurrogateKeyJoin, 6, LEN(@SurrogateKeyJoin))

    DECLARE @StagingColumnList NVARCHAR(max) = N''
    SELECT @StagingColumnList = @StagingColumnList + N', ' + IIF(InStaging = 1, N's.', N'm.') + ColumnName FROM @AllColumns WHERE InDimension = 1 AND (InStaging = 1 OR InMap = 1) AND IsMetaColumn = 0 ORDER BY ColumnPos
    SET @StagingColumnList = SUBSTRING(@StagingColumnList, 3, LEN(@StagingColumnList))

    DECLARE @CompareColumnList NVARCHAR(max) = ''
    SELECT @CompareColumnList = @CompareColumnList + N' OR (sta.' + ColumnName + N' <> dim.' + ColumnName + N' OR (sta.' + ColumnName + N' IS NULL AND dim.' + ColumnName + N' IS NOT NULL) OR (sta.' + ColumnName + N' IS NOT NULL AND dim.' + ColumnName + N' IS NULL))' + @NewLine FROM @AllColumns WHERE InDimension = 1 AND InStaging = 1 AND IsMetaColumn = 0 ORDER BY ColumnPos
    SET @CompareColumnList = SUBSTRING(@CompareColumnList, 5, LEN(@CompareColumnList))

    DECLARE @UpdateColumnList NVARCHAR(max) = ''
    SELECT @UpdateColumnList = @UpdateColumnList + ', dim.' + ColumnName + ' = ' + IIF(IsMetaColumn = 1, DefaultOnUpdate, N'sta.' + ColumnName) FROM @AllColumns WHERE (InDimension = 1 AND InStaging = 1 AND IsMetaColumn = 0) OR (IsMetaColumn = 1 AND DefaultOnUpdate IS NOT NULL) ORDER BY ColumnPos
    SET @UpdateColumnList = SUBSTRING(@UpdateColumnList, 3, LEN(@UpdateColumnList))

    DECLARE @InsertColumnList NVARCHAR(max) = N''
    DECLARE @InsertValueList NVARCHAR(max) = N''
    SELECT
        @InsertColumnList = @InsertColumnList + N', ' + ColumnName,
        @InsertValueList = @InsertValueList + N', ' + IIF(IsMetaColumn = 1, DefaultOnInsert, N'sta.' + ColumnName)
    FROM @AllColumns WHERE (InDimension = 1 AND (InStaging = 1 OR InMap = 1) AND IsMetaColumn = 0) OR (IsMetaColumn = 1 AND DefaultOnInsert IS NOT NULL) ORDER BY ColumnPos
    SET @InsertColumnList = SUBSTRING(@InsertColumnList, 3, LEN(@InsertColumnList))
    SET @InsertValueList = SUBSTRING(@InsertValueList, 3, LEN(@InsertValueList))
    
    DECLARE @DeleteColumnList NVARCHAR(max) = N''
    SELECT @DeleteColumnList = @DeleteColumnList + N', map.' + ColumnName + ' = ' + IIF(IsMetaColumn = 1, DefaultOnDelete, N'sta.' + ColumnName) FROM @AllColumns WHERE IsMetaColumn = 1 AND DefaultOnDelete IS NOT NULL ORDER BY ColumnPos
    SET @DeleteColumnList = SUBSTRING(@DeleteColumnList, 3, LEN(@DeleteColumnList))

    DECLARE @SQL NVARCHAR(max) = N''

    IF @LogingIsEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
    /*** Start log ***/
    DECLARE @DataTransferId BIGINT = -1;
    EXECUTE [Audit].[DataTransferStart] @SchemaName = ''<DimensionSchemaName>'',
                                        @TableName = ''<DimensionTableName>'',
                                        @DataTransferId = @DataTransferId OUTPUT,
                                        @ExecutionId = @ExecutionId,
                                        @Source = ''<StagingSchemaName>.<StagingTableName>'',
                                        @StoredProcedureName = ''UpdateDimensionT1'',
                                        @StoredProcedureVersion = ''1.0'',
                                        @TableTruncated = @TruncateDimension;
    '
    END
    ELSE BEGIN
        SET @SQL = @SQL + N'
    DECLARE @DataTransferId BIGINT = @ExecutionId;
    '
    END

    SET @SQL = @SQL + N'
    BEGIN TRY
        /*** Start transaction - join if there is an existing one ***/
        DECLARE @TranCounter INT = @@TRANCOUNT;
        DECLARE @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N''_'' + CAST(@@NESTLEVEL AS NVARCHAR(2));

        IF @TranCounter > 0
            SAVE TRANSACTION @SavePoint;
        ELSE
            BEGIN TRANSACTION;

			/*** Truncate dimension ***/
			IF @TruncateDimension = 1 BEGIN
			    TRUNCATE TABLE <DimensionTableFullName>
			
			/*** Insert data if we truncated the dimension ***/
			INSERT into <DimensionTableFullName> (<InsertColumnList>)
				SELECT <InsertValueList> 
				FROM (SELECT <StagingColumnList>
					FROM <StagingTableFullName> s
					INNER JOIN <MapTableFullName> m ON <BusinessKeyJoin>) sta
        END

		ELSE
		BEGIN
    
			/*** Merge dimension statement if we do not truncate the dimension table (@TruncateDimension = 0) ***/
			DECLARE @Actions TABLE (act NVARCHAR (10));

			MERGE <DimensionTableFullName> WITH (TABLOCKX) dim
			USING ('

    IF @MapIsUsed = 1 BEGIN
        SET @SQL = @SQL + N'
            SELECT ' + IIF(@StagingHasHistory = 1, 'TOP 1 WITH TIES ', '') + '<StagingColumnList>
            FROM <StagingTableFullName> s
            INNER JOIN <MapTableFullName> m ON <BusinessKeyJoin>
            ' + IIF(@StagingHasHistory = 1, 'ORDER BY ROW_NUMBER() OVER (PARTITION BY <BusinessKeyList> ORDER BY <ValidFromColumnName> DESC)', '') + '
        ) sta ON <SurrogateKeyJoin>
        '
    END
    ELSE BEGIN
        SET @SQL = @SQL + N'
            SELECT ' + IIF(@StagingHasHistory = 1, 'TOP 1 WITH TIES ', '') + '<StagingColumnList>
            FROM <StagingTableFullName> s
            ' + IIF(@StagingHasHistory = 1, 'ORDER BY ROW_NUMBER() OVER (PARTITION BY <BusinessKeyList> ORDER BY <ValidFromColumnName> DESC)', '') + '
        ) sta ON <BusinessKeyJoin>
        '
    END

    SET @SQL = @SQL + N'
        WHEN MATCHED AND (<CompareColumnList>)
            THEN UPDATE
            SET <UpdateColumnList>

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

		/*** End of IF ELSE statement (truncate dimension table) ***/
	END
        
        /*** Commit transaction (if started here) ***/
		IF @TranCounter = 0 BEGIN
			COMMIT TRANSACTION;
        END
    '

	IF @LogingIsEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
        /*** End log - Succeeded ***/
        DECLARE @RecordsSelected INT = 0, @RecordsInserted INT = 0, @RecordsDeleted INT = 0;'
	END

	/*** Counts for updated loads ***/
	IF @LogingIsEnabled = 1 and @TruncateDimension <> 1 BEGIN
		SET @SQL = @SQL + N'
        SELECT @RecordsSelected = COUNT(*) FROM <StagingTableFullName>;
        SELECT @RecordsInserted = COUNT(*) FROM @Actions WHERE act = ''INSERT'';
        SELECT @RecordsDeleted = COUNT(*) FROM @Actions WHERE act = ''UPDATE'';'
	END
	
	/*** Counts for truncate reloads ***/
	IF @LogingIsEnabled = 1 and @TruncateDimension = 1 BEGIN
		SET @SQL = @SQL + N'
        SELECT @RecordsSelected = COUNT(*) FROM <StagingTableFullName>;
        SELECT @RecordsInserted = COUNT(*) FROM <DimensionTableFullName>;
        SET @RecordsDeleted = 0;'
	END
	
	IF @LogingIsEnabled = 1 BEGIN
		SET @SQL = @SQL + N'
		EXECUTE [Audit].[DataTransferEnd] @DataTransferId = @DataTransferId,
                                          @RecordsSelected = @RecordsSelected,
                                          @RecordsInserted = @RecordsInserted,
                                          @RecordsDeleted = @RecordsDeleted;
    '
    END



	SET @SQL = @SQL + N'
	END TRY
	BEGIN CATCH
        /*** Rollback if transaction was started here OR rollback to @SavePoint if transaction OK ***/
        IF @TranCounter = 0
	        ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
	        ROLLBACK TRANSACTION @SavePoint;
    '

    IF @LogingIsEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
        /*** End log - Failed ***/
        EXECUTE [Audit].[DataTransferEnd] @DataTransferId = @DataTransferId,
                                          @Status = N''Failed'';
        '
    END




    SET @SQL = @SQL + N'
        THROW;
	END CATCH
    '

    SET @SQL = REPLACE(@SQL, N'<DimensionSchemaName>', @DimensionSchemaName);
	SET @SQL = REPLACE(@SQL, N'<DimensionTableName>', @DimensionTableName);
    SET @SQL = REPLACE(@SQL, N'<StagingSchemaName>', @StagingSchemaName);
    SET @SQL = REPLACE(@SQL, N'<StagingTableName>', @StagingTableName);
    SET @SQL = REPLACE(@SQL, N'<StagingTableFullName>', @StagingTableFullName);
    SET @SQL = REPLACE(@SQL, N'<MapTableFullName>', @MapTableFullName);
    SET @SQL = REPLACE(@SQL, N'<DimensionTableFullName>', @DimensionTableFullName);
    SET @SQL = REPLACE(@SQL, N'<ValidFromColumnName>', @ValidFromColumnName);
    SET @SQL = REPLACE(@SQL, N'<BusinessKeyList>', @BusinessKeyList);
    SET @SQL = REPLACE(@SQL, N'<BusinessKeyJoin>', @BusinessKeyJoin);
    SET @SQL = REPLACE(@SQL, N'<SurrogateKeyJoin>', @SurrogateKeyJoin);
    SET @SQL = REPLACE(@SQL, N'<StagingColumnList>', @StagingColumnList);
    SET @SQL = REPLACE(@SQL, N'<CompareColumnList>', @CompareColumnList);
    SET @SQL = REPLACE(@SQL, N'<UpdateColumnList>', @UpdateColumnList);
    SET @SQL = REPLACE(@SQL, N'<InsertColumnList>', @InsertColumnList);
    SET @SQL = REPLACE(@SQL, N'<InsertValueList>', @InsertValueList);
    SET @SQL = REPLACE(@SQL, N'<DeleteColumnList>', @DeleteColumnList);


    -----------------------------------------------------------------------------------------------
    -- Execute or print SQL statement
    -----------------------------------------------------------------------------------------------
    IF @PrintOnly = 1 BEGIN
        SET @SQL = N'
    DECLARE @ExecutionId BIGINT = -1
    DECLARE @TruncateDimension BIT = 0
    ' + @SQL

        EXEC Utility.PrintLargeString @SQL

        SELECT * FROM @AllColumns ORDER BY ColumnPos
    END
    ELSE BEGIN
        EXECUTE sp_executesql @SQL, N'@ExecutionId BIGINT, @TruncateDimension BIT', @ExecutionId, @TruncateDimension
    END

END
GO