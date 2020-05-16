CREATE PROCEDURE [Utility].[usp_CursorCountRows] @Table NVARCHAR(100)
AS

-- Declare variables. 

DECLARE @CountRows NVARCHAR(MAX)
DECLARE @Createstatement NVARCHAR(MAX) = N''
DECLARE @Template NVARCHAR(MAX) = N'SELECT DISTINCT
	''{Tabel}'' AS Tabel,
	''{Kolonne}'' AS Kolonne,
	COUNT(*) AS AllRows,
	COUNT({Kolonne}) AS RowsWithData,
	COUNT(DISTINCT {Kolonne}) AS DistinctCount
FROM 
	{Skema}.{Tabel}'

-- Declare Cursor. Get tables and columns from sys tables. 

DECLARE c_countrows CURSOR FOR 

	SELECT REPLACE ( REPLACE ( REPLACE ( @Template, 
	'{Tabel}', ST.[name] ),
	'{Kolonne}', SC.[name]),
	'{Skema}', SS.[name])
	FROM sys.columns SC
			INNER JOIN sys.tables ST
			ON SC.object_id = ST.object_id
			INNER JOIN sys.schemas SS
			ON ST.schema_id = ss.schema_id
			where ST.[name] = @Table 

-- Activate Cursor. 
	
BEGIN TRY

	OPEN c_countrows

	FETCH NEXT FROM c_countrows INTO @CountRows

	WHILE @@FETCH_STATUS = 0 

	BEGIN

		SET @Createstatement = @Createstatement + ' UNION ' + @CountRows

		FETCH NEXT FROM c_countrows INTO @CountRows

	END

		CLOSE c_countrows
		DEALLOCATE c_countrows

-- All rows in @Createstatement and after execute. 

	SET @Createstatement = SUBSTRING( @Createstatement, 7, LEN(@Createstatement))

	EXEC sp_executesql @Createstatement

END TRY

BEGIN CATCH

THROW;

END CATCH 