CREATE PROCEDURE [Audit].[ProcessCubeStart]
    @CubeName		NVARCHAR (255),
    @Starttime		DATETIME OUTPUT,
    @ExecutionId	BIGINT = -1

AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO [Audit].[CubeLog] ([ExecutionId], [Status], [StartTime], [EndTime], [CubeName], [TableName],[RecordsSelected], [RecordsProcessed] )
    VALUES (@ExecutionId, 'Started', GETDATE(), GETDATE(), @CubeName,'',0 ,0 );
	 

	SET @Starttime = GETDATE()

END
