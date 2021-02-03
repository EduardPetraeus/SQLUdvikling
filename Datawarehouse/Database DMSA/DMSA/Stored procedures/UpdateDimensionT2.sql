CREATE PROCEDURE [DMSA].[UpdateDimensionT2]
    @DimensionTableName NVARCHAR (255),
    @StagingTableName NVARCHAR(255) = NULL,
    @ExecutionId BIGINT = -1,
    --@DMSA BIGINT = -1,
    @TruncateDimension BIT = 0, -- If 1 truncate dimension table before load, otherwise do nothing
    @MarkDeletes BIT = 0, -- If 1 then 'WHEN NOT MATCHED BY SOURCE' will be added to merge
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON 
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    -----------------------------------------------------------------------------------------------
    -- Set meta column names and default (NULL will be interpreted as not used)
    -----------------------------------------------------------------------------------------------
    DECLARE @MetaColumns TABLE (ColumnName NVARCHAR(255), DefaultOnInsert NVARCHAR(255), DefaultOnUpdate NVARCHAR(255), DefaultOnNewVersion NVARCHAR(255), DefaultOnDelete NVARCHAR(255))

    INSERT INTO @MetaColumns
    VALUES (N'Meta_CreateJob', N'@DMSAId', NULL, N'@DMSAId', NULL)
          ,(N'Meta_CreateTime', N'GETDATE()', NULL, N'GETDATE()', NULL)
          ,(N'Meta_UpdateJob', NULL, N'@DMSAId', NULL, NULL)
          ,(N'Meta_UpdateTime', NULL, N'GETDATE()', NULL, NULL)
          ,(N'Meta_DeleteJob', NULL, NULL, NULL, N'@DMSAId')
          ,(N'Meta_DeleteTime', NULL, NULL, NULL, N'GETDATE()')
          ,(N'Meta_IsDeleted', N'0', NULL, N'0', N'1')
          ,(N'Meta_IsInferred', N'0', NULL, N'0', NULL)
          ,(N'Meta_IsCurrent', N'1', N'0', N'1', NULL)
          ,(N'Meta_ValidFrom', N'@DateBOU', NULL, N'sta.Meta_ValidFrom', NULL)
          ,(N'Meta_ValidTo', N'@DateEOU', N'sta.Meta_ValidFrom', N'@DateEOU', NULL)
          ,(N'Meta_Id',      NULL, NULL, NULL, NULL)

    DECLARE @IdColumnName NVARCHAR (100) = N'Meta_Id'
    DECLARE @ValidFromColumnName NVARCHAR (100) = N'Meta_ValidFrom'
    DECLARE @ValidToColumnName NVARCHAR (100) = N'Meta_ValidTo'


    -----------------------------------------------------------------------------------------------
    -- Set schema and table variables
    -----------------------------------------------------------------------------------------------
    SET @DimensionTableName = REPLACE(REPLACE(@DimensionTableName, N']', N''), N'[', N'')
    SET @StagingTableName = REPLACE(REPLACE(@StagingTableName, N']', N''), N'[', N'')

    IF @StagingTableName IS NULL SET @StagingTableName = N'Dimension_' + @DimensionTableName

    SET @DimensionTableName = @DimensionTableName + N'_T2'

    DECLARE @DimensionSchemaName NVARCHAR(255) = N'DMSA'
    DECLARE @StagingSchemaName NVARCHAR(255) = N'Staging'
    DECLARE @MapTableName NVARCHAR(255) = REPLACE(@StagingTableName, N'Dimension_', N'')
    DECLARE @MapSchemaName NVARCHAR(255) = N'Map'
    --DECLARE @DimensionDatabase NVARCHAR(255) = N'DMSA'
	--DECLARE @StagingDatabase NVARCHAR(255) = N'Staging'

    --DECLARE @MapTableFullName NVARCHAR(500) = QUOTENAME(@StagingDatabase) + N'.' + QUOTENAME(@MapSchemaName) + N'.' + QUOTENAME(@MapTableName)
    --DECLARE @StagingTableFullName NVARCHAR(500) = QUOTENAME(@StagingDatabase) + N'.' + QUOTENAME(@StagingSchemaName) + N'.' + QUOTENAME(@StagingTableName)
    --DECLARE @DimensionTableFullName NVARCHAR(500) = QUOTENAME(@DimensionDatabase) + N'.' + QUOTENAME(@DimensionSchemaName) + N'.' + QUOTENAME(@DimensionTableName);
    
    DECLARE @MapTableFullName NVARCHAR(500) =  QUOTENAME(@MapSchemaName) + N'.' + QUOTENAME(@MapTableName)
    DECLARE @StagingTableFullName NVARCHAR(500) = QUOTENAME(@StagingSchemaName) + N'.' + QUOTENAME(@StagingTableName)
    DECLARE @DimensionTableFullName NVARCHAR(500) =  QUOTENAME(@DimensionSchemaName) + N'.' + QUOTENAME(@DimensionTableName);
    DECLARE @VersionTableFullName NVARCHAR(500) = @StagingSchemaName + N'_' + @StagingTableName;
    DECLARE @ActionTableFullName NVARCHAR(500) =  N'Actions_' + @StagingSchemaName + N'_' + @StagingTableName;


    -----------------------------------------------------------------------------------------------
    -- Set other setup variables
    -----------------------------------------------------------------------------------------------
    DECLARE @LogingIsEnabled BIT = 0
    IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'Audit' AND TABLE_NAME = 'DMSALog') BEGIN
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
    DECLARE @AllColumns TABLE (ColumnName NVARCHAR (255), ColumnPos INT, InStaging BIT, InMap BIT, InDimension BIT, DefaultOnInsert NVARCHAR (255), DefaultOnUpdate NVARCHAR (255), DefaultOnNewVersion NVARCHAR (255), DefaultOnDelete NVARCHAR(255), IsBusinessKeyColumn BIT, IsSurrogateKeyColumn BIT, IsMetaColumn BIT)

    INSERT INTO @AllColumns
    SELECT
        N'[' + ISNULL(dim.COLUMN_NAME, map.COLUMN_NAME) + N']' AS ColumnName
    ,   ISNULL(dim.ORDINAL_POSITION, map.ORDINAL_POSITION) AS ColumnPos
    ,   IIF(sta.COLUMN_NAME IS NOT NULL, 1, 0) AS InStaging
    ,   IIF(map.COLUMN_NAME IS NOT NULL, 1, 0) AS InMap
    ,   IIF(dim.COLUMN_NAME IS NOT NULL, 1, 0) AS InDimension
    ,   meta.DefaultOnInsert
    ,   meta.DefaultOnUpdate
    ,   meta.DefaultOnNewVersion
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

    DECLARE @MapMergeJoin NVARCHAR(max) = N''
    DECLARE @MapInsertJoin NVARCHAR(max) = N''
    SELECT
        @MapMergeJoin = @MapMergeJoin + N' AND m.' + ColumnName + N' = s.' + ColumnName,
        @MapInsertJoin = @MapInsertJoin + N' AND map.' + ColumnName + N' = sta.' + ColumnName
    FROM @AllColumns WHERE IsBusinessKeyColumn = 1 ORDER BY ColumnPos
    SET @MapMergeJoin = SUBSTRING(@MapMergeJoin, 6, LEN(@MapMergeJoin))
    SET @MapInsertJoin = SUBSTRING(@MapInsertJoin, 6, LEN(@MapInsertJoin))

    DECLARE @DimensionJoin NVARCHAR(max) = N''
    IF EXISTS(SELECT TOP 1 1 FROM @AllColumns WHERE InDimension = 1 AND IsSurrogateKeyColumn = 1) BEGIN
        SELECT @DimensionJoin = @DimensionJoin + N' AND sta.' + ColumnName + N' = dim.' + ColumnName FROM @AllColumns WHERE IsSurrogateKeyColumn = 1 ORDER BY ColumnPos
    END
    ELSE BEGIN
        SELECT @DimensionJoin = @DimensionJoin + N' AND sta.' + ColumnName + N' = dim.' + ColumnName FROM @AllColumns WHERE IsBusinessKeyColumn = 1 ORDER BY ColumnPos
    END
    SET @DimensionJoin = SUBSTRING(@DimensionJoin, 6, LEN(@DimensionJoin))

    DECLARE @TempColumnList NVARCHAR(max) = N''
    SELECT @TempColumnList = @TempColumnList + N', ' + IIF(InStaging = 1, N's.', N'm.') + ColumnName FROM @AllColumns WHERE InDimension = 1 AND InStaging = 0 AND InMap = 1 AND IsMetaColumn = 0 ORDER BY ColumnPos
    --SET @TempColumnList = SUBSTRING(@TempColumnList, 3, LEN(@TempColumnList))

    DECLARE @StagingColumnList NVARCHAR(max) = N''
    SELECT @StagingColumnList = @StagingColumnList + N', ' + IIF(InStaging = 1, N's.', N'm.') + ColumnName FROM @AllColumns WHERE InDimension = 1 AND (InStaging = 1 OR InMap = 1) AND IsMetaColumn = 0 ORDER BY ColumnPos
	--SET @StagingColumnList = SUBSTRING(@StagingColumnList, 3, LEN(@StagingColumnList))

    DECLARE @CompareColumnList NVARCHAR(max) = ''
    SELECT @CompareColumnList = @CompareColumnList + N' OR (sta.' + ColumnName + N' <> dim.' + ColumnName + N' OR (sta.' + ColumnName + N' IS NULL AND dim.' + ColumnName + N' IS NOT NULL) OR (sta.' + ColumnName + N' IS NOT NULL AND dim.' + ColumnName + N' IS NULL))' + @NewLine FROM @AllColumns WHERE InDimension = 1 AND InStaging = 1 AND IsMetaColumn = 0 ORDER BY ColumnPos
    SET @CompareColumnList = SUBSTRING(@CompareColumnList, 5, LEN(@CompareColumnList))

    DECLARE @InsertColumnList NVARCHAR(max) = N''
    DECLARE @InsertValueList NVARCHAR(max) = N''
    SELECT
        @InsertColumnList = @InsertColumnList + N', ' + ColumnName,
        @InsertValueList = @InsertValueList + N', ' + IIF(IsMetaColumn = 1, DefaultOnInsert, N'sta.' + ColumnName)
    FROM @AllColumns WHERE (InDimension = 1 AND (InStaging = 1 OR InMap = 1) AND IsMetaColumn = 0) OR (IsMetaColumn = 1 AND DefaultOnInsert IS NOT NULL) ORDER BY ColumnPos
    SET @InsertColumnList = SUBSTRING(@InsertColumnList, 3, LEN(@InsertColumnList))
    SET @InsertValueList = SUBSTRING(@InsertValueList, 3, LEN(@InsertValueList))

    DECLARE @NewVersionColumnList NVARCHAR(max) = N''
    DECLARE @NewVersionSelectList NVARCHAR(max) = N''
    SELECT
        @NewVersionColumnList = @NewVersionColumnList + N', ' + ColumnName,
        @NewVersionSelectList = @NewVersionSelectList + N', ' + IIF(IsMetaColumn = 1, DefaultOnNewVersion, IIF(InStaging = 1, N'sta.', N'map.') + ColumnName)
    FROM @AllColumns WHERE (InDimension = 1 AND (InStaging = 1 OR InMap = 1) AND IsMetaColumn = 0) OR (IsMetaColumn = 1 AND DefaultOnNewVersion IS NOT NULL) ORDER BY ColumnPos
    SET @NewVersionColumnList = SUBSTRING(@NewVersionColumnList, 3, LEN(@NewVersionColumnList))
    SET @NewVersionSelectList = SUBSTRING(@NewVersionSelectList, 3, LEN(@NewVersionSelectList))
    
    DECLARE @DeleteColumnList NVARCHAR(max) = N''
    SELECT @DeleteColumnList = @DeleteColumnList + N', dim.' + ColumnName + ' = ' + IIF(IsMetaColumn = 1, DefaultOnDelete, N'sta.' + ColumnName) FROM @AllColumns WHERE IsMetaColumn = 1 AND DefaultOnDelete IS NOT NULL ORDER BY ColumnPos
    SET @DeleteColumnList = SUBSTRING(@DeleteColumnList, 3, LEN(@DeleteColumnList))

    DECLARE @SQL NVARCHAR(max) = N''

    IF @LogingIsEnabled = 0 BEGIN
        SET @SQL = @SQL + N'
    /*** Start log ***/
    DECLARE @DMSAId BIGINT = -1;
    DECLARE @Database NVARCHAR(30) = ''DMSA'';
    DECLARE @Schema   NVARCHAR(30) = ''DMSA'';
    EXECUTE [DZDB].[Audit].[DMSAStart]  @Database  = @Database,
                                        @TableName = ''<DimensionTableName>'',
                                        @Schema = @Schema,
                                        @DMSAId = @DMSAId OUTPUT,
                                        @ExecutionId = @ExecutionId;
                        

    '
    END
    ELSE BEGIN
        SET @SQL = @SQL + N'
    DECLARE @DMSAId BIGINT = -1;
    '
    END

    SET @SQL = @SQL + N'
    /*** Get Begin- and EndOfUniverse dates ***/
    DECLARE @DateEOU DATE = ''9999-12-31''
    --SELECT @DateEOU = CAST(Value AS DATE) FROM Utility.FixedValues WHERE [Key] = ''DateEOU''

    DECLARE @DateBOU DATE = ''1800-01-01''
    --SELECT @DateBOU = CAST(Value AS DATE) FROM Utility.FixedValues WHERE [Key] = ''DateBOU''


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
		
		/*** Insert data ***/
			INSERT INTO <DimensionTableFullName>  (<InsertColumnList>)
            	SELECT <NewVersionSelectList> 
				FROM <StagingTableFullName> sta
            	INNER JOIN <MapTableFullName> map ON <MapInsertJoin> ;
        END
		
		ELSE
		BEGIN
    
		/*** Merge dimension statement when we do not truncate the dimension table (@TruncateDimension = 0) ***/
        /*** Split staging table into different versions ***/
        IF OBJECT_ID(''tempdb..#<VersionTableFullName>'') IS NOT NULL DROP TABLE #<VersionTableFullName>

			SELECT Meta_Id, ROW_NUMBER () OVER (PARTITION BY <BusinessKeyList> ORDER BY <ValidFromColumnName> ASC) AS Meta_RowNumber
			INTO #<VersionTableFullName>
			FROM <StagingTableFullName> s

        CREATE INDEX IDX_<VersionTableFullName>_Join ON #<VersionTableFullName> (Meta_Id ASC)
        CREATE INDEX IDX_<VersionTableFullName>_RowNumber ON #<VersionTableFullName> (Meta_RowNumber ASC, Meta_Id ASC)

        /*** Merge dimension table, one version at a time ***/
        IF OBJECT_ID(''tempdb..#<ActionTableFullName>'') IS NOT NULL DROP TABLE #<ActionTableFullName>
        CREATE TABLE #<ActionTableFullName> (Meta_Id BIGINT PRIMARY KEY, Meta_RowNumber INT, Meta_Action NVARCHAR(10));

        DECLARE @RowNumber INT = 1
        DECLARE @RowCount INT = 1
        
        WHILE (@RowCount > 0) BEGIN

            MERGE <DimensionTableFullName> WITH (TABLOCKX) dim
            USING (
                SELECT s.Meta_Id, s.<ValidFromColumnName><StagingColumnList>
                FROM <StagingTableFullName> s
                INNER JOIN <MapTableFullName> m ON <MapMergeJoin>
                INNER JOIN #<VersionTableFullName> x ON x.Meta_Id = s.Meta_Id AND x.Meta_RowNumber = @RowNumber
            ) sta ON <DimensionJoin>

            WHEN MATCHED AND dim.[Meta_IsCurrent] = 1 AND (<CompareColumnList>)
                THEN UPDATE
                SET dim.[Meta_ValidTo] = sta.Meta_ValidFrom, dim.[Meta_IsCurrent] = 0, dim.[Meta_UpdateTime] = GETDATE(), dim.[Meta_UpdateJob] = @DMSAId

            WHEN NOT MATCHED BY TARGET
                THEN INSERT (<InsertColumnList>)
                VALUES (<InsertValueList>)
    
            OUTPUT sta.Meta_Id, @RowNumber, $action INTO #<ActionTableFullName>;

            INSERT <DimensionTableFullName> WITH (TABLOCKX) (<NewVersionColumnList>)
            SELECT <NewVersionSelectList>
            FROM <StagingTableFullName> sta
            INNER JOIN <MapTableFullName> map ON <MapInsertJoin>
            INNER JOIN #<ActionTableFullName> act ON act.Meta_Id = sta.Meta_Id AND act.Meta_RowNumber = @RowNumber
            WHERE act.Meta_Action = ''UPDATE''

            SET @RowNumber = @RowNumber + 1
            SELECT @RowCount = COUNT(*) FROM #<VersionTableFullName> WHERE Meta_RowNumber = @RowNumber

        END

        /*** Mark missing rows as deleted ***/
        IF @MarkDeletes = 1 BEGIN
            UPDATE dim WITH (TABLOCKX)
            SET <DeleteColumnList>
            FROM <DimensionTableFullName> dim
            LEFT JOIN (
                SELECT TOP 1 WITH TIES s.Meta_Id<StagingColumnList>
                FROM <StagingTableFullName> s
                INNER JOIN <MapTableFullName> m ON <MapMergeJoin>
                ORDER BY ROW_NUMBER () OVER (PARTITION BY <BusinessKeyList> ORDER BY <ValidFromColumnName> ASC)
            ) sta ON <DimensionJoin>
            WHERE dim.<ValidFromColumnName> = @DateEOU AND sta.Meta_Id IS NULL
        END


		/*** End of IF ELSE statement (truncate dimension table) ***/
	END

        /*** Commit transaction (if started here) ***/
		IF @TranCounter = 0 BEGIN
			COMMIT TRANSACTION;
        END
    '


	IF @LogingIsEnabled = 0 BEGIN
        SET @SQL = @SQL + N'
        /*** End log - Succeeded ***/
        DECLARE @RecordsSelected INT = 0, @RecordsInserted INT = 0, @RecordsUpdated INT = 0, @RecordsDeleted INT = 0;'
	END

	IF @LogingIsEnabled = 0 and @TruncateDimension <> 1 BEGIN
		SET @SQL = @SQL + N'
        SELECT @RecordsSelected = COUNT(*) FROM <StagingTableFullName>;
        SELECT @RecordsInserted = COUNT(*) FROM #<ActionTableFullName> WHERE Meta_Action = ''INSERT'';
        SELECT @RecordsUpdated = COUNT(*) FROM #<ActionTableFullName> WHERE Meta_Action = ''UPDATE'';
        SELECT @RecordsDeleted = COUNT(*) FROM #<ActionTableFullName> WHERE Meta_Action = ''DELETE'';
        
        
        
        UPDATE [DZDB].[Audit].[DMSALog]
        SET [Status] = ''Succeeded'',
            [EndTime] = GETDATE(),
            [IsFullLoad] = 1,
            [RecordsSelected] = @RecordsSelected,
            [RecordsInserted] = @RecordsInserted,
            [RecordsUpdated] =  @RecordsUpdated,
            [RecordsFailed] = 0,
            [RecordsDiscarded] = @RecordsSelected - @RecordsInserted - @RecordsUpdated
        WHERE [Id] = @DMSAId
        
        '

        
	END


	IF @LogingIsEnabled = 0 and @TruncateDimension = 1 BEGIN
		SET @SQL = @SQL + N'
		SELECT @RecordsSelected = COUNT(*) FROM <StagingTableFullName>;
        SELECT @RecordsInserted = COUNT(*) FROM <DimensionTableFullName>;
        SET @RecordsUpdated = 0;
        --SET @RecordsDeleted = 0;
        
        UPDATE [DZDB].[Audit].[DMSALog]
        SET [Status] = ''Succeeded'',
            [EndTime] = GETDATE(),
            [IsFullLoad] = 0,
            [RecordsSelected] = @RecordsSelected,
            [RecordsInserted] = @RecordsInserted,
            [RecordsUpdated] =  @RecordsUpdated,
            [RecordsFailed] = 0,
            [RecordsDiscarded] = 0
        WHERE [Id] = @DMSAId
        '
	END
	

	IF @LogingIsEnabled = 1 BEGIN
		SET @SQL = @SQL + N'
		EXECUTE [DZDB].[Audit].[DMSAEnd] @DMSAId = @DMSAId,
                                          @RecordsSelected = @RecordsSelected,
                                          @RecordsInserted = @RecordsInserted,
										  @RecordsUpdated = @RecordsUpdated;
                                          --@RecordsDeleted = @RecordsDeleted;
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

    IF @LogingIsEnabled = 0 BEGIN
        SET @SQL = @SQL + N'
        /*** End log - Failed ***/
        EXECUTE [DZDB].[Audit].[DMSAEnd] @DMSAId = @DMSAId,
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
    SET @SQL = REPLACE(@SQL, N'<VersionTableFullName>', @VersionTableFullName);
    SET @SQL = REPLACE(@SQL, N'<ActionTableFullName>', @ActionTableFullName);
    SET @SQL = REPLACE(@SQL, N'<IdColumnName>', @IdColumnName);
    SET @SQL = REPLACE(@SQL, N'<ValidFromColumnName>', @ValidFromColumnName);
    SET @SQL = REPLACE(@SQL, N'<BusinessKeyList>', @BusinessKeyList);
    SET @SQL = REPLACE(@SQL, N'<MapMergeJoin>', @MapMergeJoin);
    SET @SQL = REPLACE(@SQL, N'<MapInsertJoin>', @MapInsertJoin);
    SET @SQL = REPLACE(@SQL, N'<DimensionJoin>', @DimensionJoin);
    SET @SQL = REPLACE(@SQL, N'<TempColumnList>', @TempColumnList);
    SET @SQL = REPLACE(@SQL, N'<StagingColumnList>', @StagingColumnList);
    SET @SQL = REPLACE(@SQL, N'<CompareColumnList>', @CompareColumnList);
    SET @SQL = REPLACE(@SQL, N'<InsertColumnList>', @InsertColumnList);
    SET @SQL = REPLACE(@SQL, N'<InsertValueList>', @InsertValueList);
    SET @SQL = REPLACE(@SQL, N'<NewVersionColumnList>', @NewVersionColumnList);
    SET @SQL = REPLACE(@SQL, N'<NewVersionSelectList>', @NewVersionSelectList);
    SET @SQL = REPLACE(@SQL, N'<DeleteColumnList>', @DeleteColumnList);


    -----------------------------------------------------------------------------------------------
    -- Execute or print SQL statement
    -----------------------------------------------------------------------------------------------
    IF @PrintOnly = 1 BEGIN
        SET @SQL = N'
    DECLARE @ExecutionId BIGINT = -1
    DECLARE @TruncateDimension BIT = 0
    DECLARE @MarkDeletes BIT = 0
    ' + @SQL

        EXEC Utility.PrintLargeString @SQL

        SELECT * FROM @AllColumns ORDER BY ColumnPos
    END
    ELSE BEGIN
        EXECUTE sp_executesql @SQL, N'@ExecutionId BIGINT, @TruncateDimension BIT, @MarkDeletes BIT', @ExecutionId, @TruncateDimension, @MarkDeletes
    END

END
GO