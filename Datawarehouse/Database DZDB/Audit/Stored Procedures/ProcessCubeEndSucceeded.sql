CREATE PROCEDURE [Audit].[ProcessCubeEndSucceeded]

    @Status    NVARCHAR (20) = 'Succeeded',
    @CubeName  NVARCHAR (255),
	@ExecutionId BIGINT,
	@Starttime DATETIME

AS

BEGIN

    SET NOCOUNT ON


BEGIN TRY

BEGIN TRAN
	
declare @sql nvarchar(max)
set @sql = 'INSERT INTO [DZDB].[Audit].[CubeLog] ([CubeName], [TableName], [RecordsProcessed]) 
SELECT *
FROM OPENROWSET(
	''MSOLAP''
	,''Data Source= <datasource>; Catalog = <connection>; Integrated Security=SSPI;''
	,''SELECT DISTINCT [CATALOG_NAME] AS [Kube], DIMENSION_CAPTION AS [Tabel Navn], DIMENSION_CARDINALITY AS [Rækker]  
	FROM $system.MDSchema_Dimensions WHERE DIMENSION_CAPTION <> ''''Measures'''' ORDER BY DIMENSION_CAPTION''
)'

SET @sql = REPLACE(@sql,'<connection>', @CubeName);
SET @sql = REPLACE(@sql,'<datasource>', @@SERVERNAME);

EXECUTE sp_executesql @sql

	
		UPDATE [Audit].[CubeLog]
		SET [ExecutionId] = @ExecutionId
		where [ExecutionId] IS NULL

		
		UPDATE [Audit].[CubeLog]
        SET 
			[Status] = @Status,
            [EndTime] = GETDATE(),
			[StartTime] = @Starttime
       
        WHERE [CubeName] = @CubeName 
		AND [ExecutionId] =@ExecutionId


		DELETE FROM [Audit].[CubeLog]
        WHERE [TableName] = ''

		--INSERT INTO [Audit].[CubeLog] (Id)
		--VALUES (400)


COMMIT TRAN

		END TRY 

	BEGIN CATCH

		-- ROLLBACK TRAN
		-- RAISERROR
		THROW

	END CATCH


END

GO


