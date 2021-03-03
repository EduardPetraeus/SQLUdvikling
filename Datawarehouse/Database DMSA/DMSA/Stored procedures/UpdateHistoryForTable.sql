CREATE PROCEDURE [DMSA].[UpdateHistoryForTable]

@table  NVARCHAR(120)

AS 
DECLARE @v_Schema NVARCHAR(50) = 'DMSA'
DECLARE @v_prefixedTable NVARCHAR(180) = '[' + @v_Schema + ']' + '.' + '[' + @table + ']'
DECLARE @v_historyTable NVARCHAR(200) = '[' + @v_Schema +  '_History' + ']' + '.' + '[' +  @table + ']'
--DECLARE @opgørelsesmåned NCHAR(6) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyyMM'), -- kan bruges hvis man vil arkivere baseret på en bestemt måned

-- Check if the procedure has been run before in the current reporting month.
-- If that is the case, an error is raised. The history table must be cleaned up manualley before the operation can be performed
--DECLARE @v_check NVARCHAR(MAX) = 'SELECT TOP(1) @exists = 1 FROM' + @v_historyTable -- + N' WHERE DKey_Opgørelsesmåned = ' + @opgørelsesmåned
--DECLARE @v_exists INT

--EXECUTE sp_executesql	@stmt = @v_check,
--						@params = N'@exists INT OUTPUT',
--						@exists = @v_exists OUTPUT

--IF @v_exists = 1
--BEGIN
--	DECLARE @message NVARCHAR(MAX) = N'Data for tabellen ' + @table + N' er allerede arkiveret' -- for opgørelsesmåneden ' + @opgørelsesmåned
--	RAISERROR (@message, 14, 1)
--	RETURN
--END

-- Generate and execute an insert statement
DECLARE @v_columns NVARCHAR(MAX) = N''
SELECT
	@v_columns += N'[' + name + N'], '
FROM sys.columns
WHERE object_id = OBJECT_ID(@v_prefixedTable)
AND [name] NOT LIKE '%Meta_%'
ORDER BY column_id;
--                                                                                      N'[DKey_Opgørelsesmåned]), hvis man bruger tidsintervaller til at styre efter
DECLARE @insert NVARCHAR(MAX) = N'INSERT INTO'  + @v_historyTable + N'(' + @v_columns + N'[Insert_Datetime]) 
SELECT ' + @v_columns + 'GETDATE()'  -- + @opgørelsesmåned 
+ N' FROM ' + @v_prefixedTable


EXECUTE (@insert)
-- PRINT @insert


-- Check if the source is a table, truncate if it is
--IF EXISTS(SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(@v_prefixedTable))
--EXECUTE Utility.TruncateWithReseed @table = @v_prefixedTable, @restart = 0