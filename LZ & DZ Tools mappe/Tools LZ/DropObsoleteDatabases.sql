DECLARE @dropStatement NVARCHAR(MAX)

DECLARE c CURSOR FOR
SELECT
    CONCAT(N'DROP DATABASE [', name, ']')
FROM sys.databases
WHERE name IN (
    'Database AES_ATP',
    'Database Staging')

OPEN c
FETCH NEXT FROM c INTO @dropStatement

WHILE @@FETCH_STATUS = 0   
BEGIN
    PRINT @dropStatement
    EXECUTE(@dropStatement)
    FETCH NEXT FROM c INTO @dropStatement
END

CLOSE c
DEALLOCATE c
