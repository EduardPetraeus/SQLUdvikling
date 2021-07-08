CREATE PROCEDURE Audit.ArchiveEnd
    @ArchiveId BIGINT,
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

        UPDATE Audit.ArchiveLog
        SET [Status] = @Status,
            [EndTime] = GETDATE(),
            [RecordsSelected] = @RecordsSelected,
            [RecordsInserted] = @RecordsInserted,
            [RecordsUpdated] = @RecordsUpdated,
            [RecordsDeleted] = @RecordsDeleted,
            [RecordsFailed] = @RecordsFailed,
            [RecordsDiscarded] = @RecordsDiscarded
        WHERE [Id] = @ArchiveId
	
	END TRY

	BEGIN CATCH

        -- Ignore any errors
		
	END CATCH

END