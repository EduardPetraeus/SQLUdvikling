CREATE PROCEDURE [Audit].[StagingEnd]
    @StagingId BIGINT,
    @Status NVARCHAR (20) = 'Succeeded',
    @RecordsSelected INT = 0,
    @RecordsInserted INT = 0,
    @RecordsFailed INT = 0,
	@RecordsDiscarded INT = 0

AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        UPDATE [Audit].[StagingLog]
        SET [Status] = @Status,
            [EndTime] = GETDATE(),
            [RecordsSelected] = @RecordsSelected,
            [RecordsInserted] = @RecordsInserted,
            [RecordsFailed] = @RecordsFailed,
			[RecordsDiscarded] = @RecordsDiscarded

        WHERE [Id] = @StagingId
	
	END TRY

	BEGIN CATCH

        -- Ignore any errors
		
	END CATCH

END