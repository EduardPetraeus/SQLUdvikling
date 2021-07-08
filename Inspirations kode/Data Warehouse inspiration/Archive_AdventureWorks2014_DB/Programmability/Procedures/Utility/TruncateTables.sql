--
-- This procedure will truncate all tables in a given schema that matches a given name pattern
-- Use it e.g. as the first step in loads to the Extract layer
--
CREATE PROCEDURE Utility.TruncateTables
	@SchemaName SYSNAME,
	@TableNamePattern SYSNAME = N'%'
AS
DECLARE @truncateCmd NVARCHAR(150)

DECLARE c CURSOR FOR
SELECT N'TRUNCATE TABLE ' + @SchemaName + '.' + name + ';' FROM sys.tables
WHERE schema_id = SCHEMA_ID(@SchemaName)
	AND name LIKE @TableNamePattern

OPEN c
FETCH c INTO @truncateCmd
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @truncateCmd
	EXECUTE (@truncateCmd)
	FETCH c INTO @truncateCmd
END
CLOSE c
DEALLOCATE c
