CREATE PROCEDURE Audit.ArchiveStart
    @TableName NVARCHAR (255),
    @ArchiveId BIGINT = -1 OUTPUT,
    @ExecutionId BIGINT = -1,
    @StoredProcedureName NVARCHAR (255) = NULL,
    @StoredProcedureVersion NVARCHAR (255) = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        INSERT INTO Audit.ArchiveLog ([TableName], [ExecutionId], [StoredProcedureName], [StoredProcedureVersion], [StartTime], [EndTime], [Status])
        VALUES (@TableName, @ExecutionId, @StoredProcedureName, @StoredProcedureVersion, GETDATE(), GETDATE(), 'Started');

        SELECT @ArchiveId = SCOPE_IDENTITY()
	
	END TRY

	BEGIN CATCH

		THROW

	END CATCH

END
