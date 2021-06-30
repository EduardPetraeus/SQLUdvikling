CREATE PROCEDURE [Audit].[CountRows_Forudsætningsoverblik]

    @CubeName  NVARCHAR (255),
	@ExecutionId BIGINT 

	AS
	BEGIN

    SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @TableOfTables TABLE(
		[CubeLogTableName] nvarchar(250),
		[SourceViewName] nvarchar(250)
		);

	INSERT INTO @TableOfTables 
	(CubeLogTableName,SourceViewName)
	VALUES
	('Brancheoplysninger'		, '[DM].[Forudsætningsoverblik].[v_Branche]'),
	('Forudsætningsoverblik'	, '[DM].[Forudsætningsoverblik].[v_Forudsætningsoverblik] '),
	('Kommende besøg'			, '[DM].[Forudsætningsoverblik].[v_KommendeBesøg]'),
	('Kommune'					, '[DM].[Forudsætningsoverblik].[v_Kommune]'),
	('Medarbejder'				, '[DM].[Forudsætningsoverblik].[v_Medarbejder]'),
	('TC - Branche TG'			, '[DM].[Forudsætningsoverblik].[v_Org_Enhed]'),
	('TC – US'					, '[DM].[Forudsætningsoverblik].[v_Tc_Us]'),
	('Tid Besøgsplan dag'		, '[DM].[Forudsætningsoverblik].[v_Tid_Besøgsplan_Dag]'),
	('Tid Oprettet dato'		, '[DM].[Forudsætningsoverblik].[v_Tid_Oprettet_Dato]'),
	('Tid Startdato'			, '[DM].[Forudsætningsoverblik].[v_Tid_Startdato]'),
	('Tid Varslingsdato'		, '[DM].[Forudsætningsoverblik].[v_Tid_Varslingsdato]')
	;

	DECLARE @currentCubeLogTableName NVARCHAR(250), @currentSourceViewName NVARCHAR(250);

	DECLARE cursTable CURSOR FOR 
		SELECT CubeLogTableName,SourceViewName FROM @TableOfTables;

	OPEN cursTable;
	FETCH NEXT FROM cursTable INTO @currentCubeLogTableName, @currentSourceViewName;

	WHILE @@FETCH_STATUS=0
	BEGIN
		DECLARE @count BIGINT;
		DECLARE @cmd NVARCHAR(max) = 'SELECT @countParam=COUNT(*) FROM '+@currentSourceViewName;

		EXEC sp_executesql @cmd, N'@countParam bigint OUTPUT', @countParam = @count OUTPUT;

		UPDATE [Audit].[CubeLog]
			SET [RecordsSelected] = @count
		WHERE [ExecutionId] = @ExecutionId 
		AND [CubeName] = @CubeName 
		AND [TableName] = @currentCubeLogTableName;

		FETCH NEXT FROM cursTable INTO @currentCubeLogTableName, @currentSourceViewName;
	END
	CLOSE cursTable;
	DEALLOCATE cursTable;
	 
	--Extra candy for Forudsætningsoverblik
	UPDATE [Audit].[CubeLog]
		SET [RecordsSelected] = 1
	WHERE [ExecutionId] = @ExecutionId 
	AND [CubeName] = @CubeName 
	AND [TableName] IN ( 'Data sidst opdateret forudsætningsoverblik', 'Data sidst opdateret kommende besøg' );

END
GO