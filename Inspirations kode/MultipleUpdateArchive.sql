CREATE PROCEDURE [Archive].[MultipleUpdateArchive]
    @Database SYSNAME,
    @ExecutionId BIGINT = -1,
    @ExtractDeleteAction NVARCHAR(10) = 'Delete',
    @PrintOnly BIT = 0,
	@RunUpdateArchiveCVR BIT = 0 --Parameter to run UpdateArchiveCVR for Virk, Prod and Deltagerperson tables (Extract --> Archive).
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -------------------------------------------------------
        -- Start transaction - join if there is an existing one
        -------------------------------------------------------
        DECLARE @TranCounter INT = @@TRANCOUNT
        DECLARE @SavePoint NVARCHAR(32) = CAST(@@PROCID AS NVARCHAR(20)) + N'_' + CAST(@@NESTLEVEL AS NVARCHAR(2));

        IF @TranCounter > 0
            SAVE TRANSACTION @SavePoint;
        ELSE
            BEGIN TRANSACTION SERIALIZABLE;
		
		DECLARE @DatabaseQueueName NVARCHAR(MAX) = @Database+'.System.ArchiveQueue';

		DECLARE @TableName NVARCHAR(255);
		DECLARE @Count INT;

		-- Dynamisk SQL til at finde længden af @Database+'.System.ArchiveQueue'
		DECLARE @QueueCountCommand NVARCHAR(255) = 
			'SELECT @cnt=COUNT(*) FROM ' + @DatabaseQueueName + ' WHERE ExecutionId = ' +CAST(@ExecutionId as NVARCHAR(MAX));

		-- Dynamisk SQL til hente og slette et element fra @Database+'.System.ArchiveQueue';
		DECLARE @PopQueueCommand NVARCHAR(512) = 
			'DECLARE @Tables TABLE (TableName NVARCHAR(255))

			 DELETE TOP (1) FROM ' + @DatabaseQueueName + ' WITH (ROWLOCK, READPAST)
			 OUTPUT DELETED.TableName INTO @Tables
			 WHERE ExecutionId = '+CAST(@ExecutionId as NVARCHAR(MAX))+'

			 SELECT TOP 1 @TableName = TableName FROM @Tables';


		EXECUTE sp_executesql @QueueCountCommand, N'@cnt INT OUTPUT', @cnt = @Count OUTPUT;
		WHILE (@Count > 0) 
		BEGIN
			EXECUTE sp_executesql @PopQueueCommand, N'@TableName VARCHAR(255) OUTPUT', @TableName = @TableName OUTPUT;
			EXECUTE sp_executesql @QueueCountCommand, N'@cnt INT OUTPUT', @cnt = @Count OUTPUT;
			IF @RunUpdateArchiveCVR = 1
				BEGIN 
					EXEC Archive.UpdateArchiveCVR @ExecutionId, @Tablename, @ExtractDeleteAction;
				END
			ELSE
				BEGIN
					EXEC Archive.UpdateArchive @Database, @TableName, @ExecutionId, @ExtractDeleteAction, @PrintOnly;
				END
		END

		-------------------------------------------------------
		-- Commit transaction (if started here)
		-------------------------------------------------------
		IF @TranCounter = 0
			COMMIT TRANSACTION;
	
	END TRY

	BEGIN CATCH

        -------------------------------------------------------
		-- Rollback if transaction was started here OR rollback
        -- to @SavePoint if transaction OK, ELSE throw error
        -------------------------------------------------------
	DECLARE @ErrorMessage NVARCHAR(MAX)
		,@ErrorSeverity INT
		,@ErrorState INT;
	SELECT @ErrorMessage = ERROR_MESSAGE() + 'Line' + CAST(ERROR_LINE() AS NVARCHAR(5))
		,@ErrorSeverity = ERROR_SEVERITY()
		,@ErrorState = ERROR_STATE();
	RAISERROR (
			 @ErrorMessage
			,@ErrorSeverity
			,@ErrorState
			);
		
		IF @TranCounter = 0 BEGIN
			ROLLBACK TRANSACTION;
		END;
		ELSE IF XACT_STATE() = 1 BEGIN
			ROLLBACK TRANSACTION @SavePoint
		END;

		THROW;
	END CATCH
END