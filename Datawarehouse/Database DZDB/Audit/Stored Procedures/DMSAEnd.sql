﻿CREATE PROCEDURE [Audit].[DMSAEnd]
    @DMSAId BIGINT,
    @Status NVARCHAR (20) = 'Succeeded',
    @RecordsSelected INT = 0,
    @RecordsInserted INT = 0,
    @RecordsUpdated INT = 0,
    @RecordsFailed INT = 0,
    @RecordsDiscarded INT = 0
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        UPDATE [Audit].[DMSALog]
        SET [Status] = @Status,
            [EndTime] = GETDATE(),
            [RecordsSelected] = @RecordsSelected,
            [RecordsInserted] = @RecordsInserted,
            [RecordsUpdated] =  @RecordsUpdated,
            [RecordsFailed] = @RecordsFailed,
            [RecordsDiscarded] = @RecordsDiscarded
        WHERE [Id] = @DMSAId
	
	END TRY

	BEGIN CATCH

        -- Ignore any errors
		
	END CATCH

END