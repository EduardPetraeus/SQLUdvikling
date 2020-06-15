CREATE PROCEDURE [Audit].[CountRows_Ordre]

    @CubeName  NVARCHAR (255),
	@ExecutionId BIGINT 

	AS
	BEGIN

    SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET XACT_ABORT ON

	BEGIN TRY

	UPDATE [Audit].[CubeLog]
	SET [RecordsSelected] = 
	CASE 
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Kunde' 
	THEN (SELECT COUNT(*) FROM [DMSA].[Ordre].[v_Kunde] WITH (NOLOCK))
	 
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Ordre' 
	THEN (SELECT COUNT(*) FROM [DMSA].[Ordre].[v_Ordre] WITH (NOLOCK)) 
	
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Produkt' 
	THEN (SELECT COUNT(*) FROM [DMSA].[Ordre].[v_Produkt] WITH (NOLOCK)) 
		
	END

 	WHERE RecordsSelected IS NULL

	END TRY
	
	BEGIN CATCH

	    DECLARE @ErrorMessage NVARCHAR(max)
		,@ErrorSeverity INT
		,@ErrorState INT;
	SELECT @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() AS NVARCHAR(5))
		,@ErrorSeverity = ERROR_SEVERITY()
		,@ErrorState = ERROR_STATE();
	IF @@trancount > 0
		ROLLBACK TRANSACTION;
	RAISERROR (
			@ErrorMessage
			,@ErrorSeverity
			,@ErrorState
			);

	END CATCH

END
GO