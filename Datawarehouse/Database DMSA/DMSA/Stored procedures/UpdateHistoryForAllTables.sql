CREATE PROCEDURE [DMSA].[UpdateHistoryForAllTables]
AS 

DECLARE @v_tableName NVARCHAR(120)
DECLARE c_tables CURSOR LOCAL FAST_FORWARD FOR 
SELECT tableName = name 
FROM sys.tables where schema_id = schema_id('DMSA_History')

SET NOCOUNT ON
SET XACT_ABORT ON

OPEN c_tables
BEGIN TRANSACTION
BEGIN TRY
    FETCH NEXT FROM c_tables INTO @v_tableName

    WHILE @@FETCH_STATUS = 0  
    BEGIN
        EXECUTE DMSA.UpdateHistoryForTable @table = @v_tableName
        FETCH NEXT FROM c_tables INTO @v_tableName
    END 

    COMMIT TRANSACTION
    CLOSE c_tables
    DEALLOCATE c_tables
END TRY
BEGIN CATCH
    DECLARE @errorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    ROLLBACK TRANSACTION
    DECLARE @cursorStatus INT = Cursor_Status('local', 'c_tables')
    IF @cursorStatus >= 0 BEGIN
        CLOSE c_tables
        DEALLOCATE c_tables
    END
    ELSE IF @cursorStatus = -1 BEGIN
        DEALLOCATE c_tables
    END
    RAISERROR (@errorMessage, 16, 1)
END CATCH