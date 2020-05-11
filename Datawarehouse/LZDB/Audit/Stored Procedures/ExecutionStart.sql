CREATE PROCEDURE Audit.ExecutionStart
    @PackageName NVARCHAR (260),
    @PackageId NVARCHAR (50),
    @ServerExecutionID BIGINT = 0,
    @Id BIGINT = 0 OUTPUT,
	@ParentId BIGINT = -1,
    @Status NVARCHAR(10) = 'Started', 
	@Database NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        -------------------------------------------------------
        -- Insert data
        -------------------------------------------------------
        INSERT INTO Audit.ExecutionLog ([PackageID], [PackageName], [ServerExecutionID], [StartTime], [EndTime], [Status], [UserName], [HostName], [Database])
        VALUES (@PackageId, @PackageName, @ServerExecutionID, GETDATE(), GETDATE(), @Status, SYSTEM_USER, HOST_NAME(), @Database);

        SELECT @Id = SCOPE_IDENTITY()
	
	END TRY

	BEGIN CATCH

		THROW

	END CATCH

END
