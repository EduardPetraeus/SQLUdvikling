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
        -- Get data from parent job
        -------------------------------------------------------
        --IF @PackageName IS NULL OR @PackageId IS NULL
        --BEGIN
        --    IF NOT EXISTS (SELECT 1 FROM Audit.ExecutionLog WHERE Id = @ParentId)
        --        THROW 60000, 'ParentId must be valid if no package name or id is supplied', 1;
        --    ELSE
        --    BEGIN
        --        SELECT @PackageName = PackageName, @PackageId = PackageID
        --        FROM Audit.ExecutionLog
        --        WHERE Id = @ParentId
        --    END
        --END

        --DECLARE @JobLevel BIGINT = 1
        --IF EXISTS (SELECT 1 FROM Audit.ExecutionLog WHERE Id = @ParentId)
        --    SELECT @JobLevel = JobLevel + 1 FROM Audit.ExecutionLog WHERE Id = @ParentId

        -------------------------------------------------------
        -- Insert data
        -------------------------------------------------------
        INSERT INTO Audit.ExecutionLog ( [PackageID], [PackageName], [ServerExecutionID], [StartTime], [EndTime], [Status], [UserName], [HostName], [Database])
        VALUES ( @PackageId, @PackageName, @ServerExecutionID, GETDATE(), GETDATE(), @Status, SYSTEM_USER, HOST_NAME(), @Database);

        SELECT @Id = SCOPE_IDENTITY()
	
	END TRY

	BEGIN CATCH

		THROW

	END CATCH

END
