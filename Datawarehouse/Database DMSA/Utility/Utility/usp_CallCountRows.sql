CREATE PROCEDURE [Utility].[usp_CallCountRows]
AS

-- Declare variables. Aim: to provide table input and call usp_CursorCountRows.

DECLARE @TableInput NVARCHAR(100)
DECLARE @CreateStatement NVARCHAR(MAX) = N''

-- Declare Cursor. Schema_is 5 & 6 (DMSA and audit)

DECLARE c_CountRows CURSOR FOR 

	SELECT [name]
	FROM sys.tables
	WHERE schema_id in(5, 6)

-- Activate Cursor. Execute usp_CursorCountRows with table input from sys.tables. 

BEGIN TRY

	OPEN c_CountRows

	FETCH NEXT FROM c_CountRows INTO @TableInput

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @CreateStatement = @CreateStatement + 'EXEC [Utility].[usp_CursorCountRows] @Table = ' + '''' + @TableInput + '''' + ' '
		
		FETCH NEXT FROM c_CountRows INTO @TableInput
	END

		PRINT @Createstatement
		EXEC sp_executesql @Createstatement


END TRY

BEGIN CATCH

THROW;

END CATCH 