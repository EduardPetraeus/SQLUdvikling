CREATE PROCEDURE Utility.TruncateWithReseed(
	@table NVARCHAR(256),	-- The name of the table - prefixed with schema
	@restart BIT = 1		-- 1 to reset the identity column to the current minimum value, 0 to continue the sequence from its
							-- current maximum value
) 
AS

DECLARE @stmt NVARCHAR(MAX) = N'SELECT @count = COUNT(*) FROM ' + @table
DECLARE @count BIGINT

EXECUTE sp_executesql	@stmt = @stmt,
						@params = N'@count BIGINT OUTPUT',
						@count  = @count  OUTPUT

-- Do nothing if the table is empty
IF @count = 0 RETURN

DECLARE @column SYSNAME = (SELECT name FROM sys.identity_columns WHERE object_id = OBJECT_ID(@table))
DECLARE @reseedValue BIGINT = NULL

-- If the table has an identity column
IF @column IS NOT NULL BEGIN
	IF @restart = 1
		SET @stmt = N'SELECT @reseedValue = MIN([' + @column + ']) FROM ' + @table
	ELSE
		SET @stmt = N'SELECT @reseedValue = 1 + MAX([' + @column + ']) FROM ' + @table

	EXECUTE sp_executesql	@stmt = @stmt,
							@params = N'@reseedValue BIGINT OUTPUT',
							@reseedValue = @reseedValue OUTPUT
END

EXECUTE ('TRUNCATE TABLE ' + @table)

IF @reseedValue IS NOT NULL
	DBCC CHECKIDENT (@table, RESEED, @reseedValue)