CREATE PROCEDURE [Audit].[DataTransferStart]
    @SchemaName NVARCHAR (255),
    @TableName NVARCHAR (255),
    @DataTransferId BIGINT = -1 OUTPUT,
    @ExecutionId BIGINT = -1,
    @Source NVARCHAR (1000) = NULL,
    @TaskID NVARCHAR (50) = NULL,
	@TaskName NVARCHAR (260) = NULL,
    @StoredProcedureName NVARCHAR (255) = NULL,
    @StoredProcedureVersion NVARCHAR (255) = NULL,
    @TableTruncated BIT = NULL,
    @Status NVARCHAR(10) = 'Started'
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        INSERT INTO [Audit].[DataTransferLog] ([SchemaName], [TableName], [ExecutionId], [Source], [TaskID], [TaskName], [StoredProcedureName], [StoredProcedureVersion], [TableTruncated], [StartTime], [EndTime], [Status])
        VALUES (@SchemaName, @TableName, @ExecutionId, @Source, @TaskID, @TaskName, @StoredProcedureName, @StoredProcedureVersion, @TableTruncated, GETDATE(), GETDATE(), @Status);

        SELECT @DataTransferId = SCOPE_IDENTITY()
	
	END TRY

	BEGIN CATCH

		THROW;

	END CATCH

END
