CREATE PROCEDURE [Fact].[SwitchFact]
    @FactTableName NVARCHAR (255),
    @StagingTableName NVARCHAR(255) = NULL,
    @ExecutionId BIGINT = -1,
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @NewLine NVARCHAR(2) = CHAR(13)


    -----------------------------------------------------------------------------------------------
    -- Set schema and table variables
    -----------------------------------------------------------------------------------------------
    SET @FactTableName = REPLACE(REPLACE(@FactTableName, N']', N''), N'[', N'')
    SET @StagingTableName = REPLACE(REPLACE(@StagingTableName, N']', N''), N'[', N'')

    IF @StagingTableName IS NULL SET @StagingTableName = N'Fact_' + @FactTableName

    DECLARE @FactSchemaName NVARCHAR(255) = N'Fact'
    DECLARE @StagingSchemaName NVARCHAR(255) = N'Staging'

    DECLARE @StagingTableFullName NVARCHAR(500) = QUOTENAME(@StagingSchemaName) + N'.' + QUOTENAME(@StagingTableName)
    DECLARE @FactTableFullName NVARCHAR(500) =  QUOTENAME(@FactSchemaName) + N'.' + QUOTENAME(@FactTableName);


    -----------------------------------------------------------------------------------------------
    -- Set other setup variables
    -----------------------------------------------------------------------------------------------
    DECLARE @LogingIsEnabled BIT = 0
    IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'Audit' AND TABLE_NAME = 'DataTransferLog') BEGIN
        SET @LogingIsEnabled = 1
    END


    -----------------------------------------------------------------------------------------------
    -- Test if the tables exists
    -----------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @FactSchemaName AND TABLE_NAME = @FactTableName) BEGIN
        RAISERROR(N'The fact table %s does not exists.', 16, 1, @FactTableFullName)
    END

    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName) BEGIN
        RAISERROR(N'The staging table %s does not exists.', 16, 1, @StagingTableFullName)
    END

    
    -----------------------------------------------------------------------------------------------
    -- Construct SQL statement
    -----------------------------------------------------------------------------------------------
    DECLARE @SQL NVARCHAR(max) = N''

    IF @LogingIsEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
    /*** Start log ***/
    DECLARE @DataTransferId BIGINT = -1;
    EXECUTE [Audit].[DataTransferStart] @SchemaName = ''<FactSchemaName>'',
                                        @TableName = ''<FactTableName>'',
                                        @DataTransferId = @DataTransferId OUTPUT,
                                        @ExecutionId = @ExecutionId,
                                        @Source = ''<StagingSchemaName>.<StagingTableName>'',
                                        @StoredProcedureName = ''SwitchFact'',
                                        @StoredProcedureVersion = ''1.0'',
                                        @TableTruncated = 1;
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

        /*** Switch tables ***/
        TRUNCATE TABLE <FactTableFullName>;
        ALTER TABLE <StagingTableFullName>
            SWITCH TO <FactTableFullName>;
        
        /*** Commit transaction (if started here) ***/
		IF @TranCounter = 0 BEGIN
			COMMIT TRANSACTION;
        END
    '

    IF @LogingIsEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
        /*** End log - Succeeded ***/
        DECLARE @RecordsSelected INT = 0, @RecordsInserted INT = 0;
        SELECT @RecordsSelected = COUNT(*), @RecordsInserted = COUNT(*) FROM <StagingTableFullName>;

        EXECUTE [Audit].[DataTransferEnd] @DataTransferId = @DataTransferId,
                                          @RecordsSelected = @RecordsSelected,
                                          @RecordsInserted = @RecordsInserted;
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

    SET @SQL = REPLACE(@SQL, N'<FactSchemaName>', @FactSchemaName);
	SET @SQL = REPLACE(@SQL, N'<FactTableName>', @FactTableName);
    SET @SQL = REPLACE(@SQL, N'<StagingSchemaName>', @StagingSchemaName);
    SET @SQL = REPLACE(@SQL, N'<StagingTableName>', @StagingTableName);
    SET @SQL = REPLACE(@SQL, N'<StagingTableFullName>', @StagingTableFullName);
    SET @SQL = REPLACE(@SQL, N'<FactTableFullName>', @FactTableFullName);


    -----------------------------------------------------------------------------------------------
    -- Execute or print SQL statement
    -----------------------------------------------------------------------------------------------
    IF @PrintOnly = 1 BEGIN
        SET @SQL = N'
    DECLARE @ExecutionId BIGINT = -1
    ' + @SQL

        EXEC Utility.PrintLargeString @SQL
    END
    ELSE BEGIN
        EXECUTE sp_executesql @SQL, N'@ExecutionId BIGINT', @ExecutionId
    END

END