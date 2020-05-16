CREATE PROCEDURE [Audit].[DMSAStart]
	@Database		NVARCHAR (255),
    @TableName		NVARCHAR (255),
	@Schema			NVARCHAR (255),
    @DMSAId		BIGINT = -1 OUTPUT,
    @ExecutionId	BIGINT = -1

AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO [Audit].[DMSALog] ([Database], [TableName], [Schema], [ExecutionId], [StartTime], [EndTime], [Status])
    VALUES (@Database, @TableName, @Schema, @ExecutionId, GETDATE(), GETDATE(), 'Started');

    SELECT @DMSAId = SCOPE_IDENTITY()
END
