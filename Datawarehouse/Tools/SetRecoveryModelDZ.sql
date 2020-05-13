--Settings
SET NOCOUNT ON;

--Variables
DECLARE @sql NVARCHAR(max)
DECLARE @targer_server NVARCHAR(100)
DECLARE @cur_hostname NVARCHAR(100)
SET @cur_hostname = HOST_NAME() COLLATE DATABASE_DEFAULT

--Set DB for full Recovery
DECLARE @CompleteRecModelTbl TABLE (
   [host] NVARCHAR(255),
   [dbnametest] NVARCHAR(255),
   [recovery_model_desc] NVARCHAR(255)
)

-- recovery_model_desc kan kun vaere 'FULL' eller 'SIMPLE'
INSERT INTO @CompleteRecModelTbl
VALUES 
('BMAT-DZSQL-P01', 'Maintenance', 'SIMPLE'),
('BMAT-DZSQL-P01', 'SSISDB', 'SIMPLE'),
('BMAT-DZSQL-P01', 'DM', 'SIMPLE'),
('BMAT-DZSQL-P01', 'DM Direktionsrapportering', 'SIMPLE'),
('BMAT-DZSQL-P01', 'DZDB', 'SIMPLE')
;

DECLARE @target_host NVARCHAR(255)
DECLARE @target_dbname NVARCHAR(255)
DECLARE @target_recovery_model_desc NVARCHAR(255)
DECLARE @C_target_RM CURSOR

--Server info
DECLARE @RecModelTbl TABLE (
   [dbname] NVARCHAR(255),
   [recovery_model_desc] NVARCHAR(255)
)
DECLARE @c_dbname NVARCHAR(255)
DECLARE @c_recovery_model_desc NVARCHAR(255)
DECLARE @C_RM CURSOR
SET @sql = 'SELECT name as dbname, recovery_model_desc FROM sys.databases'
DELETE @RecModelTbl
INSERT INTO @RecModelTbl EXEC (@sql)

-- Method
SET @C_RM = CURSOR FOR
SELECT * FROM @RecModelTbl

OPEN @C_RM 
FETCH NEXT
FROM @C_RM INTO @c_dbname, @c_recovery_model_desc
WHILE @@FETCH_STATUS = 0
    BEGIN
        --PRINT @c_dbname + ' ' +  @c_recovery_model_desc

        SET @C_target_RM = CURSOR FOR
        SELECT * FROM @CompleteRecModelTbl WHERE host = @cur_hostname

        OPEN @C_target_RM
        FETCH NEXT
        FROM @C_target_RM INTO @target_host, @target_dbname, @target_recovery_model_desc
        WHILE @@FETCH_STATUS = 0
            BEGIN
                --PRINT @target_host + ' ' +  @target_dbname + ' ' + @target_recovery_model_desc
                IF @c_dbname = @target_dbname AND @c_recovery_model_desc <> @target_recovery_model_desc
                    BEGIN
                        PRINT 'Host:"'+@target_host+'" DB:"'+ @target_dbname+'"'
                        PRINT 'Aendrer RecModel: "'+@c_recovery_model_desc+'" til "'+@target_recovery_model_desc+'"' + CHAR(10)
                        SET @sql = 'ALTER DATABASE ['+@target_dbname+ '] SET RECOVERY ' + @target_recovery_model_desc
                        --PRINT @sql
                        EXEC (@sql)
                    END
                FETCH NEXT
                FROM @C_target_RM INTO @target_host, @target_dbname, @target_recovery_model_desc
            END
        CLOSE @C_target_RM
            
        FETCH NEXT
        FROM @C_RM INTO @c_dbname, @c_recovery_model_desc
    END
CLOSE @C_RM

SET @sql = 'SELECT name as dbname, recovery_model_desc FROM sys.databases ORDER by recovery_model_desc, dbname'
DELETE @RecModelTbl
INSERT INTO @RecModelTbl EXEC (@sql)
OPEN @C_RM
FETCH NEXT
FROM @C_RM INTO @c_dbname, @c_recovery_model_desc
PRINT CHAR(10) + 'Samlet status for recovery model for host:"'+@cur_hostname+'"'
WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '"'+@c_recovery_model_desc + '" - "'+@c_dbname+'"'
        FETCH NEXT
        FROM @C_RM INTO @c_dbname, @c_recovery_model_desc
    END
CLOSE @C_RM

SET NOCOUNT OFF;