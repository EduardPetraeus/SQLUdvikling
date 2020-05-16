CREATE PROCEDURE [Audit].[ProcessCubeEndFailed]
    @ExecutionId	  BIGINT,
    @Status           NVARCHAR (20) = 'Failed',
	@TableName        NVARCHAR (100) = 'None processed',
	@RecordsSelected  INT = 0,
	@RecordsProcessed INT = 0,
	@StartTime DATETIME
	
AS

BEGIN


    SET NOCOUNT ON

    BEGIN TRY

        UPDATE [Audit].[CubeLog]
        SET [Status] = @Status,
            [EndTime] = GETDATE(),
			[TableName] = @TableName,
			[RecordsSelected] = @RecordsSelected,
			[RecordsProcessed] = @RecordsProcessed
			
			
       
        WHERE [ExecutionId] = @ExecutionId
	
	END TRY

	BEGIN CATCH

        -- Ignore any errors
		
	END CATCH

END

