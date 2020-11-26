CREATE PROCEDURE [Audit].[DMSAStart]
	@Database		NVARCHAR (255),
    @TableName		NVARCHAR (255),
	@Schema			NVARCHAR (255),
    @DMSAId		BIGINT = -1 OUTPUT,
    @ExecutionId	BIGINT = -1

AS
BEGIN
    SET NOCOUNT ON
	DECLARE @DMSACurrentId table (Inserted_Id BIGINT);


    INSERT INTO [Audit].[DMSALog] ([Database], [TableName], [Schema], [ExecutionId], [StartTime], [EndTime], [Status])
    
	OUTPUT INSERTED.Id INTO @DMSACurrentId
	
	VALUES (@Database, @TableName, @Schema, @ExecutionId, GETDATE(), GETDATE(), 'Started');

    SELECT @DMSAId = Inserted_Id from @DMSACurrentId 
END


