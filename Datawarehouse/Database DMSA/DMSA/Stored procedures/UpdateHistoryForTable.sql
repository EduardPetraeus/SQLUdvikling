CREATE   PROCEDURE [DMSA].[UpdateHistoryForTable]

@table NVARCHAR(128) 

AS 

DECLARE @prefixedTable NVARCHAR(140) = N'DMSA.' + @table
--DECLARE @opgørelsesmåned NCHAR(6) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyyMM'), -- kan bruges hvis man vil arkivere baseret på en bestemt måned

-- Check if the procedure has been run before in the current reporting month.
-- If that is the case, an error is raised. The history table must be cleaned up manualley before the operation can be performed
DECLARE @check NVARCHAR(MAX) = 'SELECT TOP(1) @exists = 1 FROM DM_History.' + @table -- + N' WHERE DKey_Opgørelsesmåned = ' + @opgørelsesmåned
DECLARE @exists INT

EXECUTE sp_executesql	@stmt = @check,
						@params = N'@exists INT OUTPUT',
						@exists = @exists OUTPUT

IF @exists = 1
BEGIN
	DECLARE @message NVARCHAR(MAX) = N'Data for tabellen ' + @table + N' er allerede arkiveret' -- for opgørelsesmåneden ' + @opgørelsesmåned
	RAISERROR (@message, 14, 1)
	RETURN
END

-- Generate and execute an insert statement
DECLARE @columns NVARCHAR(MAX) = N''
SELECT
	@columns += N'[' + name + N'], '
FROM sys.columns
WHERE object_id = OBJECT_ID(N'DMSA.' + @table)
ORDER BY column_id;

DECLARE @insert NVARCHAR(MAX) = N'INSERT INTO DM_History.' + @table + N'(' + @columns + N'[DKey_Opgørelsesmåned]) SELECT ' + @columns -- + @opgørelsesmåned 
+ N' FROM ' + @prefixedTable
EXECUTE (@insert)

-- Check if the source is a table, truncate if it is
IF EXISTS(SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(@prefixedTable))
EXECUTE Util.TruncateWithReseed @table = @prefixedTable, @restart = 0