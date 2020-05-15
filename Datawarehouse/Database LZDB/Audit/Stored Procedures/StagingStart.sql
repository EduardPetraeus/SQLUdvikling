CREATE PROCEDURE [Audit].[StagingStart]
	@Database		NVARCHAR (255),
    @TableName		NVARCHAR (255),
	@Schema			NVARCHAR (255),
    @StagingId		BIGINT = -1 OUTPUT,
    @ExecutionId	BIGINT = -1,
    @IsFullLoad		BIT = 1
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO [Audit].[StagingLog]([Database], [TableName], [Schema], [ExecutionId], [StartTime], [EndTime], [Status], [IsFullLoad])
    VALUES (@Database, @TableName, @Schema, @ExecutionId, GETDATE(), GETDATE(), 'Started', @IsFullLoad);

    SELECT @StagingId = SCOPE_IDENTITY()
END
