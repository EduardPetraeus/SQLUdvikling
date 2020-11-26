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
	DECLARE @ArchiveCurrentId table (Inserted_Id BIGINT);

    INSERT INTO Audit.ArchiveLog ([Database], [TableName], [Schema], [ExecutionId], [StartTime], [EndTime], [IsFullLoad], [Status])

	OUTPUT INSERTED.Id INTO @ArchiveCurrentId

    VALUES (@Database, @TableName, @Schema,@ExecutionId, GETDATE(), GETDATE(), @IsFullLoad,'Started');

	SELECT @ArchiveId = Inserted_Id from @ArchiveCurrentId	
END
