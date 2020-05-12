CREATE PROCEDURE Audit.ArchiveStart
    @Database NVARCHAR (255),
    @TableName NVARCHAR (255),
	@Schema		NVARCHAR (255) = 'Archive',
    @ArchiveId BIGINT = -1 OUTPUT,
    @ExecutionId BIGINT = -1,
	@IsFullLoad INT = -1
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO Audit.ArchiveLog ([Database], [TableName], [Schema], [ExecutionId], [StartTime], [EndTime], [IsFullLoad], [Status])
    VALUES (@Database, @TableName, @Schema,@ExecutionId, GETDATE(), GETDATE(), @IsFullLoad,'Started');

    SELECT @ArchiveId = SCOPE_IDENTITY()	
END
