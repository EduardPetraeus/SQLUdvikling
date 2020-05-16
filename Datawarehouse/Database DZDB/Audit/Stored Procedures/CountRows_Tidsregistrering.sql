CREATE PROCEDURE [Audit].[CountRows_Tidsregistrering]

    @CubeName  NVARCHAR (255),
	@ExecutionId BIGINT 

	AS
	BEGIN

    SET NOCOUNT ON

	BEGIN TRY

	UPDATE [Audit].[CubeLog]
	SET [RecordsSelected] = 
	CASE 
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Data sidst opdateret' 
	THEN (SELECT COUNT(*) FROM [DM].[Tidsregistrering].[V_dwh_load_date])
	 
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Kontoplan' 
	THEN (SELECT COUNT(*) FROM [DM].[Tidsregistrering].[V_Kontoplan]) 
	
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Medarbejder' 
	THEN (SELECT COUNT(*) FROM [DM].[Tidsregistrering].[V_Medarbejder]) 
		
	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Registreringskategori' 
	THEN (SELECT COUNT(*) FROM [DM].[Tidsregistrering].[V_Registreringskategori]) 

	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Tid aktivitetsdato' 
	THEN (SELECT COUNT(*) FROM [DM].[Tidsregistrering].[V_Tid_Aktivitetsdato]) 

	WHEN [ExecutionId] = @ExecutionId AND [CubeName] = @CubeName AND [TableName] = 'Tidsregistrering' 
	THEN (SELECT COUNT(*) FROM [DM].[Tidsregistrering].[V_Tidsregistrering]) 

	END

 	WHERE RecordsSelected IS NULL

	END TRY
	
	BEGIN CATCH

	    THROW

	END CATCH

END
GO