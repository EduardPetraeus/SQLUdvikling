CREATE PROCEDURE Audit.ExtractStart
    @TableName NVARCHAR (255),
    @ExtractId BIGINT = -1 OUTPUT,
    @ExecutionId BIGINT = -1,
    @IsFullLoad BIT = 1
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        INSERT INTO Audit.ExtractLog ([TableName], [ExecutionId], [StartTime], [EndTime], [Status], [IsFullLoad])
        VALUES (@TableName, @ExecutionId, GETDATE(), GETDATE(), 'Started', @IsFullLoad);

        SELECT @ExtractId = SCOPE_IDENTITY()
	
	END TRY

	BEGIN CATCH

		THROW

	END CATCH

END
