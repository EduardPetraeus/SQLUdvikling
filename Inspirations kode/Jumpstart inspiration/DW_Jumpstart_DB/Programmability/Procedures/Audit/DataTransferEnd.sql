CREATE PROCEDURE Audit.DataTransferEnd
    @DataTransferId BIGINT,
    @Status NVARCHAR (20) = 'Succeeded',
    @RecordsSelected INT = 0,
    @RecordsInserted INT = 0,
    @RecordsUpdated INT = 0,
    @RecordsDeleted INT = 0,
    @RecordsFailed INT = 0,
    @RecordsDiscarded INT = 0
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        UPDATE [Audit].[DataTransferLog]
        SET [Status] = @Status,
            [EndTime] = GETDATE(),
            [RecordsSelected] = @RecordsSelected,
            [RecordsInserted] = @RecordsInserted,
            [RecordsUpdated] = @RecordsUpdated,
            [RecordsDeleted] = @RecordsDeleted,
            [RecordsFailed] = @RecordsFailed,
            [RecordsDiscarded] = @RecordsDiscarded
        WHERE [Id] = @DataTransferId
	
	END TRY

	BEGIN CATCH

        THROW;-- Ignore any errors
		
	END CATCH

END