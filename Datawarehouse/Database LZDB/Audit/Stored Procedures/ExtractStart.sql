CREATE PROCEDURE Audit.ExtractStart
	@Database		NVARCHAR (255),
    @TableName		NVARCHAR (255),
	@Schema			NVARCHAR (255),
    @ExtractId		BIGINT = -1 OUTPUT,
    @ExecutionId	BIGINT = -1,
    @IsFullLoad		BIT = 1
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO Audit.ExtractLog ([Database], [TableName], [Schema], [ExecutionId], [StartTime], [EndTime], [Status], [IsFullLoad])
    VALUES (@Database, @TableName, @Schema, @ExecutionId, GETDATE(), GETDATE(), 'Started', @IsFullLoad);

    SELECT @ExtractId = SCOPE_IDENTITY()
END
