CREATE PROCEDURE [DMSA].[SwitchPartition]
-- Denne stored procedure kan bruges på alle tabeller, selvom parametre og variabler hedder noget med Fact.
-- Det kræver dog at tabellerne, som bruges til at stage data og udstille data er fuldstændig ens.
    @FactTableName NVARCHAR (255) = NULL,
    @StagingTableName NVARCHAR(255) = NULL,
    @Database NVARCHAR(50) = NULL,
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

    DECLARE @FactSchemaName NVARCHAR(255) = N'DMSA'
    DECLARE @StagingSchemaName NVARCHAR(255) = N'Load'

    DECLARE @StagingTableFullName NVARCHAR(500) = QUOTENAME(@StagingSchemaName) + N'.' + QUOTENAME(@StagingTableName)
    DECLARE @FactTableFullName NVARCHAR(500) =  QUOTENAME(@FactSchemaName) + N'.' + QUOTENAME(@FactTableName);


    -----------------------------------------------------------------------------------------------
    -- Set other setup variables
    -----------------------------------------------------------------------------------------------
    DECLARE @LogingIsEnabled BIT = 0
    IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'Audit' AND TABLE_NAME = 'DMSALog') BEGIN
        SET @LogingIsEnabled = 1
    END


    -----------------------------------------------------------------------------------------------
    -- Test if the tables exists
    -----------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @FactSchemaName AND TABLE_NAME = @FactTableName) BEGIN
        RAISERROR(N'The DMSA fact table %s does not exists.', 16, 1, @FactTableFullName)
    END

    IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @StagingSchemaName AND TABLE_NAME = @StagingTableName) BEGIN
        RAISERROR(N'The staging load table %s does not exists.', 16, 1, @StagingTableFullName)
    END

    
    -----------------------------------------------------------------------------------------------
    -- Construct SQL statement
    -----------------------------------------------------------------------------------------------
    DECLARE @SQL NVARCHAR(MAX) = N''

    IF @LogingIsEnabled = 1 BEGIN
        SET @SQL = @SQL + N'
    /*** Start log ***/
    DECLARE @DMSAId BIGINT = -1;
    EXECUTE [DZDB].[Audit].[DMSAStart]         @Database  = ''<Database>'',
                                        @TableName = ''<FactTableName>'',
                                        @Schema = ''<FactSchemaName>'',
                                        @DMSAId = @DMSAId OUTPUT,
                                        @ExecutionId = @ExecutionId;
                                        --@Source = ''<StagingSchemaName>.<StagingTableName>'',
                                        --@StoredProcedureName = ''SwitchFact'',
                                        --@StoredProcedureVersion = ''1.0'',
                                        --@TableTruncated = 1;
    '
    END
    ELSE BEGIN
        SET @SQL = @SQL + N'
    DECLARE @DMSAId BIGINT = -1;  --@DMSAId;
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
        SELECT @RecordsSelected = COUNT(*), @RecordsInserted = COUNT(*) FROM <FactTableFullName>;

        EXECUTE [DZDB].[Audit].[DMSAEnd]         @DMSAId = @DMSAId,
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
        EXECUTE [DZDB].[Audit].[DMSAEnd] @DMSAId = @DMSAId,
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
    SET @SQL = REPLACE(@SQL, N'<Database>', @Database);


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